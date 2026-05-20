$response = Invoke-WebRequest `
  -Uri "http://localhost:8081/orders" `
  -Method Post `
  -ContentType "application/json" `
  -Body '{"orderId":"ORD-1002","customerId":"CUST-888","amount":256.50}'

$response.StatusCode
$response.Content