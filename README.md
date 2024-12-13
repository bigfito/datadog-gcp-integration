# Datadog-GCP Integration

This repository contains a series of bash shell scripts meant to facilitate the setup process of the Datadog integration with Google Cloud Platform in order to start receiving metrics and logs from the available GCP services.  The scripts were developed following the directions from the official Datadog documentation for the Datadog-GCP integration that can be found at https://docs.datadoghq.com/integrations/google_cloud_platform/?tab=dataflowmethodrecommended#log-collection.  The shell scripts make call to commands from the Google Cloud SDK, especially "gcloud" commands in order to enable and create the required resources.
