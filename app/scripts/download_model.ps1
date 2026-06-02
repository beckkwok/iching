# Download Qwen3 0.6B model for the I-Ching app
# Run this script once before building the app.
# The model is stored at: ./models/Qwen3-0.6B.litertlm

$ModelUrl = "https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm"
$OutputDir = Join-Path $PSScriptRoot ".." "models"
$OutputFile = Join-Path $OutputDir "Qwen3-0.6B.litertlm"

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created directory: $OutputDir"
}

Write-Host "Downloading Qwen3 0.6B model (586 MB)..."
Write-Host "URL: $ModelUrl"
Write-Host "Saving to: $OutputFile"
Write-Host ""

# Download with progress
$ProgressPreference = 'Continue'
Invoke-WebRequest -Uri $ModelUrl -OutFile $OutputFile -UseBasicParsing

# Verify
$FileSize = (Get-Item $OutputFile).Length
$FileSizeMB = [math]::Round($FileSize / 1MB, 1)
Write-Host ""
Write-Host "Download complete!" -ForegroundColor Green
Write-Host "File size: $FileSizeMB MB"
Write-Host "Location: $OutputFile"
