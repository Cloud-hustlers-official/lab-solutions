# GSP306 - Challenge Lab Solution
## Migrate a WordPress Database to Cloud SQL

# Task 1 - Create Cloud SQL Instance

**Navigation:** `SQL → Create Instance → MySQL`

| Instance ID | Password | Version | Region | Zone | Machine |
|--------------|----------|---------|--------|------|---------|
| `wordpress` | `Password1*` | `MySQL 5.7` | `REGION` | `ZONE` | `db-n1-standard-1` |

**Create Instance** → Wait until **Runnable**

> **If enabled:** `SQL → wordpress → Connections → Security → Disable "Allow only SSL connections" → Save`

✅ Check Progress

---

# Task 2 - Configure Cloud SQL

| Action | Navigation | Value |
|---------|------------|-------|
| Create Database | `SQL → wordpress → Databases → Create Database` | `wordpress` |
| Create User | `SQL → wordpress → Users → Add User Account` | `blogadmin` / `Password1*` / Host `%` |
| Authorize VM | `SQL → wordpress → Connections → Networking → Authorized Networks → Add Network` | `blog-vm` → `BLOG_VM_EXTERNAL_IP/32` |

> **Wait 1–2 minutes** after saving the Authorized Network before connecting to Cloud SQL.

✅ Check Progress

---

# Automate Way

## Set Variables

```bash
export ZONE=ZONE
export REGION=REGION
```

---

# Task 1 & Task 2 - Create Cloud SQL Instance

```bash
export BLOG_IP=$(gcloud compute instances describe blog --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
gcloud sql instances create wordpress --database-version=MYSQL_5_7 --tier=db-n1-standard-1 --region=$REGION --root-password="Password1*"
gcloud sql instances patch wordpress --authorized-networks=${BLOG_IP}/32 --quiet
gcloud sql databases create wordpress --instance=wordpress
gcloud sql users create blogadmin --instance=wordpress --host=% --password="Password1*"
```

### If "Allow only SSL connections" is Enabled

Go to:

```
SQL → wordpress → Connections → Security
```

Disable:

```
Allow only SSL connections
```

Click **Save**.

✅ **Check Progress**

---

# Task 3, Task 4 & Task 5

### Get the Cloud SQL Public IP (Run in Cloud Shell)

```bash
export CLOUD_SQL_IP=$(gcloud sql instances describe wordpress --format="value(ipAddresses.ipAddress)")
echo $CLOUD_SQL_IP
```

### SSH into the **blog** VM and run:

```bash
export CLOUD_SQL_IP=<CLOUD_SQL_PUBLIC_IP>

sudo apt update
sudo apt install default-mysql-client -y

sudo mysqldump -u blogadmin -p'Password1*' wordpress > wordpress_db_backup.sql

mysql --host=$CLOUD_SQL_IP -u blogadmin -p'Password1*' wordpress < wordpress_db_backup.sql

sudo sed -i "/DB_HOST/c\define('DB_HOST', '$CLOUD_SQL_IP');" /var/www/html/wordpress/wp-config.php

echo "Verify DB_HOST:"
grep DB_HOST /var/www/html/wordpress/wp-config.php

sudo service apache2 restart
```

Open the **Blog VM External IP** in your browser.

✅ **Check Progress**

---

# Lab Complete ✅

- ✅ Task 1 Complete
- ✅ Task 2 Complete
- ✅ Task 3 Complete
- ✅ Task 4 Complete
- ✅ Task 5 Complete
- ✅ 100% Score
