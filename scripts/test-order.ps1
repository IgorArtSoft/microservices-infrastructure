$response = Invoke-WebRequest `
  -Uri "http://localhost:8081/orders" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"orderId":"ORD-1001","customerId":"CUST-777","amount":125.50}'

$response.StatusCode
$response.Content