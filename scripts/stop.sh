#!/bin/bash

cd ../local-dev-env
cd scripts
docker compose down --remove-orphans
cd ..

kill $(lsof -ti :8081)
kill $(lsof -ti :8082)
