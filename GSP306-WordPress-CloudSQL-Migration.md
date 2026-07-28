# GSP306 — Challenge Lab Guide
## Migrate a WordPress Database to Cloud SQL

> **Lab:** Migrate a WordPress Website to Cloud SQL (Challenge Lab)
> **Difficulty:** ⭐⭐⭐☆☆
> **Objective:** Migrate a locally hosted WordPress MySQL database on a Compute Engine VM to a managed Cloud SQL instance, then reconfigure WordPress to use it.

This guide works for **any student** taking this lab — it uses placeholders instead of specific IPs/values, since every lab session generates different credentials, IPs, and sometimes zone/region.

---

## 📋 Before You Start

Every lab session gives you different values. Note these down from your lab instructions panel first:

| Placeholder | Where to find it |
|---|---|
| `ZONE` | Lab instructions panel (top left) |
| `REGION` | Lab instructions panel (top left) |
| `BLOG_VM_EXTERNAL_IP` | Compute Engine → VM instances → `blog` row |
| `CLOUD_SQL_PUBLIC_IP` | SQL → your instance → Overview page |

**Known/fixed lab values** (same across all sessions of this lab):

| Item | Value |
|---|---|
| Existing local DB name | `wordpress` |
| Existing/target DB user | `blogadmin` |
| Existing/target DB password | `Password1*` |
| WordPress config file path | `/var/www/html/wordpress/wp-config.php` |
| Blog VM name | `blog` |

---

## Task 1 — Create a Cloud SQL Instance

**Goal:** Create a MySQL Cloud SQL instance to eventually host the migrated `wordpress` database.

1. Go to **Navigation menu → SQL → Create Instance → Choose MySQL**.
2. Fill in the instance settings:

| Setting | Value |
|---|---|
| Instance ID | `wordpress` |
| Password (root) | `Password1*` |
| Database version | MySQL 5.7 (or the version offered by the lab) |
| Region | `REGION` |
| Zone | `ZONE` (single zone, not "Any") |
| Machine type | Lightweight / `db-n1-standard-1` |
| Storage | Default is fine |

3. Click **Create Instance**.
4. Wait for the instance status to change to **Runnable** (this can take a few minutes).

**✅ Check progress** — this verifies a Cloud SQL instance exists.

---

## Task 2 — Configure the New Database

**Goal:** Create the `wordpress` database and `blogadmin` user inside the new Cloud SQL instance.

### Step 2.1 — Create the database

1. Open your Cloud SQL instance (`wordpress`).
2. Go to **Databases → Create Database**.
3. Database name: `wordpress`
4. Click **Create**.

### Step 2.2 — Create the user

1. Go to **Users → Add User Account**.
2. Fill in:

| Setting | Value |
|---|---|
| Username | `blogadmin` |
| Password | `Password1*` |
| Host name | `%` (any host) |

3. Click **Add**.

**✅ Check progress** — this verifies a user database exists on the instance.

---

## Task 3 — Authorize the VM, Dump, and Import the Database

This task has two parts: **networking** (Console) and **data migration** (VM terminal).

### Step 3.1 — Get the Blog VM's external IP

1. Go to **Compute Engine → VM instances**.
2. Copy the **External IP** of the `blog` instance (e.g. `35.xxx.xxx.xxx`).

### Step 3.2 — Authorize the Blog VM on Cloud SQL

1. Go to **SQL → wordpress instance → Connections → Networking** tab.
2. Under **Authorized networks**, click **Add a network**.
3. Fill in:

| Setting | Value |
|---|---|
| Name | `blog-vm` |
| Network | `BLOG_VM_EXTERNAL_IP/32` |

4. Click **Done → Save**.
5. Wait 1–2 minutes for the change to apply.

**✅ Check progress** — this verifies the blog instance is authorized to access Cloud SQL.

### Step 3.3 — Get the Cloud SQL instance's public IP

1. Go to **SQL → wordpress instance → Overview**.
2. Copy the **Public IP address** (e.g. `34.xxx.xxx.xxx`).

### Step 3.4 — SSH into the Blog VM

From **Compute Engine → VM instances**, click **SSH** next to `blog`.

### Step 3.5 — Install the MySQL client (if missing)

```bash
sudo apt update
sudo apt install mysql-client -y
```

### Step 3.6 — Set an environment variable for convenience

```bash
export CLOUD_SQL_IP=CLOUD_SQL_PUBLIC_IP
```
> Replace `CLOUD_SQL_PUBLIC_IP` with the value from Step 3.3.

### Step 3.7 — Dump the existing local database

```bash
sudo mysqldump -u blogadmin -pPassword1* wordpress > wordpress_db_backup.sql
```

### Step 3.8 — Import the dump into Cloud SQL

```bash
mysql --host=$CLOUD_SQL_IP -u blogadmin -pPassword1* wordpress < wordpress_db_backup.sql
```

> If this fails with an access/privilege error, run the following once to ensure the grants exist, then repeat Step 3.8:
> ```bash
> mysql --host=$CLOUD_SQL_IP -u root -pPassword1* <<EOF
> GRANT ALL PRIVILEGES ON wordpress.* TO 'blogadmin'@'%';
> FLUSH PRIVILEGES;
> EOF
> ```

**✅ Check progress** — this should now confirm the authorization/migration objective for Task 3.

---

## Task 4 — Reconfigure WordPress to Use Cloud SQL

Still connected via SSH to the `blog` VM.

### Step 4.1 — Update `wp-config.php`

```bash
sudo sed -i "s/localhost/$CLOUD_SQL_IP/g" /var/www/html/wordpress/wp-config.php
```

**Or edit manually:**

```bash
sudo nano /var/www/html/wordpress/wp-config.php
```

Find:
```php
define('DB_HOST', 'localhost');
```

Change to:
```php
define('DB_HOST', 'CLOUD_SQL_PUBLIC_IP');
```

Save and exit: `Ctrl+O` → `Enter` → `Ctrl+X`

### Step 4.2 — Confirm the change

```bash
grep DB_HOST /var/www/html/wordpress/wp-config.php
```

Expected output:
```
define('DB_HOST', 'CLOUD_SQL_PUBLIC_IP');
```

### Step 4.3 — Restart Apache

```bash
sudo service apache2 restart
```

**✅ Check progress** — this verifies `wp-config.php` points to the Cloud SQL instance.

---

## Task 5 — Validate the Migration

1. Go to **Compute Engine → VM instances**, copy the `blog` VM's **External IP**.
2. Open it in a browser: `http://BLOG_VM_EXTERNAL_IP`
3. Confirm the WordPress homepage loads normally (posts, theme, images visible).

If it doesn't load correctly:
- Re-check `wp-config.php` has the correct `DB_HOST` value.
- Re-check the Cloud SQL authorized network entry matches the VM's current external IP.
- Restart Apache again: `sudo service apache2 restart`

**✅ Check progress** — this verifies the blog still responds to requests.

---

## 🧾 All Blog VM Commands in One Block

Run this after completing the Console steps (Tasks 1–2 and the authorized network step in Task 3). Replace `CLOUD_SQL_PUBLIC_IP` first.

```bash
export CLOUD_SQL_IP=CLOUD_SQL_PUBLIC_IP

sudo apt update
sudo apt install mysql-client -y

sudo mysqldump -u blogadmin -pPassword1* wordpress > wordpress_db_backup.sql

mysql --host=$CLOUD_SQL_IP -u blogadmin -pPassword1* wordpress < wordpress_db_backup.sql

sudo sed -i "s/localhost/$CLOUD_SQL_IP/g" /var/www/html/wordpress/wp-config.php

sudo service apache2 restart
```

---

## ✅ Final Checklist

- [ ] Cloud SQL instance created and **Runnable**
- [ ] `wordpress` database created on the instance
- [ ] `blogadmin` user created with password `Password1*`
- [ ] Blog VM's external IP added as an authorized network
- [ ] Local database dumped to `wordpress_db_backup.sql`
- [ ] Dump imported into Cloud SQL
- [ ] `wp-config.php` `DB_HOST` updated to Cloud SQL public IP
- [ ] Apache restarted
- [ ] Blog homepage loads correctly at the VM's external IP
- [ ] All 5 tasks show green in **Check my progress**

---

## 🛠️ Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| `ERROR 2003: Can't connect to MySQL server` | Authorized network missing/wrong IP | Re-add the VM's current external IP under Cloud SQL → Networking |
| `ERROR 1045: Access denied` | Wrong user/password or missing grants | Re-run the `GRANT ALL PRIVILEGES` command as `root` |
| Site shows "Error establishing a database connection" | `wp-config.php` still points to `localhost` or wrong IP | Re-check `DB_HOST` value, restart Apache |
| Progress check for Task 3 fails despite import working | VM not authorized in Cloud SQL networking | Confirm the `/32` CIDR matches the VM's current external IP exactly |
