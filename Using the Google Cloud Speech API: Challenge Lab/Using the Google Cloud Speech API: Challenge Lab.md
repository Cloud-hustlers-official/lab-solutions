## Using the Google Cloud Speech API: Challenge Lab

<div align="center">
  <a href="https://www.cloudskillsboost.google/focuses/65993?catalog_rank=%7B%22rank%22%3A1%2C%22num_filters%22%3A0%2C%22has_search%22%3Atrue%7D&parent=catalog&search_id=44037533" target="_blank" rel="noopener noreferrer" style="text-decoration: none;">
    <img src="https://img.shields.io/badge/🚀_Launch_Challenge_Lab-Google_Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white&labelColor=EA4335&color=white&link=https://www.cloudskillsboost.google" alt="Google Cloud Challenge Lab" style="height: 40px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">
  </a>
</div>

### In this lab, You need to:

- Create an API key.
- Create and call your API request.
- Update the API request for transcription in different languages.


### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏


### Run the following Commands in CloudShell (wait till vm is logged into the cloud shell then run 2nd command)
```bash
export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```

```
curl -LO https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Using%20the%20Google%20Cloud%20Speech%20API%3A%20Challenge%20Lab/abhishek.sh
sudo chmod +x abhishek.sh
./abhishek.sh
```
### Congratulations !!!!

<div style="text-align: center; display: flex; flex-direction: column; align-items: center; gap: 20px;">
  <p>Connect with fellow cloud enthusiasts, ask questions, and share your learning journey.</p>  

  <a href="https://t.me/+gBcgRTlZLyM4OGI1" target="_blank">
    <img src="https://img.shields.io/badge/Telegram_Group-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram">
  </a>

  <a href="https://www.youtube.com/@drabhishek.5460?sub_confirmation=1" target="_blank">
    <img src="https://img.shields.io/badge/Subscribe-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube">
  </a>

  <a href="https://www.instagram.com/drabhishek.5460/" target="_blank">
    <img src="https://img.shields.io/badge/Follow-%23E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram">
  </a>
</div>
