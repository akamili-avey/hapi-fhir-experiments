# HAPI FHIR Learning Tests

This repository contains a collection of learning tests that demonstrate various features and behaviors of the HAPI FHIR server with JPA implementation. Each experiment is self-contained and focuses on a specific aspect of FHIR functionality.

## Prerequisites

- Docker and Docker Compose installed
- curl command-line tool
- Basic understanding of FHIR concepts

## Initial Setup

Before running any experiments, you need to start the HAPI FHIR server at least once to ensure all dependencies are downloaded and the database is properly initialized:

```bash
docker-compose up
```

Wait until you see logs indicating that the server has started successfully. You can then stop the server with Ctrl+C and proceed with the experiments.

## Project Structure

```
.
├── docker-compose.yml      # Docker Compose configuration for HAPI FHIR
├── hapi.application.yaml   # HAPI FHIR server configuration
└── experiments/           # Directory containing all learning tests
    ├── 1-load-patient-data-into-fhir/    # First experiment
    │   ├── README.md      # Experiment documentation
    │   ├── test.sh        # Test script
    │   └── sample-patient.json  # Test data
    └── ... (more experiments to come)
```

## Available Experiments

1. [Loading Patient Data](experiments/1-load-patient-data-into-fhir/README.md) - Demonstrates how to load patient data into HAPI FHIR and verify its storage.

## Running Experiments

Each experiment is contained in its own directory under `experiments/` and includes:
- A README.md file explaining the purpose and expected outcomes
- A test.sh script that runs the experiment
- Any necessary sample data files

To run an experiment:

1. Make sure you've completed the initial setup step above
2. Navigate to the experiment's directory
3. Make the test script executable: `chmod +x test.sh`
4. Run the test: `./test.sh`

## Infrastructure

The project uses Docker Compose to set up:
- A HAPI FHIR server (latest version)
- A PostgreSQL database for complete simulation (NOT persistent for reproducibility)

The FHIR server is accessible at http://localhost:8080/fhir when running.

## Contributing

To add a new experiment:
1. Create a new directory under `experiments/`
2. Include a README.md explaining the purpose and expected outcomes
3. Add a test.sh script that demonstrates the behavior
4. Include any necessary sample data files

## Notes

- Each test script handles starting and stopping the Docker containers
- The HAPI FHIR server may take a few seconds to start up completely

