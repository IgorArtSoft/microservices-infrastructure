Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serviceName = "order-service"
$port = 8081

# Script is located in:
# D:\Programming\webservicesjava25\kafka-local-dev\scripts
$scriptDir = $PSScriptRoot

# order-service is located in:
# D:\Programming\webservicesjava25\order-service
$projectDir = Resolve-Path (Join-Path $scriptDir "..\..\order-service")

Write-Host "Redeploying $serviceName ..." -ForegroundColor Cyan
Write-Host "Project directory: $projectDir" -ForegroundColor Gray

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
        Write-Host "$ServiceName is not currently listening on port $Port." -ForegroundColor Yellow
        return
    }

    $processIds = $connections.OwningProcess | Sort-Object -Unique

    foreach ($processId in $processIds) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

        if (!$process) {
            Write-Host "Process with PID $processId is already gone." -ForegroundColor Yellow
            continue
        }

        if ($process.ProcessName -eq "com.docker.backend") {
            Write-Host "Port $Port is owned by Docker backend. Not killing Docker Desktop process." -ForegroundColor Red
            Write-Host "If $ServiceName is running as a Docker container, stop that container manually or with docker stop $ServiceName." -ForegroundColor Yellow
            continue
        }

        Write-Host "Stopping $ServiceName. Process: $($process.ProcessName), PID: $processId" -ForegroundColor Yellow
        Stop-Process -Id $processId -Force
    }
}

Stop-ProcessUsingPort -Port $port -ServiceName $serviceName

Write-Host "Building $serviceName ..." -ForegroundColor Cyan

Push-Location $projectDir

try {
    if (Test-Path ".\mvnw.cmd") {
        .\mvnw.cmd -DskipTests clean package
    }
    else {
        mvn -DskipTests clean package
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $serviceName."
    }

    $jar = Get-ChildItem ".\target\*.jar" |
        Where-Object {
            $_.Name -notlike "*sources*" `
            -and $_.Name -notlike "*javadoc*" `
            -and $_.Name -notlike "*.original"
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (!$jar) {
        throw "No runnable jar was found in target directory."
    }

    Write-Host "Starting $serviceName from jar:" -ForegroundColor Green
    Write-Host $jar.FullName -ForegroundColor Gray

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$projectDir'; java -jar '$($jar.FullName)'"
    )

    Write-Host "$serviceName redeploy command completed." -ForegroundColor Green
}
finally {
    Pop-Location
}