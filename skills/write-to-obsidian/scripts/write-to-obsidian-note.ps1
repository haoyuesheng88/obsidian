param(
    [string]$Content,

    [string]$RelativePath,

    [string]$Title,

    [string]$VaultPath,

    [switch]$Append,

    [switch]$OpenInObsidian
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Content)) {
    throw "Content is required."
}

function Get-ActiveVaultPath {
    $configCandidates = @(
        (Join-Path $env:APPDATA "Obsidian\obsidian.json"),
        (Join-Path $env:APPDATA "obsidian\obsidian.json")
    )

    foreach ($configPath in $configCandidates) {
        if (-not (Test-Path -LiteralPath $configPath)) {
            continue
        }

        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        if (-not $config.vaults) {
            continue
        }

        $vaultEntries = foreach ($item in $config.vaults.PSObject.Properties) {
            if ($item.Value.path) {
                [PSCustomObject]@{
                    Path = [string]$item.Value.path
                    Open = [bool]($item.Value.open)
                    Timestamp = [long]($item.Value.ts)
                }
            }
        }

        if ($vaultEntries) {
            $preferred = $vaultEntries |
                Sort-Object @{ Expression = { if ($_.Open) { 1 } else { 0 } }; Descending = $true },
                            @{ Expression = { $_.Timestamp }; Descending = $true } |
                Select-Object -First 1

            if ($preferred.Path -and (Test-Path -LiteralPath $preferred.Path)) {
                return $preferred.Path
            }
        }
    }

    throw "Could not find an active Obsidian vault from local config."
}

function ConvertTo-SafeLeafName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $safe = $Name
    foreach ($invalid in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace($invalid, "-")
    }

    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) {
        throw "Title resolved to an empty file name."
    }

    return $safe
}

if (-not $VaultPath) {
    $VaultPath = Get-ActiveVaultPath
}

if (-not (Test-Path -LiteralPath $VaultPath)) {
    throw "Vault path does not exist: $VaultPath"
}

if (-not $RelativePath) {
    if ($Title) {
        $fileName = ConvertTo-SafeLeafName -Name $Title
    } else {
        $fileName = "note-" + (Get-Date -Format "yyyy-MM-dd-HHmmss")
    }

    if (-not [System.IO.Path]::GetExtension($fileName)) {
        $fileName += ".md"
    }

    $RelativePath = $fileName
}

$normalizedRelativePath = $RelativePath.Replace("/", "\")
$targetPath = Join-Path $VaultPath $normalizedRelativePath
$targetDirectory = [System.IO.Path]::GetDirectoryName($targetPath)

if ($targetDirectory -and -not (Test-Path -LiteralPath $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
}

if ($Append -and (Test-Path -LiteralPath $targetPath)) {
    $existing = Get-Content -LiteralPath $targetPath -Raw
    $prefix = ""

    if ($existing.Length -gt 0 -and -not $existing.EndsWith([Environment]::NewLine)) {
        $prefix = [Environment]::NewLine
    }

    Add-Content -LiteralPath $targetPath -Value ($prefix + $Content) -Encoding utf8
} else {
    Set-Content -LiteralPath $targetPath -Value $Content -Encoding utf8
}

if ($OpenInObsidian) {
    $vaultName = Split-Path -LiteralPath $VaultPath -Leaf
    $uriRelativePath = $normalizedRelativePath.Replace("\", "/")
    $uri = "obsidian://open?vault=" +
        [System.Uri]::EscapeDataString($vaultName) +
        "&file=" +
        [System.Uri]::EscapeDataString($uriRelativePath)
    Start-Process $uri | Out-Null
    Write-Output ("OPEN_URI=" + $uri)
}

Write-Output ("VAULT_PATH=" + $VaultPath)
Write-Output ("TARGET_PATH=" + $targetPath)
Write-Output ("MODE=" + ($(if ($Append) { "append" } else { "write" })))
