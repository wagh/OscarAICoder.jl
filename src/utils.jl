module Utils

using OscarAICoder

"""
    debug_print(msg::String)

Print a debug message if debug mode is enabled.
"""
function debug_print(msg::String)
    if OscarAICoder.CONFIG[:debug_mode]
        println(msg)
    end
end

end # module Utils
