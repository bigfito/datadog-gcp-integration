#!/bin/bash
#
# @author: Adolfo Orozco - adolfo.orozco@datadoghq.com
# @version: 1.0
# @description: This script grants to the Service Account all necessary BigQuery roles on the GCP CCM project

# GCP PROJECT FOR DATADOG'S CLOUD COST MANAGEMENT
GCP_CCM_PROJECT_ID="dd-integration-439619"

# GCP SERVICE ACCOUNT USED FOR DATADOG INTEGRATION
GCP_DD_SA="sa-datadog@dd-integration-439619.iam.gserviceaccount.com"
MEMBER_VALUE="serviceAccount:$GCP_DD_SA"

echo "Granting Bigquery Admin to the service account..."
gcloud projects add-iam-policy-binding $GCP_CCM_PROJECT_ID \
       --member=$MEMBER_VALUE \
       --role='roles/bigquery.admin'

printf "\n"
echo "All BigQuery roles granted to the Service Account."
echo "Press ENTER to continue..."
read -r PRESS_KEY

printf "\n"
echo "Now perform the following steps manually.."
echo "Step 1): Navigate to Billing Export under Google Cloud console Billing."
echo "Step 2): Enable the Detailed Usage cost export (choose the GCP datadog integration project)."
echo "Step 3): Select the BigQuery dataset that was created with the help of the script dd-ccm-for-gcp-2.sh."
echo "Click SAVE.  You have now completed the Cloud Cost Management (CCM) setup on the GCP side."

printf "\n"
echo "Press ENTER to exit..."
read -r PRESS_KEY

exit 0