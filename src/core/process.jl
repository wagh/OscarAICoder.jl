module Core

using ..Config
using ..Validator
using ..History
using ..Backends
using ..Debug
using ..Types
using ..SeedDictionary
using Dates

export process_statement

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
            History.add_entry!(string(Dates.now()), statement, code, true)
            return code
        else
            debug_print("Invalid Oscar code generated")
            
            # Add invalid entry to history
            History.add_entry!(string(Dates.now()), statement, code, false, "Invalid Oscar code")
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

export process_statement, execute_statement, execute_statement_with_format

using Base.Meta
using Oscar
using ..Config
using ..Debug

"""
    execute_statement(oscar_code::String)

Execute Oscar code and return the result.
"""
function execute_statement(oscar_code::Union{String, SubString{String}}; clear_context=false)
    # Convert SubString to String if needed
    code_str = String(oscar_code)
    
    debug_print("Starting Oscar execution")
    
    # Execute the code and capture the result
    try
        # Clear context if requested
        if clear_context
            Config.CONFIG.context.history = []
        end

        # Check if this is the first statement in context mode
        is_first_statement = isempty(Config.CONFIG.context.history)

        # Add current statement to history
        push!(Config.CONFIG.context.history, ("user", code_str))
        
        # # Keep only last N interactions
        # if length(Config.CONFIG.context.history) > Config.CONFIG.context.max_history
        #     Config.CONFIG.context.history = Config.CONFIG.context.history[end-Config.CONFIG.context.max_history+1:end]
        # end

        # If this is the first statement, don't use history
        if is_first_statement
            debug_print("First statement, not using history")
        else
            # Process history entries, skipping duplicates
            processed_code = Set{String}()
            for (role, code) in Config.CONFIG.context.history
                if role == "assistant" && !isempty(code) && !in(code, processed_code)
                    debug_print("Processing history code: $code")
                    # Split and evaluate each line
                    lines = split(strip(code), '\n')
                    for line in lines
                        if !isempty(strip(line))
                            eval(Meta.parse(line))
                        end
                    end
                    push!(processed_code, code)
                end
            end
        end
        
        # Split the code into lines and evaluate
        debug_print("Code: $oscar_code")
        debug_print("Splitting code into lines")
        lines = split(strip(oscar_code), '\n')
        
        # Evaluate each line separately
        for line in lines
            if !isempty(strip(line))
                eval(Meta.parse(line))
            end
        end
        
        # Return the last evaluated expression
        last_result = eval(Meta.parse(lines[end]))
        
        # Add the result to history
        push!(Config.CONFIG.context.history, ("assistant", string(last_result)))
        
        return last_result
    catch e
        error("Error executing Oscar code: $e\nCode: $oscar_code")
    end
end

"""
    execute_statement(oscar_code::String; output_format=:string)

Execute Oscar code and return the result in the specified format.
Available formats: :string, :latex, :html
"""
function execute_statement_with_format(oscar_code::String; output_format=:string)
    debug_print("=== Starting formatted execution ===")
    debug_print("Input code: $oscar_code")
    debug_print("Output format: $output_format")
    
    # Load Oscar only when needed
    Oscar = load_oscar()
    debug_print("Oscar loaded successfully")
    
    # Execute the code and capture the result
    try
        debug_print("Parsing and evaluating code")
        # Use eval to execute the code
        result = eval(Meta.parse(oscar_code))
        debug_print("Raw result: $result")
        
        # Format the output based on requested format
        debug_print("Formatting result as $output_format")
        if output_format == :latex
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
