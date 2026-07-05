#!/bin/bash

# Enhanced Color Definitions
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
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

clear

# Display Header
echo "${BG_MAGENTA}${BOLD}============================================${RESET}"
echo "${BG_MAGENTA}${BOLD}   CLOUD HUSTLER TERRAFORM MODULES LAB    ${RESET}"
echo "${BG_MAGENTA}${BOLD}============================================${RESET}"
echo

# Get Region Input
echo "${CYAN}${BOLD}Step 1: Please enter your preferred region (e.g., us-central1):${RESET}"
read REGION
export REGION
echo "${GREEN}✓ Region set to: ${REGION}${RESET}"
echo

# Start Execution
echo "${BG_MAGENTA}${BOLD}Starting Terraform Modules Deployment${RESET}"
echo

# Clone Terraform Network Module
echo "${BLUE}${BOLD}Step 2: Cloning Terraform Network Module${RESET}"
git clone https://github.com/terraform-google-modules/terraform-google-network
cd terraform-google-network
git checkout tags/v6.0.1 -b v6.0.1
echo "${GREEN}✓ Network module cloned${RESET}"
echo

# Configure Simple Project Example
echo "${BLUE}${BOLD}Step 3: Configuring VPC Network Example${RESET}"
cd ~/terraform-google-network/examples/simple_project

# Create variables.tf
cat > variables.tf <<EOF
variable "project_id" {
  description = "The project ID to host the network in"
  default     = "$DEVSHELL_PROJECT_ID"
}

variable "network_name" {
  description = "The name of the VPC network being created"
  default     = "example-vpc"
}
EOF

# Create main.tf with region variable
cat > main.tf <<EOF
module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 6.0"
  project_id   = var.project_id
  network_name = var.network_name
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "$REGION"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = "$REGION"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = "$REGION"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]
}
EOF

# Initialize and Apply Terraform
echo "${BLUE}${BOLD}Step 4: Deploying VPC Network${RESET}"
terraform init
terraform apply --auto-approve
echo "${GREEN}✓ VPC network deployed${RESET}"
echo

# Clean up VPC
echo "${BLUE}${BOLD}Step 5: Cleaning Up VPC Resources${RESET}"
terraform destroy --auto-approve
cd ~
rm -rf terraform-google-network
echo "${GREEN}✓ VPC resources cleaned up${RESET}"
echo

# Create GCS Static Website Module
echo "${BLUE}${BOLD}Step 6: Creating GCS Static Website Module${RESET}"
mkdir -p modules/gcs-static-website-bucket
cd modules/gcs-static-website-bucket

# Create module files
cat > website.tf <<EOF
resource "google_storage_bucket" "bucket" {
  name               = var.name
  project            = var.project_id
  location           = var.location
  storage_class      = var.storage_class
  labels             = var.labels
  force_destroy      = var.force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = var.versioning
  }
}
EOF

cat > variables.tf <<EOF
variable "name" {
  description = "The name of the bucket."
  type        = string
}
variable "project_id" {
  description = "The ID of the project to create the bucket in."
  type        = string
}
variable "location" {
  description = "The location of the bucket."
  type        = string
}
EOF

# Create root configuration
cd ~
cat > main.tf <<EOF
module "gcs-static-website-bucket" {
  source     = "./modules/gcs-static-website-bucket"
  name       = var.name
  project_id = var.project_id
  location   = "$REGION"
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
  default     = "$DEVSHELL_PROJECT_ID"
}
variable "name" {
  description = "Name of the buckets to create."
  type        = string
  default     = "$DEVSHELL_PROJECT_ID"
}
EOF

# Deploy GCS Bucket
echo "${BLUE}${BOLD}Step 7: Deploying GCS Bucket${RESET}"
terraform init
terraform apply --auto-approve
echo "${GREEN}✓ GCS bucket deployed${RESET}"
echo

# Upload Website Files
echo "${BLUE}${BOLD}Step 8: Uploading Website Files${RESET}"
curl -O https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Arcade-Voyage/Interact%20with%20Terraform%20Modules/index.html
curl -O https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Arcade-Voyage/Interact%20with%20Terraform%20Modules/error.html
gsutil cp *.html gs://$DEVSHELL_PROJECT_ID
echo "${GREEN}✓ Website files uploaded${RESET}"
echo

# Completion Message
echo "${BG_RED}${BOLD}============================================${RESET}"
echo "${BG_RED}${BOLD}   TERRAFORM MODULES LAB COMPLETED!         ${RESET}"
echo "${BG_RED}${BOLD}============================================${RESET}"
echo
echo "${GREEN}${BOLD}Congratulations on completing the lab!${RESET}"
echo
echo "${BLUE}${BOLD}For more cloud tutorials:${RESET}"
echo "${CYAN}Subscribe to Cloud Hustler YouTube Channel:${RESET}"

