Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$OriginalLocation = Get-Location

function Find-InfrastructureRoot {
    param (
        [string]$StartDirectory
    )

    $currentDirectory = Resolve-Path $StartDirectory

    while ($true) {
        $candidateComposeFile = Join-Path $currentDirectory "docker-compose.infra.yml"

        if (Test-Path $candidateComposeFile) {
            return $currentDirectory.Path
        }

        $parentDirectory = Split-Path -Parent $currentDirectory

        if ($parentDirectory -eq $currentDirectory.Path -or [string]::IsNullOrWhiteSpace($parentDirectory)) {
            throw "Could not find infrastructure repository root. Expected docker-compose.infra.yml above $StartDirectory."
        }

        $currentDirectory = Resolve-Path $parentDirectory
    }
}

function Stop-ProcessByIdSafely {
    param (
        [int]$ProcessId,
        [string]$Reason
    )

    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue

    if (!$process) {
        Write-Host "Process PID $ProcessId is already stopped. Reason: $Reason" -ForegroundColor Yellow
        return
    }

    if ($process.ProcessName -eq "com.docker.backend") {
        Write-Host "Skipping Docker Desktop backend PID $ProcessId. Reason: $Reason" -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Stopping process PID $ProcessId, Name: $($process.ProcessName). Reason: $Reason" -ForegroundColor Cyan
        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Host "Stopped PID $ProcessId." -ForegroundColor Green
    }
    catch {
        Write-Host "Could not stop PID $ProcessId. $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

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
        Write-Host "$ServiceName is not listening on port $Port." -ForegroundColor Yellow
        return
    }

    $processIds = $connections.OwningProcess | Sort-Object -Unique

    foreach ($processId in $processIds) {
        Stop-ProcessByIdSafely -ProcessId $processId -Reason "$ServiceName listening on port $Port"
    }
}

function Stop-ServiceProcessesByCommandLine {
    param (
        [string[]]$ServiceNames
    )

    Write-Host "Checking Java/Maven processes by command line..." -ForegroundColor Cyan

    $candidateProcesses = Get-CimInstance Win32_Process |
        Where-Object {
            $_.CommandLine -and (
                $_.Name -match "java|mvn|mvnw|cmd"
            )
        }

    foreach ($serviceName in $ServiceNames) {
        $matches = $candidateProcesses |
            Where-Object {
                $_.CommandLine -like "*$serviceName*"
            }

        if (!$matches) {
            Write-Host "No Java/Maven process found for $serviceName by command line." -ForegroundColor Yellow
            continue
        }

        foreach ($match in $matches) {
            Stop-ProcessByIdSafely -ProcessId $match.ProcessId -Reason "Command line contains $serviceName"
        }
    }
}

function Stop-Infrastructure {
    param (
        [string]$ComposeInfraFile
    )

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
    Write-Host "Using Compose file: $ComposeInfraFile" -ForegroundColor DarkGray

    docker compose -f $ComposeInfraFile stop

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker Compose stop returned a non-zero result. Containers may already be stopped or missing." -ForegroundColor Yellow
        return
    }

    Write-Host "Infrastructure containers stopped." -ForegroundColor Green
    Write-Host "Data is preserved because containers were stopped, not removed." -ForegroundColor DarkGray
}

try {
    Write-Host "Stopping local development environment..." -ForegroundColor Cyan
    Write-Host "Script directory: $ScriptDir" -ForegroundColor DarkGray
    Write-Host ""

    $InfrastructureRoot = Find-InfrastructureRoot -StartDirectory $ScriptDir
    $ComposeInfraFile = Join-Path $InfrastructureRoot "docker-compose.infra.yml"

    Write-Host "Infrastructure root: $InfrastructureRoot" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Step 1: Stopping Spring Boot microservices by port..." -ForegroundColor Cyan

    Stop-ProcessUsingPort -Port 8081 -ServiceName "order-service"
    Stop-ProcessUsingPort -Port 8082 -ServiceName "payment-service"
    Stop-ProcessUsingPort -Port 8083 -ServiceName "customer-service"
	
	Start-Sleep -Seconds 2

    Write-Host ""
    Write-Host "Step 2: Stopping remaining Java/Maven processes by command line..." -ForegroundColor Cyan

    Stop-ServiceProcessesByCommandLine -ServiceNames @(
        "order-service",
        "payment-service",
        "customer-service"
    )

    Write-Host ""
    Write-Host "Step 3: Stopping local Docker infrastructure..." -ForegroundColor Cyan

    Stop-Infrastructure -ComposeInfraFile $ComposeInfraFile

    Write-Host ""
    Write-Host "Step 4: Verifying ports..." -ForegroundColor Cyan

    foreach ($port in @(8081, 8082, 8083, 8085, 9092, 27017)) {
        $connection = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue

        if ($connection) {
            Write-Host "Port $port is still listening." -ForegroundColor Yellow
        }
        else {
            Write-Host "Port $port is stopped." -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "Local development environment stop command completed." -ForegroundColor Green
}
finally {
    Set-Location $OriginalLocation
}