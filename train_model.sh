#!/bin/bash

# Configuration
export OLLAMA_SERVER="http://localhost:11434"
export MODEL_NAME="qwen2.5-coder"
export FINE_TUNED_MODEL_NAME="oscar-coder"

# Convert dictionary to training format
echo "Converting dictionary to training format..."
# Use Julia to read the dictionary and convert it to JSON
julia << 'END'
using Pkg
Pkg.add("JSON")
using JSON

# Read the dictionary from the file
include("src/seed_dictionary.jl")

# Convert dictionary entries to input/output pairs
examples = []
for (input, output) in SeedDictionary.SEED_DICTIONARY
    push!(examples, Dict("input" => input, "output" => output))
end

# Convert to JSON format
json_data = JSON.json(examples)

# Write to file
write("training_data.json", json_data)

println("Created training_data.json with ", length(examples), " examples")
END

# Check if training data was created
echo "Checking training data..."
if [ ! -f "training_data.json" ]; then
    echo "Error: Failed to create training data"
    exit 1
fi

# Start fine-tuning
echo "Starting fine-tuning process..."
python3 << END
import requests
import json
import os
from datetime import datetime

# Read training data
with open('training_data.json', 'r') as f:
    training_data = json.load(f)

# Get environment variables
OLLAMA_SERVER = os.environ.get('OLLAMA_SERVER')
FINE_TUNED_MODEL_NAME = os.environ.get('FINE_TUNED_MODEL_NAME')
MODEL_NAME = os.environ.get('MODEL_NAME')

if not all([OLLAMA_SERVER, FINE_TUNED_MODEL_NAME, MODEL_NAME]):
    print("Error: Missing required environment variables")
    exit(1)

# First, check if the base model exists
print(f"Checking if base model {MODEL_NAME} exists...")
try:
    # Check available models
    models_response = requests.get(f"{OLLAMA_SERVER}/api/tags")
    models_response.raise_for_status()
    models = models_response.json()
    
    # Check if our base model is available
    if MODEL_NAME not in models:
        print(f"Base model {MODEL_NAME} not found. Attempting to pull it...")
        pull_response = requests.post(f"{OLLAMA_SERVER}/api/pull", json={"name": MODEL_NAME})
        pull_response.raise_for_status()
        print(f"Successfully pulled base model {MODEL_NAME}")
    else:
        print(f"Base model {MODEL_NAME} already exists")

except requests.exceptions.RequestException as e:
    print(f"Error checking or pulling base model: {e}")
    print("\nAvailable models:")
    try:
        models_response = requests.get(f"{OLLAMA_SERVER}/api/tags")
        models_response.raise_for_status()
        models = models_response.json()
        for model in models:
            print(f"- {model}")
    except requests.exceptions.RequestException as e:
        print(f"Error fetching available models: {e}")
    exit(1)

# Prepare fine-tuning request
request_data = {
    "name": FINE_TUNED_MODEL_NAME,
    "base": MODEL_NAME,
    "system": "You are an expert Oscar programmer. Given a mathematical statement in English, generate idiomatic Oscar code using the Oscar.jl package.",
    "fine_tune": {
        "data": training_data
    }
}

try:
    # Create the model
    create_response = requests.post(
        f"{OLLAMA_SERVER}/api/create",
        json={
            "name": FINE_TUNED_MODEL_NAME,
            "base": MODEL_NAME,
            "system": "You are an expert Oscar programmer. Given a mathematical statement in English, generate idiomatic Oscar code using the Oscar.jl package.",
            "fine_tune": {
                "data": training_data
            }
        }
    )
    create_response.raise_for_status()
    
    print("Model creation initiated successfully")
    
    # Get the model status
    ready = False
    while not ready:
        status_response = requests.get(f"{OLLAMA_SERVER}/api/tags")
        status_response.raise_for_status()
        
        # Print raw response for debugging
        print("\nDebug: API Response:")
        print(status_response.text)
        
        try:
            response_data = status_response.json()
            print("\nDebug: Parsed JSON:")
            print(json.dumps(response_data, indent=2))
            
            # Get the list of models from the response
            models = response_data.get("models", [])
            
            # Check if our model is ready
            for model in models:
                if model["name"] == FINE_TUNED_MODEL_NAME:
                    print(f"Model status: ready")
                    print("Fine-tuning completed successfully!")
                    print(f"Fine-tuned model saved as: {FINE_TUNED_MODEL_NAME}")
                    ready = True
                    break
            else:
                print(f"Model status: training (as of {datetime.now().strftime('%Y-%m-%d %H:%M:%S')})")
                import time
                time.sleep(30)  # Check every 30 seconds
                continue
            
            if ready:
                break
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON: {e}")
            print("Raw response:", status_response.text)
            exit(1)
        except TypeError as e:
            print(f"Error processing model data: {e}")
            print("Raw data type:", type(response_data))
            print("Raw data:", response_data)
            exit(1)

except requests.exceptions.RequestException as e:
    print(f"Error during fine-tuning process: {e}")
    print("\nNote: Make sure the model name is unique and the base model exists")
    exit(1)

except requests.exceptions.RequestException as e:
    print(f"Error during fine-tuning process: {e}")
    print("\nNote: Make sure the model name is unique and the base model exists")
    exit(1)
END

# Update the model name in the configuration
echo "Updating configuration to use fine-tuned model..."
python3 << END
import json
import os

# Get environment variables
FINE_TUNED_MODEL_NAME = os.environ.get('FINE_TUNED_MODEL_NAME')

if not FINE_TUNED_MODEL_NAME:
    print("Error: FINE_TUNED_MODEL_NAME environment variable not set")
    exit(1)

# Update the configuration
with open('src/OscarAICoder.jl', 'r') as f:
    content = f.read()

# Update the default model
content = content.replace('const DEFAULT_MODEL = "llama3.3"', 
                         f'const DEFAULT_MODEL = "{FINE_TUNED_MODEL_NAME}"')

# Update the local backend settings
content = content.replace(':model => "llama3.3"', 
                         f':model => "{FINE_TUNED_MODEL_NAME}"')

with open('src/OscarAICoder.jl', 'w') as f:
    f.write(content)

print("Updated configuration to use fine-tuned model")
END

# Clean up
echo "Cleaning up temporary files..."
rm training_data.json

# Restart the application to use the new model
echo "Restarting the application..."
# Add any necessary restart commands here

echo "Fine-tuning complete! The application is now using the fine-tuned model."
