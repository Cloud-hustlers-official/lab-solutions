
# Build Global and Regional Load Balancing Solutions: Challenge Lab

[![Watch on YouTube](https://img.shields.io/badge/Watch_on_YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/)

> **Note:** Establish Hybrid Network Connectivity with NCC

---
### 🤝 Support
If you found this helpful, please **Subscribe** to [Cloud Hustlers](https://www.youtube.com/@CloudHustlers/videos) for more Google Cloud solutions!


### ⚠️ Disclaimer
- **This script and guide are provided for  the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services. Ensure that you follow 'Qwiklabs' terms of service and YouTube’s community guidelines. The goal is to enhance your learning experience, not to bypass it.**

### ©Credit
- **DM for credit or removal request (no copyright intended) ©All rights and credits for the original content belong to Google Cloud [Google Cloud Skill Boost website](https://www.cloudskillsboost.google/)** 🙏

## Task 1: ek bina md file wala aur ek chatgpt se  thumbnail copy krne wala banda isko copy karega aur bolega github nahi use krna (not for subscribers)

### 1. Create Regional MIG

Go to:
Compute Engine → Instance Groups → Create Instance Group

Create:
- Name: mig-proxy-internal
- Template: template-proxy-internal
- Region: Region B

Add Named Port:
- tcp80 → 80

---

### 2. Create Firewall Rules

Go to:
VPC Network → Firewall

Create:

Rule 1:
```
gcloud compute firewall-rules create fw-allow-hc-proxy-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```

Rule 2:
```
gcloud compute firewall-rules create fw-allow-proxy-subnet-internal \
  --network=lb-network \
  --action=ALLOW \
  --direction=INGRESS \
  --source-ranges=10.129.0.0/23 \
  --target-tags=tag-proxy-internal \
  --rules=tcp:80
```
---

### 3. Create Health Check
```
read -p "Enter REGION_A: " REGION_A
read -p "Enter REGION_B: " REGION_B

echo "export REGION_A=$REGION_A" >> ~/.bashrc
echo "export REGION_B=$REGION_B" >> ~/.bashrc

source ~/.bashrc

gcloud compute health-checks create tcp hc-internal-proxy \
    --region=$REGION_B \
    --port=80
```
---

### 4. Reserve Internal Static IP

Go to:
VPC Network → IP Addresses → Reserve Internal

Create:
- Name: ip-internal-proxy
- Region: Region B
- Network: lb-network
- Subnet: lb-backend-subnet-region-b
- Purpose: Shared Load Balancer VIP

---

### 5. Create Regional Internal Proxy Network Load Balancer

```
gcloud compute backend-services create internal-proxy-backend \
    --load-balancing-scheme=INTERNAL_MANAGED \
    --protocol=TCP \
    --region=$REGION_B \
    --health-checks=hc-internal-proxy \
    --health-checks-region=$REGION_B

gcloud compute backend-services add-backend internal-proxy-backend \
    --instance-group=mig-proxy-internal \
    --instance-group-region=$REGION_B \
    --region=$REGION_B
```
Frontend:
- Name: rule-internal-proxy
- IP Address: ip-internal-proxy
- Protocol: TCP
- Port: 110
- Global Access: Disabled

Create the Load Balancer.
---

### 6. Create Client VM
```
gcloud compute instances create vm-client-internal \
   --zone=${REGION_B}-b \
   --machine-type=e2-micro \
   --network=lb-network \
   --subnet=lb-backend-subnet-region-b \
   --tags=allow-ssh
```
---

### 7. Validate Access

SSH into vm-client-internal

Test:
```
# Get Internal LB IP
LB_IP=$(gcloud compute addresses describe ip-internal-proxy \
    --region=$REGION_B \
    --format="value(address)")

echo $LB_IP
```
Run in SSH
```
curl http://[LB_IP]:110
```
```bash
curl -LO https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Build%20Global%20and%20Regional%20Load%20Balancing%20Solutions%3A%20Challenge%20Lab/GSP539.sh
sudo chmod +x GSP539.sh
./GSP539.sh
```
```
curl -LO https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Build%20Global%20and%20Regional%20Load%20Balancing%20Solutions%3A%20Challenge%20Lab/1GSP539.sh
sudo chmod +x 1GSP539.sh
./1GSP539.sh
```
```
curl http://[LB_IP]:110
```
Then click:
Check my progress → Create a regional internal proxy NLB



<div align="center">

<h3 style="font-family: 'Segoe UI', sans-serif; color: linear-gradient(90deg, #4F46E5, #E114E5);">🌟 Connect with Cloud Enthusiasts 🌟</h3>
<p style="font-family: 'Segoe UI', sans-serif;">Join the community, share knowledge, and grow together!</p>

<a href="https://t.me/Cloud_Hustlers" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Join_Telegram_Channel-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white&labelColor=2CA5E0" alt="Telegram Channel"/>
</a>

<a href="https://t.me/Cloud_Hustlers" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Join_Telegram_Group-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white&labelColor=2CA5E0" alt="Telegram Group"/>
</a>

<a href="https://whatsapp.cloudhustlers.in" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Join_WhatsApp_Channel-25D366?style=for-the-badge&logo=whatsapp&logoColor=white&labelColor=25D366" alt="WhatsApp Channel"/>
</a>

<a href="https://www.youtube.com/@CloudHustlers?sub_confirmation=1" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Subscribe_YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white&labelColor=FF0000" alt="YouTube"/>
</a>

<a href="https://instagram.com/cloud_hustlers/" target="_blank" style="text-decoration: none;">
  <img src="https://img.shields.io/badge/-Follow_Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white&labelColor=E4405F" alt="Instagram"/>
</a>



</div>
