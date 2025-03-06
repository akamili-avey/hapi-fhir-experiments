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

echo -e "\nStep 3: Verifying initial patient data (should have no nationality extension)..."
curl -s "http://localhost:8080/fhir/Patient/$PATIENT_ID" | jq .

echo -e "\nStep 4: Adding nationality extension definition..."
curl -s -X POST -H "Content-Type: application/json" -d @fhir-nationality-extension.json http://localhost:8080/fhir/StructureDefinition | jq .

echo -e "\nStep 5: Verifying patient data after adding extension definition (should still have no nationality)..."
curl -s "http://localhost:8080/fhir/Patient/$PATIENT_ID" | jq .

echo -e "\nStep 6: Updating patient with nationality using PATCH..."
echo "Verifying server is still responsive..."
if ! curl --max-time 1 --output /dev/null --silent --fail http://localhost:8080/fhir/metadata; then
    echo "Error: Server is not responding. Exiting."
    exit 1
fi

echo "Server is responsive, proceeding with PATCH..."
echo "PATCH request body:"
cat update-patient-nationality.json | jq .

echo "Sending PATCH request..."
curl -s -X PATCH \
     -H "Content-Type: application/json-patch+json" \
     --max-time 2 \
     -d @update-patient-nationality.json \
     "http://localhost:8080/fhir/Patient/$PATIENT_ID"

echo -e "\nStep 7: Verifying final patient data (should now have nationality)..."
echo "Expected extension value:"
EXPECTED_EXTENSION=$(cat update-patient-nationality.json | jq '.[0].value')
echo "$EXPECTED_EXTENSION"

echo -e "\nActual extension value:"
ACTUAL_EXTENSION=$(curl -s "http://localhost:8080/fhir/Patient/$PATIENT_ID" | jq '.extension[-1]')
echo "$ACTUAL_EXTENSION"

if [ "$ACTUAL_EXTENSION" = "$EXPECTED_EXTENSION" ]; then
    echo -e "\nVerification successful - extension matches expected value"
else
    echo -e "\nVerification failed - extension does not match expected value"
    exit 1
fi

echo -e "\nStep 8: Cleaning up - expunging all patient data..."
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

echo -e "\nStep 9: Verifying that all data has been expunged..."
curl -s "http://localhost:8080/fhir/Patient" | jq .

