
module OscarHistory

using JLD2

export HistoryEntry, view_history, save_history, load_history, edit_history_entry, delete_history_entry, is_valid_oscar_code, process_statement, HISTORY

# HistoryEntry struct
struct HistoryEntry
    id::Int
    user_input::String
    oscar_code::String
end

# Initialize HISTORY
const HISTORY = Vector{HistoryEntry}()

# View history entries
function view_history()
    for entry in HISTORY
        println("ID: \$(entry.id)")
        println("User Input: \$(entry.user_input)")
        println("OSCAR Code: \$(entry.oscar_code)")
        println("-----")
    end
end

# Save history to a file
function save_history(filename::String)
    @save filename HISTORY
end

# Load history from a file with validation
function load_history(filename::String)
    if !isfile(filename)
        error("File does not exist: \$filename")
    end
    data = load(filename)
    if !haskey(data, "HISTORY")
        error("Invalid history file: missing 'HISTORY' key")
    end
    loaded_history = data["HISTORY"]
    if !isa(loaded_history, Vector{HistoryEntry})
        error("Invalid history format: expected Vector{HistoryEntry}")
    end
    empty!(HISTORY)
    append!(HISTORY, loaded_history)
end

# Edit a history entry
end

# Delete entry by ID
function delete_history_entry(id::Int)
    if isempty(HISTORY)
        error("Cannot delete from an empty history")
    end
    
    idx = findfirst(e -> e.id == id, HISTORY)
    if isnothing(idx)
        error("No history entry with ID $id")
    end
    
    # Prevent deletion of first entry
    if idx == 1
        error("Cannot delete the first entry as it may break the conversation context")
    end
    
    deleteat!(HISTORY, idx)
    return nothing
end

# Get history entry by ID
function get_history_entry(id::Int)
    idx = findfirst(e -> e.id == id, HISTORY)
    if isnothing(idx)
        error("No history entry with ID $id")
    end
    return HISTORY[idx]
end

# Get all history entries
function get_all_history()
    return deepcopy(HISTORY)
end

# Update history entry
function update_history_entry(id::Int, role::String, content::String)
    if isempty(HISTORY)
        error("Cannot update in an empty history")
    end
    
    idx = findfirst(e -> e.id == id, HISTORY)
    if isnothing(idx)
        error("No history entry with ID $id")
    end
    
    # Prevent changing role of first entry
    if idx == 1 && role != HISTORY[idx].role
        error("Cannot change the role of the first entry")
    end
    
    HISTORY[idx] = HistoryEntry(id, role, content, HISTORY[idx].timestamp)
    return nothing
end

# Get first statement flag
function is_first_statement()::Bool
    return length(HISTORY) == 0 || length(HISTORY) == 1
end

# Enforce max history
function enforce_max_history!(max_history::Int)
    if max_history < 2
        error("Max history must be at least 2")
    end
    
    if length(HISTORY) > max_history
        # Keep first entry and last max_history-1 entries
        HISTORY[2:end-(max_history-2)] = []
    end
    return nothing
end

end # module OscarHistory
