clear
CYAN='\e[1;36m'
BLUE='\e[1;34m'
RESET='\e[0m'
BOLD='\e[1m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
MAGENTA='\e[1;35m'

echo -e "${CYAN}${BOLD}"
cat << "EOF"
   _____ _                 _   _   _           _   _                
  / ____| |               | | | | | |         | | | |               
 | |    | | ___  _   _  __| | | |_| |_   _ ___| |_| | ___ _ __ ___ 
 | |    | |/ _ \| | | |/ _` | |  _  | | | / __| __| |/ _ \ '__/ __|
 | |____| | (_) | |_| | (_| | | | | | |_| \__ \ |_| |  __/ |  \__ \
  \_____|_|\___/ \__,_|\__,_| \_| |_/\__,_|___/\__|_|\___|_|  |___/
EOF

echo -e "${RESET}"
echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}${BOLD}║   🚀 BROUGHT TO YOU BY CLOUD HUSTLERS                     ║${RESET}"
echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}\n"

# PRE-FLIGHT CHECKS & VARIABLES (DYNAMIC AUTO-FETCH)
# ==============================================================================
echo "${BOLD}${YELLOW}[Cloud Hustlers] Auto-fetching Project, Zone, and Region...${RESET}"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

export ZONE=$(gcloud compute instances list --filter="name=alloydb-client" --format="value(zone)" 2>/dev/null)

if [[ -z "$ZONE" ]]; then
    export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)
fi

if [[ -z "$ZONE" ]]; then
    echo "${BOLD}${RED}⚠️ Could not auto-detect the default zone.${RESET}"
    read -p "${BOLD}${CYAN}Please enter the lab Zone (e.g., us-east1-c): ${RESET}" ZONE
    export ZONE
fi

export REGION=${ZONE%-*}
gcloud config set compute/zone $ZONE 2>/dev/null
gcloud config set compute/region $REGION 2>/dev/null

echo -e "✅ Project ID: ${GREEN}$PROJECT_ID${RESET}"
echo -e "✅ Zone:       ${GREEN}$ZONE${RESET}"
echo -e "✅ Region:     ${GREEN}$REGION${RESET}\n"
# ==============================================================================

echo -e "${YELLOW}Starting Infrastructure Provisioning... (This will take a while, grab a coffee!)☕${RESET}"

echo -e "${CYAN}Task 1: Creating AlloyDB Cluster 'lab-cluster'...${RESET}"
gcloud beta alloydb clusters create lab-cluster \
    --password=Change3Me \
    --network=peering-network \
    --region=$REGION \
    --project=$PROJECT_ID

echo -e "${CYAN}Task 1: Creating Primary Instance 'lab-instance'...${RESET}"
gcloud beta alloydb instances create lab-instance \
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region=$REGION \
    --cluster=lab-cluster \
    --project=$PROJECT_ID

echo -e "${CYAN}Fetching AlloyDB Private IP Address...${RESET}"
ALLOYDB_IP=$(gcloud alloydb instances describe lab-instance --cluster=lab-cluster --region=$REGION --format="value(ipAddress)")
echo -e "${GREEN}AlloyDB IP: $ALLOYDB_IP${RESET}"

echo -e "${CYAN}Tasks 2 & 3: Creating SQL Script for Tables and Data...${RESET}"
cat << 'EOF' > schema.sql
CREATE TABLE regions (region_id bigint NOT NULL, region_name varchar(25));
ALTER TABLE regions ADD PRIMARY KEY (region_id);

CREATE TABLE countries (country_id char(2) NOT NULL, country_name varchar(40), region_id bigint);
ALTER TABLE countries ADD PRIMARY KEY (country_id);

CREATE TABLE departments (department_id smallint NOT NULL, department_name varchar(30), manager_id integer, location_id smallint);
ALTER TABLE departments ADD PRIMARY KEY (department_id);

INSERT INTO regions VALUES (1, 'Europe'), (2, 'Americas'), (3, 'Asia'), (4, 'Middle East and Africa');

INSERT INTO countries VALUES ('IT', 'Italy', 1), ('JP', 'Japan', 3), ('US', 'United States of America', 2), ('CA', 'Canada', 2), ('CN', 'China', 3), ('IN', 'India', 3), ('AU', 'Australia', 3), ('ZW', 'Zimbabwe', 4), ('SG', 'Singapore', 3);

INSERT INTO departments VALUES (10, 'Administration', 200, 1700), (20, 'Marketing', 201, 1800), (30, 'Purchasing', 114, 1700), (40, 'Human Resources', 203, 2400), (50, 'Shipping', 121, 1500), (60, 'IT', 103, 1400);
EOF

echo -e "${CYAN}Executing SQL securely via SSH on alloydb-client...${RESET}"
gcloud compute scp schema.sql alloydb-client:~ --zone=$ZONE
gcloud compute ssh alloydb-client --zone=$ZONE --command="echo $ALLOYDB_IP > alloydbip.txt && PGPASSWORD=Change3Me psql -h $ALLOYDB_IP -U postgres -f schema.sql"

echo -e "${CYAN}Task 4: Creating Read Pool Instance 'lab-instance-rp1'...${RESET}"
gcloud alloydb instances create lab-instance-rp1 \
  --cluster=lab-cluster \
  --region=$REGION \
  --instance-type=READ_POOL \
  --cpu-count=2 \
  --read-pool-node-count=2

echo -e "${CYAN}Task 5: Creating Manual Backup 'lab-backup'...${RESET}"
gcloud beta alloydb backups create lab-backup \
  --region=$REGION \
  --cluster=lab-cluster

echo -e "\n${MAGENTA}${BOLD}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║            🎉 AUTOMATION COMPLETED SUCCESSFULLY 🎉           ║${RESET}"
echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════════════╝${RESET}"

# Subscribe to Cloud Hustlers https://www.youtube.com/@cloudhustlers
