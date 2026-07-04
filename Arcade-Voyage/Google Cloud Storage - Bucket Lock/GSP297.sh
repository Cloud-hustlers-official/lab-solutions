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
echo "${TEXT_COLOR}This lab demonstrates advanced Cloud Storage features including${RESET_FORMAT}"
echo "${TEXT_COLOR}retention policies, holds, and object lifecycle management.${RESET_FORMAT}"
echo

# Region selection with validation
if [ -z "$region" ]; then
  while true; do
    read -p "${PROMPT_COLOR}${BOLD_TEXT}🌍 Enter your GCP region (e.g., us-central1): ${RESET_FORMAT}" region
    if [[ -z "$region" ]]; then
      echo "${WARNING_COLOR}⚠ Region cannot be empty. Please try again.${RESET_FORMAT}"
    elif [[ $region =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
      export region
      echo "${SUCCESS_COLOR}✓ Region set to: $region${RESET_FORMAT}"
      break
    else
      echo "${WARNING_COLOR}⚠ Invalid region format. Use format like 'us-central1'${RESET_FORMAT}"
    fi
  done
fi

export BUCKET=$(gcloud config get-value project)

# Cloud Storage operations section
echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━ CLOUD STORAGE OPERATIONS ━━━━━━━━━━━━┓${RESET_FORMAT}"
echo

echo "${ACTION_COLOR}${BOLD_TEXT}🛠️  Creating bucket: gs://$BUCKET${RESET_FORMAT}"
gsutil mb -l $region "gs://$BUCKET"
until gsutil ls -b "gs://$BUCKET" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Waiting for bucket to become available...${RESET_FORMAT}"
done
echo "${SUCCESS_COLOR}✓ Bucket created successfully${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}⏱️  Setting 10-second retention policy${RESET_FORMAT}"
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"
echo "${SUCCESS_COLOR}✓ Retention policy applied${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}📂 Uploading dummy_transactions file${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
until gsutil ls "gs://$BUCKET/dummy_transactions" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Waiting for upload to finish...${RESET_FORMAT}"
done
gsutil ls -L "gs://$BUCKET/dummy_transactions"
echo "${SUCCESS_COLOR}✓ File uploaded successfully${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}🔒 Locking retention policy${RESET_FORMAT}"
gsutil retention lock "gs://$BUCKET/"
echo "${SUCCESS_COLOR}✓ Retention policy locked${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}⏸️  Setting temporary hold on file${RESET_FORMAT}"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"
echo "${SUCCESS_COLOR}✓ Temporary hold applied${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}🗑️  Attempting file deletion (should fail)${RESET_FORMAT}"
gsutil rm "gs://$BUCKET/dummy_transactions"
echo "${WARNING_COLOR}⚠ Expected error occurred (file protected by hold)${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}▶️  Releasing temporary hold${RESET_FORMAT}"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"
echo "${SUCCESS_COLOR}✓ Hold released successfully${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}🗑️  Deleting dummy_transactions (waiting for retention to expire)${RESET_FORMAT}"
until gsutil rm "gs://$BUCKET/dummy_transactions" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Retention period not yet expired, retrying...${RESET_FORMAT}"
done
echo "${SUCCESS_COLOR}✓ File deleted successfully${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}⚙️  Setting event-based hold as default${RESET_FORMAT}"
gsutil retention event-default set "gs://$BUCKET/"
echo "${SUCCESS_COLOR}✓ Event-based hold configured${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}📂 Uploading dummy_loan file${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"
until gsutil ls "gs://$BUCKET/dummy_loan" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Waiting for upload to finish...${RESET_FORMAT}"
done
gsutil ls -L "gs://$BUCKET/dummy_loan"
echo "${SUCCESS_COLOR}✓ File uploaded successfully${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}🔓 Releasing event-based hold${RESET_FORMAT}"
gsutil retention event release "gs://$BUCKET/dummy_loan"
gsutil ls -L "gs://$BUCKET/dummy_loan"
echo "${SUCCESS_COLOR}✓ Event-based hold released${RESET_FORMAT}"

echo
echo "${ACTION_COLOR}${BOLD_TEXT}🗑️  Deleting dummy_loan (waiting for retention to expire)${RESET_FORMAT}"
until gsutil rm "gs://$BUCKET/dummy_loan" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Retention period not yet expired, retrying...${RESET_FORMAT}"
done
echo "${SUCCESS_COLOR}✓ File deleted successfully${RESET_FORMAT}"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━ REMOVING RETENTION POLICY BUCKET ━━━━━━━━━━━━┓${RESET_FORMAT}"
echo

echo "${ACTION_COLOR}${BOLD_TEXT}🧹 Deleting empty bucket: gs://$BUCKET${RESET_FORMAT}"
until gsutil rb "gs://$BUCKET/" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Waiting for bucket to be ready for removal, retrying...${RESET_FORMAT}"
done
echo "${SUCCESS_COLOR}✓ Bucket deleted successfully${RESET_FORMAT}"

# Completion message
echo
echo "${HEADER_COLOR}${BOLD_TEXT}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET_FORMAT}"
echo "${SUCCESS_COLOR}${BOLD_TEXT}          🎉 LAB COMPLETED SUCCESSFULLY! 🎉         ${RESET_FORMAT}"
echo "${HEADER_COLOR}${BOLD_TEXT}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET_FORMAT}"
echo
echo "${TEXT_COLOR}${BOLD_TEXT}You've successfully completed these advanced operations:${RESET_FORMAT}"
echo "${TEXT_COLOR}• Created and configured a storage bucket"
echo "• Implemented retention policies and holds"
echo "• Managed object lifecycle controls"
echo "• Tested protection mechanisms"
echo "• Removed a locked-retention-policy bucket${RESET_FORMAT}"
echo
echo "${PROMPT_COLOR}${BOLD_TEXT}   Don't forget to like and subscribe!${RESET_FORMAT}"
echo
