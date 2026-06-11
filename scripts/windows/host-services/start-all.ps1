Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$OriginalLocation = Get-Location

try {
    Write-Host "Starting local development environment..." -ForegroundColor Cyan
    Write-Host ""

    & (Join-Path $ScriptDir "start-infra.ps1")

    Write-Host ""
    Write-Host "Waiting for Kafka and MongoDB to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    & (Join-Path $ScriptDir "start-services.ps1")

    Write-Host ""
    Write-Host "Local environment started." -ForegroundColor Green
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