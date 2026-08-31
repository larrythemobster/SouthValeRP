# Zip all text/code files in the repository for AI review
# Excludes binary assets, images, 3D models, audio, caches, and secrets.

param(
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

# Determine repository root (two levels up from ops/scripts)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path "$scriptDir\..\..").Path

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputFile = Join-Path $repoRoot "southvale_text_files_$timestamp.zip"
} else {
    # Resolve relative path if needed
    if (![System.IO.Path]::IsPathRooted($OutputFile)) {
        $OutputFile = Join-Path (Get-Location) $OutputFile
    }
}

Write-Host "=== Packaging Text Files for AI ===" -ForegroundColor Cyan
Write-Host "Repository root : $repoRoot"
Write-Host "Target archive  : $OutputFile"

# Included text/code extensions
$textExtensions = @(
    ".lua", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx",
    ".json", ".cfg", ".sql", ".md", ".html", ".htm", ".css", ".scss",
    ".yml", ".yaml", ".ps1", ".sh", ".txt", ".xml", ".meta", ".ini", ".editorconfig",
    ".gitignore", ".gitattributes"
)

# Explicit excluded directory patterns
$excludedDirs = @(
    "\.git\",
    "\cache\",
    "\txData\",
    "\db\",
    "\node_modules\",
    "\backups\",
    "\.vscode\"
)

# Explicit excluded file names
$excludedFiles = @(
    "secrets.cfg"
)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Delete existing zip if present
if (Test-Path $OutputFile) {
    Remove-Item -Force $OutputFile
}

$zip = [System.IO.Compression.ZipFile]::Open($OutputFile, [System.IO.Compression.ZipArchiveMode]::Create)

$fileCount = 0
$totalBytes = 0

Write-Host "`nScanning and archiving text files..." -ForegroundColor Cyan

Get-ChildItem -Path $repoRoot -Recurse -File | ForEach-Object {
    $file = $_
    $relPath = $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/')
    
    # Check directory exclusions
    $skip = $false
    foreach ($dir in $excludedDirs) {
        if ($file.FullName -like "*$dir*") {
            $skip = $true
            break
        }
    }
    
    # Check filename exclusions
    if (-not $skip -and ($excludedFiles -contains $file.Name -or $file.Name.StartsWith(".env"))) {
        $skip = $true
    }
    
    # Check if file has target text extension or is known extensionless text file
    if (-not $skip) {
        $ext = $file.Extension.ToLower()
        $isText = $textExtensions -contains $ext -or $file.Name -in @("LICENSE", "README", "AGENTS", ".gitignore")
        
        if ($isText) {
            # Use forward slashes for zip entries (standard across all OS/tools)
            $entryName = $relPath.Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            $fileCount++
            $totalBytes += $file.Length
        }
    }
}

$zip.Dispose()

$zipItem = Get-Item $OutputFile
$zipSizeMB = [math]::Round($zipItem.Length / 1MB, 2)
$origSizeMB = [math]::Round($totalBytes / 1MB, 2)

Write-Host "`n[SUCCESS] Archive created successfully!" -ForegroundColor Green
Write-Host "Total text files archived : $fileCount"
Write-Host "Uncompressed text size    : $origSizeMB MB"
Write-Host "Compressed archive size   : $zipSizeMB MB"
Write-Host "Archive location          : $OutputFile"
