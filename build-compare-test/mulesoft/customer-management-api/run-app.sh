#!/bin/bash

# Script to run the Mule application
# Requires Mule Runtime 4.9.0+ to be installed

JAR_FILE="target/customer-management-api-1.0.0-mule-application.jar"

if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JAR file not found. Please build the application first:"
    echo "  mvn clean package"
    exit 1
fi

echo "Starting Customer Management API..."
echo "JAR: $JAR_FILE"
echo ""
echo "To run this application, you need Mule Runtime 4.9.0 or later."
echo ""
echo "Option 1: Using Mule Runtime directly:"
echo "  \$MULE_HOME/bin/mule -M-Dmule.verbose=true -app $JAR_FILE"
echo ""
echo "Option 2: Using Anypoint Studio:"
echo "  1. Import this project into Anypoint Studio"
echo "  2. Right-click the project -> Run As -> Mule Application"
echo ""
echo "Option 3: Deploy to CloudHub (requires Anypoint Platform credentials):"
echo "  mvn clean package deploy -DmuleDeploy"
echo ""
echo "The application will be available at: http://localhost:8081"
echo "Health check: http://localhost:8081/health"
