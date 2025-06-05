module Debug

using ..Config

# Debug utilities
#
# Print debug message if debug mode is enabled
# Arguments:
# - msg: Message to print
# Behavior:
# - Only prints when Config.CONFIG.debug is true
# - Prefixes messages with "DEBUG: "
# Usage:
# - Used throughout the codebase for debugging purposes
# - Should be used sparingly in production code
#
function debug_print(msg::String)
    if Config.CONFIG.debug
        println("DEBUG: $msg")
    end
end

function debug_print(msg::Vector{Base.StackTraces.StackFrame})
    if Config.CONFIG.debug
        println("DEBUG: Stacktrace:")
        for frame in msg
            println("DEBUG:   $(frame.file):$(frame.line) - $(frame.func)")
        end
    end
end

function debug_print(msg::Any)
    if Config.CONFIG.debug
        println("DEBUG: $msg")
    end
end

# Export debug utilities
export debug_print

end # module Debug