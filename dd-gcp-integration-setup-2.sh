#!/bin/bash

# Author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# Version: 1.1
# Description: Enables all required GCP APIs for Datadog integration in all GCP projects.

set -e  # Exit immediately if a command exits with a non-zero status.

# List of required APIs
REQUIRED_APIS=(
  "cloudresourcemanager.googleapis.com"
  "cloudbilling.googleapis.com"
  "monitoring.googleapis.com"
  "compute.googleapis.com"
  "cloudasset.googleapis.com"
  "iam.googleapis.com"
)

# Introductory message
echo "This script enables all GCP APIs required for Datadog integration in your GCP projects."
echo "Please ensure you have GCP ADMIN role before proceeding."
read -p "Do you want to continue? [y/N]: " CONFIRMATION

if [[ "$CONFIRMATION" != "y" && "$CONFIRMATION" != "Y" ]]; then
  echo "Operation canceled."
  exit 1
fi

# Retrieve the list of GCP projects
PROJECTS=$(gcloud projects list --format="value(projectId)")
if [[ -z "$PROJECTS" ]]; then
  echo "No GCP projects found. Exiting."
  exit 1
fi

# Enable required APIs for each project
for PROJECT in $PROJECTS; do
  echo " "
  echo "Processing project: $PROJECT"

  for API in "${REQUIRED_APIS[@]}"; do
    echo "Enabling API: $API"
    gcloud services enable "$API" --project="$PROJECT" || {
      echo "Failed to enable $API for project $PROJECT. Skipping..."
      continue
    }
  done

echo "Completed enabling APIs for project: $PROJECT."
done

# Completion message
echo "All required APIs for Datadog integration have been enabled in all GCP projects."

exit 0