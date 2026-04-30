param(
    [Parameter(Mandatory = $true)]
    [string]$AlwaysdataHost
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend"
$frontendOutput = Join-Path $projectRoot "build\\web"
$targetDir = Join-Path $backendRoot "public\\app"
$apiBaseUrl = "https://$AlwaysdataHost/api"

Write-Host "Building Flutter Web for alwaysdata..."
flutter build web --release --base-href /app/ --dart-define="API_BASE_URL=$apiBaseUrl"

if (Test-Path $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}

New-Item -ItemType Directory -Path $targetDir | Out-Null
Copy-Item -Path (Join-Path $frontendOutput "*") -Destination $targetDir -Recurse -Force

Write-Host ""
Write-Host "Flutter web build copied to: $targetDir"
Write-Host "Frontend URL after deployment: https://$AlwaysdataHost/app"
Write-Host "API URL after deployment: $apiBaseUrl"
