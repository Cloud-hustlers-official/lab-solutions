
# Discover and Protect Sensitive Data Across Your Ecosystem: Challenge Lab || [GSP522](https://www.cloudskillsboost.google/focuses/109502?parent=catalog) ||


* Go to **Sensitive Data Protection** from [here](https://console.cloud.google.com/security/sensitive-data-protection/create/discoveryConfiguration;source=DATA_PROFILE_COVERAGE_DASHBOARD;discoveryType=4?project=)

 ### Run the following Commands in CloudShell

```
curl -LO https://raw.githubusercontent.com/Itsabhishek7py/GoogleCloudSkillsboost/refs/heads/main/Discover%20and%20Protect%20Sensitive%20Data%20Across%20Your%20Ecosystem%20Challenge%20Lab/abhishek.sh
sudo chmod +x abhishek.sh
./abhishek.sh
```

 ```
```

```
# Redefine original function to inspect and deidentify output with Sensitive Data Protection
import google.cloud.dlp  
from typing import List 

def deidentify_with_replace_infotype(
    project: str, item: str, info_types: List[str]
) -> None:
    """Uses the Data Loss Prevention API to deidentify sensitive data in a
    string by replacing it with the info type.
    """
    # Instantiate a client
    dlp = google.cloud.dlp_v2.DlpServiceClient()

    # Convert the project id into a full resource id.
    parent = f"projects/{project}"

    # Construct inspect configuration dictionary
    inspect_config = {"info_types": [{"name": info_type} for info_type in info_types]}

    # Construct deidentify configuration dictionary
    deidentify_config = {
        "info_type_transformations": {
            "transformations": [
                {"primitive_transformation": {"replace_with_info_type_config": {}}}
            ]
        }
    }

    # Call the API for deidentify
    response = dlp.deidentify_content(
        request={
            "parent": parent,
            "deidentify_config": deidentify_config,
            "inspect_config": inspect_config,
            "item": {"value": item},
        }
    )

    return_payload = response.item.value
    
    # Add conditional return to block responses containing US Vehicle Identification Numbers (VIN)
    # We add US_VEHICLE_IDENTIFICATION_NUMBER to the inspection list
    check_types = ["DOCUMENT_TYPE/R&D/SOURCE_CODE", "US_VEHICLE_IDENTIFICATION_NUMBER"]
    inspect_config_block = {"info_types": [{"name": t} for t in check_types]}

    response_inspect = dlp.inspect_content(
        request={
            "parent": parent,
            "inspect_config": inspect_config_block,
            "item": {"value": item},
        }
    )

    if response_inspect.result.findings:
        for finding in response_inspect.result.findings:
            if finding.info_type.name == "DOCUMENT_TYPE/R&D/SOURCE_CODE":
                return_payload = '[Blocked due to category: Source Code]'
            elif finding.info_type.name == "US_VEHICLE_IDENTIFICATION_NUMBER":
                return_payload = '[Blocked due to category: US VIN]'
                
    # Print results
    print(return_payload)
```

```
# Create prompt that generates an example response with US Vehicle Identification Number (VIN)
prompt = "Is 4Y1SL65848Z411439 an example of a US Vehicle Identification Number (VIN)?"

# Run model with prompt setting the temperature to 0
from google.genai import types
response_vin = client.models.generate_content(
    model=model,
    contents=prompt,
    config=types.GenerateContentConfig(
        temperature=0.0,
    ),
)

# Print response without blocking it (VIN provided)
print("Original Response:")
print(response_vin.text)

print("\n--- Running DLP Block Guard ---")
# Block model response that includes US Vehicle Identification Number (VIN)
deidentify_with_replace_infotype(
    project=PROJECT_ID, 
    item=response_vin.text, 
    info_types=["US_VEHICLE_IDENTIFICATION_NUMBER"]
)
````


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
