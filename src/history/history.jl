module History

using Dates
using ..Types
using ..Config

# History management functions
function add_entry!(timestamp::String, original::String, generated::String, is_valid::Bool, validation_error::Union{Nothing,String}=nothing)
    entry = HistoryEntry(
        timestamp,
        original,
        generated,
        is_valid,
        validation_error
    )
    push!(Config.CONFIG.history_store.entries, entry)
    Config.CONFIG.history_store.current_index = length(Config.CONFIG.history_store.entries)
end

function delete_entry!(idx::Int)
    deleteat!(Config.CONFIG.history_store.entries, idx)
    if Config.CONFIG.history_store.current_index ≥ idx
        Config.CONFIG.history_store.current_index = min(Config.CONFIG.history_store.current_index - 1, length(Config.CONFIG.history_store.entries))
    end
end

function clear_entries!()
    empty!(Config.CONFIG.history_store.entries)
    Config.CONFIG.history_store.current_index = 0
end

function edit_entry!(idx::Int, original::String, generated::String)
    Config.CONFIG.history_store.entries[idx] = HistoryEntry(
        Config.CONFIG.history_store.entries[idx].timestamp,
        original,
        generated,
        true,
        nothing
    )
end

function save_history(filename::String)
    open(filename, "w") do io
        JSON.print(io, Config.CONFIG.history_store.entries)
    end
end

function load_history(filename::String)
    store = HistoryStore()
    open(filename, "r") do io
        entries = JSON.parse(io)
        for entry in entries
            push!(store.entries, HistoryEntry(
                entry["timestamp"],
                entry["original_statement"],
                entry["generated_code"],
                entry["is_valid"],
                get(entry, "validation_error", nothing)
            ))
        end
        store.current_index = length(store.entries)
    end
    Config.CONFIG.history_store = store
end

function get_entries()
    return Config.CONFIG.history_store.entries
end

function get_entry(idx::Int)
    return Config.CONFIG.history_store.entries[idx]
end

function current_timestamp()
    return Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
end

# Export history functions
export add_entry!, delete_entry!, clear_entries!, edit_entry!, save_history, load_history, get_entries, get_entry, current_timestamp

end # module History
