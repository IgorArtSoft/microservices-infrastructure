Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$OriginalLocation = Get-Location

$StartInfraScript = Join-Path $ScriptDir "start-infra.ps1"
$StartServicesScript = Join-Path $ScriptDir "start-services.ps1"

function Invoke-Step {
    param (
        [string]$StepName,
        [string]$ScriptPath
    )

    if (!(Test-Path $ScriptPath)) {
        throw "Required script was not found: $ScriptPath"
    }

    Write-Host ""
    Write-Host $StepName -ForegroundColor Cyan
    Write-Host "Running: $ScriptPath" -ForegroundColor DarkGray

    & $ScriptPath

    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $StepName"
    }
}

try {
    Write-Host "Starting local development environment..." -ForegroundColor Cyan
    Write-Host "Script directory: $ScriptDir" -ForegroundColor DarkGray

    Invoke-Step `
        -StepName "Step 1: Starting Kafka, Kafka UI, and MongoDB..." `
        -ScriptPath $StartInfraScript

    Write-Host ""
    Write-Host "Waiting for Kafka and MongoDB to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    Invoke-Step `
        -StepName "Step 2: Starting Spring Boot microservices..." `
        -ScriptPath $StartServicesScript

    Write-Host ""
    Write-Host "Local environment startup command completed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Useful URLs:" -ForegroundColor Cyan
    Write-Host "Kafka broker: localhost:9092"
    Write-Host "Kafka UI:     http://localhost:8085"
    Write-Host "MongoDB:      localhost:27017"
    Write-Host "Order API:    http://localhost:8081"
    Write-Host "Payment API:  http://localhost:8082"
    Write-Host "Swagger:      http://localhost:8081/swagger-ui/index.html"
}
finally {
    Set-Location $OriginalLocation
}