Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

        # Safety: do not kill Docker Desktop backend.
        # If Docker containers are using ports 8081/8082, Windows may show com.docker.backend.exe.
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
    $projectDir = Split-Path -Parent $PSScriptRoot

    Write-Host "Checking Docker availability..." -ForegroundColor Cyan

    docker version *> $null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker is not available or Docker Desktop is not running. Kafka containers may already be stopped." -ForegroundColor Yellow
        return
    }

    Write-Host "Stopping Kafka and Kafka UI..." -ForegroundColor Cyan

    Push-Location $projectDir

    try {
        docker compose stop

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Docker Compose stop returned a non-zero result. Containers may already be stopped or missing." -ForegroundColor Yellow
            return
        }

        Write-Host "Kafka and Kafka UI stopped or were already stopped." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

Write-Host "Stopping local development environment..." -ForegroundColor Cyan
Write-Host ""

Stop-ProcessUsingPort -Port 8081 -ServiceName "order-service"
Stop-ProcessUsingPort -Port 8082 -ServiceName "payment-service"

Write-Host ""

Stop-DockerComposeServices

Write-Host ""
Write-Host "Local development environment stop command completed." -ForegroundColor Green