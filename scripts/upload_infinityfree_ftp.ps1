param(
    [Parameter(Mandatory = $true)]
    [string]$LocalRoot,

    [Parameter(Mandatory = $true)]
    [string]$FtpHost,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$RemoteRoot = "/"
)

$ErrorActionPreference = "Stop"

function Get-FtpUri {
    param(
        [string]$Server,
        [string]$Path
    )

    $normalized = $Path.Replace("\", "/").TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return "ftp://$Server/"
    }

    return "ftp://$Server/$normalized"
}

function Invoke-FtpRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [string]$SourceFile
    )

    $request = [System.Net.FtpWebRequest]::Create($Uri)
    $request.Method = $Method
    $request.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
    $request.UsePassive = $true
    $request.UseBinary = $true
    $request.KeepAlive = $false

    if ($Method -eq [System.Net.WebRequestMethods+Ftp]::UploadFile) {
        $content = [System.IO.File]::ReadAllBytes($SourceFile)
        $request.ContentLength = $content.Length
        $stream = $request.GetRequestStream()
        $stream.Write($content, 0, $content.Length)
        $stream.Dispose()
    }

    try {
        $response = $request.GetResponse()
        $response.Dispose()
    } catch [System.Net.WebException] {
        throw
    }
}

function Ensure-RemoteDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $segments = $RelativePath.Replace("\", "/").Trim("/").Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)
    $current = $RemoteRoot.TrimEnd("/")

    foreach ($segment in $segments) {
        $current = if ([string]::IsNullOrWhiteSpace($current) -or $current -eq "/") {
            "/$segment"
        } else {
            "$current/$segment"
        }

        $uri = Get-FtpUri -Server $FtpHost -Path $current
        try {
            Invoke-FtpRequest -Method ([System.Net.WebRequestMethods+Ftp]::MakeDirectory) -Uri $uri
        } catch [System.Net.WebException] {
            $response = $_.Exception.Response
            if ($response -is [System.Net.FtpWebResponse] -and $response.StatusCode -in @(
                [System.Net.FtpStatusCode]::ActionNotTakenFileUnavailable,
                [System.Net.FtpStatusCode]::ActionNotTakenFilenameNotAllowed
            )) {
                $response.Dispose()
                continue
            }

            if ($response) {
                $response.Dispose()
            }
            throw
        }
    }
}

$resolvedLocalRoot = (Resolve-Path $LocalRoot).Path
Write-Host "Uploading bundle from $resolvedLocalRoot to ftp://$FtpHost$RemoteRoot"

$directories = Get-ChildItem -Path $resolvedLocalRoot -Directory -Recurse | Sort-Object FullName
foreach ($directory in $directories) {
    $relative = $directory.FullName.Substring($resolvedLocalRoot.Length).TrimStart('\')
    if (-not [string]::IsNullOrWhiteSpace($relative)) {
        Ensure-RemoteDirectory -RelativePath $relative
    }
}

$files = Get-ChildItem -Path $resolvedLocalRoot -File -Recurse | Sort-Object FullName
foreach ($file in $files) {
    $relative = $file.FullName.Substring($resolvedLocalRoot.Length).TrimStart('\').Replace("\", "/")
    $remotePath = if ($RemoteRoot -eq "/") { "/$relative" } else { "$($RemoteRoot.TrimEnd('/'))/$relative" }
    $remoteDir = Split-Path -Path $relative -Parent
    if (-not [string]::IsNullOrWhiteSpace($remoteDir)) {
        Ensure-RemoteDirectory -RelativePath $remoteDir
    }

    $uri = Get-FtpUri -Server $FtpHost -Path $remotePath
    Write-Host "Uploading $relative"
    Invoke-FtpRequest -Method ([System.Net.WebRequestMethods+Ftp]::UploadFile) -Uri $uri -SourceFile $file.FullName
}

Write-Host "FTP upload completed."
