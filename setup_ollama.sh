#!/bin/bash
# Script to check Ollama server availability and pull the mistral model

set -e

# Configuration
OLLAMA_SERVER="http://localhost:11434"
MODEL="qwen2.5-coder"
OLLAMA_BINARY="ollama"

# Function to check if Ollama is installed
check_ollama_installed() {
    if ! command -v $OLLAMA_BINARY &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to check if Ollama server is running
check_ollama_running() {
    if ! curl -s $OLLAMA_SERVER/api/version &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to install Ollama
install_ollama() {
    echo "Installing Ollama..."
    if [ "$(uname)" == "Linux" ]; then
        wget https://ollama.ai/download/ollama-linux-amd64 -O /tmp/ollama
        chmod +x /tmp/ollama
        sudo mv /tmp/ollama /usr/local/bin/
    else
        echo "Unsupported OS. Please install Ollama manually from https://ollama.ai/download"
        exit 1
    fi
}

# Main script logic
echo "Checking Ollama server at $OLLAMA_SERVER..."

# Check if server is running
if check_ollama_running; then
    echo "Ollama server is running."
    # Pull the model
    echo "Pulling $MODEL model from remote server..."
    if ! curl -s -X POST $OLLAMA_SERVER/api/pull -H "Content-Type: application/json" -d "{"name": "$MODEL"}" &> /dev/null; then
        echo "Failed to pull $MODEL model."
        exit 1
    fi
    echo "Successfully pulled $MODEL model."
    exit 0
fi

# Server not running, check if installed
if ! check_ollama_installed; then
    echo "Ollama is not installed."
    read -p "Would you like to install Ollama? (y/n): " choice
    case "$choice" in
        y|Y ) install_ollama
              ;;
        n|N ) echo "Exiting. Please install Ollama manually."
             exit 1
             ;;
        * ) echo "Invalid input. Exiting."
            exit 1
            ;;
    esac
fi

# Start Ollama server
echo "Starting Ollama server..."
$OLLAMA_BINARY serve &

# Wait for server to start
sleep 5

# Check if server started successfully
if check_ollama_running; then
    echo "Ollama server started successfully."
    # Pull the model
    echo "Pulling $MODEL model from remote server..."
    if ! curl -s -X POST $OLLAMA_SERVER/api/pull -H "Content-Type: application/json" -d "{"name": "$MODEL"}" &> /dev/null; then
        echo "Failed to pull $MODEL model."
        exit 1
    fi
    echo "Successfully pulled $MODEL model."
else
    echo "Failed to start Ollama server."
    exit 1
fi
echo "Setup complete!"
