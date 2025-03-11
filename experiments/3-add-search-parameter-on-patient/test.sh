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
# Extract the patient ID from the response
PATIENT_ID=$(echo "$PATIENT_RESPONSE" | jq -r '.entry[0].response.location' | cut -d'/' -f2)
echo "Created patient with ID: $PATIENT_ID"

echo -e "\nStep 3: Updating patient with nationality using PATCH..."
curl -s -X PATCH \
     -H "Content-Type: application/json-patch+json" \
     --max-time 2 \
     -d @update-patient-nationality.json \
     "http://localhost:8080/fhir/Patient/$PATIENT_ID"

echo -e "\nStep 4: Requiring patient data should now have nationality..."
EXPECTED_EXTENSION=$(cat update-patient-nationality.json | jq '.[0].value')

ACTUAL_EXTENSION=$(curl -s "http://localhost:8080/fhir/Patient/$PATIENT_ID" | jq '.extension[-1]')
if [ "$ACTUAL_EXTENSION" = "$EXPECTED_EXTENSION" ]; then
    echo -e "\nVerification successful - extension matches expected value"
else
    echo -e "\nVerification failed - extension does not match expected value"
    echo "Expected: $EXPECTED_EXTENSION"
    echo "Actual: $ACTUAL_EXTENSION"
    exit 1
fi

echo -e "\nStep 5: Adding nationality search parameter..."
echo "POSTing nationality search parameter to FHIR server..."
SEARCH_PARAM_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d @nationality-search-extension.json \
  http://localhost:8080/fhir/SearchParameter)
echo "$SEARCH_PARAM_RESPONSE" | jq .

echo -e "\nStep 6: Searching before reindexing... expect 0 results"
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?nationality=CA")
SEARCH_COUNT=$(echo "$SEARCH_RESULT" | jq '.total')
if [ "$SEARCH_COUNT" -eq 0 ]; then
    echo -e "\nSearch verification successful - found $SEARCH_COUNT patient with nationality=CA"
    echo "Search result:"
    echo "$SEARCH_RESULT" | jq '.entry[0].resource.id'
else
    echo -e "\nSearch verification failed - expected 0 patients with nationality=CA, but found $SEARCH_COUNT"
    echo "Search result:"
    echo "$SEARCH_RESULT" | jq .
    exit 1
fi

echo -e "\nStep 6: Reindexing Patient resources to enable search..."
REINDEX_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Parameters",
    "parameter": [
      {
        "name": "url",
        "valueString": "Patient?"
      }
    ]
  }' \
  http://localhost:8080/fhir/\$reindex)
echo "Reindex initiated. Waiting for completion..."
sleep 5 

# THE FOLLOWING MIGHT FAIL - Indexing new search parameters sometimes take minutes, for reasons I don't know.
# if it does, just re-run the script after some delay and manual expunge (copy from below).
echo -e "\nStep 7: Verifying nationality search functionality..."
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?nationality=CA")
SEARCH_COUNT=$(echo "$SEARCH_RESULT" | jq '.total')

if [ "$SEARCH_COUNT" -eq 1 ]; then
    echo -e "\nSearch verification successful - found $SEARCH_COUNT patient with nationality=CA"
    echo "Search result:"
    echo "$SEARCH_RESULT" | jq '.entry[0].resource.id'
    
    # Verify it's the same patient we created
    FOUND_PATIENT_ID=$(echo "$SEARCH_RESULT" | jq -r '.entry[0].resource.id')
    if [ "$FOUND_PATIENT_ID" = "$PATIENT_ID" ]; then
        echo "Patient ID verification successful - found the correct patient"
    else
        echo "Patient ID verification failed - expected $PATIENT_ID but found $FOUND_PATIENT_ID"
        exit 1
    fi
else
    echo -e "\nSearch verification failed - expected 1 patient with nationality=CA, but found $SEARCH_COUNT"
    echo "Search result:"
    echo "$SEARCH_RESULT" | jq .
    exit 1
fi

echo -e "\nAll tests passed successfully!"

echo -e "\nCleaning up - expunging all data."
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