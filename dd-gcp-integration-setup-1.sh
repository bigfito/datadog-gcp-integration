#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @description: This script enables all GCP APIs required for the integration with Datadog in all GCP projects.

echo "NOTE: This script will enable all GCP APIs required for the integration with Datadog in all of your GCP projects."
echo "NOTE: This script should be executed by a GCP user with GCP ADMIN role."
printf "\n"

# Retrieve the list of GCP projects from the current organization
# Enable the required GCP APIs for each project

while read GCP_PROJECT; do

    # Process the list of GCP projects
    echo "Enabling GCP APIs for project: $GCP_PROJECT"

    echo "Enabling Cloud Resource Manager API..."
    gcloud services enable cloudresourcemanager.googleapis.com --project=$GCP_PROJECT

    echo "Enabling Cloud Billing API..."
    gcloud services enable cloudbilling.googleapis.com --project=$GCP_PROJECT

    echo "Enabling Cloud Monitoring API..."
    gcloud services enable monitoring.googleapis.com --project=$GCP_PROJECT

    echo "Enabling Compute Engine API..."
    gcloud services enable compute.googleapis.com --project=$GCP_PROJECT

    echo "Enabling Cloud Asset API..."
    gcloud services enable cloudasset.googleapis.com --project=$GCP_PROJECT

    echo "Enabling Cloud Identity and Access Management (IAM) API..."
    gcloud services enable iam.googleapis.com --project=$GCP_PROJECT

    printf "\n"

done < < (gcloud projects list | grep PROJECT_ID | cut -d " " -f 2)

echo "All GCP APIs required for the integration with Datadog have been ENABLED in all GCP projects."

exit 0