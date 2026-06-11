Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Port {
    param (
        [string]$Name,
        [int]$Port
    )

    $connection = Get-NetTCPConnection `
        -LocalPort $Port `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($connection) {
        Write-Host "$Name is listening on port $Port" -ForegroundColor Green
    }
    else {
        Write-Host "$Name is not listening on port $Port" -ForegroundColor Yellow
    }
}

function Test-HttpEndpoint {
    param (
        [string]$Name,
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        Write-Host "$Name responded with HTTP $($response.StatusCode): $Url" -ForegroundColor Green
    }
    catch {
        Write-Host "$Name did not respond: $Url" -ForegroundColor Yellow
    }
}

Write-Host "Docker containers:" -ForegroundColor Cyan
docker ps

Write-Host ""
Write-Host "Ports:" -ForegroundColor Cyan
Test-Port -Name "Kafka" -Port 9092
Test-Port -Name "Kafka UI" -Port 8085
Test-Port -Name "MongoDB" -Port 27017
Test-Port -Name "order-service" -Port 8081
Test-Port -Name "payment-service" -Port 8082
Test-Port -Name "customer-service" -Port 8083

Write-Host ""
Write-Host "HTTP endpoints:" -ForegroundColor Cyan
Test-HttpEndpoint -Name "Kafka UI" -Url "http://localhost:8085"
Test-HttpEndpoint -Name "order-service health" -Url "http://localhost:8081/actuator/health"
Test-HttpEndpoint -Name "payment-service health" -Url "http://localhost:8082/actuator/health"

Write-Host ""
Write-Host "Kafka topics:" -ForegroundColor Cyan
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list