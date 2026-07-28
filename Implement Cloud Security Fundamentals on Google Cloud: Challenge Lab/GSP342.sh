#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL=$'\033[38;5;50m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                                         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo


read -p "Enter CUSTOM_SECURITY_ROLE: " CUSTOM_SECURITY_ROLE
read -p "Enter SERVICE_ACCOUNT: " SERVICE_ACCOUNT
read -p "Enter CLUSTER_NAME: " CLUSTER_NAME
read -p "Enter ZONE: " ZONE

gcloud config set compute/zone $ZONE

cat > role-definition.yaml <<EOF
title: "$CUSTOM_SECURITY_ROLE"
description: "Permissions"
stage: "ALPHA"
includedPermissions:
- storage.buckets.get
- storage.objects.get
- storage.objects.list
- storage.objects.update
- storage.objects.create
EOF

gcloud iam service-accounts create orca-private-cluster-sa \
--display-name="Orca Private Cluster Service Account"

gcloud iam roles create $CUSTOM_SECURITY_ROLE \
--project $DEVSHELL_PROJECT_ID \
--file role-definition.yaml

gcloud iam service-accounts create $SERVICE_ACCOUNT \
--display-name="Orca Private Cluster Service Account"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role roles/monitoring.viewer

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role roles/logging.logWriter

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--role projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_SECURITY_ROLE

gcloud container clusters create $CLUSTER_NAME \
--num-nodes 1 \
--master-ipv4-cidr=172.16.0.64/28 \
--network orca-build-vpc \
--subnetwork orca-build-subnet \
--enable-master-authorized-networks \
--master-authorized-networks 192.168.10.2/32 \
--enable-ip-alias \
--enable-private-nodes \
--enable-private-endpoint \
--service-account $SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--zone $ZONE

gcloud compute ssh --zone "$ZONE" "orca-jumphost" \
--project "$DEVSHELL_PROJECT_ID" \
--quiet \
--command "
gcloud config set compute/zone $ZONE &&
gcloud container clusters get-credentials $CLUSTER_NAME --internal-ip &&
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin &&
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0 &&
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 80 \
--target-port 8080
"

# Final message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
