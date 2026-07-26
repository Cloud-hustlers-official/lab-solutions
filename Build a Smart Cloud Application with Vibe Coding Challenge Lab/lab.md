
# Build a Smart Cloud Application with Vibe Coding: Challenge Lab

[![Watch on YouTube](https://img.shields.io/badge/Watch_on_YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/QLpiCXoLMlE)

> **Note:** Establish Hybrid Network Connectivity with NCC

---
### 🤝 Support
If you found this helpful, please **Subscribe** to [Cloud Hustlers](https://www.youtube.com/@CloudHustlers/videos) for more Google Cloud solutions!


### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏


```bash
gcloud services enable \
aiplatform.googleapis.com \
artifactregistry.googleapis.com \
compute.googleapis.com \
cloudbuild.googleapis.com \
run.googleapis.com
```

```bash
read -p $'\e[1;36mEnter your student email address (the one used to start the lab): \e[0m' STUDENT_EMAIL
PROJECT_ID=$(gcloud config get-value project)
echo -e "\n\e[1;34m Using Project ID:\e[0m \e[1;33m$PROJECT_ID\e[0m"
echo -e "\e[1;34m Using Student Email:\e[0m \e[1;33m$STUDENT_EMAIL\e[0m\n"
echo -e "\e[1;35mGranting Cloud Run Admin role...\e[0m"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/run.admin" \
  --quiet
echo -e "\e[1;35mGranting Vertex AI User role...\e[0m"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$STUDENT_EMAIL" \
  --role="roles/aiplatform.user" \
  --quiet

echo -e "\n\e[1;32mIAM roles applied successfully for\e[0m \e[1;33m$STUDENT_EMAIL\e[0m \e[1;32mon project\e[0m \e[1;33m$PROJECT_ID\e[0m\n"
```
FOR THE EXTERNAL ENVIRONMENT ISSUE
```
uv python install 3.13
uv python pin 3.13
uv run server.py
```

[![Watch on YouTube For 100% SCORE](https://img.shields.io/badge/Watch_on_YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/QLpiCXoLMlE)

```bash
tools = [google_search]
```
