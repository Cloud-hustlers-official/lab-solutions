#!/bin/bash

BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RESET=$'\033[0m'

# Text Colors
BLACK=$'\033[0;90m'
RED=$'\033[0;91m'
GREEN=$'\033[0;92m'
YELLOW=$'\033[0;93m'
BLUE=$'\033[0;94m'
MAGENTA=$'\033[0;95m'
CYAN=$'\033[0;96m'
WHITE=$'\033[0;97m'

# Background Colors
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'

# ======================
#  SCRIPT HEADER
# ======================
clear
echo "${BLUE}${BOLD}============================================${RESET}"
echo "${BLUE}${BOLD}        WELCOME TO CLOUD HUSTLERS TUTORIALS        ${RESET}"
echo "${BLUE}${BOLD}============================================${RESET}"
echo ""
echo "${CYAN}${BOLD}⚡ Expertly crafted by Cloud Hustlers${RESET}"
echo "${YELLOW}${BOLD}📺 YouTube: ${UNDERLINE}http://www.youtube.com/@CloudHustlers${RESET}"
echo ""

# ======================
#  ENABLE REQUIRED SERVICES
# ======================
echo "${MAGENTA}${BOLD}🔧 STEP 0: Enabling Required Services...${RESET}"
gcloud services enable cloudapis.googleapis.com || {
    echo "${RED}${BOLD}❌ Error: Failed to enable Cloud APIs${RESET}"
    exit 1
}
gcloud services enable vision.googleapis.com || {
    echo "${RED}${BOLD}❌ Error: Failed to enable Vision API${RESET}"
    exit 1
}
echo "${GREEN}${BOLD}✔ Success: Services enabled${RESET}"
echo ""

# ======================
#  API KEY CREATION WITH VISION API RESTRICTION
# ======================
echo "${MAGENTA}${BOLD}🔑 STEP 1: Creating API Key restricted to Vision API...${RESET}"

# Check if key already exists
EXISTING_KEY=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-lab-key")

if [ -n "$EXISTING_KEY" ]; then
    echo "${YELLOW}${BOLD}⚠️ API key already exists. Deleting old key...${RESET}"
    gcloud alpha services api-keys delete $EXISTING_KEY --quiet || {
        echo "${RED}${BOLD}❌ Error: Failed to delete existing key${RESET}"
        exit 1
    }
    # Wait a moment for deletion to propagate
    sleep 5
fi

# Create new API key with Vision API restriction
gcloud alpha services api-keys create \
    --display-name="vision-lab-key" \
    --api-target="service=vision.googleapis.com" \
    --quiet || {
    echo "${RED}${BOLD}❌ Error: Failed to create API key${RESET}"
    exit 1
}

# Get the key name and value
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=vision-lab-key")
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
export PROJECT_ID=$(gcloud config get-value project)

echo "${GREEN}${BOLD}✔ Success: API Key created and restricted to Vision API only${RESET}"
echo "${WHITE}Key Name: ${YELLOW}$KEY_NAME${RESET}"
echo "${WHITE}Key Value: ${YELLOW}$API_KEY${RESET}"
echo "${WHITE}Project ID: ${YELLOW}$PROJECT_ID${RESET}"
echo ""

# ======================
#  CREATE BUCKET AND UPLOAD IMAGE
# ======================
echo "${MAGENTA}${BOLD}📦 STEP 2: Setting up Cloud Storage...${RESET}"

# Check if bucket exists, create if not
if ! gsutil ls gs://$PROJECT_ID-bucket &>/dev/null; then
    echo "${WHITE}Creating bucket...${RESET}"
    gsutil mb gs://$PROJECT_ID-bucket || {
        echo "${RED}${BOLD}❌ Error: Failed to create bucket${RESET}"
        exit 1
    }
fi

# Check if image exists in bucket, if not download it
if ! gsutil ls gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg &>/dev/null; then
    echo "${WHITE}Image not found in bucket. Please ensure you have uploaded the image.${RESET}"
    echo "${YELLOW}To upload image, use: gsutil cp /path/to/image.jpg gs://$PROJECT_ID-bucket/${RESET}"
    echo "${YELLOW}Or download sample image:${RESET}"
    echo "${YELLOW}wget -O sample.jpg https://storage.googleapis.com/cloud-samples-data/vision/using_curl/shanghai.jpg${RESET}"
    echo "${YELLOW}gsutil cp sample.jpg gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg${RESET}"
    exit 1
fi

# Set image permissions
echo "${WHITE}Setting image to public readable...${RESET}"
gsutil acl ch -u allUsers:R gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg || {
    echo "${RED}${BOLD}❌ Error: Failed to set image permissions${RESET}"
    exit 1
}
echo "${GREEN}${BOLD}✔ Success: Image made publicly readable${RESET}"
echo ""

# ======================
#  TEXT DETECTION
# ======================
echo "${MAGENTA}${BOLD}📝 STEP 3: Performing TEXT_DETECTION...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "TEXT_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o text-response.json

# Check if response contains error
if grep -q "error" text-response.json; then
    echo "${RED}${BOLD}❌ Error: Text detection failed${RESET}"
    cat text-response.json | jq '.'
    exit 1
fi

gsutil cp text-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}${BOLD}❌ Error: Failed to upload text response${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}✔ Success: Text detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/text-response.json${RESET}"
echo ""

# ======================
#  LANDMARK DETECTION
# ======================
echo "${MAGENTA}${BOLD}🏛️ STEP 4: Performing LANDMARK_DETECTION...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LANDMARK_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o landmark-response.json

# Check if response contains error
if grep -q "error" landmark-response.json; then
    echo "${RED}${BOLD}❌ Error: Landmark detection failed${RESET}"
    cat landmark-response.json | jq '.'
    exit 1
fi

gsutil cp landmark-response.json gs://$PROJECT_ID-bucket/ || {
    echo "${RED}${BOLD}❌ Error: Failed to upload landmark response${RESET}"
    exit 1
}

echo "${GREEN}${BOLD}✔ Success: Landmark detection completed${RESET}"
echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/landmark-response.json${RESET}"
echo ""

# ======================
#  LABEL DETECTION (BONUS)
# ======================
echo "${MAGENTA}${BOLD}🏷️ STEP 5: Performing LABEL_DETECTION (Bonus)...${RESET}"
cat > request.json <<EOF
{
  "requests": [
      {
        "image": {
          "source": {
              "gcsImageUri": "gs://$PROJECT_ID-bucket/manif-des-sans-papiers.jpg"
          }
        },
        "features": [
          {
            "type": "LABEL_DETECTION",
            "maxResults": 10
          }
        ]
      }
  ]
}
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}" -o label-response.json

if grep -q "error" label-response.json; then
    echo "${RED}${BOLD}❌ Error: Label detection failed${RESET}"
else
    gsutil cp label-response.json gs://$PROJECT_ID-bucket/ || {
        echo "${RED}${BOLD}❌ Error: Failed to upload label response${RESET}"
        exit 1
    }
    echo "${GREEN}${BOLD}✔ Success: Label detection completed${RESET}"
    echo "${WHITE}Results saved to: ${YELLOW}gs://$PROJECT_ID-bucket/label-response.json${RESET}"
fi
echo ""

# ======================
#  DISPLAY RESULTS
# ======================
echo "${MAGENTA}${BOLD}📊 STEP 6: Displaying Results...${RESET}"

# Display text detection results
if [ -f "text-response.json" ]; then
    echo "${CYAN}${BOLD}📝 Text Detection Results:${RESET}"
    cat text-response.json | jq '.responses[].textAnnotations[0].description' 2>/dev/null || echo "No text found"
    echo ""
fi

# Display landmark detection results
if [ -f "landmark-response.json" ]; then
    echo "${CYAN}${BOLD}🏛️ Landmark Detection Results:${RESET}"
    cat landmark-response.json | jq '.responses[].landmarkAnnotations[].description' 2>/dev/null || echo "No landmarks found"
    echo ""
fi

# Display label detection results
if [ -f "label-response.json" ]; then
    echo "${CYAN}${BOLD}🏷️ Label Detection Results:${RESET}"
    cat label-response.json | jq '.responses[].labelAnnotations[].description' 2>/dev/null || echo "No labels found"
    echo ""
fi

# ======================
#  COMPLETION MESSAGE
# ======================
echo "${BG_GREEN}${BLACK}${BOLD}============================================${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}        LAB EXECUTED SUCCESSFULLY!         ${RESET}"
echo "${BG_GREEN}${BLACK}${BOLD}============================================${RESET}"
echo ""
echo "${WHITE}${BOLD}🔍 Access your detection results:${RESET}"
echo "${YELLOW}https://console.cloud.google.com/storage/browser/$PROJECT_ID-bucket${RESET}"
echo ""
echo "${WHITE}${BOLD}🔑 API Key restricted to:${RESET}"
echo "${YELLOW}Cloud Vision API only${RESET}"
echo ""
echo "${CYAN}${BOLD}💡 For more Google Cloud labs and tutorials:${RESET}"
echo "${YELLOW}${BOLD}👉 ${UNDERLINE}https://www.youtube.com/@CloudHustlers/videos${RESET}"
echo "${GREEN}${BOLD}🔔 Don't forget to subscribe!${RESET}"
echo ""

# ======================
#  CLEANUP (OPTIONAL)
# ======================
echo "${YELLOW}${BOLD}🧹 Would you like to cleanup resources? (y/N)${RESET}"
read -r CLEANUP

if [[ $CLEANUP =~ ^[Yy]$ ]]; then
    echo "${WHITE}Deleting API Key...${RESET}"
    gcloud alpha services api-keys delete $KEY_NAME --quiet
    
    echo "${WHITE}Deleting bucket contents...${RESET}"
    gsutil -m rm -r gs://$PROJECT_ID-bucket/*
    
    echo "${GREEN}${BOLD}✔ Cleanup completed${RESET}"
fi
