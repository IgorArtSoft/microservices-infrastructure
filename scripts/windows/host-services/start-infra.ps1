Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$ComposeInfraFile = Join-Path $RepoRoot "compose\docker-compose.infra.yml"

function Invoke-NativeCommand {
    param (
        [string]$Description,
        [scriptblock]$Command
    )

    Write-Host $Description -ForegroundColor Cyan
    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Description"
    }
}

if (!(Test-Path $ComposeInfraFile)) {
    throw "Compose file was not found: $ComposeInfraFile"
}

Write-Host "Checking Docker availability..." -ForegroundColor Cyan
docker version *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Docker is not available. Start Docker Desktop first."
}

Write-Host "Using Compose file: $ComposeInfraFile" -ForegroundColor DarkGray

Invoke-NativeCommand "Starting Kafka, Kafka UI, and MongoDB..." {
    docker compose -f $ComposeInfraFile up -d
}

Write-Host ""
Write-Host "Infrastructure started successfully." -ForegroundColor Green
Write-Host "Kafka broker for Spring Boot: localhost:9092" -ForegroundColor Green
Write-Host "Kafka UI: http://localhost:8085" -ForegroundColor Green
Write-Host "MongoDB: localhost:27017" -ForegroundColor Green
Write-Host ""

docker ps