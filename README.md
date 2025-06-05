# OscarAICoder.jl

A Julia package that translates English mathematical statements into Oscar code using various LLM backends.

## Quick Start

There are two ways to install OscarAICoder.jl:

### 1. Project Environment Installation (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/wagh/OscarAICoder.jl.git
```

2. Navigate to the project directory:
```bash
cd OscarAICoder.jl
```

3. Install the package and its dependencies (only needed once):
```julia
import Pkg
Pkg.develop(path=".")  # Register the package in the project environment
Pkg.instantiate()  # Install all dependencies (only needed once)
```

4. In any new Julia session:
```julia
import Pkg
Pkg.activate(".")  # Activate the project environment
using OscarAICoder
```

### 2. Global Installation (Not Recommended)

If you want to use `using OscarAICoder` directly without activating any environment:

1. Clone the repository:
```bash
git clone https://github.com/wagh/OscarAICoder.jl.git
```

2. Navigate to the project directory:
```bash
cd OscarAICoder.jl
```

3. Install globally (only run once):
```julia
import Pkg
Pkg.add(path=".")
Pkg.instantiate()
```

4. In any new Julia session:
```julia
using OscarAICoder
```

### Why Project Environment Installation is Recommended
Project environment installation is the recommended approach because:
- It prevents dependency conflicts with other packages
- It ensures consistent behavior across different projects
- It makes it easier to manage different versions of the package
- It follows Julia's best practices for package development
- It's easier for others to use your package with the exact same dependencies

### Why Global Installation is Not Recommended
Global installation is not recommended because:
- It can cause dependency conflicts with other packages
- It makes it harder to manage different versions of the package
- It can interfere with package development
- It can make it harder to ensure consistent behavior across different systems
- It can make maintenance more difficult

### Troubleshooting Installation Issues
If you encounter any installation issues, try these steps:
1. Ensure you have the correct permissions to access the package directory
2. Check that all required dependencies are installed
3. Run `Pkg.status()` to verify the package installation
4. If needed, run `Pkg.build("OscarAICoder")` to build the package
5. Try `Pkg.precompile()` to force precompilation

If you still encounter errors, please check that:
- All source files are present in the `src` directory
- The main package file `src/OscarAICoder.jl` exists and is properly structured
- All required dependencies are installed correctly

### Note about Pkg.develop()
The `Pkg.develop()` command is not needed when you're working directly in the package's directory. It's only used when you want to develop a package from a different location. Since we're already in the package's directory, we can skip this step.

4. After installation, in any new Julia session, you need to:
```julia
import Pkg
Pkg.activate(".")  # Activate the project environment
using OscarAICoder
```

### Why do I need to activate the project environment every time?
This is because the package is not registered in the Julia General registry. When you start a new Julia session, it doesn't know about your local package unless you activate its environment.

If you want to use `using OscarAICoder` directly without activating the project environment, you have two options:

1. **Recommended Approach** (current approach):
   - Continue using `Pkg.activate(".")` before using the package
   - This ensures consistent dependencies and prevents conflicts with other packages
   - Best practice for package development and maintenance

2. **Alternative Approach** (not recommended):
   ```julia
   import Pkg
   Pkg.develop(path="/path/to/OscarAICoder")  # Only run once
   ```
   After this, you can use `using OscarAICoder` directly in any Julia session.
   However, this approach is not recommended because:
   - It can cause dependency conflicts with other packages
   - It makes the package harder to maintain
   - It doesn't ensure consistent behavior across different systems
   - It's harder for others to use your package with the exact same dependencies

### Troubleshooting Precompilation Errors
If you encounter precompilation errors, try these steps:
1. Ensure you're in the project directory
2. Run `Pkg.develop(path=".")` to properly link the package sources
3. If needed, run `Pkg.build("OscarAICoder")` to build the package
4. Finally, try `Pkg.precompile()` to force precompilation

If you still encounter errors, please check that:
- All source files are present in the `src` directory
- The main package file `src/OscarAICoder.jl` exists and is properly structured
- All required dependencies are installed

### Why do I need to use Pkg.activate(".")?
Since this package is not registered in the Julia General registry, we need to use a project environment to manage its dependencies. This ensures consistent behavior across different systems. The project environment approach is actually a good practice because it:
- Ensures reproducible builds
- Manages specific package versions
- Prevents dependency conflicts with other packages
- Makes it easy for others to use the package with the exact same dependencies

If you prefer not to use the project environment, you can install the package globally by:
```julia
import Pkg
Pkg.develop(path=".")
```
But this approach is not recommended as it can lead to dependency conflicts with other packages.

# Process a mathematical statement
oscar_code = process_statement("Find the roots of x^2 - 4x + 4")

# Execute the generated code
result = execute_statement(oscar_code)
```

## Installation

### Basic Requirements
- Julia 1.6 or later
- Oscar.jl package
- HTTP.jl and JSON.jl packages

### Setting Up LLM Backends

#### Local LLM Server (Recommended)
1. Install Ollama:
```bash
wget https://raw.githubusercontent.com/wagh/OscarAICoder.jl/main/setup_ollama.sh
chmod +x setup_ollama.sh
./setup_ollama.sh
```

2. After installation:
```julia
using OscarAICoder
oscar_code = process_statement("Factor the polynomial x^2 - 5x + 6 over the integers.")
```

## Main Functions

### `process_statement(statement::String; kwargs...)`
- Converts English math statements to Oscar code
- Supports multiple backends (LOCAL, REMOTE, HUGGINGFACE, GITHUB)
- Can use context/history for better results

### `execute_statement(oscar_code::String; kwargs...)`
- Executes Oscar code and returns results
- Handles context management

### `execute_all_statements()`
- Executes the most recent statement from history

## Advanced Features

- Dictionary mode for faster processing of common statements
- Debug mode for detailed logging
- Multiple backend support
- History management
- Code validation

## Documentation

For detailed documentation, including:
- Mathematical examples
- Advanced usage
- Configuration options
- Error handling
- Validation rules
- Backend-specific configurations

Please refer to the [full manual](doc/manual.pdf) (PDF format).

## Support

For issues and support, please check the documentation or open an issue on the repository.

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

#### Context Management

```julia
using OscarAICoder

# Process statements with context
process_statement("Define a polynomial ring R with variables x, y, z", clear_context=true)
process_statement("Now define an ideal I = (x^2, y^2)")

# View current context
get_context()

# Save context to a file (uses timestamp for filename if none provided)
save_path = save_context()

# Later, load the context back
load_context(save_path)

# Or load with a specific name
save_context("my_workspace.json")
load_context("my_workspace.json")

# Change the save directory
set_save_dir("/path/to/save/directory")
```

#### Basic Code Generation

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
