from google import genai
from google.genai import types

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
):
    """Generate an image using a text prompt via the new GenAI SDK."""

    # 1. Initialize the GenAI Client for Vertex AI
    client = genai.Client(
        vertexai=True,
        project=project_id,
        location=location
    )

    # 2. Invoke the Gemini 2.5 Flash Image model using generate_content
    response = client.models.generate_content(
        model="gemini-2.5-flash-image",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE"],
        )
    )

    # 3. Save the image to the specified output file locally
    for part in response.parts:
        if part.inline_data:
            generated_image = part.as_image()
            generated_image.save(output_file)
            print(f"Success! Image successfully saved to {output_file}")

# ==============================================================================
# EDIT THESE VARIABLES BEFORE RUNNING
# ==============================================================================
PROJECT_ID = 'Project id'  # <-- UPDATE to current Project ID
REGION = 'region'                          # <-- UPDATE to current Region

generate_image(
    project_id=PROJECT_ID,
    location=REGION,
    output_file='image.jpeg',
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
)
