#!/bin/bash
echo "Checking if FHIR server is ready..."
until curl --max-time 1 --output /dev/null --silent --fail http://localhost:8080/fhir/metadata; do
    echo "Waiting for FHIR server to be ready..."
    sleep 1
done
echo "FHIR server is ready at http://localhost:8080/fhir"

echo "Asserting that the server has NO DATA"
PATIENT_COUNT=$(curl -s "http://localhost:8080/fhir/Patient" | jq '.total')
if [ "$PATIENT_COUNT" -ne 0 ]; then
    echo "Error: Expected 0 patients, but got $PATIENT_COUNT"
    exit 1
fi

echo -e "\nStep 2: Loading initial patient data..."
echo "POSTing patient data from sample-patient.json to FHIR server..."
PATIENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d @sample-patient.json http://localhost:8080/fhir)
echo "$PATIENT_RESPONSE" | jq .

# Extract the patient ID from the response
PATIENT_ID=$(echo "$PATIENT_RESPONSE" | jq -r '.entry[0].response.location' | cut -d'/' -f2)
echo "Created patient with ID: $PATIENT_ID"

echo -e "\nStep 3: Updating patient with nationality using PATCH..."
curl -s -X PATCH \
     -H "Content-Type: application/json-patch+json" \
     --max-time 2 \
     -d @update-patient-nationality.json \
     "http://localhost:8080/fhir/Patient/$PATIENT_ID"

echo -e "\nStep 4: Verifying patient data has nationality..."
EXPECTED_EXTENSION=$(cat update-patient-nationality.json | jq '.[0].value')
ACTUAL_EXTENSION=$(curl -s "http://localhost:8080/fhir/Patient/$PATIENT_ID" | jq '.extension[-1]')

if [ "$ACTUAL_EXTENSION" = "$EXPECTED_EXTENSION" ]; then
    echo -e "\nVerification successful - extension matches expected value"
else
    echo -e "\nVerification failed - extension does not match expected value"
    exit 1
fi

echo -e "\nStep 5: Cleaning up - expunging all data..."
curl -s -X POST 'http://localhost:8080/fhir/$expunge' \
  -H 'Content-Type: application/fhir+json' \
  -d '{
    "resourceType": "Parameters",
    "parameter": [
      {
        "name": "expungeEverything",
        "valueBoolean": true
      }
    ]
  }'
