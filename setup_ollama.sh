#!/bin/bash
# Script to check Ollama server availability and pull the mistral model

set -e

# Configuration
OLLAMA_SERVER="http://server01.mydomain.net:11434"

# Check if Ollama server is accessible
echo "Checking Ollama server at $OLLAMA_SERVER..."
if curl -s -f "$OLLAMA_SERVER/api/version" > /dev/null; then
    echo "Successfully connected to Ollama server at $OLLAMA_SERVER"
else
    echo "Error: Cannot connect to Ollama server at $OLLAMA_SERVER"
    echo "Please ensure:"
    echo "1. The server is running and accessible"
    echo "2. Port 11434 is open on the server"
    echo "3. Network connectivity is available"
    exit 1
fi

# Pull the mistral model
echo "Pulling mistral model from remote server..."
curl -X POST "$OLLAMA_SERVER/api/pull" -d '{"name": "mistral"}'
echo "Setup complete!"
