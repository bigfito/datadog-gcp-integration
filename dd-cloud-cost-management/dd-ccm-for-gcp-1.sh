#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @description: This script enables all GCP APIs required for Datadog's Cloud Cost Management

# GCP PROJECT FOR DATADOG'S CLOUD COST MANAGEMENT
# NOTE: It is recommended you choose the same GCP project where the Datadog's GCP integration is hosted
GCP_CCM_PROJECT_ID="dd-integration-439619"

echo "Enabling BigQuery API..."
gcloud services enable bigquery.googleapis.com --project=$GCP_CCM_PROJECT_ID

echo "Enabling BigQuery Data Transfer Service API..."
gcloud services enable bigquerydatatransfer.googleapis.com --project=$GCP_CCM_PROJECT_ID

echo "All GCP APIs required for Cloud Cost Management (CCM) have been ENABLED in project:$GCP_CCM_PROJECT_ID"
echo "Press ENTER to exit..."
read -r PRESS_KEY

exit 0