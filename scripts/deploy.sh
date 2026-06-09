#!/bin/bash

cd ../local-dev-env
cd scripts
docker compose down --remove-orphans
docker compose up -d  --build
cd ..

echo ""
echo "              Kafka: http://localhost:9092"
echo "          Kafka UI: http://localhost:8085/ui/clusters/local-kafka/brokers"
echo "      Mongo-express: http://localhost:8084/db/orderdb/"
echo "      User/Password: admin/admin123"
echo "        Payment API: http://localhost:8082/actuator/health"
echo "          Order API: http://localhost:8081/actuator/health"
echo "      Order Swagger: http://localhost:8081/swagger-ui/index.html#/order-controller/createOrder"


