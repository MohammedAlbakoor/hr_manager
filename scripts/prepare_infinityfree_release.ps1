param(
    [Parameter(Mandatory = $true)]
    [string]$Domain,

    [Parameter(Mandatory = $true)]
    [string]$DbHost,

    [Parameter(Mandatory = $true)]
    [string]$DbName,

    [Parameter(Mandatory = $true)]
    [string]$DbUser,

    [Parameter(Mandatory = $true)]
    [string]$DbPassword,

    [string]$DeployToken
)

$ErrorActionPreference = "Stop"

function New-RandomToken {
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return -join ($bytes | ForEach-Object { $_.ToString("x2") })
}

function Copy-DirectoryContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend"
$buildRoot = Join-Path $projectRoot "build\web"
$deployRoot = Join-Path $projectRoot "deploy\infinityfree"
$laravelRoot = Join-Path $deployRoot "laravel"
$htdocsRoot = Join-Path $deployRoot "htdocs"
$apiBaseUrl = "https://$Domain/api"

if ([string]::IsNullOrWhiteSpace($DeployToken)) {
    $DeployToken = New-RandomToken
}

$appKeyBytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($appKeyBytes)
$appKey = "base64:" + [Convert]::ToBase64String($appKeyBytes)

Write-Host "Preparing InfinityFree release bundle..."

if (Test-Path $deployRoot) {
    Remove-Item -LiteralPath $deployRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $deployRoot | Out-Null

Write-Host "Building Flutter Web with Wasm..."
flutter build web --release --wasm --base-href /app/ --dart-define="API_BASE_URL=$apiBaseUrl"

$webHtaccessPath = Join-Path $projectRoot "web\.htaccess"
$buildHtaccessPath = Join-Path $buildRoot ".htaccess"
if (Test-Path $webHtaccessPath) {
    Copy-Item -LiteralPath $webHtaccessPath -Destination $buildHtaccessPath -Force
}

Write-Host "Copying backend..."
New-Item -ItemType Directory -Path $laravelRoot | Out-Null
Copy-DirectoryContent -Source $backendRoot -Destination $laravelRoot

foreach ($path in @(
    ".env",
    ".git",
    "tests",
    ".phpunit.result.cache",
    "phpunit.xml",
    "README.md",
    "database\database.sqlite",
    "storage\logs\laravel.log",
    "public"
)) {
    $fullPath = Join-Path $laravelRoot $path
    if (Test-Path $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $htdocsRoot | Out-Null
Copy-DirectoryContent -Source (Join-Path $backendRoot "public") -Destination $htdocsRoot

$indexPhpPath = Join-Path $htdocsRoot "index.php"
$indexPhp = Get-Content -LiteralPath $indexPhpPath -Raw
$indexPhp = $indexPhp.Replace("__DIR__.'/../storage/framework/maintenance.php'", "__DIR__.'/../laravel/storage/framework/maintenance.php'")
$indexPhp = $indexPhp.Replace("__DIR__.'/../vendor/autoload.php'", "__DIR__.'/../laravel/vendor/autoload.php'")
$indexPhp = $indexPhp.Replace("__DIR__.'/../bootstrap/app.php'", "__DIR__.'/../laravel/bootstrap/app.php'")
Set-Content -LiteralPath $indexPhpPath -Value $indexPhp -Encoding UTF8

$appDir = Join-Path $htdocsRoot "app"
if (Test-Path $appDir) {
    Remove-Item -LiteralPath $appDir -Recurse -Force
}
New-Item -ItemType Directory -Path $appDir | Out-Null
Copy-DirectoryContent -Source $buildRoot -Destination $appDir

$envContent = @"
APP_NAME=HRManager
APP_ENV=production
APP_KEY=$appKey
APP_DEBUG=false
APP_URL=https://$Domain
CORS_ALLOWED_ORIGINS=https://$Domain,http://$Domain

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=$DbHost
DB_PORT=3306
DB_DATABASE=$DbName
DB_USERNAME=$DbUser
DB_PASSWORD=$DbPassword

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database

CACHE_STORE=database

MEMCACHED_HOST=127.0.0.1

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_SCHEME=null
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="`$`{APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

VITE_APP_NAME="`$`{APP_NAME}"
"@

Set-Content -LiteralPath (Join-Path $laravelRoot ".env") -Value $envContent -Encoding UTF8

$deployPhpPath = Join-Path $htdocsRoot "deploy.php"
$deployPhp = @"
<?php

declare(strict_types=1);

use Illuminate\Contracts\Console\Kernel;

header('Content-Type: text/plain; charset=utf-8');

if (!isset(`$_GET['token']) || !hash_equals('$DeployToken', (string) `$_GET['token'])) {
    http_response_code(403);
    echo 'Forbidden';
    exit;
}

set_time_limit(0);
define('LARAVEL_START', microtime(true));

require __DIR__ . '/../laravel/vendor/autoload.php';
`$app = require __DIR__ . '/../laravel/bootstrap/app.php';
/** @var Kernel `$kernel */
`$kernel = `$app->make(Kernel::class);

`$commands = [
    ['config:clear', []],
    ['route:clear', []],
    ['view:clear', []],
    ['migrate', ['--force' => true]],
    ['db:seed', ['--force' => true]],
    ['config:cache', []],
];

foreach (`$commands as [`$command, `$arguments]) {
    echo ">>> `$command\n";
    `$exitCode = `$kernel->call(`$command, `$arguments);
    echo trim(`$kernel->output()) . "\n";
    if (`$exitCode !== 0) {
        http_response_code(500);
        echo "FAILED: `$command (exit code `$exitCode)\n";
        exit;
    }
}

echo "Deployment initialization completed successfully.\n";
"@

Set-Content -LiteralPath $deployPhpPath -Value $deployPhp -Encoding UTF8

$deployInfo = [ordered]@{
    domain = $Domain
    apiBaseUrl = $apiBaseUrl
    deployRoot = $deployRoot
    htdocsRoot = $htdocsRoot
    laravelRoot = $laravelRoot
    deployToken = $DeployToken
}

$deployInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $deployRoot "deploy-info.json") -Encoding UTF8

Write-Host ""
Write-Host "InfinityFree bundle ready."
Write-Host "Deploy root: $deployRoot"
Write-Host "Deploy token: $DeployToken"
