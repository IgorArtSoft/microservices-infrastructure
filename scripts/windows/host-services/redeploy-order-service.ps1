Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ServiceName = "order-service"
$Port = 8081

$ScriptDir = $PSScriptRoot
$InfrastructureRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
$WorkspaceRoot = (Resolve-Path (Join-Path $InfrastructureRoot "..")).Path
$ProjectDir = Join-Path $WorkspaceRoot $ServiceName

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
            Write-Host "If $ServiceName is running as a Docker container, stop that container manually." -ForegroundColor Yellow
            continue
        }

        Write-Host "Stopping $ServiceName. Process: $($process.ProcessName), PID: $processId" -ForegroundColor Yellow
        Stop-Process -Id $processId -Force
    }
}

if (!(Test-Path $ProjectDir)) {
    throw "$ServiceName folder was not found: $ProjectDir"
}

Write-Host "Redeploying $ServiceName ..." -ForegroundColor Cyan
Write-Host "Project directory: $ProjectDir" -ForegroundColor Gray

Stop-ProcessUsingPort -Port $Port -ServiceName $ServiceName

Write-Host "Building $ServiceName ..." -ForegroundColor Cyan

Push-Location $ProjectDir

try {
    if (Test-Path ".\mvnw.cmd") {
        .\mvnw.cmd -DskipTests clean package
    }
    else {
        mvn -DskipTests clean package
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $ServiceName."
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

    Write-Host "Starting $ServiceName from jar:" -ForegroundColor Green
    Write-Host $jar.FullName -ForegroundColor Gray

    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$ProjectDir'; java -jar '$($jar.FullName)'"
    )

    Write-Host "$ServiceName redeploy command completed." -ForegroundColor Green
}
finally {
    Pop-Location
}