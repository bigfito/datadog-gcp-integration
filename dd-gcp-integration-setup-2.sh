#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @date: December 12, 2024
# @description: This script executes all required steps to setup the integration of Datadog with GCP

# GLOBAL GCP PARAMETERS
GCP_ORG="bigfito.cloud"
GCP_ORG_ID="584378483656"
GCP_FOLDER_ID="199236173099"
GCP_PROJECT_NAME="PRJ-DD-INTEGRATION-01"
GCP_PROJECT_ID="prj-dd-integration-01"
GCP_BILLING_ACCOUNT_ID="01F61D-EF7B6F-CD50BA"

# NETWORKING PARAMETERS
VPC_NETWORK="vpc-dd-network"
VPC_SUBNETWORK="subnet-dd-default"
VPC_SUBNETWORK_RANGE="192.168.252.0/29"
VPC_SUBNETWORK_REGION="us-central1"
ROUTER_NAME="router-dd-network"
NAT_GATEWAY="nat-dd-network"

# SERVICE ACCOUNT PARAMETERS
GCP_SA_NAME="sa-dd-integration"
GCP_SA_DISPLAY_NAME="sa-dd-integration"
GCP_SA_PRINCIPAL="serviceAccount:$GCP_SA_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com"
GCP_SA_EMAIL="$GCP_SA_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com"

# DATADOG PARAMETERS
DD_PRINCIPAL_DD="ddgci-6f89e2938a017fa434aa@datadog-gci-sts-us1-prod.iam.gserviceaccount.com"
DD_PRINCIPAL="serviceAccount:$DD_PRINCIPAL_DD"

echo "NOTE: This script should be run by a GCP user with GCP ADMIN role from a Cloud Shell window or a GCP SDK CLI."
printf "\n"

# STEP 1)

echo "Step 1): Creating a GCP project for the Datadog integration in the specified folder..."
printf "\n"

gcloud projects create $GCP_PROJECT_ID \
       --name=$GCP_PROJECT_NAME \
       --folder=$GCP_FOLDER_ID \
       --set-as-default

printf "\n"
echo "Attaching Billing Account to the GCP project..."
gcloud billing projects link $GCP_PROJECT_ID --billing-account=$GCP_BILLING_ACCOUNT_ID
printf "\n"

echo "Enabling the Compute Engine API in the project..."
gcloud services enable compute.googleapis.com --project=$GCP_PROJECT_ID
printf "\n"

echo "GCP project ($GCP_PROJECT_NAME) created in organization ($GCP_ORG)."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# STEP 2)

printf "\n"
echo "Step 2): Creating a VPC network in custom mode and a default subnet for the GCP project..."

echo "Removing the default vpc network..."
gcloud compute firewall-rules delete default-allow-internal
gcloud compute firewall-rules delete default-allow-rdp
gcloud compute firewall-rules delete default-allow-ssh
gcloud compute firewall-rules delete default-allow-icmp
gcloud compute networks delete default

printf "\n"
echo "Creating the new VPC network..."

gcloud compute networks create $VPC_NETWORK \
      --project=$GCP_PROJECT_ID \
      --subnet-mode=custom \
      --mtu=1460 \
      --bgp-routing-mode=regional \
      --bgp-best-path-selection-mode=legacy

gcloud compute networks subnets create $VPC_SUBNETWORK \
      --project=$GCP_PROJECT_ID \
      --range=$VPC_SUBNETWORK_RANGE \
      --stack-type=IPV4_ONLY \
      --network=$VPC_NETWORK \
      --region=$VPC_SUBNETWORK_REGION \
      --enable-private-ip-google-access

printf "\n"
echo "Creating a firewall rule for INBOUND dataflow traffic between VMs..."
gcloud compute firewall-rules create allow-ports-for-dataflow \
       --network $VPC_NETWORK \
       --allow tcp:12345-12346 \
       --source-ranges $VPC_SUBNETWORK_RANGE

printf "\n"
echo "Creating a firewall rule for INBOUND ssh traffic to VMs from Google IAP only..."
gcloud compute firewall-rules create allow-ssh-iap \
       --network vpc-dd-network \
       --allow tcp:22 \
       --source-ranges 35.235.240.0/20

printf "\n"
echo "Creating a ROUTER for the vpc network..."
gcloud compute routers create $ROUTER_NAME \
       --region $VPC_SUBNETWORK_REGION \
       --network $VPC_NETWORK

printf "\n"
echo "Creating a NAT gateway for the vpc network..."
gcloud compute routers nats create $NAT_GATEWAY --router=$ROUTER_NAME \
       --region=$VPC_SUBNETWORK_REGION \
       --auto-allocate-nat-external-ips \
       --nat-all-subnet-ip-ranges

echo "VPC network ($VPC_NETWORK) and subnetwork ($VPC_SUBNETWORK) created in region ($VPC_SUBNETWORK_REGION)."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# STEP 3)

printf "\n"
echo "Step 3): Create a Service Account for the GCP project..."

gcloud iam service-accounts create $GCP_SA_NAME --display-name=$GCP_SA_DISPLAY_NAME --project=$GCP_PROJECT_ID

echo "Service Account $GCP_SA_EMAIL created."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# STEP 4)

printf "\n"
echo "Step 4): Grant the Service Account with the proper roles in the GCP project..."

echo "Adding Monitoring Viewer role to the service account..."
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/monitoring.viewer'
printf "\n"

echo "Adding Compute Viewer role to the service account..."
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/compute.viewer'
printf "\n"

echo "Adding Cloud Asset Viewer role to the service account..."
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/cloudasset.viewer'
printf "\n"

echo "Adding Browser role to the service account..."
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/browser'
printf "\n"

echo "Service Account roles granted at the project level."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 5)

printf "\n"
echo "Step 5): Grant the Service Account the proper roles at the organization level..."

echo "Grating Compute Viewer role..."
gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/compute.viewer'

echo "Grating Monitoring Viewer role..."
gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/monitoring.viewer'

echo "Grating Cloud Asset Viewer role..."
gcloud organizations add-iam-policy-binding $GCP_ORG_ID \
        --member=$GCP_SA_PRINCIPAL \
        --role='roles/cloudasset.viewer'

echo "Service Account (SA) roles granted at the organization level."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 6)

printf "\n"
echo "Step 6): Adding the Datadog Principal to impersonate the Service Account (SA)..."

gcloud iam service-accounts add-iam-policy-binding $GCP_SA_EMAIL \
        --member=$DD_PRINCIPAL \
        --role='roles/iam.serviceAccountTokenCreator'

echo "Datadog Principal can now impersonate the Service Account (SA)."
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

# Step 7)

printf "\n"
echo "Step 7): Copy the Service Account email and paste it into your Datadog Integration configuration..."
echo "GCP Service Account: $GCP_SA_EMAIL"
printf "\n"
echo "Press ENTER to continue..."
read -r PRESS_KEY

printf "\n"
echo "All required configurations have been applied."

exit 0