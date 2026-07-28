# Google Cloud Challenge Lab -- Manual Console Guide 

> **Goal:** Complete the lab manually using the Google Cloud Console.

------------------------------------------------------------------------

# Task 1 -- Create a Custom IAM Role

### Step 1

Open **☰ Navigation Menu → IAM & Admin → Roles**

### Step 2

Click **Create Role**

### Step 3

Fill the fields

  Field          Value
  -------------- --------------------------
  Role ID        `<CUSTOM_SECURITY_ROLE>`
  Title          `<CUSTOM_SECURITY_ROLE>`
  Description    `Permissions`
  Launch Stage   **Alpha**

### Step 4

Click **Add Permissions**

Add:

    storage.buckets.get
    storage.objects.get
    storage.objects.list
    storage.objects.update
    storage.objects.create

### Step 5

Click **Create**

------------------------------------------------------------------------

# Task 2 -- Create Service Accounts

## Service Account 1

Navigate to

**☰ → IAM & Admin → Service Accounts**

Click **Create Service Account**

  Field          Value
  -------------- ----------------------------------------
  Name           `orca-private-cluster-sa`
  Display Name   `Orca Private Cluster Service Account`

Click **Create and Continue**

No roles required.

Click **Done**

------------------------------------------------------------------------

## Service Account 2

Click **Create Service Account**

  Field          Value
  -------------- ----------------------------------------
  Name           `<SERVICE_ACCOUNT>`
  Display Name   `Orca Private Cluster Service Account`

Click **Create and Continue**

No roles required.

Click **Done**

------------------------------------------------------------------------

# Task 3 -- Grant IAM Roles

Go to

**☰ → IAM & Admin → IAM**

Locate

`<SERVICE_ACCOUNT>`

Click the **✏️ Edit Principal** icon.

Add these roles:

-   Monitoring Viewer
-   Monitoring Metric Writer
-   Logs Writer
-   `<CUSTOM_SECURITY_ROLE>` (Custom Role)

Click **Save**

------------------------------------------------------------------------

# Task 4 -- Create the Private GKE Cluster

Navigate to

**☰ → Kubernetes Engine → Clusters**

Click **Create**

Choose **Standard Cluster**

------------------------------------------------------------------------

## Basic

  Setting   Value
  --------- ------------------
  Name      `<CLUSTER_NAME>`
  Zone      `<ZONE>`

------------------------------------------------------------------------

## Networking

  Setting      Value
  ------------ ---------------------
  Network      `orca-build-vpc`
  Subnetwork   `orca-build-subnet`

Enable

-   VPC Native (IP Alias)

------------------------------------------------------------------------

## Node Pool

Set

    Number of nodes = 1

Select the Service Account

    <SERVICE_ACCOUNT>

------------------------------------------------------------------------

## Security

Enable

-   Private Cluster
-   Private Nodes
-   Private Endpoint

Master IPv4 CIDR

    172.16.0.64/28

------------------------------------------------------------------------

## Master Authorized Networks

Enable

    Master Authorized Networks

Add

    192.168.10.2/32

Click **Create**

Wait until cluster status becomes **Running**.

------------------------------------------------------------------------

# Task 5 -- Open the Jump Host

Go to

**☰ → Compute Engine → VM Instances**

Locate

    orca-jumphost

Click **SSH**

------------------------------------------------------------------------

# Task 6 -- Install GKE Authentication Plugin

Run

``` bash
sudo apt update
sudo apt install -y google-cloud-sdk-gke-gcloud-auth-plugin
```

------------------------------------------------------------------------

# Task 7 -- Connect to the Cluster

``` bash
gcloud config set compute/zone <ZONE>
```

``` bash
gcloud container clusters get-credentials <CLUSTER_NAME> --internal-ip
```

------------------------------------------------------------------------

# Task 8 -- Deploy the Application

``` bash
kubectl create deployment hello-server \
--image=gcr.io/google-samples/hello-app:1.0
```

------------------------------------------------------------------------

# Task 9 -- Expose the Deployment

``` bash
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 80 \
--target-port 8080
```

------------------------------------------------------------------------

# Task 10 -- Verify

Check Pods

``` bash
kubectl get pods
```

Check Services

``` bash
kubectl get svc
```

The service **orca-hello-service** should be created successfully.

------------------------------------------------------------------------

Alternate of task 4 and 5

```
gcloud container clusters create $CLUSTER_NAME \
--num-nodes 1 \
--master-ipv4-cidr=172.16.0.64/28 \
--network orca-build-vpc \
--subnetwork orca-build-subnet \
--enable-master-authorized-networks \
--master-authorized-networks 192.168.10.2/32 \
--enable-ip-alias \
--enable-private-nodes \
--enable-private-endpoint \
--service-account $SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
--zone $ZONE


```

Task 5
```

gcloud compute ssh --zone "$ZONE" "orca-jumphost" \
--project "$DEVSHELL_PROJECT_ID" \
--quiet \
--command "
gcloud config set compute/zone $ZONE &&
gcloud container clusters get-credentials $CLUSTER_NAME --internal-ip &&
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin &&
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0 &&
kubectl expose deployment hello-server \
--name orca-hello-service \
--type LoadBalancer \
--port 80 \
--target-port 8080
"

```

# Checklist

-   ✅ Custom IAM Role Created
-   ✅ Service Account Created
-   ✅ IAM Roles Assigned
-   ✅ Private GKE Cluster Created
-   ✅ Jump Host Connected
-   ✅ Auth Plugin Installed
-   ✅ Cluster Credentials Configured
-   ✅ Deployment Created
-   ✅ LoadBalancer Service Created
-   ✅ Lab Completed
