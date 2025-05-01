#!/bin/bash
# Script to check Ollama server availability and pull the mistral model

set -e

# Configuration
# OLLAMA_SERVER="http://server01.mydomain.net:11434"
OLLAMA_SERVER="http://localhost:11434"

# Check if Ollama server is accessible
echo "Checking Ollama server at $OLLAMA_SERVER..."
if python3 -c "import requests
try:
    response = requests.get('$OLLAMA_SERVER/api/version')
    response.raise_for_status()
    print('Successfully connected to Ollama server at $OLLAMA_SERVER')
except requests.exceptions.RequestException as e:
    print(f'Error: Cannot connect to Ollama server at $OLLAMA_SERVER')
    print('Please ensure:')
    print('1. The server is running and accessible')
    print('2. Port 11434 is open on the server')
    print('3. Network connectivity is available')
    exit(1)"; then
    :
else
    exit 1
fi

# Pull the llama3.3 model
echo "Pulling llama3.3 model from remote server..."
python3 -c "import requests
response = requests.post('$OLLAMA_SERVER/api/pull', json={'name': 'llama3.3'})
response.raise_for_status()
print('Successfully pulled llama3.3 model')"
echo "Setup complete!"
