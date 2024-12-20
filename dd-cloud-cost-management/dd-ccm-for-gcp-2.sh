#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @description: This script creates a new BigQuery dataset and a storage bucket

# GCP PROJECT FOR DATADOG'S CLOUD COST MANAGEMENT
GCP_PROJECT_ID="dd-integration-439619"
GCP_REGION="us-central1"

# DATASET NAME
GCP_BIGQUERY_DATASET="dd-ccm-dataset"

# STORAGE BUCKET NAME
GCP_BUCKET_NAME="dd-ccm-$GCP_PROJECT_ID"

# GCP SERVICE ACCOUNT USED FOR DATADOG INTEGRATION
GCP_DD_SA="sa-datadog@dd-integration-439619.iam.gserviceaccount.com"

printf "\n"
echo "Creating BigQuery dataset for Cloud Cost Management..."
bq mk --dataset $GCP_BIGQUERY_DATASET --location=$GCP_REGION

printf "\n"
echo "Your BigQuery dataset has been created.  Now perform the following steps manually.."
echo "Step 1): Go to your GCP console and pick your GCP Datadog integration project form the project selector."
echo "Step 2): Go to the main page of BigQuery in your GCP datadog integration project($GCP_PROJECT_ID)."
echo "Step 3): Expand your project and select the export BigQuery dataset we just created."
echo "Step 4): Click Sharing > Permissions and then add principal."
echo "Step 5): In the new principals field, enter the service account: $GCP_DD_SA"
echo "Step 6): Assign the roles/bigquery.dataEditor to the service account."

printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

printf "\n"
echo "Creating Storage Bucket for Cloud Cost Management..."
gcloud storage buckets create gs://$GCP_BUCKET_NAME \
        --location=$GCP_REGION \
        --storage-class=STANDARD \
        --public-access-prevention=enforced \
        --uniform-bucket-level-access=enabled

printf "\n"
echo "Adding the proper roles to the Service Account on the storage bucket..."
gcloud storage buckets add-iam-policy-binding \
    --member=serviceAccount:$GCP_DD_SA \
    --role=roles/storage.legacyObjectReader \
    --bucket=gs://$GCP_BUCKET_NAME

gcloud storage buckets add-iam-policy-binding \
    --member=serviceAccount:$GCP_DD_SA \
    --role=roles/storage.legacyBucketWriter \
    --bucket=gs://$GCP_BUCKET_NAME

printf "\n"
echo "All resources have been created."
echo "Press ENTER to exit..."
read -r PRESS_KEY

exit 0