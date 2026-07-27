
****add .env file and thier value in task 4 and replcae the all content of agent.py and add this below ****


```

import asyncio
import os
import sys

from dotenv import load_dotenv
from pydantic import BaseModel

from google.adk import Agent
from google.adk.runners import InMemoryRunner
from google.adk.sessions import Session
from google.genai import types

import google.cloud.logging

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from callback_logging import log_query_to_model, log_model_response


# Load environment variables
load_dotenv()

google_cloud_project = os.getenv("GOOGLE_CLOUD_PROJECT")
google_cloud_location = os.getenv("GOOGLE_CLOUD_LOCATION")
google_genai_use_enterprise = os.getenv("GOOGLE_GENAI_USE_ENTERPRISE")
model_name = os.getenv("MODEL", "gemini-3.5-flash")

cloud_logging_client = google.cloud.logging.Client()
cloud_logging_client.setup_logging()


# Required Pydantic schema
class CountryCapital(BaseModel):
    capital: str


async def main():

    app_name = "geo_validator_app"
    user_id_1 = "user1"

    root_agent = Agent(
        model="gemini-3.5-flash",
        name="geo_validator",
        instruction=(
            "You are a geography validator. "
            "Return ONLY the capital city of the requested country. "
            "Do not include explanations."
        ),
        output_schema=CountryCapital,
        disallow_transfer_to_parent=True,
        disallow_transfer_to_peers=True,
        before_model_callback=log_query_to_model,
        after_model_callback=log_model_response,
    )

    runner = InMemoryRunner(
        agent=root_agent,
        app_name=app_name,
    )

    my_session = await runner.session_service.create_session(
        app_name=app_name,
        user_id=user_id_1,
    )

    async def run_prompt(session: Session, new_message: str):
        content = types.Content(
            role="user",
            parts=[types.Part.from_text(text=new_message)],
        )

        print("** User says:", content.model_dump(exclude_none=True))

        async for event in runner.run_async(
            user_id=user_id_1,
            session_id=session.id,
            new_message=content,
        ):
            if event.content.parts and event.content.parts[0].text:
                print(f"** {event.author}: {event.content.parts[0].text}")

        cloud_logging_client.close()

    query = "What is the capital of France?"
    await run_prompt(my_session, query)


if __name__ == "__main__":
    asyncio.run(main())


```


**Create .env file in llm_autitor and  , remove one commented line and add one value in sub agent in reversive_agnet and save and run******


