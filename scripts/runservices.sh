#!/bin/bash

cd ..

cd ../order-service
mkdir logs
nohup mvn spring-boot:run > logs/order-service.log 2>&1 &
 
cd ../payment-service
mkdir logs
nohup mvn spring-boot:run > logs/payment-service.log 2>&1 &
