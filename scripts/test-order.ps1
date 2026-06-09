$response = Invoke-WebRequest `
  -Uri "http://localhost:8081/orders" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"orderId":"ORD-321","customerId":"CUST-123","amount":35.78}'

$response.StatusCode
$response.Content