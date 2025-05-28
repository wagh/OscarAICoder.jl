module Debug

using ..Config

# Debug utilities
function debug_print(msg::String)
    if Config.CONFIG.debug
        println("DEBUG: $msg")
    end
end

# Export debug utilities
export debug_print

end # module Debug