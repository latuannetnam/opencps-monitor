#!/bin/bash
echo "Starting up ..."
docker-compose -f docker-compose.yml up -d --build
echo "Icinga2 started"
