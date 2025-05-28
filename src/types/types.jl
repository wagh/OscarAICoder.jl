module Types

# History types
struct HistoryEntry
    timestamp::String
    original_statement::String
    generated_code::String
    is_valid::Bool
    validation_error::Union{Nothing, String}
end

mutable struct HistoryStore
    entries::Vector{HistoryEntry}
    current_index::Int

    # Constructor with empty entries
    HistoryStore() = new(Vector{HistoryEntry}(), 0)
end

# Global history store
const HISTORY_STORE = HistoryStore()

# Export types
export HistoryEntry, HistoryStore, HISTORY_STORE

end # module Types
