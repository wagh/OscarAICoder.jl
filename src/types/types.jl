module Types

# History types
#
# Represents a single entry in the code generation history
# Fields:
# - timestamp: When the code was generated
# - original_statement: The original user input
# - generated_code: The generated Oscar code
# - is_valid: Whether the generated code was valid
# - validation_error: Error message if validation failed
#
struct HistoryEntry
    timestamp::String
    original_statement::String
    generated_code::String
    is_valid::Bool
    validation_error::Union{Nothing, String}
end

#
# Stores the history of code generation attempts
# Fields:
# - entries: List of all history entries
# - current_index: Current position in the history
# Constructors:
# - Empty constructor initializes with empty history
# - Parameterized constructor allows initializing with specific entries
#
mutable struct HistoryStore
    entries::Vector{HistoryEntry}
    current_index::Int

    # Constructor with empty entries
    HistoryStore() = new(Vector{HistoryEntry}(), 0)
    
    # Constructor with specific entries and index
    HistoryStore(entries::Vector{HistoryEntry}, current_index::Int) = new(entries, current_index)
end

# Global history store
const HISTORY_STORE = HistoryStore()

# Export types
export HistoryEntry, HistoryStore, HISTORY_STORE

end # module Types
