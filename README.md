# Datadog-GCP Integration

This repository contains a series of bash shell scripts meant to facilitate the setup process of the Datadog integration with Google Cloud Platform in order to start receiving metrics and logs from the available GCP services.  The scripts were developed following the directions from the official Datadog documentation for the Datadog-GCP integration that can be found at https://docs.datadoghq.com/integrations/google_cloud_platform/?tab=dataflowmethodrecommended#log-collection.

The shell scripts make calls to different commands from the Google Cloud SDK, especially "gcloud" commands in order to enable and create the required resources. For more information regarding the Google Cloud SKD you can visit the following link: https://cloud.google.com/sdk/docs/install.

# Prerequisites (read carefully)

1) You must execute the scripts either from a Cloud Shell windows from your GCP environment or a local terminal session in your own laptop/desktop (assuming you have previously installed the Google Cloud SDK locally and you have authenticated with 'gcloud auth login').  The preferred method is to do it in a Cloud Shell windows in your GCP environment.
2) The user account you use to execute the scripts must have ADMIN priviliges in your GCP organization.  Otherwise, it will add complexity to the scripts to consider all the different IAM roles scenarios.
3) Do not forget to add execution permissions over the scripts so you can execute them in your shell environment.
4) DO NOT TEST IN PRODUCTION.  Try the scripts in a SAFE environment first such as DEV or a personal GCP account.

# Part I.  Enabling the Datadog-GCP Integration

For enbaling the Datadog-GCP integration you must execute the following scripts:

1) dd-gcp-integration-setup-1.sh: This script will enable all GCP APIs that are required for the Datadog-GCP integration to work on each one of your GCP projects.
2) dd-gcp-integration-setup-2.sh: This script will walk you through the setup process of the Datadog-GCP integration by creating a series of resources than will be needed.  (This script requires you update the PARAMETERS section at the top of the script with the proper values you are willing to use for your configurations).

The central idea is creating a new dedicated GCP project (03-OBSERVABILITY/PRJ-DD-INTEGRATION-01) to host all related resources that will be needed for the Datadog-GCP integration to work properly.  A recommended hierarchy of resources in GCP is shown below:

![bigfito-cloud-resources](https://github.com/user-attachments/assets/36e8df9e-e44e-4ab9-ba6c-2e08a0ed051b)

# Part II.  Enabling the LOG collection for the Datadog-GCP Integration

By default the Datadog-GCP integration DOES NOT configure your GCP environment to forward LOGS to Datadog.  This is something you will have to do on your own.  But no worries, you can still get assistance by executing our last bash shell script.  For enbaling the Datadog-GCP log forwarding to the Datadog intake service you must execute the following script:

1) dd-gcp-integration-setup-3.sh: Executing this script assumes you have already executed the 2 previous ones from the PART I of this series.  This script will create a ROUTER LOG SINK in your Cloud Logging service and routing all logs to a Cloud Pub/Sub subscription that will be read by a Dataflow job and then all logs will be forwarded to the intake Datadog service.  Take some time to customize this script by updating the proper values to in the PARAMETERS section at the top of the script.

![image](https://github.com/user-attachments/assets/9c8e849d-8e05-4bbf-8a0f-41493359f6bd)


If you feel my scripts were helpful to you, I will appreciate you STAR my repository, PINT it to your profile, save it in your browser's bookmarks and also tell your friends and colleagues about it.  Spread the word!.  I am open to suggestions as well, so in case you come up with a good idea to improve my scripts, feel free to drop me a message.  Enjoy my repo!.
