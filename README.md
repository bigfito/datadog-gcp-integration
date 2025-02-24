# Datadog-GCP Integration

This repository contains a series of bash shell scripts meant to facilitate the setup process of the Datadog integration with Google Cloud Platform in order to start receiving metrics and logs from the available GCP services.  The scripts were developed following the directions from the official Datadog documentation for the Datadog-GCP integration that can be found at https://docs.datadoghq.com/integrations/google_cloud_platform/?tab=dataflowmethodrecommended#log-collection.

The shell scripts make calls to different commands from the Google Cloud SDK, especially "gcloud" commands in order to enable and create the required resources. For more information regarding the Google Cloud SDK you can visit the following link: https://cloud.google.com/sdk/docs/install.

# Prerequisites (read carefully)

1) You must execute the scripts either from a Cloud Shell windows from your GCP environment or a local terminal session in your own laptop/desktop (assuming you have previously installed the Google Cloud SDK locally and you have authenticated with 'gcloud auth login').  The preferred method is to do it in a Cloud Shell windows in your GCP environment.
2) The user account you use to execute the scripts must have ADMIN priviliges in your GCP organization.  Otherwise, it will add complexity to the scripts to consider all the different IAM roles scenarios.
3) Do not forget to add execution permissions over the scripts so you can execute them in your shell environment.
4) DO NOT TEST IN PRODUCTION.  Try the scripts in a SAFE environment first such as DEV or a personal GCP account.

# Part I.  Enabling the Datadog-GCP Integration

For enbaling the Datadog-GCP integration you must execute the following scripts:

1) dd-gcp-integration-setup-1.sh: This script will enable all GCP APIs that are required for the Datadog-GCP integration to work on each one of your GCP projects.
2) dd-gcp-integration-setup-2.sh: This script will walk you through the setup process of the Datadog-GCP integration by creating a series of resources than will be needed.  (This script requires you to update the PARAMETERS section at the top of the script with the proper values you are willing to use for your configurations).

The main idea is creating a new dedicated GCP project (03-OBSERVABILITY/PRJ-DD-INTEGRATION-01) to host all related resources that will be needed for the Datadog-GCP integration to work properly.  If you have a resource architecture based in "Shared VPC", it is not necessary to create your observability project based on that, again, the main purpose is to reduce complexity.  At the end, the resources created in the GCP datadog integration project will be monitoring the whole structure of projects in your organization.  A recommended hierarchy of resources in GCP is shown below:

![resource-manager-observability](https://github.com/user-attachments/assets/e83b1b68-0f9e-4b6e-b8f7-7c317cc38e14)


# Part II.  Enabling the LOG collection for the Datadog-GCP Integration

By default the Datadog-GCP integration DOES NOT configure your GCP environment to forward LOGS to the Datadog intake service.  This is something you will have to do on your own.  But no worries, you can still get assistance by executing our last bash shell script.  For enbaling the Datadog-GCP log forwarding to the Datadog intake service you must execute the following script:

1) dd-gcp-integration-setup-3.sh: Executing this script assumes you have already executed the 2 previous ones from the PART I of this series.  This script will create a ROUTER LOG SINK in your Google Cloud Logging service and route all logs (you should consider applying a log filter to reduce the amount of logs) to a Google Cloud Pub/Sub subscription that will be read by a Dataflow data job and then all of the logs will be forwarded to the intake Datadog service.  Take some time to customize this script by updating the proper values in the PARAMETERS section at the top of the script.

![dd-gcp-log-collection](https://github.com/user-attachments/assets/99b3ffb5-aa24-4c8b-baf3-7d6e280af6e6)


# BONUS.  If you are also considering to work with Datadog's Cloud Cost Management (CCM) module.  There is an additional directory with scripts to facilitate that integration too.

If you feel my scripts were helpful to you, I will appreciate you STAR my repository, PIN it to your profile, save it in your browser's bookmarks and also tell your friends and colleagues about it.  Spread the word!.  I am open to suggestions as well, so in case you come up with a good idea to improve my scripts, feel free to drop me a message.  Enjoy my repo!.
