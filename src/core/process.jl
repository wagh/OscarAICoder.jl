module Core

using ..Config
using ..Validator
using ..History
using ..Backends
using ..Debug
using ..Types
using ..SeedDictionary

export process_statement

"""
    process_statement(statement::String; kwargs...)

Process a mathematical statement and generate corresponding Oscar code.
Keyword arguments:
- backend: BackendType (default: Config.CONFIG.default_backend)
- model: String (default: Config.CONFIG.backend_settings[backend].model)
- api_key: String (for HuggingFace backend)
- token: String (for GitHub backend)
"""
function process_statement(statement::String; 
    backend::Config.BackendType=Config.CONFIG.default_backend,
    model::String="",
    api_key::Union{String,Nothing}=nothing,
    token::Union{String,Nothing}=nothing,
    kwargs...
)
    # If no model specified, use the configured model from backend settings
    if isempty(model)
        model = Config.CONFIG.backend_settings[backend].model
    end
    # Input validation
    if !isa(statement, String)
        error("Statement must be a string")
    end
    
    if isempty(statement)
        error("Empty statement provided")
    end
    
    debug_print("=== Processing Statement ===")
    debug_print("Input statement: $statement")
    debug_print("Selected backend: $backend")
    debug_print("Selected model: $model")
    
    # Add statement to context if not in training mode
    if !Config.CONFIG.training_mode
        Config.CONFIG.context.history = push!(Config.CONFIG.context.history, (statement, ""))
        Config.CONFIG.context.is_first_statement = false
    end
    
    # Try to find a match in seed dictionary first
    if Config.CONFIG.dictionary_mode == :enabled
        for entry in SeedDictionary.SEED_DICTIONARY
            if entry["input"] == statement
                debug_print("Found exact match in seed dictionary")
                code = entry["output"]
                
                # Validate the code
                if Validator.validate_oscar_code(code)
                    debug_print("Valid Oscar code found in dictionary")
                    
                    # Add to history
                    History.add_entry!(Types.HISTORY_STORE, statement, code, true)
                    return code
                else
                    debug_print("Invalid Oscar code in dictionary, falling back to API")
                end
            end
        end
    end
    
    debug_print("No dictionary match found, using API")
    
    # Select appropriate backend function
    try
        code = nothing
        
        if backend == Config.LOCAL
            debug_print("Using local backend")
            code = Backends.Local.process_statement_local(
                statement,
                model=model,
                kwargs...
            )
        elseif backend == Config.HUGGINGFACE
            debug_print("Using HuggingFace backend")
            if api_key === nothing
                error("API key is required for HuggingFace backend")
            end
            code = Backends.HuggingFace.process_statement_huggingface(
                statement,
                api_key=api_key,
                model=model,
                kwargs...
            )
        elseif backend == Config.GITHUB
            debug_print("Using GitHub backend")
            if token === nothing
                error("Token is required for GitHub backend")
            end
            code = Backends.GitHub.process_statement_github(
                statement,
                token=token,
                model=model,
                kwargs...
            )
        else
            error("Unsupported backend: $backend")
        end
        
        # Validate the generated code
        if Validator.validate_oscar_code(code)
            debug_print("Valid Oscar code generated")
            
            # Add to history
            History.add_entry!(Types.HISTORY_STORE, statement, code, true)
            return code
        else
            debug_print("Invalid Oscar code generated")
            
            # Add invalid entry to history
            History.add_entry!(Types.HISTORY_STORE, statement, code, false, "Invalid Oscar code")
            error("Generated invalid Oscar code")
        end
    catch e
        debug_print("Error processing statement: $e")
        
        # Add error to history
        History.add_entry!(Types.HISTORY_STORE, statement, "", false, string(e))
        
        # Rethrow with more context
        throw(ErrorException("Failed to process statement: $e"))
    end
end

export process_statement

end # module Core
