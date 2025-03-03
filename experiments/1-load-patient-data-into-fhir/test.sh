#!/bin/bash
set -e

echo "Step 1: Starting HAPI FHIR server with docker-compose..."
docker-compose up -d
echo "Waiting for FHIR server to start up (10 seconds)..."
sleep 10

# Verify containers are running
echo "Verifying containers are running:"
docker ps

# Check container logs
echo "Checking FHIR server logs:"
docker logs fhir --tail 10

echo -e "\nStep 2: Creating a sample patient..."
echo "POSTing patient data from sample-patient.json to FHIR server..."
curl -X POST -H "Content-Type: application/fhir+json" -d @experiments/1-load-patient-data-into-fhir/sample-patient.json http://localhost:8080/fhir

echo -e "\nStep 3: Verifying patient data was loaded..."
echo "GET request to retrieve the patient:"
# The server assigns ID 1 to the first patient
curl -X GET -H "Accept: application/fhir+json" http://localhost:8080/fhir/Patient/1

echo -e "\nTest completed successfully! Shutting down containers..."
docker-compose down
