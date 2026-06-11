Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$OrderApiUrl = "http://localhost:8081/orders"

$OrderId = "ORD-" + (Get-Date -Format "yyyyMMdd-HHmmss")

$Body = @{
    orderId = $OrderId
    customerId = "CUST-123"
    amount = 35.78
    currency = "CAD"
} | ConvertTo-Json

Write-Host "Creating test order: $OrderId" -ForegroundColor Cyan

$response = Invoke-WebRequest `
    -Uri $OrderApiUrl `
    -Method Post `
    -ContentType "application/json" `
    -Body $Body `
    -UseBasicParsing

Write-Host "HTTP status: $($response.StatusCode)" -ForegroundColor Green
Write-Host $response.Content