module Config

__precompile__(false)

# Configuration types
#
# Enum representing different backend types for code generation
# - LOCAL: Uses local model (e.g., Ollama)
# - REMOTE: Uses remote API (e.g., OpenAI)
# - HUGGINGFACE: Uses HuggingFace models
# - GITHUB: Uses GitHub Copilot
#
@enum BackendType LOCAL REMOTE HUGGINGFACE GITHUB

using OscarAICoder.Types

export BackendType, LOCAL, REMOTE, HUGGINGFACE, GITHUB
export CONFIG, BackendSettings, ContextState, ConfigType, configure_dictionary_mode, configure_offline_mode, HistoryStore, set_local_model, get_local_model, get_sessions_directory, get_config, set_config, get_backend_settings, set_backend_settings, get_training_mode, set_training_mode, get_dictionary_mode, set_dictionary_mode, get_debug_mode, set_debug_mode

# Define types first
#
# Configuration settings for a specific backend
# Fields:
# - url: API endpoint URL for remote backends
# - model: Name of the model to use
# - model_choices: List of available model choices for this backend
#
struct BackendSettings
    url::String
    model::String
    model_choices::Vector{Symbol}
end

#
# Maintains the context state during code generation
# Fields:
# - history: List of previous (statement, code) pairs
# - is_first_statement: Flag indicating if this is the first statement in a session
#
mutable struct ContextState
    history::Vector{Tuple{String, String}}
    is_first_statement::Bool
end

#
# Global configuration type for the code generation system
# Fields:
# - default_backend: Default backend to use for code generation
# - backend_settings: Configuration settings for each backend type
# - training_mode: Flag indicating if system is in training mode
# - dictionary_mode: Mode for dictionary lookup (e.g., :full, :partial)
# - context: Maintains session context
# - debug: Debug mode flag
# - history_store: Stores history of generated code
# - sessions_directory: Directory for session history files
#
mutable struct ConfigType
    default_backend::BackendType
    backend_settings::Dict{BackendType, BackendSettings}
    training_mode::Bool
    dictionary_mode::Symbol
    context::ContextState
    debug::Bool
    history_store::HistoryStore
    sessions_directory::String
end

# Initialize backend settings
function initialize_backend_settings()
    """
    Initialize backend settings with default values
    """
    return Dict{BackendType, BackendSettings}(
        LOCAL => BackendSettings(
            "http://localhost:11434/api/generate",
            "qwen2.5-coder",
            [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        ),
        REMOTE => BackendSettings(
            "https://api.example.com/generate",
            "gpt-4-coder",
            [:gpt4, :gpt4_coder, :oscar_coder]
        ),
        HUGGINGFACE => BackendSettings(
            "https://api-inference.huggingface.co/models/",
            "Qwen/Qwen-2.5-Coder",
            [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        ),
        GITHUB => BackendSettings(
            "https://api.github.com/repos",
            "qwen2.5-coder",
            [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        )
    )
end

# Initialize default configuration
function initialize_config()
    """
    Initialize the default configuration with:
    - Default backend: LOCAL
    - Empty backend settings
    - Training mode: false
    - Dictionary mode: :enabled
    - Debug mode: false
    - Sessions directory: ~/.OscarAICoder_sessions
    """
    sessions_dir = joinpath(homedir(), ".OscarAICoder_sessions")
    if !isdir(sessions_dir)
        mkpath(sessions_dir)
    end
    
    backend_settings = initialize_backend_settings()
    
    # Check if Ollama service is running
    try
        # First try to check if Ollama is running as a service
        service_status = read(`systemctl status ollama`, String)
        if occursin("active (running)", service_status)
            # If Ollama service is running, use LOCAL backend with enabled mode
            @info "Ollama service is running. Using LOCAL backend with enabled mode."
            return ConfigType(
                LOCAL,
                backend_settings,
                false,
                :enabled,
                ContextState([], true),
                false,
                HistoryStore(Vector{HistoryEntry}(), 0),
                sessions_dir
            )
        end
        
        # If not running as a service, check if Ollama process is running
        # Use a more portable method that works across different systems
        try
            # Try to connect to Ollama's default port (11434)
            sock = connect("localhost", 11434)
            close(sock)
            # If we can connect, Ollama is running
            @info "Ollama service is running. Using LOCAL backend with full mode."
            return ConfigType(
                LOCAL,
                backend_settings,
                false,
                :full,
                ContextState([], true),
                false,
                HistoryStore(Vector{HistoryEntry}(), 0),
                sessions_dir
            )
        catch e
            # If we can't connect, Ollama is not running
            @warn "Ollama service not running. Switching to DICTIONARY mode."
            return ConfigType(
                LOCAL,
                backend_settings,
                false,
                :dictionary,
                ContextState([], true),
                false,
                HistoryStore(Vector{HistoryEntry}(), 0),
                sessions_dir
            )
        end
    catch e
        # If any system command fails, default to DICTIONARY mode
        @warn "Failed to check Ollama status. Switching to DICTIONARY mode."
        return ConfigType(
            LOCAL,
            backend_settings,
            false,
            :dictionary,
            ContextState([], true),
            false,
            HistoryStore(Vector{HistoryEntry}(), 0),
            sessions_dir
        )
    end
end

# Global configuration object
const CONFIG = initialize_config()

export CONFIG, BackendType, LOCAL, REMOTE, HUGGINGFACE, GITHUB, BackendSettings, ContextState, ConfigType, configure_dictionary_mode, configure_offline_mode, HistoryStore, set_local_model, get_local_model, get_sessions_directory



# Configuration functions
function get_config()
    """Get the current configuration settings as a formatted string."""
    settings = [
        "Backend Settings:",
        "  Default backend: $(CONFIG.default_backend)",
        "  Backend URL: $(CONFIG.backend_settings[CONFIG.default_backend].url)",
        "  Model: $(CONFIG.backend_settings[CONFIG.default_backend].model)",
        "",
        "Modes:",
        "  Training mode: $(CONFIG.training_mode)",
        "  Dictionary mode: $(CONFIG.dictionary_mode)",
        "  Debug mode: $(CONFIG.debug)",
        "",
        "Context:",
        "  First statement: $(CONFIG.context.is_first_statement)",
        "  History count: $(length(CONFIG.context.history))",
        "",
        "Sessions:",
        "  Sessions directory: $(CONFIG.sessions_directory)",
        "  History entries: $(length(Config.CONFIG.history_store.entries))"
    ]
    return join(settings, "\n")
end

function get_sessions_directory()
    """Get the current sessions directory."""
    return CONFIG.sessions_directory
end

function set_config(new_config::ConfigType)
    """Set the configuration to a new ConfigType instance."""
    global CONFIG = new_config
end

function get_backend_settings(backend::BackendType=LOCAL)
    """Get settings for a specific backend. Defaults to LOCAL if not specified."""
    return CONFIG.backend_settings[backend]
end

function set_backend_settings(backend::BackendType, settings::BackendSettings)
    """Set settings for a specific backend."""
    # Update the model choices if they're different from the current model
    if settings.model ∉ settings.model_choices
        settings.model_choices = [Symbol(settings.model)]
    end
    CONFIG.backend_settings[backend] = settings
end

"""
    set_local_model(model_name::String)

Set the model name for the local backend. The model must be available on your local LLM server.
"""
function set_local_model(model_name::String)
    """Set the model name for the local backend."""
    # Get current settings
    current_settings = get_backend_settings(LOCAL)
    
    # Create new settings with updated model name
    new_settings = BackendSettings(
        current_settings.url,
        model_name,
        [Symbol(model_name)]  # Start with just this model in choices
    )
    
    # Update the settings
    CONFIG.backend_settings[LOCAL] = new_settings
end

"""
    get_local_model()

Get the current model name for the local backend.
"""
function get_local_model()
    """Get the current model name for the local backend."""
    return get_backend_settings(LOCAL).model
end

function get_training_mode()
    """Get the current training mode."""
    return CONFIG.training_mode
end

function set_training_mode(mode::Bool)
    """Set the training mode."""
    CONFIG.training_mode = mode
end

function get_dictionary_mode()
    """Get the current dictionary mode."""
    return CONFIG.dictionary_mode
end

function set_dictionary_mode(mode::Symbol)
    """Set the dictionary mode. Valid modes are :enabled, :only, or :disabled."""
    valid_modes = [:enabled, :only, :disabled]
    if !(mode in valid_modes)
        throw(ArgumentError("Invalid dictionary mode. Valid modes are: $(join(valid_modes, ", "))"))
    end
    CONFIG.dictionary_mode = mode
end

function configure_dictionary_mode(mode::Symbol)
    """Configure the dictionary mode."""
    CONFIG.dictionary_mode = mode
end

function configure_offline_mode(mode::Bool)
    """Configure offline mode."""
    CONFIG.offline_mode = mode
end

function get_debug_mode()
    """Get the current debug mode."""
    return CONFIG.debug
end

function set_debug_mode(mode::Bool)
    """Set the debug mode."""
    CONFIG.debug = mode
end

end # module Config
