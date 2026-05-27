$response = Invoke-WebRequest `
  -Uri "http://localhost:8081/orders" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"orderId":"ORD-1011","customerId":"CUST-1011","amount":56.12}'

$response.StatusCode
$response.Content