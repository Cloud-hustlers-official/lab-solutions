#!/bin/bash

BOLD=`tput bold`
CYAN=`tput setaf 6`
GREEN=`tput setaf 2`
RED=`tput setaf 1`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

INSTANCE=banking-ops-instance
DB=banking-ops-db

# ======================================================================
# STEP 0: Dynamically detect REGION and ZONE from project metadata
# ======================================================================
echo "${CYAN}${BOLD}Detecting region and zone from project metadata...${RESET}"

ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

# Fallback 1: derive region from zone (strip trailing -a/-b/-c)
if [ -z "$REGION" ] && [ -n "$ZONE" ]; then
  REGION=${ZONE%-*}
fi

# Fallback 2: gcloud config
if [ -z "$REGION" ]; then
  REGION=$(gcloud config get-value compute/region 2>/dev/null)
fi

# Fallback 3: ask the user (default = europe-west1, what GSP381 pins)
if [ -z "$REGION" ]; then
  read -p "${BOLD}Could not auto-detect. Enter region (Enter = europe-west1): ${RESET}" REGION
  REGION=${REGION:-europe-west1}
fi

echo "${GREEN}${BOLD}REGION = $REGION${RESET}"
[ -n "$ZONE" ] && echo "${GREEN}${BOLD}ZONE   = $ZONE${RESET}"

# Sanity check: does a Spanner config exist for this region?
if ! gcloud spanner instance-configs describe regional-$REGION >/dev/null 2>&1; then
  echo "${RED}${BOLD}regional-$REGION is not a valid Spanner config. Falling back to europe-west1.${RESET}"
  REGION=europe-west1
fi

# ======================================================================
# Helper: retry any command on failure (Spanner ABORTED, propagation, etc.)
# ======================================================================
retry() {
  local n=1
  local max=5
  local delay=8
  while true; do
    "$@" && break
    if [ $n -ge $max ]; then
      echo "${RED}${BOLD}Command failed after $max attempts: $*${RESET}"
      return 1
    fi
    echo "${YELLOW}Attempt $n failed (likely ABORTED / propagation delay). Retrying in ${delay}s...${RESET}"
    n=$((n+1))
    sleep $delay
  done
}

# ======================================================================
# Task 1: Create Spanner instance
# ======================================================================
echo "${CYAN}${BOLD}Task 1: Creating Spanner instance${RESET}"
retry gcloud spanner instances create $INSTANCE \
  --config=regional-$REGION \
  --description="Banking Operations Instance" \
  --nodes=1

# ======================================================================
# Task 2 + 3: Create database with all four tables
# ======================================================================
echo "${CYAN}${BOLD}Task 2 & 3: Creating database and tables${RESET}"
retry gcloud spanner databases create $DB --instance=$INSTANCE \
  --ddl='CREATE TABLE Portfolio (
    PortfolioId INT64 NOT NULL,
    Name STRING(MAX),
    ShortName STRING(MAX),
    PortfolioInfo STRING(MAX)
  ) PRIMARY KEY (PortfolioId);
  CREATE TABLE Category (
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    CategoryName STRING(MAX),
    PortfolioInfo STRING(MAX)
  ) PRIMARY KEY (CategoryId);
  CREATE TABLE Product (
    ProductId INT64 NOT NULL,
    CategoryId INT64 NOT NULL,
    PortfolioId INT64 NOT NULL,
    ProductName STRING(MAX),
    ProductAssetCode STRING(25),
    ProductClass STRING(25)
  ) PRIMARY KEY (ProductId);
  CREATE TABLE Customer (
    CustomerId STRING(36) NOT NULL,
    Name STRING(MAX) NOT NULL,
    Location STRING(MAX) NOT NULL
  ) PRIMARY KEY (CustomerId);'

# Give the schema a moment to settle before firing DML at it
echo "${YELLOW}Waiting 15s for schema to settle...${RESET}"
sleep 15

# ======================================================================
# Task 4: Load simple datasets (each wrapped in retry — fixes ABORTED)
# ======================================================================
echo "${CYAN}${BOLD}Task 4: Loading Portfolio table${RESET}"
retry gcloud spanner databases execute-sql $DB --instance=$INSTANCE \
  --sql='INSERT INTO Portfolio (PortfolioId, Name, ShortName, PortfolioInfo)
  VALUES
    (1, "Banking", "Bnkg", "All Banking Business"),
    (2, "Asset Growth", "AsstGrwth", "All Asset Focused Products"),
    (3, "Insurance", "Insurance", "All Insurance Focused Products")'

echo "${CYAN}${BOLD}Task 4: Loading Category table${RESET}"
retry gcloud spanner databases execute-sql $DB --instance=$INSTANCE \
  --sql='INSERT INTO Category (CategoryId, PortfolioId, CategoryName)
  VALUES
    (1, 1, "Cash"),
    (2, 2, "Investments - Short Return"),
    (3, 2, "Annuities"),
    (4, 3, "Life Insurance")'

echo "${CYAN}${BOLD}Task 4: Loading Product table${RESET}"
retry gcloud spanner databases execute-sql $DB --instance=$INSTANCE \
  --sql='INSERT INTO Product (ProductId, CategoryId, PortfolioId, ProductName, ProductAssetCode, ProductClass)
  VALUES
    (1, 1, 1, "Checking Account", "ChkAcct", "Banking LOB"),
    (2, 2, 2, "Mutual Fund Consumer Goods", "MFundCG", "Investment LOB"),
    (3, 3, 2, "Annuity Early Retirement", "AnnuFixed", "Investment LOB"),
    (4, 4, 3, "Term Life Insurance", "TermLife", "Insurance LOB"),
    (5, 1, 1, "Savings Account", "SavAcct", "Banking LOB"),
    (6, 1, 1, "Personal Loan", "PersLn", "Banking LOB"),
    (7, 1, 1, "Auto Loan", "AutLn", "Banking LOB"),
    (8, 4, 3, "Permanent Life Insurance", "PermLife", "Insurance LOB"),
    (9, 2, 2, "US Savings Bonds", "USSavBond", "Investment LOB")'

# ======================================================================
# Task 5: Load Customer_List_500.csv WITHOUT Dataflow
# Tries the official lab bucket first, then the cloud-training mirror
# ======================================================================
echo "${CYAN}${BOLD}Task 5: Downloading Customer_List_500.csv${RESET}"
if ! gsutil cp gs://spls/gsp381/Customer_List_500.csv . 2>/dev/null; then
  echo "${YELLOW}Primary bucket failed, trying cloud-training mirror...${RESET}"
  gsutil cp gs://cloud-training/OCBL375/Customer_List_500.csv .
fi

if [ ! -f Customer_List_500.csv ]; then
  echo "${RED}${BOLD}Could not download the CSV from either bucket. Aborting Task 5.${RESET}"
  exit 1
fi

echo "${CYAN}${BOLD}Installing Spanner client library${RESET}"
pip3 install --user --quiet google-cloud-spanner

cat > load_customers.py << 'EOF'
import csv
import time
from google.cloud import spanner

client = spanner.Client()
instance = client.instance("banking-ops-instance")
database = instance.database("banking-ops-db")

rows = []
with open("Customer_List_500.csv", "r", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    for row in reader:
        if not row:
            continue
        if row[0].strip().lower() == "customerid":
            continue
        rows.append([row[0].strip(), row[1].strip(), row[2].strip()])

BATCH = 100
total = 0
i = 0
while i < len(rows):
    chunk = rows[i:i+BATCH]
    attempt = 0
    while attempt < 5:
        try:
            with database.batch() as batch:
                batch.insert_or_update(
                    table="Customer",
                    columns=("CustomerId", "Name", "Location"),
                    values=chunk,
                )
            break
        except Exception as e:
            attempt = attempt + 1
            print("Batch failed (attempt " + str(attempt) + "): " + str(e))
            time.sleep(5)
    total = total + len(chunk)
    print("Inserted " + str(total) + " rows")
    i = i + BATCH

print("Done. Total rows loaded: " + str(total))
EOF

retry python3 load_customers.py

echo "${CYAN}${BOLD}Verifying Customer row count${RESET}"
gcloud spanner databases execute-sql $DB --instance=$INSTANCE \
  --sql='SELECT COUNT(*) AS TotalCustomers FROM Customer'

# ======================================================================
# Task 6: Add MarketingBudget column
# ======================================================================
echo "${CYAN}${BOLD}Task 6: Adding MarketingBudget column${RESET}"
retry gcloud spanner databases ddl update $DB --instance=$INSTANCE \
  --ddl='ALTER TABLE Category ADD COLUMN MarketingBudget INT64;'

echo ""
echo "${GREEN}${BOLD}==============================================${RESET}"
echo "${GREEN}${BOLD} All 6 tasks completed.                       ${RESET}"
echo "${GREEN}${BOLD} Region used: $REGION                         ${RESET}"
echo "${GREEN}${BOLD} Now click every 'Check my progress' button.  ${RESET}"
echo "${GREEN}${BOLD}==============================================${RESET}"
