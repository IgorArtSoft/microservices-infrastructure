#!/bin/bash

cd ..

cd ../order-service
mvn clean install -Dmaven.test.skip=true
 
cd ../payment-service
mvn clean install -Dmaven.test.skip=true
