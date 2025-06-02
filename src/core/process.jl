module Core

using ..Config
using ..Validator
using ..History
using ..Backends
using ..Debug
using ..Types
using ..SeedDictionary
using Dates
using Base.Meta
using Oscar

export process_statement, execute_statement, execute_statement_with_format, execute_all_statements

"""
    process_statement(statement::String; kwargs...)

Process a mathematical statement and generate corresponding Oscar code.
Keyword arguments:
- backend: BackendType (default: Config.CONFIG.default_backend)
- model: String (default: Config.CONFIG.backend_settings[backend].model)
- api_key: String (for HuggingFace backend)
- token: String (for GitHub backend)
- use_history: Bool (default: true) - whether to use history/context
- clear_history: Bool (default: false) - whether to clear history before processing
"""
function process_statement(statement::String; 
    backend::Config.BackendType=Config.CONFIG.default_backend,
    model::String="",
    api_key::Union{String,Nothing}=nothing,
    token::Union{String,Nothing}=nothing,
    use_history::Bool=true,
    clear_history::Bool=false,
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
    
    # Handle history options
    if clear_history
        Config.CONFIG.context.history = []
        Config.CONFIG.context.is_first_statement = true
        debug_print("History cleared before processing")
    end

    # Add statement to context if not in training mode and use_history is true
    if !Config.CONFIG.training_mode && use_history
        Config.CONFIG.context.history = push!(Config.CONFIG.context.history, (statement, ""))
        Config.CONFIG.context.is_first_statement = false
        debug_print("Statement added to history")
    else
        debug_print("History not used for this statement")
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
                    timestamp = string(Dates.now())
                    History.add_entry!(timestamp, statement, code, true)
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
                clear_context=clear_history
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
            
            # Convert SubString to String and add to history
            History.add_entry!(string(Dates.now()), statement, String(code), true, nothing)
            return code
        else
            debug_print("Invalid Oscar code generated")
            
            # Add invalid entry to history
            History.add_entry!(string(Dates.now()), statement, String(code), false, "Invalid Oscar code")
            error("Generated invalid Oscar code")
        end
    catch e
        debug_print("Error processing statement: $e")
        
        # Add error to history
        History.add_entry!(string(Dates.now()), statement, "", false, string(e))
        
        # Rethrow with more context
        throw(ErrorException("Failed to process statement: $e"))
    end
end

"""
    execute_all_statements()

Execute the most recent statement from history.
"""
function execute_all_statements()
    return execute_statement()  # Call the main function with default parameter
end

"""
    execute_statement(oscar_code::String)

Execute Oscar code and return the result.
"""
function execute_statement(oscar_code::Union{String, SubString{String}}=""; clear_context=false)
    # If no code is provided, use the most recent history entry
    if isempty(oscar_code)
        entries = History.get_entries()
        if isempty(entries)
            error("No history entries available")
        end
        oscar_code = entries[end].generated_code
    end
    
    # Convert SubString to String if needed
    code_str = String(oscar_code)
    
    debug_print("Starting Oscar execution")
    debug_print("Oscar code:\n$code_str")
    debug_print("Clear context: $clear_context")
    
    try
        debug_print("=== Oscar Execution Start ===")
        debug_print("Executing Oscar code:")
        debug_print("""$code_str""")  # Use triple quotes for better formatting
        
        # Execute the Oscar code
        debug_print("Starting Oscar evaluation...")
        # Ensure Oscar is imported
        eval("using Oscar")

        # Execute the actual Oscar code
        # result = eval(code_str)
        lines = split(strip(code_str), '\n')
        for line in lines
            eval(Meta.parse(line))
        end

        debug_print("Oscar evaluation completed successfully")
        
        # Clear context if requested
        if clear_context
            debug_print("Clearing Oscar context as requested")
            Oscar.clear_context()
            debug_print("Oscar context cleared")
        end
        
        debug_print("=== Oscar Execution End ===")
        # return result
    catch e
        debug_print("=== Oscar Execution Error ===")
        debug_print("Error during Oscar execution: $e")
        debug_print("Error type: $(typeof(e))")
        debug_print("Stacktrace:")
        debug_print(stacktrace(catch_backtrace()))
        rethrow()
    end
end

"""
    execute_statement_with_format(oscar_code::String; output_format=:string)

Execute Oscar code and return the result in specified format.

"""
function execute_statement_with_format(oscar_code::String; output_format=:string)
    debug_print("=== Starting formatted execution ===")
    debug_print("Input code: $oscar_code")
    debug_print("Output format: $output_format")
    
    try
        # Execute the code
        result = eval(oscar_code)
        
        # Format the result based on output_format
        if output_format == :string
            formatted_result = string(result)
            debug_print("String formatted result: $formatted_result")
            return formatted_result
        elseif output_format == :latex
            formatted_result = Oscar.latex(result)
            debug_print("LaTeX formatted result: $formatted_result")
            return formatted_result
        elseif output_format == :html
            formatted_result = Oscar.html(result)
            debug_print("HTML formatted result: $formatted_result")
            return formatted_result
        else  # default to string
            formatted_result = string(result)
            debug_print("String formatted result: $formatted_result")
            return formatted_result
        end
    catch e
        debug_print("=== Formatting error ===")
        debug_print("Error: $e")
        debug_print("Stacktrace: $(stacktrace(catch_backtrace()))")
        error("Error executing Oscar code: $e\nCode: $oscar_code")
    end
end

end # module Core
