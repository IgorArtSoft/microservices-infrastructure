Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Write-Host "Starting local development environment..." -ForegroundColor Cyan

& "$PSScriptRoot\start-kafka.ps1"

Write-Host ""
Write-Host "Waiting a few seconds for Kafka to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

& "$PSScriptRoot\start-services.ps1"

Write-Host ""
Write-Host "Local environment started." -ForegroundColor Green
Write-Host "Kafka:        localhost:9092"
Write-Host "Kafka UI:     http://localhost:8085"
Write-Host "Order API:    http://localhost:8081"
Write-Host "Payment API:  http://localhost:8082"