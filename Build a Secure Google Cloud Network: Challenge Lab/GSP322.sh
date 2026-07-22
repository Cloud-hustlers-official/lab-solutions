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

NO_COLOR=$'\033[0m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'

# Header Section
echo "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}${BOLD}        WELCOME TO CLOUD TUTORIALS           ${RESET}"
echo "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echo
echo
echo "${BLUE}${BOLD}⚡ Initializing Network Security Configuration...${RESET}"
echo

# User Input Section
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ INPUT PARAMETERS ▬▬▬▬▬▬▬▬▬${RESET}"
read -p "${YELLOW}${BOLD}Enter IAP_NETWORK_TAG: ${RESET}" IAP_NETWORK_TAG
read -p "${YELLOW}${BOLD}Enter INTERNAL_NETWORK_TAG: ${RESET}" INTERNAL_NETWORK_TAG
read -p "${YELLOW}${BOLD}Enter HTTP_NETWORK_TAG: ${RESET}" HTTP_NETWORK_TAG
read -p "${YELLOW}${BOLD}Enter ZONE (e.g., us-central1-a): ${RESET}" ZONE

echo
echo "${CYAN}Configuration Parameters:${RESET}"
echo "${WHITE}IAP Network Tag: ${BOLD}$IAP_NETWORK_TAG${RESET}"
echo "${WHITE}Internal Network Tag: ${BOLD}$INTERNAL_NETWORK_TAG${RESET}"
echo "${WHITE}HTTP Network Tag: ${BOLD}$HTTP_NETWORK_TAG${RESET}"
echo "${WHITE}Zone: ${BOLD}$ZONE${RESET}"
echo

# Firewall Configuration
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FIREWALL SETUP ▬▬▬▬▬▬▬▬▬${RESET}"

echo "${YELLOW}Removing default open-access rule...${RESET}"
gcloud compute firewall-rules delete open-access --quiet
echo "${GREEN}✅ Default open-access rule removed!${RESET}"
echo

echo "${YELLOW}Creating SSH ingress rule for IAP...${RESET}"
gcloud compute firewall-rules create ssh-ingress \
  --allow=tcp:22 \
  --source-ranges 35.235.240.0/20 \
  --target-tags $IAP_NETWORK_TAG \
  --network acme-vpc
echo "${GREEN}✅ SSH ingress rule for IAP created!${RESET}"

echo "${YELLOW}Tagging bastion instance for IAP access...${RESET}"
gcloud compute instances add-tags bastion \
  --tags=$IAP_NETWORK_TAG \
  --zone=$ZONE
echo "${GREEN}✅ Bastion instance tagged!${RESET}"
echo

echo "${YELLOW}Creating HTTP ingress rule...${RESET}"
gcloud compute firewall-rules create http-ingress \
  --allow=tcp:80 \
  --source-ranges 0.0.0.0/0 \
  --target-tags $HTTP_NETWORK_TAG \
  --network acme-vpc
echo "${GREEN}✅ HTTP ingress rule created!${RESET}"

echo "${YELLOW}Tagging juice-shop instance for HTTP access...${RESET}"
gcloud compute instances add-tags juice-shop \
  --tags=$HTTP_NETWORK_TAG \
  --zone=$ZONE
echo "${GREEN}✅ Juice-shop instance tagged!${RESET}"
echo

echo "${YELLOW}Creating internal SSH ingress rule...${RESET}"
gcloud compute firewall-rules create internal-ssh-ingress \
  --allow=tcp:22 \
  --source-ranges 192.168.10.0/24 \
  --target-tags $INTERNAL_NETWORK_TAG \
  --network acme-vpc
echo "${GREEN}✅ Internal SSH ingress rule created!${RESET}"

echo "${YELLOW}Tagging juice-shop instance for internal SSH access...${RESET}"
gcloud compute instances add-tags juice-shop \
  --tags=$INTERNAL_NETWORK_TAG \
  --zone=$ZONE
echo "${GREEN}✅ Juice-shop instance tagged for internal access!${RESET}"
echo

# Instance Management
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ INSTANCE MANAGEMENT ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Starting bastion instance...${RESET}"
gcloud compute instances start bastion --zone=$ZONE
echo "${GREEN}✅ Bastion instance started!${RESET}"
echo "${YELLOW}Waiting 30 seconds for instance to initialize...${RESET}"
sleep 30
echo

# Environment Setup
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ ENVIRONMENT SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Exporting environment variables...${RESET}"
echo "export ZONE=$ZONE" > env_vars.sh
source env_vars.sh
echo "${GREEN}✅ Environment variables configured!${RESET}"
echo

# Script Preparation
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ SCRIPT SETUP ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Preparing connection script...${RESET}"
cat > prepare_disk.sh <<'EOF_END'
#!/bin/bash
# Source the environment variables
source /tmp/env_vars.sh

# Connect to juice-shop instance via internal IP
gcloud compute ssh juice-shop --zone=$ZONE --internal-ip --quiet
EOF_END
echo "${GREEN}✅ Connection script prepared!${RESET}"
echo

# File Transfer
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ FILE TRANSFER ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Transferring files to bastion instance...${RESET}"
gcloud compute scp env_vars.sh bastion:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
gcloud compute scp prepare_disk.sh bastion:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
echo "${GREEN}✅ Files transferred successfully!${RESET}"
echo

# Remote Execution
echo "${GREEN}${BOLD}▬▬▬▬▬▬▬▬▬ REMOTE EXECUTION ▬▬▬▬▬▬▬▬▬${RESET}"
echo "${YELLOW}Executing connection script on bastion...${RESET}"
gcloud compute ssh bastion --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"
echo "${GREEN}✅ Connection script executed!${RESET}"
echo

# Completion Message
echo "${GREEN}${BOLD}╔════════════════════════════════════════════════════════╗${RESET}"
echo "${GREEN}${BOLD}          LAB COMPLETED!               ${RESET}"
echo "${GREEN}${BOLD}╚════════════════════════════════════════════════════════╝${RESET}"
echoecho "${MAGENTA}${BOLD}🔒 Happy secure networking with Google Cloud!${RESET}"
