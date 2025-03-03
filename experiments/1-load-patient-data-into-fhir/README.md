# Experiment 1: Loading Patient Data into HAPI FHIR

This experiment demonstrates how to load patient data into a HAPI FHIR server using the JPA implementation.

## Prerequisites

- Docker and Docker Compose installed
- curl command-line tool

## Steps

### 1. Start the HAPI FHIR Server

The first step is to start the HAPI FHIR server using Docker Compose:

```bash
docker-compose up -d
```

**Expected Output:**
- Docker will start two containers:
  - PostgreSQL database (`db`)
  - HAPI FHIR server (`fhir`)
- The FHIR server will be accessible at http://localhost:8080/fhir

### 2. Load Patient Data

We use curl to POST a sample patient data file to the FHIR server:

```bash
curl -X POST -H "Content-Type: application/fhir+json" -d @sample-patient.json http://localhost:8080/fhir
```

**Expected Output:**
- The server responds with a Bundle transaction response
- Each resource in the bundle receives a "201 Created" status
- The server assigns sequential IDs to each resource
- The response includes location headers for each created resource

### 3. Verify Patient Data

We can verify that the patient data was loaded by retrieving it from the server:

```bash
curl -X GET -H "Accept: application/fhir+json" http://localhost:8080/fhir/Patient/1
```

**Expected Output:**
- The server returns the patient resource with ID 1
- The patient data includes demographic information, identifiers, and other details from the original sample file
- The resource includes metadata such as versionId and lastUpdated timestamp

## Notes

- The HAPI FHIR server assigns its own resource IDs, regardless of any IDs specified in the input data
- The server stores the data in a PostgreSQL database, making it persistent across server restarts
- The server supports the FHIR RESTful API for creating, reading, updating, and deleting resources

## Conclusion

This experiment demonstrates the basic functionality of loading patient data into a HAPI FHIR server. The server successfully processes the input data and makes it available through standard FHIR API endpoints.
