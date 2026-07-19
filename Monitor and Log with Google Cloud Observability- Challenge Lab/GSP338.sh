#!/bin/bash

# Enhanced Color Definitions
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

BG_BLACK=$'\033[40m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'

BOLD=$'\033[1m'
RESET=$'\033[0m'
UNDERLINE=$'\033[4m'

# Header Section
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}        WELCOME TO CLOUD HUSTLERS              ${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${CYAN}${BOLD}⚡ Initializing Video Queue Monitoring Configuration...${RESET}"
echo

# User Input Section
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ USER INPUT ▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}Enter custom_metric: ${RESET}" custom_metric
read -p "${YELLOW}Enter VALUE: ${RESET}" VALUE
echo

# Authentication Check
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ AUTHENTICATION ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Checking active GCP account...${RESET}"
gcloud auth list
echo

# Project Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ PROJECT SETUP ▬▬▬▬▬▬▬▬${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
echo "${CYAN}Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET}"
echo

# Service Enablement
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ SERVICE ENABLEMENT ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Enabling Monitoring API...${RESET}"
gcloud services enable monitoring.googleapis.com --project="$DEVSHELL_PROJECT_ID"
echo "${GREEN}✅ Monitoring API enabled successfully!${RESET}"
echo

# Zone and Region Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ REGION SETUP ▬▬▬▬▬▬▬▬${RESET}"
ZONE=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format="get(zone)" --limit=1)
gcloud config set compute/zone $ZONE
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
echo "${CYAN}Zone: ${WHITE}${BOLD}$ZONE${RESET}"
echo "${CYAN}Region: ${WHITE}${BOLD}$REGION${RESET}"
echo

# Instance Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ INSTANCE SETUP ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Retrieving instance details...${RESET}"
INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --format="get(id)")
echo "${YELLOW}Stopping video-queue-monitor instance...${RESET}"
gcloud compute instances stop video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE"
echo "${GREEN}✅ Instance stopped successfully!${RESET}"
echo

# Startup Script Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ STARTUP SCRIPT ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating startup script...${RESET}"
cat > startup-script.sh <<EOF_CP
#!/bin/bash

ZONE="$ZONE"
REGION="${ZONE%-*}"
PROJECT_ID="$DEVSHELL_PROJECT_ID"

echo "ZONE: $ZONE"
echo "REGION: $REGION"
echo "PROJECT_ID: $PROJECT_ID"

sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

mkdir -p /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

cd /work/go
mkdir -p video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

# Set project metadata
export MY_PROJECT_ID="$DEVSHELL_PROJECT_ID"
export MY_GCE_INSTANCE_ID="$INSTANCE_ID"
export MY_GCE_INSTANCE_ZONE="$ZONE"

cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_CP

echo "${GREEN}✅ Startup script created successfully!${RESET}"
echo

# Apply Startup Script and Start Instance
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ INSTANCE DEPLOYMENT ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Applying startup script and starting instance...${RESET}"
gcloud compute instances add-metadata video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --metadata-from-file startup-script=startup-script.sh
gcloud compute instances start video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE"
echo "${GREEN}✅ Instance configured and started successfully!${RESET}"
echo

# Logging Metric Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ LOGGING METRIC ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating logging metric for high resolution videos...${RESET}"
gcloud logging metrics create $custom_metric \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=("file_format=4K" OR "file_format=8K")'
echo "${GREEN}✅ Logging metric created successfully!${RESET}"
echo

# Notification Channel Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ NOTIFICATION CHANNEL ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating email notification channel...${RESET}"
cat > email-channel.json <<EOF_CP
{
  "type": "email",
  "displayName": "CloudHustlersAlerts",
  "description": "Video Queue Monitoring by CloudHustlers",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_CP

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"
echo "${GREEN}✅ Notification channel created successfully!${RESET}"
echo

# Alert Policy Creation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬ ALERT POLICY ▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating alert policy...${RESET}"
channel_info=$(gcloud beta monitoring channels list)
channel_id=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > video-queue-alert.json <<EOF_CP
{
  "displayName": "CloudHustlersVideoAlerts",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "High Resolution Video Upload Rate",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$custom_metric\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": $VALUE
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_CP

gcloud alpha monitoring policies create --policy-from-file=video-queue-alert.json
echo "${GREEN}✅ Alert policy created successfully!${RESET}"
echo

# Completion Section
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}         LAB COMPLETED SUCCESSFULLY!                  ${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${MAGENTA}${BOLD}For more cloud engineering tutorials, visit:${RESET}"
echo "${BLUE}${UNDERLINE}https://www.youtube.com/@CloudHustlers${RESET}"
echo
echo "${CYAN}${BOLD}Happy cloud monitoring!${RESET}"
