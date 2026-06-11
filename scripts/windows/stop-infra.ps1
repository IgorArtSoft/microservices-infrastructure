Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$ComposeInfraFile = Join-Path $RepoRoot "compose\docker-compose.infra.yml"

if (!(Test-Path $ComposeInfraFile)) {
    throw "Compose file was not found: $ComposeInfraFile"
}

Write-Host "Checking Docker availability..." -ForegroundColor Cyan
docker version *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Docker is not available. Start Docker Desktop first."
}

Write-Host "Stopping Kafka, Kafka UI, and MongoDB..." -ForegroundColor Cyan
docker compose -f $ComposeInfraFile stop

if ($LASTEXITCODE -ne 0) {
    throw "Failed to stop infrastructure containers."
}

Write-Host "Infrastructure containers stopped." -ForegroundColor Green
Write-Host "Data is kept because containers were stopped, not removed."