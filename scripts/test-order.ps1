$response = Invoke-WebRequest `
  -Uri "http://localhost:8081/orders" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"orderId":"ORD-1009","customerId":"CUST-1009","amount":1234.56}'

$response.StatusCode
$response.Content