#!/bin/bash
# Define rich color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Background colors
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Text effects
BOLD=$(tput bold)
DIM=$(tput dim)
BLINK=$(tput blink)
REVERSE=$(tput rev)
RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#


echo "${BG_BLUE}${WHITE}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   🌊 Welcome to Cloud Hustlers Tutorial                  ║"
echo "║                                                            ║"
echo "║   📺 Learn more at:                                        ║"
echo "║   ${BLINK}https://www.youtube.com/@CloudHustlers${RESET}${BG_BLUE}${WHITE}${BOLD}               ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "${RESET}"

# Section header function
section() {
    echo ""
    echo "${BG_MAGENTA}${WHITE}${BOLD}»»» $1 «««${RESET}"
    echo ""
}

# User input section
section "CONFIGURATION INPUTS"
echo "${BOLD}${YELLOW}Please provide the following configuration values:${RESET}"
echo ""
read -p "Enter ZONE (e.g., us-central1-a): " ZONE
read -p "Enter KEY_1 for labels: " KEY_1
read -p "Enter VALUE_1 for labels: " VALUE_1

# Export derived values
section "SETTING ENVIRONMENT"
export REGION="${ZONE%-*}"
echo "${BOLD}${GREEN}✓${RESET} Derived REGION: ${WHITE}${REGION}${RESET}"
echo "${BOLD}${GREEN}✓${RESET} Using PROJECT_ID: ${WHITE}${DEVSHELL_PROJECT_ID}${RESET}"

# Dataplex Lake creation
section "CREATING DATAPLEX LAKE"
echo "${BOLD}${GREEN}✓${RESET} Creating Customer Lake with labels..."
gcloud alpha dataplex lakes create customer-lake \
  --display-name="Customer-Lake" \
  --location=$REGION \
  --labels="key_1=$KEY_1,value_1=$VALUE_1"

# Zone creation
section "CREATING DATAPLEX ZONE"
echo "${BOLD}${GREEN}✓${RESET} Creating Public Zone..."
gcloud dataplex zones create public-zone \
  --lake=customer-lake \
  --location=$REGION \
  --type=RAW \
  --resource-location-type=SINGLE_REGION \
  --display-name="Public-Zone"

# Asset creation
section "CREATING DATAPLEX ASSETS"
echo "${BOLD}${GREEN}✓${RESET} Creating Customer Raw Data asset..."
gcloud dataplex assets create customer-raw-data \
  --location=$REGION \
  --lake=customer-lake \
  --zone=public-zone \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-bucket \
  --discovery-enabled \
  --display-name="Customer Raw Data"

echo "${BOLD}${GREEN}✓${RESET} Creating Customer Reference Data asset..."
gcloud dataplex assets create customer-reference-data \
  --location=$REGION \
  --lake=customer-lake \
  --zone=public-zone \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_reference_data \
  --display-name="Customer Reference Data"

# Completion message
echo ""
echo "${BG_GREEN}${BLACK}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   🎉 ${WHITE}LAB COMPLETED SUCCESSFULLY!${BLACK}           ║"
echo "║                                                            ║"
echo "║   ${WHITE}Created Resources:${BLACK}                                ║"
echo "║   - Lake: customer-lake                                    ║"
echo "║   - Zone: public-zone                                      ║"
echo "║   - Assets: customer-raw-data, customer-reference-data     ║"
echo "║                                                            ║"
echo "║   ${WHITE}For more  tutorials:${BLACK}               ║"
echo "║   ${BLINK}${WHITE}Subscribe to Cloud Hustlers YouTube Channel${RESET}${BG_GREEN}${BLACK}${BOLD}  ║"
echo "║   ${WHITE}https://www.youtube.com/@CloudHustlers${BLACK}                ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "${RESET}"

# Export values reminder
echo ""
echo "${BOLD}${YELLOW}Remember to export these values for future use:${RESET}"
echo "export REGION=${REGION}"
echo "export ZONE=${ZONE}"
echo "export KEY_1=${KEY_1}"
echo "export VALUE_1=${VALUE_1}"
echo ""
