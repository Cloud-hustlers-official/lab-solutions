#!/bin/bash

# Enhanced Color Definitions
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Header Section
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}        WELCOME TO CLOUD HUSTLER TUTORIAL       ${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo
echo "${BLUE}${BOLD}⚡ Initializing Vulnerability Scanning Setup...${RESET}"
echo

# Environment Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENVIRONMENT CONFIGURATION ▬▬▬▬▬▬▬▬▬${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "${YELLOW}Project ID: ${WHITE}${BOLD}$PROJECT_ID${RESET}"
echo "${YELLOW}Region: ${WHITE}${BOLD}$REGION${RESET}"
echo "${YELLOW}Zone: ${WHITE}${BOLD}$ZONE${RESET}"
echo

# Service Enablement
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENABLING SERVICES ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Enabling required Google Cloud services...${RESET}"
gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com
echo "${GREEN}✅ Services enabled successfully!${RESET}"
echo

# IAM Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ IAM PERMISSIONS ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Configuring IAM permissions...${RESET}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/ondemandscanning.admin"
echo "${GREEN}✅ IAM permissions configured!${RESET}"
echo

# Application Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ APPLICATION SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating application files...${RESET}"
mkdir -p vuln-scan && cd vuln-scan

cat > ./Dockerfile << EOF
FROM gcr.io/google-appengine/debian11

# System
RUN apt update && apt install python3-pip -y

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==1.1.4  
RUN pip3 install gunicorn==20.1.0  

CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF

cat > ./main.py << EOF
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "Worlds")
    return "Hello {}!".format(name)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF
echo "${GREEN}✅ Application files created!${RESET}"
echo

# Initial Build
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ INITIAL BUILD ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Submitting initial build...${RESET}"
gcloud builds submit
echo "${GREEN}✅ Initial build completed!${RESET}"
echo

# Artifact Registry Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ARTIFACT REGISTRY SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating Artifact Registry repository...${RESET}"
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for vulnerability scanning"
echo "${GREEN}✅ Artifact Registry repository created!${RESET}"
echo

# Docker Configuration
echo "${YELLOW}Configuring Docker authentication...${RESET}"
gcloud auth configure-docker $REGION-docker.pkg.dev
echo "${GREEN}✅ Docker configured!${RESET}"
echo

# Build with Artifact Registry
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ BUILD WITH ARTIFACT REGISTRY ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Updating cloudbuild.yaml...${RESET}"
cat > ./cloudbuild.yaml << EOF
steps:
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']

images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${YELLOW}Building and pushing image...${RESET}"
gcloud builds submit
echo "${GREEN}✅ Image built and pushed successfully!${RESET}"
echo

# Vulnerability Scanning
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ VULNERABILITY SCANNING ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Scanning Docker image for vulnerabilities...${RESET}"
docker build -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image .

gcloud artifacts docker images scan \
    $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image \
    --format="value(response.scan)" > scan_id.txt

echo "${YELLOW}Scan ID: ${WHITE}$(cat scan_id.txt)${RESET}"

echo "${YELLOW}Listing vulnerabilities...${RESET}"
gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt)

export SEVERITY=CRITICAL
echo "${YELLOW}Checking for ${SEVERITY} vulnerabilities...${RESET}"
gcloud artifacts docker images list-vulnerabilities $(cat scan_id.txt) \
  --format="value(vulnerability.effectiveSeverity)" | \
  if grep -Fxq ${SEVERITY}; then \
    echo "${RED}Failed vulnerability check for ${SEVERITY} level${RESET}"; \
  else echo "${GREEN}No ${SEVERITY} Vulnerabilities found${RESET}"; fi
echo

# Secure Build Pipeline
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ SECURE BUILD PIPELINE ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Creating secure build pipeline...${RESET}"
cat > ./cloudbuild.yaml << EOF
steps:
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

- id: scan
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    (gcloud artifacts docker images scan \
    $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image \
    --location us \
    --format="value(response.scan)") > /workspace/scan_id.txt

- id: severity check
  name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
      gcloud artifacts docker images list-vulnerabilities \$(cat /workspace/scan_id.txt) \
      --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq CRITICAL; \
      then echo "Failed vulnerability check for CRITICAL level" && exit 1; else echo "No CRITICAL vulnerability found, congrats !" && exit 0; fi

- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']

images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${YELLOW}Running secure build pipeline...${RESET}"
gcloud builds submit
echo "${GREEN}✅ Secure build pipeline completed!${RESET}"
echo

# Updated Application
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ UPDATED APPLICATION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Updating application with newer dependencies...${RESET}"
cat > ./Dockerfile << EOF
FROM python:3.12-alpine 

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==3.0.3
RUN pip3 install gunicorn==22.0.0
RUN pip3 install Werkzeug==3.0.3

CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

gcloud builds submit
echo "${GREEN}✅ Application updated successfully!${RESET}"
echo

# Completion Message
echo "${BG_GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}          VULNERABILITY SCANNING TUTORIAL COMPLETE!     ${RESET}"
echo "${BG_GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo "${RED}${BOLD}🙏 Thank you for following Cloud Hustler tutorial!${RESET}"
echo "${YELLOW}${BOLD}📺 Subscribe for more GCP security content:${RESET}"
echo
echo "${MAGENTA}${BOLD}🔒 Happy secure coding on Google Cloud!${RESET}"
