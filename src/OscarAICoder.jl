module OscarAICoder

export process_statement, configure_default_backend, configure_dictionary_mode, configure_github_backend, execute_statement

include("backends.jl")
include("seed_dictionary.jl")
include("execute.jl")

# Global configuration
const CONFIG = Dict{Symbol, Any}(
    :default_backend => :local,
    :backend_settings => Dict{Symbol, Dict{Symbol, Any}}(
        :local => Dict(
            :url => "http://localhost:11434",
            :model => "llama3.3"
        ),  # Local Ollama instance
        :remote => Dict(
            :url => "http://myserver.mydomain.net:11434",
            :model => "llama3.3"
        ),  # Remote server
        :huggingface => Dict(
            :api_key => nothing,
            :model => "gpt2",
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
    :offline_mode => false         # When true, only use dictionary
)

"""
    configure_offline_mode(enabled::Bool)

Enable or disable offline mode. In offline mode, only the local dictionary is used.
Any attempt to use LLM backends will result in an error.
"""
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
configure_github_backend(
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

    # Check dictionary based on configured mode
    dict_mode = CONFIG[:dictionary_mode]
    if dict_mode != :disabled && haskey(SEED_DICTIONARY, statement)
        return SEED_DICTIONARY[statement]
    elseif dict_mode == :only
        error("Statement not found in dictionary and dictionary_mode is :only")
    end

    # If we're in offline mode, we shouldn't reach here
    if CONFIG[:offline_mode]
        error("Offline mode is enabled - cannot use LLM backends")
    end

    # Use configured default if no backend specified
    actual_backend = isnothing(backend) ? CONFIG[:default_backend] : backend
    
    # Get backend settings and merge with kwargs
    settings = get(CONFIG[:backend_settings], actual_backend, Dict{Symbol,Any}())
    merged_kwargs = merge(settings, Dict{Symbol,Any}(kwargs))

    # Process with appropriate backend
    try
        if actual_backend == :local || actual_backend == :remote
            return OscarAICoder.Backends.Local.process_statement_local(statement; url=merged_kwargs[:url])
        elseif actual_backend == :huggingface
            if isnothing(merged_kwargs[:api_key])
                error("For the :huggingface backend, you must configure an api_key using configure_default_backend() or supply it as a keyword argument.")
            end
            return OscarAICoder.Backends.HuggingFace.process_statement_huggingface(statement; 
                api_key=merged_kwargs[:api_key],
                model=merged_kwargs[:model],
                endpoint=merged_kwargs[:endpoint]
            )
        elseif actual_backend == :github
            if isnothing(merged_kwargs[:token])
                error("For the :github backend, you must configure a token using configure_github_backend() or supply it as a keyword argument.")
            end
            return OscarAICoder.Backends.GitHub.process_statement_github(statement; 
                repo=merged_kwargs[:repo],
                token=merged_kwargs[:token],
                model=merged_kwargs[:model],
                branch=merged_kwargs[:branch],
                api_url=merged_kwargs[:api_url],
                raw_url=merged_kwargs[:raw_url]
            )
        else
            error("Unknown backend: $actual_backend")
        end
    catch e
        if isa(e, HTTP.ConnectError) || isa(e, HTTP.RequestError)
            if haskey(SEED_DICTIONARY, statement)
                @warn "LLM backend failed, falling back to dictionary"
                return SEED_DICTIONARY[statement]
            else
                error("Failed to connect to LLM backend and statement not found in dictionary")
            end
        end
        rethrow(e)
    end
end

end # module
