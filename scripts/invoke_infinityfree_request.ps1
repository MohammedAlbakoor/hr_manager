param(
    [Parameter(Mandatory = $true)]
    [string]$Domain,

    [Parameter(Mandatory = $true)]
    [string]$Path,

    [hashtable]$Query = @{},

    [ValidateSet('http', 'https')]
    [string]$Scheme = 'http',

    [string]$Method = 'GET',

    $Body = $null,

    [int]$TimeoutSec = 120
)

$ErrorActionPreference = 'Stop'

function ConvertFrom-HexString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hex
    )

    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16)
    }

    return $bytes
}

function Get-InfinityFreeBypassCookie {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DomainName
    )

    $challengeHtml = (Invoke-WebRequest -Uri "${Scheme}://$DomainName/" -UseBasicParsing -TimeoutSec $TimeoutSec).Content
    if ($challengeHtml -notmatch 'a=toNumbers\("([0-9a-f]+)"\),b=toNumbers\("([0-9a-f]+)"\),c=toNumbers\("([0-9a-f]+)"\)') {
        throw "Failed to parse the InfinityFree anti-bot challenge for $DomainName."
    }

    $key = ConvertFrom-HexString -Hex $Matches[1]
    $iv = ConvertFrom-HexString -Hex $Matches[2]
    $payload = ConvertFrom-HexString -Hex $Matches[3]

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aes.Key = $key
    $aes.IV = $iv

    try {
        $decryptor = $aes.CreateDecryptor()
        $plain = $decryptor.TransformFinalBlock($payload, 0, $payload.Length)
    } finally {
        $aes.Dispose()
    }

    $builder = New-Object System.Text.StringBuilder
    foreach ($byte in $plain) {
        [void]$builder.Append($byte.ToString('x2'))
    }

    return $builder.ToString()
}

function New-QueryString {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Values
    )

    if ($Values.Count -eq 0) {
        return ''
    }

    $pairs = foreach ($key in $Values.Keys) {
        '{0}={1}' -f [Uri]::EscapeDataString([string]$key), [Uri]::EscapeDataString([string]$Values[$key])
    }

    return '?' + ($pairs -join '&')
}

$normalizedPath = if ($Path.StartsWith('/')) { $Path } else { "/$Path" }
$cookieValue = Get-InfinityFreeBypassCookie -DomainName $Domain
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.Cookies.Add((New-Object System.Net.Cookie('__test', $cookieValue, '/', $Domain)))

$uri = "${Scheme}://$Domain$normalizedPath$(New-QueryString -Values $Query)"

try {
    $requestParams = @{
        Uri          = $uri
        UseBasicParsing = $true
        WebSession   = $session
        TimeoutSec   = $TimeoutSec
        Method       = $Method
    }

    if ($null -ne $Body) {
        $requestParams['ContentType'] = 'application/json'
        $requestParams['Body'] = if ($Body -is [string]) {
            $Body
        } else {
            $Body | ConvertTo-Json -Compress -Depth 10
        }
    }

    $response = Invoke-WebRequest @requestParams
    [pscustomobject]@{
        Url        = $uri
        StatusCode = [int]$response.StatusCode
        Content    = $response.Content
    }
} catch {
    if (-not $_.Exception.Response) {
        throw
    }

    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    try {
        $body = $reader.ReadToEnd()
    } finally {
        $reader.Dispose()
    }

    [pscustomobject]@{
        Url        = $uri
        StatusCode = [int]$_.Exception.Response.StatusCode
        Content    = $body
    }
}
