# OscarAICoder.jl

A Julia package that translates English mathematical statements into Oscar code using various LLM backends.

## Features
- `process_statement(statement::String; backend=:local)` — converts English math statements to Oscar code.
- Multiple backend options:
  - Local LLM (default): Connects to a local LLM server (e.g., Ollama)
  - Remote LLM: Connects to a remote Ollama server
  - GitHub-hosted LLM: Uses models hosted in GitHub repositories
  - Hugging Face: Uses Hugging Face's model API
- Built-in dictionary of common mathematical statements
- Configurable dictionary usage modes

## Setup Instructions

### 1. Basic Requirements
- Julia 1.6 or later
- Oscar.jl package
- HTTP.jl and JSON.jl packages

### 2. Setting Up LLM Backends

#### Local LLM Server (Recommended)
1. Install Ollama:
   - Download the setup script:
   ```bash
   wget https://raw.githubusercontent.com/wagh/OscarAICoder.jl/main/setup_ollama.sh
   chmod +x setup_ollama.sh
   ```
   - Run the setup script:
   ```bash
   ./setup_ollama.sh
   ```
   - The script will:
     - Check if Ollama is installed
     - Install Ollama if needed
     - Start the Ollama server
     - Pull the required model (qwen2.5-coder)

2. After installation, the local backend will be ready to use:
   ```julia
   using OscarAICoder
   oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
   ```

#### Remote Ollama Server
1. Ensure you have access to a remote Ollama server
2. Configure the remote backend:
   ```julia
   configure_default_backend(:remote, Dict(
       :url => "http://your-server:11434"
   ))
   ```

#### GitHub-hosted LLM
1. Ensure you have a GitHub account and access to the model repository
2. Configure the GitHub backend:
   ```julia
   configure_default_backend(:github, Dict(
       :repo => "your-username/llm-model",
       :model => "math_model.bin",
       :token => ENV["GITHUB_TOKEN"]
   ))
   ```

#### Hugging Face
1. Get an API key from Hugging Face (https://huggingface.co/settings/tokens)
2. Configure the Hugging Face backend:
   ```julia
   configure_default_backend(:huggingface, Dict(
       :api_key => "your_api_key"
   ))
   ```

### 3. Additional Configuration

#### Dictionary Mode
The package uses a built-in dictionary of common mathematical statements. You can configure how it uses this dictionary:

```julia
# Try dictionary first, then LLM (default)
configure_dictionary_mode(:priority)

# Use dictionary only (no LLM)
configure_dictionary_mode(:only)

# Disable dictionary (always use LLM)
configure_dictionary_mode(:disabled)
```

## Usage Examples

### Basic Usage
```julia
using OscarAICoder

# Process a simple statement
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

### Advanced Usage

#### Switching Backends
```julia
# Configure and use different backends
configure_default_backend(:huggingface, Dict(:api_key => "your_api_key"))
oscar_code = process_statement("Find all prime numbers less than 20.")
```

### Using a GitHub-hosted LLM
```julia
# Configure GitHub backend
configure_default_backend(:github, Dict(
    :repo => "owner/repo",          # Repository containing the model
    :model => "model.bin",          # Model file name
    :token => "github_token",       # GitHub personal access token
    :branch => "main"              # Optional, defaults to "main"
))
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

### Using the Hugging Face Backend
1. Get a free [Hugging Face API key](https://huggingface.co/settings/tokens)
2. Configure the backend:
```julia
configure_default_backend(:huggingface, Dict(
    :api_key => "hf_yourapikey",
    :endpoint => "optional_model_endpoint"  # Optional
))
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

## Dictionary Usage
The package includes a built-in dictionary of common mathematical statements. You can configure how it's used:

```julia
# Use only the dictionary (error if statement not found)
configure_dictionary_mode(:only)

# Never use dictionary (always use LLM)
configure_dictionary_mode(:disabled)

# Try dictionary first, then LLM (default)
configure_dictionary_mode(:priority)
```

## Setting up a Local LLM Environment

### Using Ollama (Recommended)

1. Install Ollama:
   - Linux: `curl https://ollama.ai/install.sh | sh`
   - macOS: `brew install ollama`
   - Windows: Download from [Ollama website](https://ollama.ai/download)

2. Pull a model:
   ```bash
   # Pull Mistral (recommended for mathematical tasks)
   ollama pull mistral
   
   # Other options:
   # ollama pull llama2
   # ollama pull code-llama
   ```

3. Start the Ollama server:
   ```bash
   ollama serve
   ```
   The server will run on `http://localhost:11434` by default.

4. Configure OscarAICoder to use Ollama:
   ```julia
   using OscarAICoder
   configure_default_backend(:local)
   ```

### Using llama.cpp

1. Build and run the llama.cpp server:
   ```bash
   # Clone the repository
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp
   
   # Build the server
   make server
   
   # Run the server
   ./server -m path/to/your/model.bin
   ```

2. Configure OscarAICoder:
   ```julia
   using OscarAICoder
   configure_default_backend(:local, url="http://localhost:8080")  # Default llama.cpp port
   ```

### Using GitHub Repository

1. Create a new GitHub repository to host your LLM models
2. Add your model files to the repository
3. Structure your repository like this:
```
your-repo/
├── models/
│   ├── llama2/          # Model directory
│   │   ├── model.bin    # Model file
│   │   └── config.json  # Model configuration
│   └── mistral/         # Another model
│       └── model.bin
└── README.md
```

4. Configure your GitHub token:
   - Go to GitHub → Settings → Developer Settings → Personal Access Tokens
   - Generate a new token with `repo` access
   - Keep this token secure and never commit it to version control

5. Configure OscarAICoder to use your GitHub-hosted model:
```julia
using OscarAICoder

# Configure GitHub backend
configure_github_backend(
    repo="yourusername/your-repo",  # Your GitHub repository
    token="your_github_token",      # Your GitHub token
    model="llama2",                 # Model name (must match directory name)
    branch="main"                   # Optional, defaults to "main"
)

# Now you can use the process_statement function
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

### Using Hugging Face

1. Get a free Hugging Face API key:
   - Go to [Hugging Face](https://huggingface.co/)
   - Sign up or log in
   - Go to Settings → Access Tokens
   - Click "New token" and generate a token with "Inference" access

2. Configure OscarAICoder:
```julia
using OscarAICoder

# Configure Hugging Face backend
configure_default_backend(:huggingface, 
    api_key="your_hf_api_key",
    model="gpt2"
)
```

## Setting up a GitHub Repository for Your Models

1. Create a new GitHub repository to host your LLM models
2. Add your model files to the repository
3. Structure your repository like this:
```
your-repo/
├── models/
│   ├── llama2/          # Model directory
│   │   ├── model.bin    # Model file
│   │   └── config.json  # Model configuration
│   └── mistral/         # Another model
│       └── model.bin
└── README.md
```

4. Configure your GitHub token:
   - Go to GitHub → Settings → Developer Settings → Personal Access Tokens
   - Generate a new token with `repo` access
   - Keep this token secure and never commit it to version control

5. Configure OscarAICoder to use your GitHub-hosted model:
```julia
using OscarAICoder

# Configure GitHub backend
configure_github_backend(
    repo="yourusername/your-repo",  # Your GitHub repository
    token="your_github_token",      # Your GitHub token
    model="llama2",                 # Model name (must match directory name)
    branch="main"                   # Optional, defaults to "main"
)

# Now you can use the process_statement function
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

## Setting up a Local LLM Server
- [Ollama](https://ollama.com/) (recommended for ease of use):
  1. Install Ollama (see their docs for your OS).
  2. Run `ollama serve` (default port 11434).
  3. Pull a model: `ollama pull mistral`
- [llama.cpp server](https://github.com/ggerganov/llama.cpp):
  1. Build and run the server as per their instructions.

## Configuration
- By default, connects to `http://localhost:11434` (Ollama).
- You can change the endpoint via keyword arguments.

## Extending
- Add new backends in the `src/backends` directory and update `OscarAICoder.jl`.

---

This package is in early development. Contributions welcome!
