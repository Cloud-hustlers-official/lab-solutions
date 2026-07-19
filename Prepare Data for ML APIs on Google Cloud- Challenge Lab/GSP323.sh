#!/bin/bash

# ANSI Color Codes
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN_TEXT}[%c]${RESET_FORMAT} ${YELLOW_TEXT}Please Subscribe: https://www.youtube.com/@CloudHustlers{RESET_FORMAT}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "                                                                        \r"
}

clear
# Welcome Animation
echo -e "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}      WELCOME TO CLOUD HUSTLER'S LAB EXECUTION  ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}📺 Channel: https://www.youtube.com/@CloudHustlers${RESET_FORMAT}\n"

export PROJECT_ID=$(gcloud config get-value project)
read -p "Enter REGION: " REGION
read -p "Enter BigQuery DATASET: " DATASET
read -p "Enter BigQuery TABLE: " TABLE
read -p "Enter Task 3 Output URI: " TASK3_OUTPUT
read -p "Enter Task 4 Output URI: " TASK4_OUTPUT

export BUCKET="${PROJECT_ID}-marking"
export TEMP_LOCATION="gs://${BUCKET}/temp"
export BQ_TEMP="gs://${BUCKET}/bigquery_temp"

# --- TASK 1: Dataflow ---
echo -e "\n${BLUE_TEXT}🚀 Task 1: Dataflow in Progress...${RESET_FORMAT}"
bq mk $DATASET 2>/dev/null
gsutil mb -l $REGION gs://$BUCKET 2>/dev/null
gcloud dataflow jobs run batch-job-task1 --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery --region $REGION --worker-machine-type n2d-standard-2 --staging-location $TEMP_LOCATION --parameters javascriptTextTransformFunctionName=transform,JSONPath=gs://spls/gsp323/lab.schema,javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,inputFilePattern=gs://spls/gsp323/lab.csv,outputTable=$PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=$BQ_TEMP &
spinner $!

# --- TASK 2: Dataproc ---
echo -e "\n${BLUE_TEXT}🚀 Task 2: Dataproc Cluster...${RESET_FORMAT}"
gcloud dataproc clusters create cluster-lab --region=$REGION --num-workers 2 --master-machine-type n2d-standard-2 --worker-machine-type n2d-standard-2 --image-version 2.2-debian12 &
spinner $!

echo -e "${YELLOW_TEXT}Verifying Cluster Status...${RESET_FORMAT}"
while [ "$(gcloud dataproc clusters describe cluster-lab --region=$REGION --format='value(status.state)')" != "RUNNING" ]; do sleep 5; done

MASTER_NODE=$(gcloud compute instances list --filter="name ~ cluster-lab-m" --format="value(name)")
MASTER_ZONE=$(gcloud compute instances list --filter="name ~ cluster-lab-m" --format="value(zone)")

gcloud compute ssh $MASTER_NODE --zone=$MASTER_ZONE --quiet --command="gsutil cp gs://spls/gsp323/data.txt . && hdfs dfs -put data.txt /data.txt" &
spinner $!

gcloud dataproc jobs submit spark --cluster=cluster-lab --region=$REGION --class=org.apache.spark.examples.SparkPageRank --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar -- /data.txt &
spinner $!

# --- TASK 3: Speech-to-Text API ---
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}Starting Task 3: Speech-to-Text...${RESET_FORMAT}"
gcloud services enable apikeys.googleapis.com
gcloud services enable speech.googleapis.com
gcloud alpha services api-keys create --display-name="dr-api-key" --api-target=service=speech.googleapis.com &
spinner $!
echo -e "${CYAN_TEXT}Waiting for API Key propagation...${RESET_FORMAT}"
sleep 30

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --limit=1)
API_KEY=$(gcloud alpha services api-keys get-key-string "$KEY_NAME" --format="value(keyString)")

cat > request.json <<EOF
{ "config": { "encoding": "FLAC", "languageCode": "en-US" }, "audio": { "uri": "gs://spls/gsp323/task3.flac" } }
EOF

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result_task3.json
gsutil -h "Content-Type: application/json" cp result_task3.json $TASK3_OUTPUT

# --- TASK 4: Natural Language API ---
echo -e "\n${YELLOW_TEXT}${BOLD_TEXT}Starting Task 4: Natural Language...${RESET_FORMAT}"
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result_task4.json
gsutil -h "Content-Type: application/json" cp result_task4.json $TASK4_OUTPUT

# Cleanup
rm -f request.json result_task3.json result_task4.json
echo -e "\n${GREEN_TEXT}${BOLD_TEXT}=================================================================="
echo -e "                  LAB COMPLETED SUCCESSFULLY! 🎉                   "
echo -e "           Please Subscribe: https://www.youtube.com/@CloudHustlers"
echo -e "==================================================================${RESET_FORMAT}"
