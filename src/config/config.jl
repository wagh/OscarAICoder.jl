module Config

# Configuration types
@enum BackendType LOCAL REMOTE HUGGINGFACE GITHUB

using OscarAICoder.Types
using OscarAICoder.Constants

export BackendType, LOCAL, REMOTE, HUGGINGFACE, GITHUB
export CONFIG, BackendSettings, ContextState, ConfigType, configure_dictionary_mode, configure_offline_mode, HistoryStore

# Define types first
struct BackendSettings
    url::String
    model::String
    model_choices::Vector{Symbol}
end

mutable struct ContextState
    history::Vector{Tuple{String, String}}
    is_first_statement::Bool
end

mutable struct ConfigType
    default_backend::BackendType
    backend_settings::Dict{BackendType, BackendSettings}
    training_mode::Bool
    dictionary_mode::Symbol
    context::ContextState
    debug::Bool
    history_store::HistoryStore
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
            "https://api.github.com",
            "github-coder",
            [:github_coder]
        )
    ),
    false,  # training_mode
    :disabled,  # dictionary_mode
    ContextState([], true),  # context
    false,  # debug
    HistoryStore()  # history_store
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

function get_backend_settings(backend::BackendType)
    """Get settings for a specific backend."""
    return CONFIG.backend_settings[backend]
end

function set_backend_settings(backend::BackendType, settings::BackendSettings)
    """Set settings for a specific backend."""
    CONFIG.backend_settings[backend] = settings
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
