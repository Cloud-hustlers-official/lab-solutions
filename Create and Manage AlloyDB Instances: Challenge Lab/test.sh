#!/bin/bash
# GSP395 - Create and Manage AlloyDB Instances: Challenge Lab
# Hardened master script. Run in Cloud Shell as:
#   bash gsp395_master.sh
# Do NOT run via `curl | bash` (interactive prompts and stdin will break).

CLUSTER=lab-cluster
INSTANCE=lab-instance
READPOOL=lab-instance-rp1
BACKUP=lab-backup
DBPASS=Change3Me
NETWORK=peering-network

# ---------------------------------------------------------------
# 0. Project / Zone / Region detection
# ---------------------------------------------------------------
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
[[ -z "$PROJECT_ID" ]] && export PROJECT_ID=$DEVSHELL_PROJECT_ID

export ZONE=$(gcloud compute instances list --filter="name=alloydb-client" --format="value(zone)" 2>/dev/null | head -n 1)

if [[ -z "$ZONE" ]]; then
  export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)
fi

if [[ -z "$ZONE" ]]; then
  read -p "Could not auto-detect zone. Enter the lab Zone (e.g. us-east1-c): " ZONE
  export ZONE
fi

export REGION=${ZONE%-*}
gcloud config set compute/zone "$ZONE" --quiet 2>/dev/null
gcloud config set compute/region "$REGION" --quiet 2>/dev/null

echo "Project: $PROJECT_ID"
echo "Zone:    $ZONE"
echo "Region:  $REGION"
echo ""

# ---------------------------------------------------------------
# 0b. Pre-generate SSH key so gcloud ssh/scp never prompts
# ---------------------------------------------------------------
mkdir -p ~/.ssh
if [[ ! -f ~/.ssh/google_compute_engine ]]; then
  ssh-keygen -t rsa -f ~/.ssh/google_compute_engine -N "" -q
  echo "Generated Cloud Shell SSH key."
fi

# ---------------------------------------------------------------
# Task 1: Cluster + Primary instance (skip if already present)
# ---------------------------------------------------------------
if ! gcloud beta alloydb clusters describe "$CLUSTER" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Task 1: Creating cluster $CLUSTER (takes a few minutes)..."
  gcloud beta alloydb clusters create "$CLUSTER" \
    --password="$DBPASS" \
    --network="$NETWORK" \
    --region="$REGION" \
    --project="$PROJECT_ID" --quiet
else
  echo "Task 1: Cluster $CLUSTER already exists, skipping."
fi

if ! gcloud beta alloydb instances describe "$INSTANCE" --cluster="$CLUSTER" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Task 1: Creating primary instance $INSTANCE (takes ~10 min)..."
  gcloud beta alloydb instances create "$INSTANCE" \
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region="$REGION" \
    --cluster="$CLUSTER" \
    --project="$PROJECT_ID" --quiet
else
  echo "Task 1: Instance $INSTANCE already exists, skipping."
fi

# ---------------------------------------------------------------
# Fetch private IP - poll until non-empty
# ---------------------------------------------------------------
echo "Fetching AlloyDB private IP..."
ALLOYDB_IP=""
for i in $(seq 1 20); do
  ALLOYDB_IP=$(gcloud beta alloydb instances describe "$INSTANCE" \
    --cluster="$CLUSTER" --region="$REGION" --project="$PROJECT_ID" \
    --format="value(ipAddress)" 2>/dev/null)
  [[ -n "$ALLOYDB_IP" ]] && break
  echo "  IP not ready yet, waiting 15s ($i/20)..."
  sleep 15
done

if [[ -z "$ALLOYDB_IP" ]]; then
  echo "ERROR: Could not get AlloyDB IP. Check the instance in the console and re-run."
  exit 1
fi
echo "AlloyDB IP: $ALLOYDB_IP"

# ---------------------------------------------------------------
# Tasks 2 & 3: Tables + data
# ---------------------------------------------------------------
cat << 'EOF' > schema.sql
CREATE TABLE IF NOT EXISTS regions (
  region_id bigint NOT NULL,
  region_name varchar(25)
);
ALTER TABLE regions ADD PRIMARY KEY (region_id);

CREATE TABLE IF NOT EXISTS countries (
  country_id char(2) NOT NULL,
  country_name varchar(40),
  region_id bigint
);
ALTER TABLE countries ADD PRIMARY KEY (country_id);

CREATE TABLE IF NOT EXISTS departments (
  department_id smallint NOT NULL,
  department_name varchar(30),
  manager_id integer,
  location_id smallint
);
ALTER TABLE departments ADD PRIMARY KEY (department_id);

INSERT INTO regions VALUES
  (1, 'Europe'),
  (2, 'Americas'),
  (3, 'Asia'),
  (4, 'Middle East and Africa');

INSERT INTO countries VALUES
  ('IT', 'Italy', 1),
  ('JP', 'Japan', 3),
  ('US', 'United States of America', 2),
  ('CA', 'Canada', 2),
  ('CN', 'China', 3),
  ('IN', 'India', 3),
  ('AU', 'Australia', 3),
  ('ZW', 'Zimbabwe', 4),
  ('SG', 'Singapore', 3);

INSERT INTO departments VALUES
  (10, 'Administration', 200, 1700),
  (20, 'Marketing', 201, 1800),
  (30, 'Purchasing', 114, 1700),
  (40, 'Human Resources', 203, 2400),
  (50, 'Shipping', 121, 1500),
  (60, 'IT', 103, 1400);

SELECT 'regions' AS t, count(*) FROM regions
UNION ALL SELECT 'countries', count(*) FROM countries
UNION ALL SELECT 'departments', count(*) FROM departments;
EOF

# SCP with retry - first attempt often fails while the new SSH key propagates
echo "Copying schema.sql to alloydb-client (retries if key not yet propagated)..."
SCP_OK=0
for i in $(seq 1 6); do
  if gcloud compute scp schema.sql alloydb-client:~ --zone="$ZONE" --quiet 2>/dev/null; then
    SCP_OK=1
    break
  fi
  echo "  SCP attempt $i failed, waiting 20s for SSH key propagation..."
  sleep 20
done

if [[ "$SCP_OK" -ne 1 ]]; then
  echo "ERROR: Could not SCP to alloydb-client. Open an SSH session to the VM once from the console, then re-run this script."
  exit 1
fi

echo "Running schema + data load on alloydb-client..."
SSH_OK=0
for i in $(seq 1 4); do
  if gcloud compute ssh alloydb-client --zone="$ZONE" --quiet --command="echo $ALLOYDB_IP > alloydbip.txt && PGPASSWORD=$DBPASS psql -h $ALLOYDB_IP -U postgres -f schema.sql"; then
    SSH_OK=1
    break
  fi
  echo "  SSH attempt $i failed, retrying in 20s..."
  sleep 20
done

if [[ "$SSH_OK" -ne 1 ]]; then
  echo "ERROR: psql load failed. SSH to alloydb-client manually and run:"
  echo "  PGPASSWORD=$DBPASS psql -h $ALLOYDB_IP -U postgres -f schema.sql"
  exit 1
fi

# ---------------------------------------------------------------
# Task 4: Read Pool instance
# ---------------------------------------------------------------
if ! gcloud beta alloydb instances describe "$READPOOL" --cluster="$CLUSTER" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Task 4: Creating read pool $READPOOL (takes ~10 min)..."
  gcloud beta alloydb instances create "$READPOOL" \
    --instance-type=READ_POOL \
    --cpu-count=2 \
    --read-pool-node-count=2 \
    --region="$REGION" \
    --cluster="$CLUSTER" \
    --project="$PROJECT_ID" --quiet
else
  echo "Task 4: Read pool already exists, skipping."
fi

# ---------------------------------------------------------------
# Task 5: Backup
# ---------------------------------------------------------------
if ! gcloud beta alloydb backups describe "$BACKUP" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Task 5: Creating backup $BACKUP..."
  gcloud beta alloydb backups create "$BACKUP" \
    --cluster="$CLUSTER" \
    --region="$REGION" \
    --project="$PROJECT_ID" --quiet
else
  echo "Task 5: Backup already exists, skipping."
fi

echo ""
echo "All tasks submitted. Click 'Check my progress' on each task in the lab page."
