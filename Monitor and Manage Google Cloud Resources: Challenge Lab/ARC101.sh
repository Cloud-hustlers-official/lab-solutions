#!/bin/bash
# Define color variables with better contrast
BLACK=$(tput setaf 0)

GREEN=$(tput setaf 10)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

#----------------------------------------------------start--------------------------------------------------#

echo "${BG_BLUE}${WHITE}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   🚀 Welcome to Google Cloud Functions Lab                 ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "${RESET}"

# Prompt user for inputs
echo ""
echo "${BOLD}${WHITE}Please provide the following configuration values:${RESET}"
read -p "${BOLD}${WHITE}Enter BUCKET_NAME: ${RESET}" BUCKET_NAME
read -p "${BOLD}${WHITE}Enter TOPIC_NAME: ${RESET}" TOPIC_NAME
read -p "${BOLD}${WHITE}Enter FUNCTION_NAME: ${RESET}" FUNCTION_NAME
read -p "${BOLD}${WHITE}Enter REGION: ${RESET}" REGION
read -p "${BOLD}${WHITE}Enter SECOND_USER: ${RESET}" SECOND_USER
read -p "${BOLD}${WHITE}Enter your email for alert notifications: ${RESET}" ALERT_EMAIL

section() {
    echo ""
    echo "${BG_BLUE}${WHITE}${BOLD}»»» $1 «««${RESET}"
    echo ""
}

# Task 1: Initial Setup
section "TASK 1: INITIAL SETUP"
echo "${BOLD}${CYAN}✓${RESET} Setting compute region to: ${BOLD}${WHITE}$REGION${RESET}"
gcloud config set compute/region $REGION

echo "${BOLD}${CYAN}✓${RESET} Enabling required services..."
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

# Task 2: Storage Configuration
section "TASK 2: STORAGE CONFIGURATION"
echo "${BOLD}${CYAN}✓${RESET} Creating storage bucket: ${BOLD}${WHITE}$BUCKET_NAME${RESET}"
for i in {1..3}; do
    if gsutil mb -l $REGION gs://$BUCKET_NAME; then
        break
    elif [ $i -eq 3 ]; then
        echo "${BOLD}${RED}✗ Error creating bucket after 3 attempts${RESET}"
        exit 1
    else
        echo "${BOLD}${YELLOW}⚠ Bucket creation failed, retrying in 10 seconds...${RESET}"
        sleep 10
    fi
done

echo "${BOLD}${CYAN}✓${RESET} Granting storage access to user..."
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$SECOND_USER \
  --role=roles/storage.objectViewer || {
    echo "${BOLD}${RED}✗ Error granting storage access${RESET}"
    exit 1
}

# Task 3: Pub/Sub Configuration
section "TASK 3: PUB/SUB CONFIGURATION"
echo "${BOLD}${CYAN}✓${RESET} Creating Pub/Sub topic: ${BOLD}${WHITE}$TOPIC_NAME${RESET}"
gcloud pubsub topics create $TOPIC_NAME || {
    echo "${BOLD}${RED}✗ Error creating Pub/Sub topic${RESET}"
    exit 1
}

# Function Setup
section "FUNCTION SETUP"
echo "${BOLD}${CYAN}✓${RESET} Creating function directory..."
mkdir -p hustlers && cd hustlers || {
    echo "${BOLD}${RED}✗ Error creating directory${RESET}"
    exit 1
}

echo "${BOLD}${CYAN}✓${RESET} Creating function files..."
cat > index.js <<'EOF_END'
/* globals exports, require */
//jshint strict: false
//jshint esversion: 6
"use strict";
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

exports.thumbnail = (event, context) => {
  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "REPLACE_WITH_YOUR_TOPIC ID";
  const pubsub = new PubSub();
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publisher()
                .publish(Buffer.from(newFilename))
                .then(messageId => {
                  console.log(`Message ${messageId} published.`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
};
EOF_END

sed -i "16c\  const topicName = '$TOPIC_NAME';" index.js || {
    echo "${BOLD}${RED}✗ Error updating topic name in index.js${RESET}"
    exit 1
}

cat > package.json <<'EOF_END'
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
      "start": "node index.js"
    },
    "dependencies": {
      "@google-cloud/pubsub": "^2.0.0",
      "@google-cloud/storage": "^5.0.0",
      "fast-crc32c": "1.0.4",
      "imagemagick-stream": "4.1.1"
    },
    "devDependencies": {},
    "engines": {
      "node": ">=4.3.2"
    }
}
EOF_END

# IAM Configuration
section "IAM CONFIGURATION"
echo "${BOLD}${CYAN}✓${RESET} Configuring service account permissions..."
export PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/artifactregistry.reader || {
    echo "${BOLD}${RED}✗ Error configuring Artifact Registry access${RESET}"
    exit 1
}

sleep 30

SERVICE_ACCOUNT="service-$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')@gs-project-accounts.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/pubsub.publisher" || {
    echo "${BOLD}${RED}✗ Error configuring Pub/Sub permissions${RESET}"
    exit 1
}

# Function Deployment
section "FUNCTION DEPLOYMENT"
echo "${BOLD}${CYAN}✓${RESET} Deploying Cloud Function..."
deploy_function() {
    gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=nodejs22 \
    --region=$REGION \
    --source=. \
    --entry-point=thumbnail \
    --trigger-bucket=$BUCKET_NAME \
    --quiet
}

for i in {1..3}; do
    if deploy_function; then
        break
    elif [ $i -eq 3 ]; then
        echo "${BOLD}${RED}✗ Failed to deploy function after 3 attempts${RESET}"
        exit 1
    else
        echo "${BOLD}${YELLOW}⚠ Deployment failed, retrying in 60 seconds...${RESET}"
        sleep 60
    fi
done

# Testing
section "TESTING FUNCTION"
echo "${BOLD}${CYAN}✓${RESET} Downloading test image..."
wget -q https://storage.googleapis.com/cloud-training/arc101/travel.jpg || {
    echo "${BOLD}${RED}✗ Error downloading test image${RESET}"
    exit 1
}

echo "${BOLD}${CYAN}✓${RESET} Uploading test image to bucket..."
for i in {1..3}; do
    if gsutil cp travel.jpg gs://$BUCKET_NAME; then
        break
    elif [ $i -eq 3 ]; then
        echo "${BOLD}${RED}✗ Error uploading test image after 3 attempts${RESET}"
        exit 1
    else
        echo "${BOLD}${YELLOW}⚠ Upload failed, retrying in 10 seconds...${RESET}"
        sleep 10
    fi
done

# Task 4: Alerting Policy - Fixed version
section "TASK 4: ALERTING POLICY"
echo "${BOLD}${CYAN}✓${RESET} Creating notification channel..."
CHANNEL_NAME=$(gcloud alpha monitoring channels create \
    --display-name="Email alerts" \
    --type=email \
    --channel-labels=email_address=$ALERT_EMAIL \
    --format="value(name)") || {
    echo "${BOLD}${RED}✗ Error creating notification channel${RESET}"
    exit 1
}

echo "${BOLD}${CYAN}✓${RESET} Creating alerting policy for Cloud Function instances..."

cat > active-instances-policy.json <<EOF_END
{
  "displayName": "Active Cloud Function Instances",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "Cloud Function Active Instances",
      "conditionThreshold": {
        "filter": "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/active_instances\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MAX"
          }
        ],
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0,
        "duration": "60s"
      }
    }
  ],
  "notificationChannels": ["$CHANNEL_NAME"]
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file="active-instances-policy.json" || {
    echo "${BOLD}${RED}✗ Error creating alerting policy${RESET}"
    exit 1
}


echo ""
echo "${BG_BLUE}${WHITE}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   🎉 ${CYAN}FOLLOW THE VIDEO NOW ${WHITE}                          ║"
echo "║                                                            ║"
echo "║   ${CYAN}Created Resources:${WHITE}                                    ║"
echo "║   - Storage Bucket: ${BOLD}${BUCKET_NAME}${RESET}${WHITE}                         ║"
echo "║   - Pub/Sub Topic: ${BOLD}${TOPIC_NAME}${RESET}${WHITE}                           ║"
echo "║   - Cloud Function: ${BOLD}${FUNCTION_NAME}${RESET}${WHITE}                       ║"
echo "║   - Alerting Policy: Active Cloud Function Instances       ║"
echo "║   - Notification Channel: ${BOLD}${ALERT_EMAIL}${RESET}${WHITE}                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
