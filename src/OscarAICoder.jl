# __precompile__(false)

module OscarAICoder

using JSON
using Dates
using Oscar

# Include internal files
include("internal/history_management.jl")
include("internal/configuration.jl")
include("internal/processing.jl")
include("internal/validator.jl")
include("execute.jl")

# Include backends
include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")

# Export public API
export process_statement, debug_mode!, debug_print, view_entries,
       append_entry, delete_entry, clear_entries, edit_entry, save_to_file,
       load_from_file, execute_statement, execute_statement_with_format, SEED_DICTIONARY, validate_oscar_code

"""
    process_statement(statement::String)

Process a mathematical statement and generate Oscar code.

# Arguments
- `statement::String`: The mathematical statement to process

# Returns
- `String`: The generated Oscar code

# Throws
- `ErrorException`: If invalid backend is specified or if Oscar code generation fails
"""
function process_statement(statement::String)
    # Add the statement to history
    append_entry("user", statement, is_first_statement=true)
    
    # Get the backend function based on configuration
    backend = CONFIG[:default_backend]
    settings = CONFIG[:backend_settings][backend]
    
    # Call the appropriate backend function
    if backend == :local
        response = Local.process_statement_local(statement; llm_url=settings[:url], model=settings[:model])
    elseif backend == :huggingface
        response = HuggingFace.process_statement_huggingface(statement; api_key=settings[:api_key], model=settings[:model])
    elseif backend == :github
        response = GitHub.process_statement_github(statement; token=settings[:token], repo=settings[:repo])
    else
        error("Unknown backend: $backend")
    end

    # Clean the response
    response_code = clean_response(response)
    
    if CONFIG[:training_mode]
        println("\nGenerated Oscar code:")
        println("-------------------")
        println(response_code)
        println("-------------------")
        println("\nWould you like to add this to the training dictionary? (y/n)")
        if readline() == "y"
            add_to_dictionary(statement, String(response_code))  # Convert to String
            println("Successfully added to training dictionary!")
        end
    end

    return response_code
end

end # module OscarAICoder
