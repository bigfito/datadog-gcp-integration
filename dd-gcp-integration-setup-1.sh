#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.1
# @date: January 27, 2025
# @description: This script automates the setup for integrating Datadog with GCP.

# GLOBAL PARAMETERS
GCP_ORG="bigfito.cloud"
GCP_ORG_ID="584378483656"
GCP_FOLDER_ID="199236173099"
GCP_PROJECT_NAME="PRJ-GCP-DD-INTEGRATION"
GCP_PROJECT_ID="prj-gcp-dd-integration"
GCP_BILLING_ACCOUNT_ID="01F61D-EF7B6F-CD50BA"

# NETWORKING PARAMETERS
VPC_NETWORK="vpc-dd-network"
VPC_SUBNETWORK="subnet-dd-default"
VPC_SUBNETWORK_RANGE="192.168.252.0/27"
VPC_SUBNETWORK_REGION="northamerica-south1"
ROUTER_NAME="router-$VPC_SUBNETWORK"
NAT_GATEWAY="nat-$VPC_SUBNETWORK"

# SERVICE ACCOUNT PARAMETERS
GCP_SA_NAME="sa-dd-integration"
GCP_SA_DISPLAY_NAME="sa-dd-integration"
GCP_SA_EMAIL="$GCP_SA_NAME@$GCP_PROJECT_ID.iam.gserviceaccount.com"

# DATADOG PARAMETERS
DD_PRINCIPAL_DD="ddgci-264b9f6d06078d90b221@datadog-gci-sts-us1-prod.iam.gserviceaccount.com"
DD_PRINCIPAL="serviceAccount:$DD_PRINCIPAL_DD"

# Utility Functions
pause() {
    echo "Press ENTER to continue..."
    read -r
    clear
}

create_project() {
    echo "Creating GCP project: $GCP_PROJECT_NAME..."
    gcloud projects create "$GCP_PROJECT_ID" \
        --name="$GCP_PROJECT_NAME" \
        --folder="$GCP_FOLDER_ID" \
        --set-as-default
    gcloud billing projects link "$GCP_PROJECT_ID" --billing-account="$GCP_BILLING_ACCOUNT_ID"
    gcloud services enable compute.googleapis.com --project="$GCP_PROJECT_ID"
    echo "Project created and configured."
    pause
}

setup_networking() {
    echo "Setting up networking..."
    gcloud compute networks delete default --quiet || echo "Default network not found, skipping delete."
    gcloud compute networks create "$VPC_NETWORK" \
        --project="$GCP_PROJECT_ID" \
        --subnet-mode=custom \
        --mtu=1460 --bgp-routing-mode=regional
    gcloud compute networks subnets create "$VPC_SUBNETWORK" \
        --project="$GCP_PROJECT_ID" \
        --range="$VPC_SUBNETWORK_RANGE" \
        --network="$VPC_NETWORK" \
        --region="$VPC_SUBNETWORK_REGION" \
        --enable-private-ip-google-access
    gcloud compute firewall-rules create allow-ports-for-dataflow \
        --network="$VPC_NETWORK" \
        --allow tcp:12345-12346 \
        --source-ranges="$VPC_SUBNETWORK_RANGE"
    gcloud compute firewall-rules create allow-ssh-iap \
        --network="$VPC_NETWORK" \
        --allow tcp:22 \
        --source-ranges 35.235.240.0/20
    gcloud compute routers create "$ROUTER_NAME" \
        --region="$VPC_SUBNETWORK_REGION" \
        --network="$VPC_NETWORK"
    gcloud compute routers nats create "$NAT_GATEWAY" \
        --router="$ROUTER_NAME" \
        --region="$VPC_SUBNETWORK_REGION" \
        --auto-allocate-nat-external-ips \
        --nat-all-subnet-ip-ranges
    echo "Networking setup complete."
    pause
}

create_service_account() {
    echo "Creating Service Account: $GCP_SA_EMAIL..."
    gcloud iam service-accounts create "$GCP_SA_NAME" \
        --display-name="$GCP_SA_DISPLAY_NAME" \
        --project="$GCP_PROJECT_ID"
    echo "Service Account created."
    pause
}

assign_roles() {
    local scope=$1
    echo "Assigning roles at $scope level..."
    if [[ "$scope" == "project" ]]; then
        ROLES=("roles/monitoring.viewer" "roles/compute.viewer" "roles/cloudasset.viewer" "roles/browser")
        for role in "${ROLES[@]}"; do
            gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
                --member="serviceAccount:$GCP_SA_EMAIL" \
                --role="$role"
        done
    elif [[ "$scope" == "organization" ]]; then
        ROLES=("roles/compute.viewer" "roles/monitoring.viewer" "roles/cloudasset.viewer")
        for role in "${ROLES[@]}"; do
            gcloud organizations add-iam-policy-binding "$GCP_ORG_ID" \
                --member="serviceAccount:$GCP_SA_EMAIL" \
                --role="$role"
        done
    fi
    echo "Roles assigned at $scope level."
    pause
}

grant_impersonation() {
    echo "Granting Datadog Principal permission to impersonate the Service Account..."
    gcloud iam service-accounts add-iam-policy-binding "$GCP_SA_EMAIL" \
        --member="$DD_PRINCIPAL" \
        --role='roles/iam.serviceAccountTokenCreator'
    echo "Impersonation granted."
    pause
}

final_instructions() {
    echo "Copy the following GCP Service Account email and add it to your Datadog configuration:"
    echo "GCP Service Account: $GCP_SA_EMAIL"
    echo "Setup complete."
}

# Main Script Execution
clear
echo "Starting Datadog-GCP integration setup..."
create_project
setup_networking
create_service_account
assign_roles "project"
assign_roles "organization"
grant_impersonation
final_instructions

exit 0