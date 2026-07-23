#!/bin/bash

# ================== ASK FOR VALUES AT RUNTIME ==================
read -p "Enter your Cloud Storage Function Name (Task 2, e.g. eventStorage/cs-monitor): " FUNCTION_NAME
read -p "Enter your Bucket Name (usually your Project ID): " BUCKET_NAME
read -p "Enter your HTTP Function Name (Task 3, e.g. helloWorld/http-responder): " HTTP_FUNCTION
read -p "Enter your Region (e.g. us-west1): " REGION

export FUNCTION_NAME
export BUCKET_NAME
export HTTP_FUNCTION
export REGION
export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
# =================================================================

echo ""
echo "===== Enabling required APIs ====="
gcloud services enable \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  artifactregistry.googleapis.com

echo "Waiting for APIs to activate..."
sleep 30

echo ""
echo "===== Granting IAM permission to Cloud Storage service account ====="
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

echo ""
echo "===== Creating bucket (skips if it already exists) ====="
gsutil mb -l $REGION gs://$BUCKET_NAME 2>/dev/null || echo "Bucket already exists, continuing..."

# ================== TASK 2: Cloud Storage Function ==================
echo ""
echo "===== TASK 2: Creating Cloud Storage function source files ====="
mkdir -p ~/$FUNCTION_NAME && cd ~/$FUNCTION_NAME

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "Deploying Cloud Storage function..."
deploy_storage_function() {
  gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime nodejs24 \
    --entry-point $FUNCTION_NAME \
    --source . \
    --region $REGION \
    --trigger-bucket $BUCKET_NAME \
    --trigger-location $REGION \
    --max-instances 2 \
    --quiet
}

while true; do
  deploy_storage_function
  if gcloud run services describe $FUNCTION_NAME --region $REGION &> /dev/null; then
    echo "Cloud Storage function deployed successfully!"
    break
  else
    echo "Waiting for deployment to complete, retrying in 10s..."
    sleep 10
  fi
done

echo "Testing Cloud Storage function by uploading a file..."
echo "hello world" > test.txt
gsutil cp test.txt gs://$BUCKET_NAME/

echo "Waiting for event to trigger..."
sleep 20

echo "Fetching Task 2 logs..."
gcloud functions logs read $FUNCTION_NAME --region $REGION --gen2 --limit 20

# ================== TASK 3: HTTP Function ==================
echo ""
echo "===== TASK 3: Creating HTTP function source files ====="
cd ~
mkdir -p ~/$HTTP_FUNCTION && cd ~/$HTTP_FUNCTION

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('HTTP function (2nd gen) has been called!');
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

echo "Deploying HTTP function..."
deploy_http_function() {
  gcloud functions deploy $HTTP_FUNCTION \
    --gen2 \
    --runtime nodejs24 \
    --entry-point $HTTP_FUNCTION \
    --source . \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated \
    --min-instances 1 \
    --max-instances 2 \
    --quiet
}

while true; do
  deploy_http_function
  if gcloud run services describe $HTTP_FUNCTION --region $REGION &> /dev/null; then
    echo "HTTP function deployed successfully!"
    break
  else
    echo "Waiting for deployment to complete, retrying in 10s..."
    sleep 10
  fi
done

echo "Fetching HTTP function URL..."
URL=$(gcloud functions describe $HTTP_FUNCTION --region $REGION --gen2 --format="value(serviceConfig.uri)")
echo "HTTP Function URL: $URL"

echo "Testing HTTP function..."
curl $URL

# ================== FINAL VERIFICATION ==================
echo ""
echo "===== Final check: listing all Cloud Functions ====="
gcloud functions list --regions=$REGION

echo ""
echo "===== Task 2 and Task 3 complete! Now go click 'Check my progress' for both tasks in the lab. ====="
