#!/bin/bash

set -e

echo "======================================"
echo " Google Cloud Function - Task 3 Setup "
echo "======================================"

read -p "Function Name: " FUNCTION_NAME
read -p "Bucket Name: " BUCKET_NAME
read -p "Pub/Sub Topic: " TOPIC_NAME
read -p "Region: " REGION

mkdir -p hustlers
cd hustlers

cat > index.js <<EOF
/* globals exports, require */
//jshint strict:false
//jshint esversion:6
"use strict";
const crc32 = require("fast-crc32c");
const { Storage } = require("@google-cloud/storage");
const gcs = new Storage();
const { PubSub } = require("@google-cloud/pubsub");
const imagemagick = require("imagemagick-stream");

exports.thumbnail = (event, context) => {
  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = gcs.bucket(bucketName);
  const topicName = "TOPIC_PLACEHOLDER";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") == -1) {
    var filename_split = fileName.split(".");
    var filename_ext = filename_split[filename_split.length-1];
    var filename_without_ext = fileName.substring(0,fileName.length-filename_ext.length);

    if (filename_ext.toLowerCase()=="png" || filename_ext.toLowerCase()=="jpg") {
      const gcsObject=bucket.file(fileName);
      let newFilename=filename_without_ext+size+"_thumbnail."+filename_ext;
      let gcsNewObject=bucket.file(newFilename);

      let srcStream=gcsObject.createReadStream();
      let dstStream=gcsNewObject.createWriteStream();
      let resize=imagemagick().resize(size).quality(90);

      srcStream.pipe(resize).pipe(dstStream);

      return new Promise((resolve,reject)=>{
        dstStream
          .on("error",(err)=>reject(err))
          .on("finish",()=>{
            gcsNewObject.setMetadata({contentType:"image/"+filename_ext.toLowerCase()});
            pubsub.topic(topicName).publisher().publish(Buffer.from(newFilename));
            resolve();
          });
      });
    }
  }
};
EOF

sed -i "16c\  const topicName = '$TOPIC_NAME';" index.js

cat > package.json <<EOF
{
  "name":"thumbnails",
  "version":"1.0.0",
  "dependencies":{
    "@google-cloud/pubsub":"^2.0.0",
    "@google-cloud/storage":"^5.0.0",
    "fast-crc32c":"1.0.4",
    "imagemagick-stream":"4.1.1"
  }
}
EOF

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
SERVICE_ACCOUNT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"

echo "Granting IAM roles..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
 --member="serviceAccount:$SERVICE_ACCOUNT" \
 --role="roles/artifactregistry.reader" --quiet

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
 --member="serviceAccount:$SERVICE_ACCOUNT" \
 --role="roles/pubsub.publisher" --quiet

sleep 30

deploy_function() {
gcloud functions deploy "$FUNCTION_NAME" \
 --gen2 \
 --runtime=nodejs22 \
 --region="$REGION" \
 --source=. \
 --entry-point=thumbnail \
 --trigger-bucket="$BUCKET_NAME" \
 --quiet
}

echo "Deploying Function..."
for i in 1 2 3; do
    if deploy_function; then
        echo "Deployment Successful"
        break
    fi
    if [ "$i" = "3" ]; then
        echo "Deployment failed after 3 attempts"
        exit 1
    fi
    echo "Retrying in 60 seconds..."
    sleep 60
done

wget -q https://storage.googleapis.com/cloud-training/arc101/travel.jpg

echo "Uploading test image..."
for i in 1 2 3; do
    if gcloud storage cp travel.jpg gs://$BUCKET_NAME; then
        echo "Upload Successful"
        break
    fi
    if [ "$i" = "3" ]; then
        echo "Upload failed after 3 attempts"
        exit 1
    fi
    echo "Retrying upload in 10 seconds..."
    sleep 10
done

echo "======================================"
echo " Task 3 Completed Successfully"
echo "======================================"
