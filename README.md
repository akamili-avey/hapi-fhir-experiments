# HAPI FHIR Learning Tests

This repository contains a collection of learning tests that demonstrate various features and behaviors of the HAPI FHIR server with JPA implementation. Each experiment is self-contained and focuses on a specific aspect of FHIR functionality.

## Prerequisites

- Docker and Docker Compose installed
- curl command-line tool
- Basic understanding of FHIR concepts

## Initial Setup

Start the HAPI FHIR server:

```bash
docker-compose up -d
```

The server will be available at http://localhost:8080/fhir (this URL is assumed by the tests).

## Project Structure

```
.
├── docker-compose.yml      # Docker Compose configuration for HAPI FHIR
├── hapi.application.yaml   # HAPI FHIR server configuration
└── experiments/           # Directory containing all learning tests
    ├── 1-load-patient-data-into-fhir/    # First experiment
    │   ├── test.sh        # Test script
    │   └── sample-patient.json  # Test data
    ├── 2-add-an-extension-on-patient/    # Second experiment
    │   ├── test.sh        # Test script
    │   ├── sample-patient.json  # Test data
    │   └── fhir-nationality-extension.json  # Extension definition
    ├── 3-add-search-parameter-on-patient/    # Third experiment
    │   ├── test.sh        # Test script
    │   ├── sample-patient.json  # Test data
    │   └── search-parameter.json  # Search parameter definition
    └── ... (more experiments to come)
```

## Available Experiments

1. [Loading Patient Data](experiments/1-load-patient-data-into-fhir/README.md) - Demonstrates how to load patient data into HAPI FHIR and verify its storage.
2. [Adding Extensions](experiments/2-add-an-extension-on-patient/README.md) - Shows how to define and add custom extensions to Patient resources.
3. [Custom Search Parameters](experiments/3-add-search-parameter-on-patient/README.md) - Illustrates creating and using custom search parameters.

## Running Experiments

Each experiment is contained in its own directory under `experiments/` and includes:
- A README.md file explaining the purpose and expected outcomes
- A test.sh script that runs the experiment
- Any necessary sample data files

To run an experiment:

1. Ensure the HAPI FHIR server is running
2. Navigate to the experiment's directory
3. Make the test script executable: `chmod +x test.sh`
4. Run the test: `./test.sh`

## Infrastructure

The project uses Docker Compose to set up:
- A HAPI FHIR server (latest version)
- A PostgreSQL database for complete simulation (NOT persistent for reproducibility)

The FHIR server is accessible at http://localhost:8080/fhir. A human-friendly navigation homepage is available at http://localhost:8080/, while FHIR resources like Patient, Observation, etc. are available at http://localhost:8080/fhir/Patient, http://localhost:8080/fhir/Observation, etc.

## Contributing

To add a new experiment:
1. Create a new directory under `experiments/`
2. Add a test.sh script that demonstrates the behavior
3. Include any necessary sample data files

## Notes

- The HAPI FHIR server should be running before executing any tests
- Each test script needs a clean server state and will clear _all_ existing data at the end
- Some operations may take a few seconds to complete due to server processing time

