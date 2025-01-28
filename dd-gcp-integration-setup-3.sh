#!/bin/bash

# @author: Adolfo Orozco
# @version: 1.0
# @description: Automates configuration for sending GCP logs to Datadog
# NOTE: Run this script in a Cloud Shell window within the Datadog integration GCP project

# Global Parameters
GCP_PROJECT_ID="gcp-dd-integration"
GCP_REGION="northamerica-south1"
GCP_TEMP_BUCKET="dataflow-gcp-to-dd-$GCP_PROJECT_ID"

# Networking Parameters
VPC_NETWORK="vpc-dd-network"
VPC_SUBNETWORK="subnet-dd-default"

# Cloud Logging Parameters
LOG_SINK_NAME="sink-export-dd-info-logs"
LOG_FILTER_VALUE="severity>INFO"

# Pub/Sub Parameters
PUB_SUB_TOPIC_ACCEPTED="dd-accepted-logs"
PUB_SUB_TOPIC_REJECTED="dd-rejected-logs"

# Dataflow Parameters
DATAFLOW_JOB_NAME="dataflow-gcp-logs-to-datadog"
DATAFLOW_DATADOG_SERVICE_ACCOUNT="dd-dataflow-sa"
DATAFLOW_SA_FQDN="$DATAFLOW_DATADOG_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com"
DATADOG_SECRET_NAME="secret-datadog-api-key"
DATADOG_API_KEY=$DD_API_KEY

clear
echo "Starting Datadog integration setup for GCP logs."

# Function Definitions

# Utility Functions
pause() {
    echo "Press ENTER to continue..."
    read -r
    clear
}

set_project() {
  echo "Setting project to $GCP_PROJECT_ID..."
  gcloud config set project "$GCP_PROJECT_ID"
  pause
}

create_service_account() {
  echo "Creating Dataflow Service Account..."
  gcloud iam service-accounts create "$DATAFLOW_DATADOG_SERVICE_ACCOUNT" \
    --display-name="$DATAFLOW_DATADOG_SERVICE_ACCOUNT" \
    --description="Service Account for Dataflow job exporting logs to Datadog" \
    --project="$GCP_PROJECT_ID"
  pause
}

assign_roles() {
  echo "Assigning roles to Service Account..."
  roles=("roles/dataflow.admin" "roles/dataflow.serviceAgent" "roles/dataflow.worker" \
         "roles/compute.networkUser" "roles/storage.objectViewer" "roles/pubsub.viewer" \
         "roles/pubsub.subscriber" "roles/pubsub.publisher" "roles/secretmanager.secretAccessor" \
         "roles/storage.objectAdmin")
  for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
      --member="serviceAccount:$DATAFLOW_SA_FQDN" --role="$role"
  done
  pause
}

enable_apis() {
  echo "Enabling required APIs..."
  apis=("dataflow.googleapis.com" "pubsub.googleapis.com" "logging.googleapis.com" \
        "monitoring.googleapis.com" "secretmanager.googleapis.com")
  for api in "${apis[@]}"; do
    gcloud services enable "$api" --project="$GCP_PROJECT_ID"
  done
  pause
}

create_secret() {
  echo "Storing Datadog API Key in Secret Manager..."
  echo "$DATADOG_API_KEY" | gcloud secrets create "$DATADOG_SECRET_NAME" \
    --data-file=- --replication-policy=user-managed --locations="$GCP_REGION"
  pause
}

create_temp_bucket() {
  echo "Creating temporary storage bucket for Dataflow job..."
  gcloud storage buckets create "gs://$GCP_TEMP_BUCKET" \
    --location="$GCP_REGION" --default-storage-class=STANDARD \
    --uniform-bucket-level-access --public-access-prevention
  pause
}

create_pubsub_topics() {
  echo "Creating Pub/Sub topics and subscriptions..."
  gcloud pubsub topics create "$PUB_SUB_TOPIC_ACCEPTED"
  gcloud pubsub subscriptions create "subscription-$PUB_SUB_TOPIC_ACCEPTED" --topic="$PUB_SUB_TOPIC_ACCEPTED"
  gcloud pubsub topics create "$PUB_SUB_TOPIC_REJECTED"
  gcloud pubsub subscriptions create "subscription-$PUB_SUB_TOPIC_REJECTED" --topic="$PUB_SUB_TOPIC_REJECTED"
  pause
}

create_log_sink() {
  echo "Creating log sink to route logs..."
  gcloud logging sinks create "$LOG_SINK_NAME" \
    "pubsub.googleapis.com/projects/$GCP_PROJECT_ID/topics/$PUB_SUB_TOPIC_ACCEPTED" \
    --log-filter="$LOG_FILTER_VALUE" --project="$GCP_PROJECT_ID"
  pause
}

run_dataflow_job() {
  echo "Starting Dataflow job to send logs to Datadog..."
  gcloud dataflow jobs run "$DATAFLOW_JOB_NAME" \
    --gcs-location "gs://dataflow-templates-us-central1/latest/Cloud_PubSub_to_Datadog" \
    --region "$GCP_REGION" --network "$VPC_NETWORK" \
    --subnetwork "regions/$GCP_REGION/subnetworks/$VPC_SUBNETWORK" \
    --disable-public-ips \
    --service-account-email "$DATAFLOW_SA_FQDN" \
    --staging-location "gs://$GCP_TEMP_BUCKET/temp" \
    --additional-experiments streaming_mode_exactly_once \
    --parameters inputSubscription="projects/$GCP_PROJECT_ID/subscriptions/subscription-$PUB_SUB_TOPIC_ACCEPTED",url="https://http-intake.logs.datadoghq.com",includePubsubMessage=true,apiKeySecretId="projects/$GCP_PROJECT_ID/secrets/$DATADOG_SECRET_NAME/versions/1",apiKeySource=SECRET_MANAGER,javascriptTextTransformReloadIntervalMinutes=0,outputDeadletterTopic="projects/$GCP_PROJECT_ID/topics/$PUB_SUB_TOPIC_REJECTED"
  pause
}

# Main Script Execution

set_project
create_service_account
assign_roles
enable_apis
create_secret
create_temp_bucket
create_pubsub_topics
create_log_sink
run_dataflow_job

echo "Datadog integration setup completed successfully!"

exit 0