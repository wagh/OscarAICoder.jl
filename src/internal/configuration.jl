# Configuration Management

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
    CONFIG[:context][:history] = []
    debug_print("Context cleared")
end

"""
    configure_backend(backend::Symbol; kwargs...)

Configure settings for a specific backend.

# Arguments
- `backend::Symbol`: The backend to configure (:local, :remote, :huggingface, :github)
- `kwargs...`: Keyword arguments to set for the backend
"""
function configure_backend(backend::Symbol; kwargs...)
    if !(backend in keys(CONFIG[:backend_settings]))
        error("Unknown backend: $backend. Available backends: $(keys(CONFIG[:backend_settings]))")
    end
    
    backend_settings = CONFIG[:backend_settings][backend]
    for (key, value) in kwargs
        if haskey(backend_settings, key)
            backend_settings[key] = value
        else
            error("Invalid keyword argument '$key' for backend $backend")
        end
    end
end

"""
    set_default_backend(backend::Symbol)

Set the default backend to use.

# Arguments
- `backend::Symbol`: The backend to use (:local, :remote, :huggingface, :github)
"""
function set_default_backend(backend::Symbol)
    if !(backend in keys(CONFIG[:backend_settings]))
        error("Unknown backend: $backend. Available backends: $(keys(CONFIG[:backend_settings]))")
    end
    CONFIG[:default_backend] = backend
end
