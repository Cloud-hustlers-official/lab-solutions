#!/bin/bash

HEADER_COLOR=$'\033[38;5;54m'
PROMPT_COLOR=$'\033[38;5;178m'
ACTION_COLOR=$'\033[38;5;44m'
SUCCESS_COLOR=$'\033[38;5;46m'
WARNING_COLOR=$'\033[38;5;196m'
TEXT_COLOR=$'\033[38;5;255m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

pause_for_check() {
  echo
  echo "${PROMPT_COLOR}${BOLD_TEXT}👉 Ab jaake 'Check my progress' click kar Task: $1 ke liye.${RESET_FORMAT}"
  read -p "${PROMPT_COLOR}${BOLD_TEXT}   Progress check karne ke baad, aage badhne ke liye ENTER daba... ${RESET_FORMAT}"
}

clear
echo
echo "${TEXT_COLOR}Advanced Cloud Storage lab: retention policies, holds, lifecycle mgmt${RESET_FORMAT}"
echo

if [ -z "$region" ]; then
  while true; do
    read -p "${PROMPT_COLOR}${BOLD_TEXT}🌍 GCP region (e.g., us-west1): ${RESET_FORMAT}" region
    if [[ -z "$region" ]]; then
      echo "${WARNING_COLOR}⚠ Region empty, try again.${RESET_FORMAT}"
    elif [[ $region =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
      export region
      echo "${SUCCESS_COLOR}✓ Region: $region${RESET_FORMAT}"
      break
    else
      echo "${WARNING_COLOR}⚠ Invalid format, use like 'us-west1'${RESET_FORMAT}"
    fi
  done
fi

export BUCKET=$(gcloud config get-value project)

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 1: Create Bucket ===${RESET_FORMAT}"
gsutil mb -l "$region" "gs://$BUCKET"
until gsutil ls -b "gs://$BUCKET" &>/dev/null; do sleep 2; done
echo "${SUCCESS_COLOR}✓ Bucket created${RESET_FORMAT}"
pause_for_check "1. Create a storage bucket"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 2: Retention Policy ===${RESET_FORMAT}"
gsutil retention set 10s "gs://$BUCKET"
gsutil retention get "gs://$BUCKET"
gsutil cp gs://spls/gsp297/dummy_transactions "gs://$BUCKET/"
until gsutil ls "gs://$BUCKET/dummy_transactions" &>/dev/null; do sleep 2; done
gsutil ls -L "gs://$BUCKET/dummy_transactions"
echo "${SUCCESS_COLOR}✓ Retention policy set + object uploaded${RESET_FORMAT}"
pause_for_check "2. Set up Retention Policy"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 3: Lock Retention Policy ===${RESET_FORMAT}"
yes | gsutil retention lock "gs://$BUCKET/"
echo "${SUCCESS_COLOR}✓ Retention policy locked${RESET_FORMAT}"
pause_for_check "3. Lock the Retention Policy"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 4: Temporary Hold ===${RESET_FORMAT}"
gsutil retention temp set "gs://$BUCKET/dummy_transactions"
echo "${ACTION_COLOR}Attempting delete (should FAIL):${RESET_FORMAT}"
gsutil rm "gs://$BUCKET/dummy_transactions"
gsutil retention temp release "gs://$BUCKET/dummy_transactions"
until gsutil rm "gs://$BUCKET/dummy_transactions" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Retention not expired yet, retrying...${RESET_FORMAT}"
  sleep 2
done
echo "${SUCCESS_COLOR}✓ Temp hold flow done, file deleted${RESET_FORMAT}"
pause_for_check "4. Set up Temporary Hold"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 5a: Enable default Event-Based Hold on bucket ===${RESET_FORMAT}"
gsutil retention event-default set "gs://$BUCKET/"
gsutil retention event-default get "gs://$BUCKET/"
echo "${SUCCESS_COLOR}✓ Default event-based hold enabled on bucket${RESET_FORMAT}"
echo "${WARNING_COLOR}${BOLD_TEXT}⚠ ABHI koi aur command mat chalao — seedha 'Check my progress' daba is state pe.${RESET_FORMAT}"
pause_for_check "5. Create Event-based holds (default hold enabled check)"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 5b: Upload loan + release hold ===${RESET_FORMAT}"
gsutil cp gs://spls/gsp297/dummy_loan "gs://$BUCKET/"
until gsutil ls "gs://$BUCKET/dummy_loan" &>/dev/null; do sleep 2; done
gsutil ls -L "gs://$BUCKET/dummy_loan"
gsutil retention event release "gs://$BUCKET/dummy_loan"
gsutil ls -L "gs://$BUCKET/dummy_loan"
echo "${SUCCESS_COLOR}✓ Event-based hold released on dummy_loan${RESET_FORMAT}"
pause_for_check "5. Create Event-based holds (release check)"

echo
echo "${HEADER_COLOR}${BOLD_TEXT}=== TASK 6: Remove Bucket ===${RESET_FORMAT}"
until gsutil rm "gs://$BUCKET/dummy_loan" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Retention not expired yet, retrying...${RESET_FORMAT}"
  sleep 2
done
until gsutil rb "gs://$BUCKET/" &>/dev/null; do
  echo "${TEXT_COLOR}⏳ Waiting to remove bucket...${RESET_FORMAT}"
  sleep 2
done
echo "${SUCCESS_COLOR}✓ Bucket deleted${RESET_FORMAT}"
pause_for_check "6. (final check)"

echo
echo "${SUCCESS_COLOR}${BOLD_TEXT}🎉 Sab task complete! Ab progress panel mein sab 100/100 hona chahiye.${RESET_FORMAT}"
