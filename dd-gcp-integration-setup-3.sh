#!/bin/bash

# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @description: This script helps you with the required configuration to send GCP logs to Datadog
# This script MUST BE executed in a Cloud Shell window in the GCP project where the Datadog Integration exists

# GLOBAL GCP PARAMETERS
GCP_PROJECT_ID="prj-dd-integration-01"
GCP_REGION="us-central1"
GCP_TEMP_BUCKET="dataflow-gcp-to-dd-$GCP_PROJECT_ID"

# NETWORKING PARAMETERS
VPC_NETWORK="vpc-dd-network"
VPC_SUBNETWORK="subnet-dd-main"

# CLOUD LOGGING PARAMETERS
LOG_SINK_NAME="sink-export-apigee-logs"

# PUBSUB PARAMETERS
PUB_SUB_TOPIC_ACCEPTED="dd-accepted-logs"
PUB_SUB_TOPIC_REJECTED="dd-rejected-logs"

# DATAFLOW PARAMETERS
DATAFLOW_DATADOG_SERVICE_ACCOUNT="dd-dataflow-sa"
DF_SA_MEMBER_VALUE="serviceAccount:$DATAFLOW_DATADOG_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com"
DATAFLOW_JOB_NAME="dataflow-gcp-logs-to-datadog-1"

# DATADOG PARAMETERS
DATADOG_SECRET_NAME="secret-datadog-api-key"
DATADOG_API_KEY=$DD_API_KEY

clear
printf "\n"
echo "This script will assist you with the required configuration to send GCP logs to Datadog using a Dataflow job."
printf "\n"

# SETTING THE PROJECT

echo "Setting the PROJECT_ID..."
gcloud config set project $GCP_PROJECT_ID

echo "The current project has been set to $GCP_PROJECT_ID."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 1). Create the service account to be used by the Dataflow job

clear
printf "\n"
echo "Creating a Service Account for the Dataflow job..."
gcloud iam service-accounts create $DATAFLOW_DATADOG_SERVICE_ACCOUNT \
       --display-name=$DATAFLOW_DATADOG_SERVICE_ACCOUNT \
       --project=$GCP_PROJECT_ID \
       --description="Service Account required for Dataflow to export logs to Datadog"

echo "The Service Account that will be used by the Dataflow job has been created."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 2). Grant the following roles to the service account in the Datadog integration GCP project

clear
printf "\n"
echo "Adding proper roles to the service account..."
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/dataflow.admin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/dataflow.serviceAgent"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/dataflow.worker"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/compute.networkUser"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/pubsub.viewer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/pubsub.subscriber"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/pubsub.publisher"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
       --member="$DF_SA_MEMBER_VALUE" \
       --role="roles/storage.objectAdmin"

echo "All required roles granted to the Service Account in the Datadog integration GCP project."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 3) Enabling all required APIs in the Datadog integration GCP project

clear
printf "\n"
echo "Enabling all required APIs in the Datadog integration GCP project..."

printf "\n"
echo "Enabling Dataflow API..."
gcloud services enable dataflow.googleapis.com --project=$GCP_PROJECT_ID

echo "Enabling Pub/Sub API..."
gcloud services enable pubsub.googleapis.com --project=$GCP_PROJECT_ID

echo "Enabling Cloud Logging API..."
gcloud services enable logging.googleapis.com --project=$GCP_PROJECT_ID

echo "Enabling Cloud Monitoring API..."
gcloud services enable monitoring.googleapis.com --project=$GCP_PROJECT_ID

echo "Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project=$GCP_PROJECT_ID

echo "All required APIs have been enabled in the Datadog integration GCP project."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 4) Create a SECRET for your Datadog API KEY

clear
printf "\n"
echo "Creating a secret for your DATADOG API KEY..."
echo $DATADOG_API_KEY | gcloud secrets create $DATADOG_SECRET_NAME \
     --data-file=- \
     --replication-policy=user-managed \
     --locations=$GCP_REGION

echo "DATADOG API KEY has been stored as a SECRET in GCP SECRET MANAGER."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 5) Create a storage bucket so Dataflow can write temporary files

clear
printf "\n"
echo "Creating a storage bucket for temporary files used by the Dataflow job..."
gcloud storage buckets create gs://$GCP_TEMP_BUCKET \
       --location=$GCP_REGION \
       --default-storage-class=STANDARD \
       --uniform-bucket-level-access \
       --public-access-prevention

echo "Storage Bucket created."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 6) Create the PubSub topics and their subscriptions


clear
printf "\n"
echo "Creating required Cloud Pub/Sub topics..."
gcloud pubsub topics create $PUB_SUB_TOPIC_ACCEPTED
gcloud pubsub subscriptions create "subscription-"$PUB_SUB_TOPIC_ACCEPTED --topic=$PUB_SUB_TOPIC_ACCEPTED

gcloud pubsub topics create $PUB_SUB_TOPIC_REJECTED
gcloud pubsub subscriptions create "subscription-"$PUB_SUB_TOPIC_REJECTED --topic=$PUB_SUB_TOPIC_REJECTED

echo "PubSub topics and subscriptions created."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 7) Create a log sink to route desired logs

clear
printf "\n"
echo "Creating Cloud Logging sink to export logs..."
gcloud logging sinks create $LOG_SINK_NAME "pubsub.googleapis.com/projects/$GCP_PROJECT_ID/topics/$PUB_SUB_TOPIC_ACCEPTED" \
       --log-filter="severity>WARNING" \
       --project=$GCP_PROJECT_ID

echo "Cloud Logging router sink created."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 8) Run a Dataflow job to start sending logs to Datadog

clear
gcloud dataflow jobs run $DATAFLOW_JOB_NAME \
     --gcs-location gs://dataflow-templates-us-central1/latest/Cloud_PubSub_to_Datadog \
     --region $GCP_REGION \
     --network $VPC_NETWORK \
     --subnetwork regions/$GCP_REGION/subnetworks/$VPC_SUBNETWORK \
     --disable-public-ips \
     --service-account-email $DATAFLOW_DATADOG_SERVICE_ACCOUNT@$GCP_PROJECT_ID.iam.gserviceaccount.com \
     --staging-location gs://$GCP_TEMP_BUCKET/temp \
     --additional-experiments streaming_mode_exactly_once \
     --parameters inputSubscription=projects/$GCP_PROJECT_ID/subscriptions/subscription-$PUB_SUB_TOPIC_ACCEPTED,url=https://http-intake.logs.datadoghq.com,includePubsubMessage=true,apiKeySecretId=projects/$GCP_PROJECT_ID/secrets/$DATADOG_SECRET_NAME/versions/1,apiKeySource=SECRET_MANAGER,javascriptTextTransformReloadIntervalMinutes=0,outputDeadletterTopic=projects/$GCP_PROJECT_ID/topics/$PUB_SUB_TOPIC_REJECTED

echo "Dataflow job started..."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

printf "\n"
echo "All required configurations have been applied."

exit 0