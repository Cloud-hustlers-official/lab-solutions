# Google Cloud App Engine Lab (Manual Steps)

## Task 1: Enable the App Engine API

1. Open **Google Cloud Console**.
2. Go to **APIs & Services → Library**.
3. Search for **App Engine Admin API**.
4. Click **Enable**.

---

## Task 2: Create an App Engine Application

1. Go to **App Engine**.
2. Click **Create Application**.
3. Select the region specified in the lab (e.g., `us-west1`).
4. Click **Create App**.

---

## Task 3: Clone the Sample Application

Open **Cloud Shell** and run:

```bash
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world
```

---

## Task 4: Update the Application Message

Replace the default message using `sed`:

```bash
sed -i '32c\    return "YOUR_MESSAGE"' main.py
```

> Replace `YOUR_MESSAGE` with the message provided in the lab.

*(Alternatively, edit `main.py` manually using `nano`.)*

---

## Task 5: Deploy the Application

Verify you're in the correct directory:

```bash
ls
```

You should see `app.yaml`.

Deploy:

```bash
gcloud app deploy
```

Type **Y** when prompted.

---

## Task 6: Verify the Deployment

Open the application:

```bash
gcloud app browse
```

Or view the URL:

```bash
gcloud app describe
```

---

## Common Error

### `An app.yaml file is required`

You're not in the application directory.

```bash
cd python-docs-samples/appengine/standard_python3/hello_world

gcloud app deploy
```
