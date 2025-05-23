# Configuration Management

# Default configuration
const CONFIG = Dict(
    :debug_mode => false,
    :training_mode => false,
    :default_backend => :local,
    :backend_settings => Dict(
        :local => Dict(
            :url => "http://localhost:11434/api/generate",
            :model => "qwen2.5-coder",
            :model_choices => [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        ),
        :remote => Dict(
            :url => "",
            :model => ""
        )
    )
)

# Seed dictionary for training
const SEED_DICTIONARY = Dict{
    String, String
}()

# Local debug flag
const LOCAL_DEBUG = false

"""
    debug_mode!(enabled::Bool)

Enable or disable debug mode.
"""
function debug_mode!(enabled::Bool)
    CONFIG[:debug_mode] = enabled
end

"""
    debug_print(msg::String; prefix="DEBUG")

Print a debug message with an optional prefix if debug mode is enabled.

# Arguments
- `msg::String`: The message to print
- `prefix::String="DEBUG"`: Optional prefix for the debug message
"""
function debug_print(msg::String; prefix="DEBUG")
    if CONFIG[:debug_mode] || LOCAL_DEBUG
        println("[$prefix] $msg")
    end
end

"""
    clear_context!()

Clear all context and reset the conversation.
"""
function clear_context!()
    clear_entries()
    debug_print("Context cleared")
end
