module History

using Dates
using JSON
using ..Types
using ..Config

# History management functions
#
# Add a new entry to the history store
# Arguments:
# - timestamp: When the code was generated
# - original: Original user input statement
# - generated: Generated Oscar code
# - is_valid: Whether the generated code was valid
# - validation_error: Error message if validation failed (optional)
#
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

#
# Delete an entry from the history store
# Arguments:
# - idx: Index of the entry to delete
# Updates:
# - Adjusts current_index if needed
#
function delete_entry!(idx::Int)
    deleteat!(Config.CONFIG.history_store.entries, idx)
    if Config.CONFIG.history_store.current_index ≥ idx
        Config.CONFIG.history_store.current_index = min(Config.CONFIG.history_store.current_index - 1, length(Config.CONFIG.history_store.entries))
    end
end

#
# Clear all entries from the history store
# Updates:
# - Resets current_index to 0
#
function clear_entries!()
    empty!(Config.CONFIG.history_store.entries)
    Config.CONFIG.history_store.current_index = 0
end

#
# Edit an existing history entry
# Arguments:
# - idx: Index of the entry to edit
# - original: New original statement
# - generated: New generated code
# Updates:
# - Keeps the original timestamp
# - Resets validation status to valid
#
function edit_entry!(idx::Int, original::String, generated::String)
    Config.CONFIG.history_store.entries[idx] = HistoryEntry(
        Config.CONFIG.history_store.entries[idx].timestamp,
        original,
        generated,
        true,
        nothing
    )
end

#
# Save the history to a JSON file
# Arguments:
# - filename: Path to save the history
# Format:
# - Saves entries as JSON array
#
function save_history(filename::String)
    open(filename, "w") do io
        JSON.print(io, Config.CONFIG.history_store.entries)
    end
end

#
# Load history from a JSON file
# Arguments:
# - filename: Path to load history from
# Updates:
# - Replaces current history store
# - Maintains current_index
#
function load_history(filename::String)
    entries = Vector{HistoryEntry}()
    open(filename, "r") do io
        # Parse JSON and convert to HistoryEntry
        for entry in JSON.parse(io)
            push!(entries, HistoryEntry(
                entry["timestamp"],
                entry["original_statement"],
                entry["generated_code"],
                entry["is_valid"],
                get(entry, "validation_error", nothing)
            ))
        end
        Config.CONFIG.history_store = HistoryStore(entries, length(entries))
    end
end

function get_entries()
    return Config.CONFIG.history_store.entries
end

function wrap_text(text::String, width::Int=70, indent::Int=6)
    lines = []
    current_line = "" * " "^(indent+2)  # Start with proper indentation
    
    # Split text into words
    words = split(text)
    
    for word in words
        # If adding this word would exceed width, start a new line
        if length(current_line) + length(word) + 1 > width
            push!(lines, current_line)
            current_line = " "^(indent+2) * word  # Start new line with proper indentation
        else
            if !isempty(current_line)
                current_line *= " "
            end
            current_line *= word
        end
    end
    
    # Add the last line if it exists
    if !isempty(current_line)
        push!(lines, current_line)
    end
    
    return lines
end

function format_output(text::String, indent::Int=6)
    # Split by semicolons or newlines
    parts = split(text, r"[;\n]")
    lines = []
    
    for part in parts
        # Add proper indentation
        if !isempty(part)
            push!(lines, " "^(indent+2) * part * ";")
        end
    end
    
    return lines
end

function display_history(entries::Vector{HistoryEntry})
    for (i, entry) in enumerate(entries)
        println("[$i]")
        println("  time: \"$(entry.timestamp)\"")
        
        # Format original statement
        println("  user:")
        for line in wrap_text(entry.original_statement, 70, 6)
            println(line)
        end
        
        # Format generated code
        println("  output:")
        for line in format_output(entry.generated_code, 6)
            println(line)
        end
        
        println("  is_valid_code: $(entry.is_valid)")
        println("  code_error: $(entry.validation_error)")
        println()
    end
end

function display_history()
    entries = get_entries()
    display_history(entries)
end

function display_history(idx::Int)
    entries = get_entries()
    if idx < 1 || idx > length(entries)
        println("Invalid index: $idx. Must be between 1 and $(length(entries))")
        return
    end
    display_history([entries[idx]])
end

function get_entry(idx::Int)
    if idx < 1 || idx > length(get_entries())
        throw(ArgumentError("Invalid index: $idx. Must be between 1 and $(length(get_entries()))"))
    end
    return Config.CONFIG.history_store.entries[idx]
end

function current_timestamp()
    return Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
end

# Export history functions
export add_entry!, delete_entry!, clear_entries!, edit_entry!, save_history, load_history, get_entries, get_entry, current_timestamp

end # module History
