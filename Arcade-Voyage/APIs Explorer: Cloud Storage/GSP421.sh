#!/bin/bash

HEADER_COLOR=$'\033[38;5;54m'       # Deep purple
TITLE_COLOR=$'\033[38;5;93m'         # Bright purple
PROMPT_COLOR=$'\033[38;5;178m'       # Gold
ACTION_COLOR=$'\033[38;5;44m'        # Teal
SUCCESS_COLOR=$'\033[38;5;46m'       # Bright green
WARNING_COLOR=$'\033[38;5;196m'      # Bright red
LINK_COLOR=$'\033[38;5;27m'          # Blue
TEXT_COLOR=$'\033[38;5;255m'         # Bright white

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear


echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${TITLE_COLOR}${BOLD_TEXT}       🎓 CLOUD HUSTLER STORAGE TUTORIAL       ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}This lab demonstrates Cloud Storage operations including${RESET_FORMAT}"
echo "${TEXT_COLOR}bucket creation and file management in Google Cloud.${RESET_FORMAT}"
echo

# Cloud Storage operations section
echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━ CLOUD HUSTLER STORAGE OPERATIONS ━━━━━━━━━━━━┓${RESET_FORMAT}"
echo

# Step 1: Creating Buckets
echo "${ACTION_COLOR}${BOLD_TEXT}🛠️  Step 1: Creating Cloud Storage Buckets${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID
gsutil mb gs://$DEVSHELL_PROJECT_ID-2
echo "${SUCCESS_COLOR}✓ Buckets created successfully${RESET_FORMAT}"

# Step 2: Downloading Images
echo
echo "${ACTION_COLOR}${BOLD_TEXT}📥 Step 2: Downloading Demo Images${RESET_FORMAT}"
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image1.png
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image2.png
curl -# -LO raw.githubusercontent.com/GoogleCloudPlatform/cloud-storage-samples/main/sample-files/demo-image1-copy.png
echo "${SUCCESS_COLOR}✓ Images downloaded successfully${RESET_FORMAT}"

# Step 3: Uploading Images
echo
echo "${ACTION_COLOR}${BOLD_TEXT}☁️  Step 3: Uploading Images to Cloud Storage${RESET_FORMAT}"
gsutil cp demo-image1.png gs://$DEVSHELL_PROJECT_ID/demo-image1.png
gsutil cp demo-image2.png gs://$DEVSHELL_PROJECT_ID/demo-image2.png
gsutil cp demo-image1-copy.png gs://$DEVSHELL_PROJECT_ID-2/demo-image1-copy.png
echo "${SUCCESS_COLOR}✓ Files uploaded successfully${RESET_FORMAT}"

# Cleanup
echo
echo "${ACTION_COLOR}${BOLD_TEXT}🧹 Performing Cleanup${RESET_FORMAT}"
SCRIPT_NAME="cloud-storage-lab.sh"
if [ -f "$SCRIPT_NAME" ]; then
    rm -- "$SCRIPT_NAME"
    echo "${SUCCESS_COLOR}✓ Temporary files cleaned up${RESET_FORMAT}"
fi

# Completion message
echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${SUCCESS_COLOR}${BOLD_TEXT}          🎉 LAB COMPLETED SUCCESSFULLY! 🎉         ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}${BOLD_TEXT}You've successfully completed these operations:${RESET_FORMAT}"
echo "${TEXT_COLOR}• Created Cloud Storage buckets"
echo "• Downloaded sample images"
echo "• Uploaded files to storage buckets"
echo "• Performed cleanup operations${RESET_FORMAT}"
echo "${PROMPT_COLOR}${BOLD_TEXT}   Don't forget to like and subscribe!${RESET_FORMAT}"
echo

