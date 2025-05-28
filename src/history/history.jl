module History

using Dates
using ..Types

# History management functions
function add_entry!(store::HistoryStore, original::String, generated::String, is_valid::Bool, error::Union{Nothing, String}=nothing)
    entry = HistoryEntry(
        Dates.format(now(), "yyyy-mm-dd_HH-MM-SS"),
        original,
        generated,
        is_valid,
        error
    )
    push!(store.entries, entry)
    store.current_index = length(store.entries)
end

function delete_entry!(store::HistoryStore, idx::Int)
    deleteat!(store.entries, idx)
    if store.current_index ≥ idx
        store.current_index = min(store.current_index - 1, length(store.entries))
    end
end

function clear_entries!(store::HistoryStore)
    empty!(store.entries)
    store.current_index = 0
end

function edit_entry!(store::HistoryStore, idx::Int, original::String, generated::String)
    store.entries[idx] = HistoryEntry(
        store.entries[idx].timestamp,
        original,
        generated,
        true,
        nothing
    )
end

function save_history(store::HistoryStore, filename::String)
    open(filename, "w") do io
        JSON.print(io, store.entries)
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
    return store
end

function get_entries(store::HistoryStore)
    return store.entries
end

function get_entry(store::HistoryStore, idx::Int)
    return store.entries[idx]
end

function current_timestamp()
    return Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
end

# Export history functions
export add_entry!, delete_entry!, clear_entries!, edit_entry!, save_history, load_history, get_entries, get_entry, current_timestamp

end # module History
