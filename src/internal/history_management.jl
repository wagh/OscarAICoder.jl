# History Management Functions

# History Entry Structure
struct HistoryEntry
    id::Int
    role::String
    content::String
    timestamp::Float64
    is_first_statement::Bool
end

const HISTORY = HistoryEntry[]

"""
    view_entries()

Get a copy of all history entries.
"""
function view_entries()
    return deepcopy(HISTORY)
end

"""
    append_entry(role::String, content::String; is_first_statement::Bool=false)

Add a new entry to the conversation history.

# Arguments
- `role::String`: The role of the entry ("user" or "assistant")
- `content::String`: The content of the entry
- `is_first_statement::Bool`: Whether this is the first statement in a sequence
"""
function append_entry(role::String, content::Union{String, SubString{String}}; is_first_statement::Bool=false)
    # Convert SubString to String if needed
    content_str = String(content)
    new_id = isempty(HISTORY) ? 1 : maximum(e.id for e in HISTORY) + 1
    entry = HistoryEntry(new_id, role, content_str, time(), is_first_statement)
    push!(HISTORY, entry)
end

"""
    delete_entry(id::Int)

Delete an entry from the conversation history by its ID.

# Arguments
- `id::Int`: The ID of the entry to delete

# Throws
- `ErrorException`: If entry with given ID doesn't exist
"""
function delete_entry(id::Int)
    idx = findfirst(e -> e.id == id, HISTORY)
    isnothing(idx) && error("No entry found with id = $id")
    deleteat!(HISTORY, idx)
end

"""
    clear_entries()

Clear all entries from the conversation history.
"""
function clear_entries()
    empty!(HISTORY)
end

"""
    edit_entry(id::Int; role=nothing, content=nothing, is_first_statement=nothing)

Edit an existing entry in the conversation history.

# Arguments
- `id::Int`: The ID of the entry to edit
- `role=nothing`: New role for the entry ("user" or "assistant")
- `content=nothing`: New content for the entry
- `is_first_statement=nothing`: New value for is_first_statement flag

# Throws
- `ErrorException`: If entry with given ID doesn't exist
"""
function edit_entry(id::Int; role=nothing, content=nothing, is_first_statement=nothing)
    idx = findfirst(e -> e.id == id, HISTORY)
    isnothing(idx) && error("No entry found with id = $id")
    current = HISTORY[idx]
    HISTORY[idx] = HistoryEntry(
        current.id,
        isnothing(role) ? current.role : role,
        isnothing(content) ? current.content : content,
        time(),
        isnothing(is_first_statement) ? current.is_first_statement : is_first_statement
    )
end

"""
    save_to_file(filename::String)

Save the conversation history to a JSON file.

# Arguments
- `filename::String`: Path to save the file
"""
function save_to_file(filename::String)
    json_array = [Dict(
        "id"=>e.id, "role"=>e.role, "content"=>e.content,
        "timestamp"=>e.timestamp, "is_first_statement"=>e.is_first_statement
    ) for e in HISTORY]

    open(filename, "w") do io
        JSON.print(io, json_array)
    end
end

"""
    load_from_file(filename::String)

Load conversation history from a JSON file.

# Arguments
- `filename::String`: Path to load the file from

# Throws
- `ErrorException`: If file doesn't exist or contains invalid entries
"""
function load_from_file(filename::String)
    isfile(filename) || error("File does not exist: $filename")
    json_array = JSON.parsefile(filename)
    clear_entries()
    for item in json_array
        all(haskey.(Ref(item), ["id","role","content","timestamp","is_first_statement"])) ||
            error("Invalid entry in file: missing fields.")
        push!(HISTORY, HistoryEntry(
            item["id"], item["role"], item["content"],
            item["timestamp"], item["is_first_statement"]
        ))
    end
end
