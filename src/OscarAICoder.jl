module OscarAICoder

export process_statement, configure_default_backend, configure_dictionary_mode, configure_github_backend, execute_statement, execute_statement_with_format, debug_mode!, debug_mode

include("utils.jl")
include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")
include("seed_dictionary.jl")
include("execute.jl")

# Global configuration
const CONFIG = Dict{Symbol, Any}(
    :default_backend => :local,
    :backend_settings => Dict{Symbol, Dict{Symbol, Any}}(
        :local => Dict(
            :url => "http://localhost:11434/api/generate",
            :model => "oscar-coder",  # Available models: qwen2.5, qwen2.5-coder, oscar-coder
            :model_choices => [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        ),  # Local Ollama instance
        :remote => Dict(
            :url => "http://myserver.mydomain.net:11434",
            :model => "qwen2.5-coder",  # Available models: qwen2.5, qwen2.5-coder
            :model_choices => [:qwen2_5, :qwen2_5_coder]
        ),  # Remote server
        :huggingface => Dict(
            :api_key => nothing,
            :model => "gpt2",  # Available models: qwen2.5, qwen2.5-coder
            :model_choices => [:qwen2_5, :qwen2_5_coder]
            :endpoint => "https://api-inference.huggingface.co/models"
        ),
        :github => Dict(
            :repo => "username/repo",
            :model => "llama2",
            :token => nothing,
            :branch => "main",
            :api_url => "https://api.github.com",
            :raw_url => "https://raw.githubusercontent.com"
        )
    ),
    :dictionary_mode => :priority,  # :priority, :only, :disabled
    :offline_mode => false,         # When true, only use dictionary
    :debug_mode => false            # When true, enable debug output
)

"""
    debug_mode!(enabled::Bool)

Enable or disable debug mode. When debug mode is enabled, detailed debug information
will be printed to the console during operations.
"""

"""
    debug_mode()

Check if debug mode is currently enabled.
Returns: Bool indicating whether debug mode is enabled.
"""

"""
    configure_offline_mode(enabled::Bool)

Enable or disable offline mode. In offline mode, only the local dictionary is used.
Any attempt to use LLM backends will result in an error.
"""

function debug_mode!(enabled::Bool)
    """
    Enable or disable debug mode. When debug mode is enabled, detailed debug information
    will be printed to the console during operations.
    """
    CONFIG[:debug_mode] = enabled
end

function debug_mode()
    """
    Check if debug mode is currently enabled.
    Returns: Bool indicating whether debug mode is enabled.
    """
    return CONFIG[:debug_mode]
end



function configure_offline_mode(enabled::Bool)
    CONFIG[:offline_mode] = enabled
end

"""
    configure_dictionary_mode(mode::Symbol)

Configure how the seed dictionary is used. Available modes:
- :priority (default) - Try dictionary first, fall back to LLM if not found
- :only - Use only the dictionary, error if statement not found
- :disabled - Never use the dictionary, always use LLM

Example:
```julia
configure_dictionary_mode(:only)  # Use only the dictionary
configure_dictionary_mode(:disabled)  # Always use LLM
```
"""
function configure_dictionary_mode(mode::Symbol)
    if !(mode in [:priority, :only, :disabled])
        error("Unknown dictionary mode: $mode. Available modes: :priority, :only, :disabled")
    end
    CONFIG[:dictionary_mode] = mode
end

"""
    configure_default_backend(backend::Symbol; kwargs...)

Configure the default LLM backend to use. Available backends:
- :local - Local Ollama instance
- :remote - Remote server instance
- :huggingface - HuggingFace API
- :github - GitHub hosted model

Keyword arguments specific to each backend:
- :local/:remote: url="http://localhost:11434"
- :huggingface: api_key="your_key", model="gpt2"
- :github: repo="username/repo", token="github_token", model="llama2"

Example:
```julia
configure_default_backend(:huggingface, api_key="your_key", model="gpt2")
configure_default_backend(:github, repo="username/repo", token="github_token")
```
"""
function configure_default_backend(backend::Symbol; kwargs...)
    if !(backend in [:local, :remote, :huggingface, :github])
        error("Unknown backend: $backend. Available backends: :local, :remote, :huggingface, :github")
    end
    
    # Update settings for the specified backend
    backend_settings = CONFIG[:backend_settings][backend]
    for (key, value) in kwargs
        if haskey(backend_settings, key)
            backend_settings[key] = value
        else
            error("Invalid keyword argument '$key' for backend $backend")
        end
    end
    
    CONFIG[:default_backend] = backend
end

"""
    configure_github_backend(; kwargs...)

Configure the GitHub backend specifically. This is a convenience function that
sets up the GitHub backend with the provided settings.

Keyword arguments:
- repo: GitHub repository path (e.g., "username/repo")
- token: GitHub personal access token
- model: Model name to use
- branch: Repository branch (default: "main")
- api_url: GitHub API URL (default: "https://api.github.com")
- raw_url: GitHub raw content URL (default: "https://raw.githubusercontent.com")

Example:
```julia
# Configure model selection
configure_backend(
    :local,
    model = :qwen2_5_coder  # Available models: qwen2.5, qwen2.5-coder, oscar-coder
)

# Configure model selection
configure_backend(
    :remote,
    model = :qwen2_5  # Available models: qwen2.5, qwen2.5-coder
)

# Configure model selection
configure_backend(
    :huggingface,
    model = :qwen2_5_coder  # Available models: qwen2.5, qwen2.5-coder
)

# Configure GitHub backend
    repo="username/repo",
    token="github_token",
    model="llama2",
    branch="main"
)
```
"""
function configure_github_backend(; kwargs...)
    github_settings = CONFIG[:backend_settings][:github]
    for (key, value) in kwargs
        if haskey(github_settings, key)
            github_settings[key] = value
        else
            error("Invalid keyword argument '$key' for GitHub backend")
        end
    end
end

"""
    process_statement(statement::String; backend=nothing, kwargs...)

Process an English mathematical statement and return Oscar code.
Options:
- backend: :local, :remote, :huggingface, or :github (defaults to configured default_backend)
- kwargs: passed to backend

The default backend can be configured using configure_default_backend().
Dictionary usage can be configured using configure_dictionary_mode().
"""
function process_statement(statement::String; backend=nothing, kwargs...)
    # Check offline mode first
    if CONFIG[:offline_mode] && !haskey(SEED_DICTIONARY, statement)
        error("Statement not found in dictionary and offline mode is enabled")
    end

    # If statement is in dictionary, use it directly
    for entry in values(SEED_DICTIONARY)
        if entry["input"] == statement
            return entry["output"]
        end
    end

    # Read the prompt template
    template = read("prompt_template.txt", String)
    
    # Replace the placeholders with actual content
    prompt = replace(template, "[USER_INPUT]" => statement)
    prompt = replace(prompt, "[OSCAR_CODE]" => "")  # This will be filled by the model
    
    # Get the current backend settings
    backend = CONFIG[:default_backend]
    settings = CONFIG[:backend_settings][backend]
    
    # Make the API request
    response = HTTP.post(
        settings[:url],
        [
            "Content-Type" => "application/json"
        ],
        JSON3.write(Dict(
            "model" => settings[:model],
            "prompt" => prompt,
            "stream" => false
        ))
    )
    
    # Parse the response
    result = JSON3.read(String(response.body))
    return result["response"]
        result = GitHub.process_statement_github(statement; repo=settings[:repo], model=settings[:model], token=settings[:token], branch=settings[:branch], api_url=settings[:api_url], raw_url=settings[:raw_url])
    else
        error("Unknown backend: $backend")
    end
end

end # module
