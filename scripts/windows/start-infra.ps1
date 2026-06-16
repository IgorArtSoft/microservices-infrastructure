Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot

function Find-InfrastructureRoot {
    param (
        [string]$StartDirectory
    )

    $currentDirectory = (Resolve-Path $StartDirectory).Path

    while ($true) {
        $candidateComposeFile = Join-Path $currentDirectory "docker-compose.infra.yml"

        if (Test-Path $candidateComposeFile) {
            return $currentDirectory
        }

        $parentDirectory = Split-Path -Parent $currentDirectory

        if ([string]::IsNullOrWhiteSpace($parentDirectory) -or $parentDirectory -eq $currentDirectory) {
            throw "Could not find infrastructure root. Expected docker-compose.infra.yml above: $StartDirectory"
        }

        $currentDirectory = $parentDirectory
    }
}

function Invoke-NativeCommand {
    param (
        [string]$Description,
        [scriptblock]$Command
    )

    Write-Host $Description -ForegroundColor Cyan
    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Description"
    }
}

$InfrastructureRoot = Find-InfrastructureRoot -StartDirectory $ScriptDir
$ComposeInfraFile = Join-Path $InfrastructureRoot "docker-compose.infra.yml"

if (!(Test-Path $ComposeInfraFile)) {
    throw "Compose file was not found: $ComposeInfraFile"
}

Write-Host "Checking Docker availability..." -ForegroundColor Cyan
docker version *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Docker is not available. Start Docker Desktop first."
}

Write-Host "Infrastructure root: $InfrastructureRoot" -ForegroundColor DarkGray
Write-Host "Using Compose file: $ComposeInfraFile" -ForegroundColor DarkGray

Invoke-NativeCommand "Starting Kafka, Kafka UI, and MongoDB..." {
    docker compose -f $ComposeInfraFile up -d
}

Write-Host ""
Write-Host "Infrastructure started successfully." -ForegroundColor Green
Write-Host "Kafka broker for Spring Boot: localhost:9092" -ForegroundColor Green
Write-Host "Kafka UI: http://localhost:8085" -ForegroundColor Green
Write-Host "MongoDB: localhost:27017" -ForegroundColor Green
Write-Host ""

docker ps