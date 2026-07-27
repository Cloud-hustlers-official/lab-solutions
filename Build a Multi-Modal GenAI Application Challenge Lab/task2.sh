import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image

def analyze_bouquet_image(image_path: str, project_id: str, location: str):
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    
    # Load the model
    model = GenerativeModel("gemini-2.5-flash")
    
    # Load the image generated in Task 1
    image_part = Part.from_image(Image.load_from_file(image_path))
    
    # Define the prompt
    prompt = "Write beautiful birthday wishes inspired by this bouquet image."
    
    print("Generating birthday wishes...\n")
    
    # Enable streaming on the prompt request
    response_stream = model.generate_content(
        [image_part, prompt],
        stream=True
    )
    
    # Capture the streamed output
    full_response = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    print("\n")
    
    # Save the complete generated message into a .txt file
    output_filename = "birthday_wishes.txt"
    with open(output_filename, "w") as file:
        file.write(full_response)
        
    print(f"Success! Birthday wishes saved to {output_filename}")


# ==============================================================================
# EDIT THESE VARIABLES BEFORE RUNNING
# ==============================================================================
PROJECT_ID = 'Project id'  # <-- UPDATE to current Project ID
REGION = 'region'                          # <-- UPDATE to current Region
IMAGE_FILE = '/home/student/image.jpeg'      # <-- Must match output from Task 1

analyze_bouquet_image(IMAGE_FILE, PROJECT_ID, REGION)
