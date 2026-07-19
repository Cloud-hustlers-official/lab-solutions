#!/bin/bash
# Define color variables

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

# Welcome message
echo "${BG_CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_CYAN}${BOLD}║     WELCOME TO CLOUD HUSTLERS TUTORIAL                       ║${RESET}"
echo "${BG_CYAN}${BOLD}║     PLEASE SUBSCRIBE TO THE CHANNEL FOR MORE UPDATES        ║${RESET}"
echo "${BG_CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "${YELLOW}${BOLD}YouTube Channel: ${CYAN}https://www.youtube.com/@CloudHustlers/videos${RESET}"
echo "${MAGENTA}${BOLD}Don't forget to LIKE, SHARE, and SUBSCRIBE!${RESET}"
echo ""
echo "${BG_BLUE}${BOLD}Starting Execution${RESET}"
echo ""

# Prompt for and export required environment variables
echo "${YELLOW}${BOLD}Please enter the following required environment variables:${RESET}"
read -p "Enter USER_2 (e.g., student3517@qwiklabs.com): " USER_2
export USER_2
read -p "Enter ZONE (e.g., us-central1-a): " ZONE
export ZONE
read -p "Enter TOPIC (e.g., thumbnail-topic): " TOPIC
export TOPIC
read -p "Enter FUNCTION (e.g., thumbnail-generator): " FUNCTION
export FUNCTION

echo ""
echo "${GREEN}${BOLD}✓ Environment variables set successfully:${RESET}"
echo "  → USER_2 = $USER_2"
echo "  → ZONE = $ZONE"
echo "  → TOPIC = $TOPIC"
echo "  → FUNCTION = $FUNCTION"
echo ""

export REGION="${ZONE%-*}"

echo "${CYAN}${BOLD}Step 1: Enabling required Google Cloud Services...${RESET}"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

sleep 30

PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')

echo "${CYAN}${BOLD}Step 2: Configuring IAM permissions...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/eventarc.eventReceiver

sleep 20

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $DEVSHELL_PROJECT_ID)"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role='roles/pubsub.publisher'

sleep 20

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
    --role=roles/iam.serviceAccountTokenCreator

sleep 20

# Additional permission for Cloud Function to publish to Pub/Sub
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role='roles/pubsub.publisher'

sleep 20

echo "${CYAN}${BOLD}Step 3: Creating Cloud Storage bucket...${RESET}"
gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID-bucket

echo "${CYAN}${BOLD}Step 4: Creating Pub/Sub topic...${RESET}"
gcloud pubsub topics create $TOPIC

mkdir lol
cd lol

# Create the corrected index.js file
echo "${CYAN}${BOLD}Step 5: Creating Cloud Function code...${RESET}"
cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('$FUNCTION_NAME', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${JSON.stringify(event)}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = process.env.TOPIC_NAME || "$TOPIC_NAME";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    const lastDotIndex = fileName.lastIndexOf('.');
    const filename_ext = fileName.substring(lastDotIndex + 1).toLowerCase();
    const filename_without_ext = fileName.substring(0, lastDotIndex);

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      const newFilename = `${filename_without_ext}_${size}_thumbnail.${filename_ext}`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: {
            contentType: `image/${filename_ext}`,
          },
        });

        console.log(`Success: ${fileName} → ${newFilename}`);

        const messageId = await pubsub
          .topic(topicName)
          .publishMessage({ 
            data: Buffer.from(newFilename),
            attributes: {
              bucket: bucketName,
              originalFile: fileName,
              thumbnail: newFilename
            }
          });
        
        console.log(`Message ${messageId} published to ${topicName}`);
      } catch (err) {
        console.error(`Error: ${err}`);
      }
    } else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  } else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
EOF_END

# Replace placeholders in index.js
sed -i "s/\$FUNCTION_NAME/$FUNCTION/g" index.js
sed -i "s/\$TOPIC_NAME/$TOPIC/g" index.js

# Create package.json
cat > package.json <<EOF_END
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
      "start": "node index.js"
    },
    "dependencies": {
      "@google-cloud/functions-framework": "^3.0.0",
      "@google-cloud/pubsub": "^2.0.0",
      "@google-cloud/storage": "^5.0.0",
      "sharp": "^0.32.0"
    },
    "devDependencies": {},
    "engines": {
      "node": ">=4.3.2"
    }
  }
EOF_END

PROJECT_ID=$(gcloud config get-value project)

echo "${CYAN}${BOLD}Step 6: Deploying Cloud Function...${RESET}"
# Deploy the function with environment variable
deploy_function() {
    gcloud functions deploy $FUNCTION \
    --gen2 \
    --runtime nodejs20 \
    --trigger-resource $DEVSHELL_PROJECT_ID-bucket \
    --trigger-event google.storage.object.finalize \
    --entry-point $FUNCTION \
    --region=$REGION \
    --source . \
    --set-env-vars TOPIC_NAME=$TOPIC \
    --quiet
}

# Variables
SERVICE_NAME="$FUNCTION"

# Loop until the Cloud Run service is created
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "${GREEN}${BOLD}✓ Cloud Function deployed successfully!${RESET}"
    break
  else
    echo "${YELLOW}Waiting for Cloud Run service to be created...${RESET}"
    sleep 20
  fi
done

echo "${CYAN}${BOLD}Step 7: Testing the thumbnail generation...${RESET}"
# Download and upload test image
curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg

gsutil cp map.jpg gs://$DEVSHELL_PROJECT_ID-bucket/map.jpg

# Wait for processing
echo "${YELLOW}Waiting for thumbnail generation (30 seconds)...${RESET}"
sleep 30

# Verify thumbnail was created
echo "${CYAN}${BOLD}Step 8: Verifying thumbnail...${RESET}"
if gsutil ls gs://$DEVSHELL_PROJECT_ID-bucket/ | grep -q "64x64_thumbnail"; then
    echo "${GREEN}${BOLD}✓ Thumbnail generated successfully!${RESET}"
else
    echo "${RED}${BOLD}✗ Thumbnail not found. Check logs for errors.${RESET}"
fi

# Remove viewer permission
echo "${CYAN}${BOLD}Step 9: Cleaning up permissions...${RESET}"
gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
--member=user:$USER_2 \
--role=roles/viewer

echo ""
echo "${BG_GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_GREEN}${BOLD}║     CONGRATULATIONS! YOU HAVE COMPLETED THE LAB           ║${RESET}"
echo "${BG_GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "${BG_MAGENTA}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo "${BG_MAGENTA}${BOLD}║     THANK YOU FOR FOLLOWING CLOUD HUSTLERS TUTORIAL      ║${RESET}"
echo "${BG_MAGENTA}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "${CYAN}${BOLD}📺 Please Subscribe to Cloud Hustlers YouTube Channel:${RESET}"
echo "${YELLOW}🔗 https://www.youtube.com/@CloudHustlers/videos${RESET}"
echo ""
echo "${MAGENTA}${BOLD}👍 Like | Share | Subscribe | Press the Bell Icon${RESET}"
echo "${MAGENTA}${BOLD}🔔 Stay updated with the latest cloud computing tutorials!${RESET}"
echo ""
echo "${GREEN}${BOLD}🎯 Follow for more:${RESET}"
echo "  • Google Cloud Labs"
echo "  • AWS Tutorials"  
echo "  • Azure Solutions"
echo "  • DevOps Best Practices"
echo "  • Kubernetes Training"
echo ""
echo "${BG_CYAN}${BOLD}          KEEP LEARNING & KEEP GROWING WITH CLOUD HUSTLERS      ${RESET}"
echo ""

#-----------------------------------------------------end----------------------------------------------------------#
