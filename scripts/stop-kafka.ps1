Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Write-Host "Stopping Kafka and Kafka UI..." -ForegroundColor Cyan

Set-Location $root
docker compose stop

Write-Host "Kafka containers stopped." -ForegroundColor Green
Write-Host "Data is kept because containers were stopped, not removed."