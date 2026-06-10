Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$root = Split-Path -Parent $scriptDir
$originalLocation = Get-Location

try {
    # Make sure start-all runs from the scripts directory
    Set-Location $scriptDir

    Write-Host "Starting local development environment..." -ForegroundColor Cyan

    & "$scriptDir\start-kafka.ps1"

    Write-Host ""
    Write-Host "Waiting a few seconds for Kafka to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    & "$scriptDir\start-services.ps1"

    Write-Host ""
    Write-Host "Local environment started." -ForegroundColor Green
    Write-Host "Kafka:        localhost:9092"
    Write-Host "Kafka UI:     http://localhost:8085"
    Write-Host "Order API:    http://localhost:8081"
    Write-Host "Payment API:  http://localhost:8082"
    Write-Host "Order Swagger: http://localhost:8081/swagger-ui/index.html#/order-controller/createOrder"
}
finally {
    # Return to the directory where you executed start-all.ps1
    Set-Location $originalLocation
}