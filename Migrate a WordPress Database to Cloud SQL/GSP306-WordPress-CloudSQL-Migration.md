# GSP306 - Challenge Lab Solution
## Migrate a WordPress Database to Cloud SQL

---

# Set Variables

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
SQL
└── wordpress
    └── Connections
        └── Security
```

Disable

```
Allow only SSL connections
```

Click **Save**.

✅ **Check Progress**

---

# Task 3, Task 4 & Task 5

SSH into the **blog** VM and run:

```bash
export CLOUD_SQL_IP=$(gcloud sql instances describe wordpress --format="value(ipAddresses.ipAddress)")

sudo apt update
sudo apt install default-mysql-client -y

sudo mysqldump -u blogadmin -p'Password1*' wordpress > wordpress_db_backup.sql

mysql --host=$CLOUD_SQL_IP -u blogadmin -p'Password1*' wordpress < wordpress_db_backup.sql

sudo sed -i "s/localhost/$CLOUD_SQL_IP/g" /var/www/html/wordpress/wp-config.php

sudo service apache2 restart
```

Open the Blog VM External IP in your browser.

✅ **Check Progress**

---

# Lab Complete ✅
