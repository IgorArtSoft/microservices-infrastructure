Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$ComposeInfraFile = Join-Path $RepoRoot "compose\docker-compose.infra.yml"

function Stop-ProcessUsingPort {
    param (
        [int]$Port,
        [string]$ServiceName
    )

    Write-Host "Checking $ServiceName on port $Port ..." -ForegroundColor Cyan

    $connections = Get-NetTCPConnection `
        -LocalPort $Port `
        -State Listen `
        -ErrorAction SilentlyContinue

    if (!$connections) {
        Write-Host "$ServiceName is already stopped. No process is listening on port $Port." -ForegroundColor Yellow
        return
    }

    $processIds = $connections.OwningProcess | Sort-Object -Unique

    foreach ($processId in $processIds) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

        if (!$process) {
            Write-Host "$ServiceName process with PID $processId is already gone." -ForegroundColor Yellow
            continue
        }

        if ($process.ProcessName -eq "com.docker.backend") {
            Write-Host "$ServiceName port $Port is used by Docker Desktop backend. Skipping process kill." -ForegroundColor Yellow
            Write-Host "If this is an old Docker container, stop/remove the container instead." -ForegroundColor Yellow
            continue
        }

        try {
            Write-Host "Stopping $ServiceName. Process: $($process.ProcessName), PID: $processId" -ForegroundColor Cyan
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "$ServiceName stopped." -ForegroundColor Green
        }
        catch {
            Write-Host "Could not stop $ServiceName PID $processId. It may already be stopped." -ForegroundColor Yellow
        }
    }
}

function Stop-DockerComposeServices {
    if (!(Test-Path $ComposeInfraFile)) {
        Write-Host "Compose file was not found: $ComposeInfraFile" -ForegroundColor Yellow
        return
    }

    Write-Host "Checking Docker availability..." -ForegroundColor Cyan
    docker version *> $null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker is not available or Docker Desktop is not running. Infrastructure containers may already be stopped." -ForegroundColor Yellow
        return
    }

    Write-Host "Stopping Kafka, Kafka UI, and MongoDB..." -ForegroundColor Cyan
    docker compose -f $ComposeInfraFile stop

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker Compose stop returned a non-zero result. Containers may already be stopped or missing." -ForegroundColor Yellow
        return
    }

    Write-Host "Infrastructure containers stopped or were already stopped." -ForegroundColor Green
}

Write-Host "Stopping local development environment..." -ForegroundColor Cyan
Write-Host ""

Stop-ProcessUsingPort -Port 8081 -ServiceName "order-service"
Stop-ProcessUsingPort -Port 8082 -ServiceName "payment-service"
Stop-ProcessUsingPort -Port 8083 -ServiceName "customer-service"

Write-Host ""

Stop-DockerComposeServices

Write-Host ""
Write-Host "Local development environment stop command completed." -ForegroundColor Green