# Task 1 
```
Update the zone if mentioned 


if error change from enterprise to vertexai
```

### Task 2. Execute code with Gemini ###
In this task, you'll use the Gemini 2.5 Flash to write and execute Python code to perform a simple data analysis task, such as calculating the average price of a list of basketball sneakers.
 ### Generate and Execute Code using Gemini 2.5 Flash ###
 #### 1. Define the code execution tool
# Task 2

```
Code == Tool(code_execution=ToolCodeExecution())


```
 #### 2. Define the prompt with the code to be executed
 ```bash
Remove the prompt = f"""what is the average price of sneakers in {sneaker_prices}
Generate and run code for the calculation."""
```

### Task 3. Grounding with Google Search
##### In this task, you'll use Gemini 2.5 Flash with grounding to enhance the accuracy and relevance of Gemini's responses to questions about retail products.

##### 1. Define the Google Search tool
```bash
google_search_tool = Tool(google_search=GoogleSearch())
```

##### 2. Define the prompt with grounding
``` bash
prompt = "Find key features and price information for Nike Air Jordan XXXVI."
```
##### 3. Generate a response with grounding
```bash
response = client.models.generate_content(
    model=MODEL_ID,
    contents=prompt,
    config= GenerateContentConfig(
        tools=[google_search_tool],
        temperature=0
    ),
)

# Print the response
print(response.text)
```


# Task 4
```
Query remove the starting lines add -- f"{model} price at {retailer}" ""
response_schema=response_schema,
```
