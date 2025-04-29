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

## Requirements
- Julia
- Oscar.jl
- HTTP.jl, JSON.jl
- One of the following:
  - **Local/Remote LLM server** (e.g., [Ollama](https://ollama.com/)) running and accessible via HTTP
  - **GitHub account** with access to model repository
  - **Hugging Face API key**

## Usage

### Configuration
First, configure your preferred backend and dictionary mode:

```julia
using OscarAICoder

# Configure dictionary mode
configure_dictionary_mode(:priority)  # Try dictionary first, then LLM
# Other options: :only (dictionary only), :disabled (always use LLM)

# Configure your preferred backend
configure_default_backend(:local)  # Use local Ollama
```

### Using the Local Backend (default)
```julia
# Local Ollama
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

### Using a Remote Ollama Server
```julia
# Configure remote server
configure_default_backend(:remote, Dict(:url => "http://server01.mydomain.net:11434"))
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
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

**Limitations:**
- Free API keys are rate-limited and suitable for research/testing only.
- Requests are sent to external servers; do not use for private or sensitive data.
- Model availability and speed may vary.

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
