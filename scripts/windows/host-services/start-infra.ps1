Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectDir = Split-Path -Parent $PSScriptRoot

function Invoke-NativeCommand {
    param (
        [string]$CommandDescription,
        [scriptblock]$Command
    )

    Write-Host $CommandDescription -ForegroundColor Cyan

    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $CommandDescription"
    }
}

Write-Host "Checking Docker availability..." -ForegroundColor Cyan

docker version | Out-Host

if ($LASTEXITCODE -ne 0) {
    throw "Docker is not available. Start Docker Desktop first."
}

Set-Location $projectDir

Invoke-NativeCommand "Starting Kafka and Kafka UI..." {
    docker compose up -d
}

Write-Host ""
Write-Host "Kafka started successfully." -ForegroundColor Green
Write-Host "Kafka broker for Spring Boot: localhost:9092" -ForegroundColor Green
Write-Host "Kafka UI: http://localhost:8085" -ForegroundColor Green
Write-Host ""

docker ps