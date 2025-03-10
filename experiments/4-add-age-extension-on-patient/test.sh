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

echo -e "\nStep 1: Adding age search parameter..."
echo "POSTing age search parameter to FHIR server..."
SEARCH_PARAM_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d @age-search-extension.json \
  http://localhost:8080/fhir/SearchParameter)
echo "$SEARCH_PARAM_RESPONSE" | jq .

echo -e "\nStep 2: Loading initial patient data..."
echo "POSTing first patient data from sample-patient.json to FHIR server..."
PATIENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d @sample-patient.json http://localhost:8080/fhir)
# Extract the patient ID from the response
PATIENT_ID_1=$(echo "$PATIENT_RESPONSE" | jq -r '.entry[0].response.location' | cut -d'/' -f2)
echo "Created first patient with ID: $PATIENT_ID_1"

echo "POSTing second patient data from sample-patient.json to FHIR server..."
PATIENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d @sample-patient.json http://localhost:8080/fhir)
PATIENT_ID_2=$(echo "$PATIENT_RESPONSE" | jq -r '.entry[0].response.location' | cut -d'/' -f2)
echo "Created second patient with ID: $PATIENT_ID_2"

echo -e "\nStep 3: Updating patients with ages using PATCH..."
echo "Setting first patient age to 25..."
curl -s -X PATCH \
     -H "Content-Type: application/json-patch+json" \
     --max-time 2 \
     -d @update-patient-age.json \
     "http://localhost:8080/fhir/Patient/$PATIENT_ID_1"

echo -e "\nSetting second patient age to 30..."
curl -s -X PATCH \
     -H "Content-Type: application/json-patch+json" \
     --max-time 2 \
     -d @update-patient-age-30.json \
     "http://localhost:8080/fhir/Patient/$PATIENT_ID_2"

echo -e "\nStep 6: Testing different age search queries..."

echo -e "\nSearching for patients with age > 25..."
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?age=gt25")
echo "Search result for age > 25:"
MATCH=$(echo "$SEARCH_RESULT" | jq '.total')
if [ "$MATCH" -ne 1 ]; then
    echo "Error: Expected 1 patient, but got $MATCH"
    exit 1
fi

echo -e "\nSearching for patients with age >= 25..."
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?age=ge25")
echo "Search result for age >= 25:"
MATCH=$(echo "$SEARCH_RESULT" | jq '.total')
if [ "$MATCH" -ne 2 ]; then
    echo "Error: Expected 2 patients, but got $MATCH"
    exit 1
fi

# test ascending and descending order
echo -e "\nSearching for patients with age ascending..."
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?_sort=age")
echo "Search result for age ascending:"
RESULT_1=$(echo "$SEARCH_RESULT" | jq -r '.entry[0].resource.id')
if [ "$RESULT_1" != "$PATIENT_ID_1" ]; then
    echo "Error: Expected patient ID $PATIENT_ID_1, but got $RESULT_1"
    exit 1
fi
RESULT_2=$(echo "$SEARCH_RESULT" | jq -r '.entry[1].resource.id')
if [ "$RESULT_2" != "$PATIENT_ID_2" ]; then
    echo "Error: Expected patient ID $PATIENT_ID_2, but got $RESULT_2"
    exit 1
fi
echo "Verified that the patients are sorted by age ascending, with $PATIENT_ID_1 first and $PATIENT_ID_2 second"

echo -e "\nSearching for patients with age descending..."
SEARCH_RESULT=$(curl -s "http://localhost:8080/fhir/Patient?_sort=-age")
RESULT_1=$(echo "$SEARCH_RESULT" | jq -r '.entry[0].resource.id')
if [ "$RESULT_1" != "$PATIENT_ID_2" ]; then
    echo "Error: Expected patient ID $PATIENT_ID_2, but got $RESULT_1"
    exit 1
fi
RESULT_2=$(echo "$SEARCH_RESULT" | jq -r '.entry[1].resource.id')
if [ "$RESULT_2" != "$PATIENT_ID_1" ]; then
    echo "Error: Expected patient ID $PATIENT_ID_1, but got $RESULT_2"
    exit 1
fi
echo "Verified that the patients are sorted by age descending, with $PATIENT_ID_2 first and $PATIENT_ID_1 second"

echo -e "\nAll tests completed!"

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