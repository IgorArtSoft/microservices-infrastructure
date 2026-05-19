Write-Host "Docker containers:" -ForegroundColor Cyan
docker ps

Write-Host ""
Write-Host "Testing Kafka container..." -ForegroundColor Cyan
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list