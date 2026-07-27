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
            # This config explicitly tells the Gemini model to return an image
            response_modalities=["IMAGE"],
        )
    )

    # 3. Save the image to the specified output file locally
    for part in response.parts:
        if part.inline_data:
            # part.as_image() converts the raw bytes into a PIL Image object
            generated_image = part.as_image()
            generated_image.save(output_file)
            print(f"Success! Image successfully saved to {output_file}")

# Execute the function using your Qwiklabs details
generate_image(
    project_id='<project id>',
    location='<region>',
    output_file='image.jpeg',
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
)
