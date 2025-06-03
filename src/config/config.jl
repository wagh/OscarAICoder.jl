module Config

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
using OscarAICoder.Constants

export BackendType, LOCAL, REMOTE, HUGGINGFACE, GITHUB
export CONFIG, BackendSettings, ContextState, ConfigType, configure_dictionary_mode, configure_offline_mode, HistoryStore, set_local_model, get_local_model

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
# - base_dir: Base directory for the system
#
mutable struct ConfigType
    default_backend::BackendType
    backend_settings::Dict{BackendType, BackendSettings}
    training_mode::Bool
    dictionary_mode::Symbol
    context::ContextState
    debug::Bool
    history_store::HistoryStore
    base_dir::String
end

# Global configuration
const CONFIG = ConfigType(
    LOCAL,  # default_backend
    Dict{
        BackendType, BackendSettings
    }(
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
    ),
    true,  # training_mode
    :disabled,  # dictionary_mode
    ContextState([], true),  # context
    false,  # debug
    HistoryStore(Vector{HistoryEntry}(), 0),  # history_store
    dirname(@__DIR__)  # base_dir
)

# Configuration functions
function get_config()
    """Get the current configuration."""
    return CONFIG
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
    """Set the dictionary mode."""
    CONFIG.dictionary_mode = mode
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
