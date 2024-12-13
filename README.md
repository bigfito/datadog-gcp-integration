# Datadog-GCP Integration

This repository contains a series of bash shell scripts meant to facilitate the setup process of the Datadog integration with Google Cloud Platform in order to start receiving metrics and logs from the available GCP services.  The scripts were developed following the directions from the official Datadog documentation for the Datadog-GCP integration that can be found at https://docs.datadoghq.com/integrations/google_cloud_platform/?tab=dataflowmethodrecommended#log-collection.  The shell scripts make call to commands from the Google Cloud SDK, especially "gcloud" commands in order to enable and create the required resources.

# Prerequsites

1) You must execute the scripts either from a Cloud Shell windows from your GCP environment or a local terminal session in your own laptop/desktop (assuming you have previously installed the Google Cloud SDK locally and you have authenticated with 'gcloud auth login').  The preferred method is to do it in a Cloud Shell windows in your GCP environment.
2) The user account you use to execute the scripts must have ADMIN priviliges in your GCP organization.  Otherwise, it will add complexity to the scripts to consider all the different IAM roles scenarios.
3) 3) Do not forget to add execution permissions over the scripts so you can execute them in your shell environment.

# Part I.  Enabling the Datadog-GCP Integration

For enbaling the Datadog-GCP integration you must execute the following scripts:

a) dd-gcp-integration-setup-1.sh: This script will enable all GCP APIs that are required for the Datadog-GCP integration to work on each one of your GCP projects.
b) dd-gcp-integration-setup-2.sh: This script will walk you through the setup process of the Datadog-GCP integration by creating a series of resources than will be needed.  (This script requires you update the PARAMETERS section at the top of the script with the proper values you are willing to use for your configurations).

The central idea is creating a new dedicated GCP project to host all related resources that will be needed for the Datadog-GCP integration to work properly.  A recommended hierarchy of resources is shown below:

![bigfito-cloud-resources](https://github.com/user-attachments/assets/36e8df9e-e44e-4ab9-ba6c-2e08a0ed051b)
