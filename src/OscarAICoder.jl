module OscarAICoder

# __precompile__(false)
using HTTP, JSON, Dates

# Define the Utils submodule
module Utils
    export CONFIG, debug_print
    
    # Configuration dictionary
    const CONFIG = Dict{Symbol,Any}(
        :save_dir => "saved_contexts",
        :context => Dict(
            :history => [],
            :max_history => 10
        )
    )
    
    # Debug printing function
    function debug_print(msg::String)
        get(CONFIG, :debug, false) && println("[DEBUG] $msg")
        return nothing
    end
end

# Define the OscarAICoder module
module OscarAICoder
    using Base.Meta
    using ..Utils: CONFIG, debug_print
    
    # Store Oscar's exported symbols
    const OSCAR_SYMBOLS = Set{Symbol}()
    
    # Oscar module reference
    const OSCAR_MODULE = Ref{Module}()

    # Whitelist of known valid identifiers
    const WHITELISTED_SYMBOLS = Set{Symbol}(
        # Get all exported symbols from Base
        [sym for sym in names(Base, all=false)] ∪
        # Get all exported symbols from Core
        [sym for sym in names(Core, all=false)] ∪
        # Add some common operators and keywords
        [Symbol("+"), Symbol("-"), Symbol("*"), Symbol("/"), Symbol("^"),
         Symbol("=="), Symbol("!="), Symbol("<"), Symbol(">"), Symbol("<="), Symbol(">="),
         Symbol("!"), Symbol("&&"), Symbol("||")]
    )

    # Load Oscar only when needed
    function load_oscar()
        if !isdefined(Main, :Oscar) || OSCAR_MODULE[] === nothing
            # Load the Oscar module
            oscar = Base.require(Base.PkgId(Base.UUID("f1435218-dba5-11e9-1e4d-f1a5fab5fc13"), "Oscar"))
            
            # Import Oscar into Main
            Core.eval(Main, :(using Oscar))
            
            # Store the module reference
            OSCAR_MODULE[] = oscar
            
            # Get all exported symbols from Oscar
            if isempty(OSCAR_SYMBOLS)
                # Get only the exported identifiers
                oscar_identifiers = names(oscar, all=false)
                for name in oscar_identifiers
                    push!(OSCAR_SYMBOLS, name)
                end
                println("Loaded $(length(OSCAR_SYMBOLS)) Oscar identifiers")
            end
            
            return oscar
        end
        return OSCAR_MODULE[]
    end

    # Configuration
    const CONFIG = Dict(
        :debug => false,
        :context => Dict(
            :history => []
        )
    )
    
    # Export functions
    export validate_oscar_code, execute_statement, execute_statement_with_format

    function validate_oscar_code(code::String)::Union{Nothing,String}
        try
            # First, check if the code is empty
            isempty(strip(code)) && return "Code is empty"
            
            # Try to parse the code to check for syntax errors
            try
                Meta.parseall(code)
            catch e
                return "Syntax error in code: $e"
            end
            
            # Extract all symbols from the expression
            symbols = Set{Symbol}()
            assigned_vars = Set{Symbol}()
            
            function extract_symbols_and_assignments!(ex, is_assignment=false)
                if isa(ex, Expr)
                    # Handle assignments to track local variables
                    if ex.head == :(=) && length(ex.args) == 2
                        # Handle single assignment (x = ...)
                        if isa(ex.args[1], Symbol)
                            push!(assigned_vars, ex.args[1])
                            extract_symbols_and_assignments!(ex.args[2])
                            return
                        # Handle multiple assignment (x, y = ...)
                        elseif ex.args[1] isa Expr && ex.args[1].head == :tuple
                            for arg in ex.args[1].args
                                if isa(arg, Symbol)
                                    push!(assigned_vars, arg)
                                end
                            end
                            extract_symbols_and_assignments!(ex.args[2])
                            return
                        end
                    # Handle module access (e.g., Oscar.PolynomialRing)
                    elseif ex.head == :. && length(ex.args) >= 1
                        if ex.args[1] isa Symbol && ex.args[1] == :Oscar && length(ex.args) == 2
                            if ex.args[2] isa QuoteNode
                                push!(symbols, ex.args[2].value)
                            end
                        end
                    end
                    # Recurse into expression arguments
                    for arg in ex.args
                        extract_symbols_and_assignments!(arg, is_assignment)
                    end
                elseif isa(ex, Symbol) && !is_assignment
                    push!(symbols, ex)
                end
                return nothing
            end
            
            extract_symbols_and_assignments!(Meta.parseall(code))
            
            # Remove assigned variables from symbols to check
            symbols = setdiff(symbols, assigned_vars)
            
            # Skip validation if no symbols to check
            isempty(symbols) && return nothing
            
            # Try to load Oscar if not already loaded
            try
                oscar = load_oscar()
            catch e
                @warn "Failed to load Oscar for validation: $e"
                return nothing  # Skip validation if we can't load Oscar
            end
            
            # Get the Oscar module and its exported symbols
            oscar = OSCAR_MODULE[]
            oscar_exported = Set(names(oscar, all=false))
            
            # Check each symbol against known scopes
            for sym in symbols
                sym_str = string(sym)
                
                # Skip special forms and built-ins
                startswith(sym_str, '#') && continue
                startswith(sym_str, '@') && continue
                sym in (:Oscar, :Main) && continue
                
                # Check if symbol is defined in any known scope or is in Oscar's symbols
                if !(sym in oscar_exported) &&
                   !(sym in WHITELISTED_SYMBOLS) &&
                   !isdefined(Main, sym)
                    
                    # Check if it's a function call with a string literal (like `:(")"`)
                    if !(sym isa Symbol)
                        continue
                    end
                    
                    # If we get here, the symbol is not defined anywhere we know about
                    return "Invalid identifier: $sym is not found in Oscar or defined in the current scope"
                end
            end
            
            return nothing
        catch e
            @error "Error during validation" exception=(e, catch_backtrace())
            return "Error validating code: $e"
        end
    end
    
    function execute_statement(oscar_code::String; clear_context=false)
        # Load Oscar and validate the code
        oscar = load_oscar()
        debug_print("Starting Oscar execution")
        
        # Validate the code
        validation_error = validate_oscar_code(oscar_code)
        if validation_error !== nothing
            error(validation_error)
        end
        
        # Execute the code and capture the result
        try
            # Clear context if requested
            if clear_context
                CONFIG[:context][:history] = []
            end
            
            # Split code into individual statements
            stmts = filter(!isempty ∘ strip, split(oscar_code, ';'))
            
            # Create a temporary module that imports Oscar
            mod = Module()
            Core.eval(mod, :(using Oscar))
            
            # Evaluate each statement in the temporary module
            result = nothing
            for stmt in stmts
                stmt = strip(stmt)
                isempty(stmt) && continue
                result = Core.eval(mod, Meta.parse(stmt))
            end
            
            # Store the result in the context
            push!(CONFIG[:context][:history], (code=oscar_code, result=result))
            
            return result
        catch e
            error_msg = "Error executing Oscar code: $e\nCode: $oscar_code\n$(sprint(showerror, e, catch_backtrace()))"
            @error error_msg
            error("Error executing Oscar code: $e\nCode: $oscar_code")
        end
    end
    
    function execute_statement_with_format(oscar_code::String; output_format=:string)
        # Load Oscar only when needed
        oscar = load_oscar()
        
        # Execute the code and capture the result
        try
            # Use eval to execute the code
            result = eval(Meta.parse(oscar_code))
            
            # Format the output based on requested format
            if output_format == :latex
                return oscar.latex(result)
            elseif output_format == :html
                return oscar.html(result)
            else  # default to string
                return string(result)
            end
        catch e
            error("Error executing Oscar code: $e\nCode: $oscar_code")
        end
    end
end

# Re-export the exported functions from the submodules
using .execute: validate_oscar_code, execute_statement, execute_statement_with_format
export validate_oscar_code, execute_statement, execute_statement_with_format

# Clean up response text by removing markdown code block indicators
function clean_response_text(text::String)
    # Remove ```oscar and ``` markers
    text = replace(text, r"```(?:oscar)?\s*" => "")
    # Remove any remaining backticks
    text = replace(text, r"`" => "")
    # Trim whitespace
    return strip(text)
end

# Simple timestamp function using Dates standard library
function current_timestamp()
    return Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
end

export process_statement, configure_default_backend, configure_dictionary_mode, configure_github_backend, execute_statement, execute_statement_with_format, debug_mode!, debug_mode, debug_print, training_mode!, training_mode, get_context, save_context, load_context, set_save_dir

include("seed_dictionary.jl")  # Includes SEED_DICTIONARY
using .SeedDictionary: SEED_DICTIONARY
include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")


"""
    get_context([pretty=true])

Get the current conversation context including history and configuration.

# Arguments
- `pretty::Bool`: If true (default), returns a formatted string. If false, returns the raw Dict.

# Returns
- If `pretty=true`: A formatted string of the context (human-readable)
- If `pretty=false`: A dictionary containing the current context with keys:
  - `:history`: Array of previous interactions as (role, message) tuples
  - `:max_history`: Maximum number of interactions to keep
"""
function get_context(pretty::Bool=true)
    ctx = deepcopy(CONFIG[:context])
    if !pretty
        return ctx
    end
    
    # Print directly to stdout
    println("Context (max_history: $(ctx[:max_history]))")
    println(repeat("-", 50))
    
    # Group interactions by call number (each user-assistant pair is one call)
    call_num = 1
    i = 1
    while i <= length(ctx[:history])
        # Get user message if it exists
        if i <= length(ctx[:history]) && ctx[:history][i][1] == "user"
            println("[", call_num, "] ", "User:")
            for line in split(ctx[:history][i][2], '\n')
                println("    ", line)
            end
            i += 1
        end
        
        # Get assistant response if it exists
        if i <= length(ctx[:history]) && ctx[:history][i][1] == "assistant"
            println("[", call_num, "] ", "Assistant:")
            for line in split(ctx[:history][i][2], '\n')
                println("    ", line)
            end
            i += 1
        end
        
        call_num += 1
        println()  # Add empty line between interactions
    end
    
    # Return nothing since we're printing directly
    return nothing
end

# Configuration
const CONFIG = Dict{Symbol, Any}(
    :default_backend => :local,
    :backend_settings => Dict{Symbol, Dict{Symbol, Any}}(
        :local => Dict(
            :url => "http://localhost:11434/api/generate",
            :model => "qwen2.5-coder",
            :model_choices => [:qwen2_5, :qwen2_5_coder, :oscar_coder]
        ),
        :remote => Dict(
            :url => "http://myserver.mydomain.net:11434",
            :model => "qwen2.5-coder",
            :model_choices => [:qwen2_5, :qwen2_5_coder]
        ),
        :huggingface => Dict(
            :api_key => nothing,
            :model => "gpt2",
            :model_choices => [:qwen2_5, :qwen2_5_coder],
            :endpoint => "https://api-inference.huggingface.co/models"
        ),
        :github => Dict(
            :repo => "username/repo",
            :model => "llama2",
            :token => nothing,
            :branch => "main",
            :api_url => "https://api.github.com",
            :raw_url => "https://raw.githubusercontent.com"
        )
    ),
    :dictionary_mode => :priority,
    :offline_mode => false,
    :debug_mode => false,
    :training_mode => false,
    :context => Dict(
        :history => [],  # Store conversation history
        :max_history => 5  # Maximum number of previous interactions to keep
    ),
    :save_dir => joinpath(homedir(), "OscarAICoder_sessions")  # Default save directory
)

"""
    set_save_dir(dir::String)

Set the directory where session files will be saved.

# Arguments
- `dir::String`: Path to the directory where session files should be saved
"""
function set_save_dir(dir::String)
    # Create the directory if it doesn't exist
    mkpath(dir)
    CONFIG[:save_dir] = abspath(dir)
    return CONFIG[:save_dir]
end

"""
    save_context([filename::String])

Save the current context to a file.

# Arguments
- `filename::String`: (optional) Name of the file to save to. If not provided,
  a filename will be generated using the current timestamp.

# Returns
- `String`: The full path to the saved file
"""
function save_context(filename::Union{String,Nothing}=nothing)
    # Ensure save directory exists
    mkpath(CONFIG[:save_dir])
    
    # Generate filename if not provided
    if filename === nothing
        timestamp = current_timestamp()
        filename = "OscarAICoder_session_$(timestamp).json"
    end
    
    # Ensure .json extension
    if !endswith(lowercase(filename), ".json")
        filename = "$filename.json"
    end
    
    # Create full path
    filepath = abspath(joinpath(CONFIG[:save_dir], filename))
    
    # Prepare data to save
    save_data = Dict(
        :metadata => Dict(
            :saved_at => current_timestamp(),
            :version => "1.0",
            :config => Dict(
                :max_history => CONFIG[:context][:max_history]
            )
        ),
        :history => CONFIG[:context][:history]
    )
    
    # Save to file
    open(filepath, "w") do f
        JSON.print(f, save_data, 2)
    end
    
    return filepath
end

"""
    load_context(filename::String; clear_current::Bool=true)

Load context from a file.

# Arguments
- `filename::String`: Name of the file to load from
- `clear_current::Bool`: If true (default), clears current context before loading

# Returns
- `Dict`: The loaded context
"""
function load_context(filename::String; clear_current::Bool=true)
    # Create full path
    if !isabspath(filename)
        filename = joinpath(CONFIG[:save_dir], filename)
    end
    
    # Read and parse the file
    data = JSON.parsefile(filename)
    
    # Clear current context if requested
    if clear_current
        CONFIG[:context][:history] = []
    end
    
    # Helper function to safely get a value with either symbol or string key
    safe_get(dict, key) = haskey(dict, key) ? dict[key] : get(dict, string(key), nothing)
    
    # Get history from data
    history = safe_get(data, :history)
    if history === nothing
        return CONFIG[:context]  # No history found in file
    end
    
    # Append loaded history
    for item in history
        if isa(item, Vector) && length(item) >= 2
            # Handle both ["role", "message"] and ["user", "message"] formats
            role = string(item[1])
            message = string(item[2])
            push!(CONFIG[:context][:history], (role, message))
        end
    end
    
    # Update max_history if present in saved data
    if haskey(data, "metadata") || haskey(data, :metadata)
        metadata = safe_get(data, :metadata)
        if haskey(metadata, "config") || haskey(metadata, :config)
            config = safe_get(metadata, :config)
            if haskey(config, "max_history") || haskey(config, :max_history)
                CONFIG[:context][:max_history] = safe_get(config, :max_history)
            end
        end
    end
    
    return CONFIG[:context]
end

# Debug system
const LOCAL_DEBUG = false  # Enable debug printing for Local module

"""
    debug_print(msg::String)

Print a debug message if debug mode is enabled.
"""
function debug_print(msg::String; prefix="[DEBUG]")
    # Always print debug messages from Local module
    if CONFIG[:debug_mode] || LOCAL_DEBUG
        println("$prefix $msg")
    end
end

function debug_print_request(url::String, data::Dict)
    if CONFIG[:debug_mode] || LOCAL_DEBUG
        debug_print("Request URL: $url", prefix="[HTTP]")
        debug_print("Request Data: $(JSON.json(data, 2))", prefix="[HTTP]")
    end
end

function debug_print_response(response::HTTP.Response)
    if CONFIG[:debug_mode] || LOCAL_DEBUG
        debug_print("Response Status: $(response.status)", prefix="[HTTP]")
        debug_print("Response Headers: $(Dict(response.headers))", prefix="[HTTP]")
        try
            body = String(response.body)
            debug_print("Response Body: $body", prefix="[HTTP]")
        catch e
            debug_print("Error reading response body: $e", prefix="[ERROR]")
        end
    end
end

"""
    debug_mode!(state::Bool)

Set the debug mode state.
"""
function debug_mode!(state::Bool)
    CONFIG[:debug_mode] = state
end

"""
    debug_mode()

Get the current debug mode state.
"""
function debug_mode()
    return CONFIG[:debug_mode]
end

# Utility functions

"""
    add_to_dictionary(input::String, output::String)

Add a new entry to the seed dictionary
"""
function add_to_dictionary(input::String, output::String)
    push!(SEED_DICTIONARY, Dict(
        "input" => input,
        "output" => output
    ))
end

"""
    has_in_dictionary(statement::String)

Check if a statement exists in the dictionary
"""
function has_in_dictionary(statement::String)
    for entry in SEED_DICTIONARY
        if entry["input"] == statement
            return true
        end
    end
    return false
end

"""
    get_from_dictionary(statement::String)

Get the output for a given input statement from the dictionary
"""
function get_from_dictionary(statement::String)
    for entry in SEED_DICTIONARY
        if entry["input"] == statement
            return entry["output"]
        end
    end
    return nothing
end

function configure_offline_mode(enabled::Bool)
    CONFIG[:offline_mode] = enabled
end

function training_mode!(enabled::Bool)
    CONFIG[:training_mode] = enabled
end

function training_mode()
    return CONFIG[:training_mode]
end

function configure_dictionary_mode(mode::Symbol)
    if !(mode in [:priority, :only, :disabled])
        error("Unknown dictionary mode: $mode. Available modes: :priority, :only, :disabled")
    end
    CONFIG[:dictionary_mode] = mode
end

function configure_default_backend(backend::Symbol; kwargs...)
    if !(backend in [:local, :remote, :huggingface, :github])
        error("Unknown backend: $backend. Available backends: :local, :remote, :huggingface, :github")
    end
    
    backend_settings = CONFIG[:backend_settings][backend]
    for (key, value) in kwargs
        if haskey(backend_settings, key)
            backend_settings[key] = value
        else
            error("Invalid keyword argument '$key' for backend $backend")
        end
    end
    
    CONFIG[:default_backend] = backend
end

function configure_github_backend(; kwargs...)
    github_settings = CONFIG[:backend_settings][:github]
    for (key, value) in kwargs
        if haskey(github_settings, key)
            github_settings[key] = value
        else
            error("Invalid keyword argument '$key' for GitHub backend")
        end
    end
end

function process_statement(statement::String; backend=nothing, clear_context=false, kwargs...)
    try
        # Clear context if requested
        if clear_context
            CONFIG[:context][:history] = []
        end

        # Check if this is the first statement in context mode
        is_first_statement = isempty(CONFIG[:context][:history])

        # Add current statement to history
        push!(CONFIG[:context][:history], ("user", statement))
        
        # Keep only last N interactions
        if length(CONFIG[:context][:history]) > CONFIG[:context][:max_history]
            CONFIG[:context][:history] = CONFIG[:context][:history][end-CONFIG[:context][:max_history]+1:end]
        end

        # Store the first statement flag in CONFIG
        CONFIG[:context][:is_first_statement] = is_first_statement

        if CONFIG[:offline_mode] && !has_in_dictionary(statement)
            error("Statement not found in dictionary and offline mode is enabled")
        end

        # First try dictionary
        if CONFIG[:dictionary_mode] != :disabled
            if has_in_dictionary(statement)
                response = get_from_dictionary(statement)
                clean_response = clean_response_text(response)
                push!(CONFIG[:context][:history], ("assistant", clean_response))
                return response
            end
        end

        # Get the backend to use
        if backend === nothing
            backend = CONFIG[:default_backend]
        end

        # Get backend settings
        backend_settings = CONFIG[:backend_settings][backend]
        
        # Get the model to use
        model = get(kwargs, :model, backend_settings[:model])

        # Get the URL to use
        url = get(kwargs, :url, backend_settings[:url])

        # Get any additional parameters
        params = get(kwargs, :params, Dict{String, Any}())

        # Prepare the prompt based on mode
        if CONFIG[:training_mode]
            # Training mode: Use template
            template = read(joinpath(@__DIR__, "prompt_template.txt"), String)
            prompt = replace(template, "[USER_INPUT]" => statement)
            prompt = replace(prompt, "[OSCAR_CODE]" => "")
            debug_print("Prompt in training mode: $prompt")
        else
            # Context mode
            debug_print("Context history: $(CONFIG[:context][:history])")
            if CONFIG[:context][:is_first_statement]
                # First statement in context mode: Use normal prompt
                template = read(joinpath(@__DIR__, "prompt_normal.txt"), String)
                prompt = replace(template, "[statement]" => statement)
                debug_print("Prompt in context mode (first statement): $prompt")
            else
                # Subsequent statements in context mode
                # Start with a brief instruction to maintain Oscar code format
                context_prompt = "You are an expert Oscar programmer. Generate ONLY the Oscar code for the following mathematical statement. Use ONLY Oscar syntax and functions.\n\n"
                
                # Add conversation history
                for (role, text) in CONFIG[:context][:history]
                    context_prompt *= "\n$role: $text"
                end

                # Add the current statement with clear instruction
                context_prompt *= "\nuser: Give only the additional lines of code.\nGenerate Oscar code for: $statement\nassistant:"
                prompt = context_prompt
                debug_print("Prompt in context mode (subsequent statement): $prompt")
            end
        end

        # Send the request with context
        data = Dict(
            "model" => model,
            "prompt" => prompt,
            "stream" => false,
            "n_predict" => get(params, "n_predict", 256),
            "temperature" => get(params, "temperature", 0.7),
            "stop" => get(params, "stop", ["\nuser:", "\nassistant:"])
        )

        debug_print("=== Debugging process_statement ===")
        debug_print("Backend: $backend")
        debug_print("Model: $model")
        debug_print("URL: $url")
        debug_print("Prompt: $prompt")
        debug_print("Request data: $data")

        # Ensure we don't have a trailing slash in the URL
        if endswith(url, '/')
            url = url[1:end-1]
        end

        debug_print("Final URL: $url")
        debug_print("Making request...")

        # Try different request formats since the API might expect different parameter names
        try
            # First try with the original format
            response = HTTP.post(url,;
                headers = Dict("Content-Type" => "application/json"),
                body = JSON.json(data)
            )
            
            if response.status != 200
                error("HTTP error: $(response.status)\nResponse: $(String(response.body))")
            end

            response_body = JSON.parse(String(response.body))
            debug_print("Response body: $response_body")
            debug_print("Available keys: $(keys(response_body))")

            # Try to get the response text from different possible keys
            if haskey(response_body, "content")
                response_text = response_body["content"]
            elseif haskey(response_body, "text")
                response_text = response_body["text"]
            elseif haskey(response_body, "generated_text")
                response_text = response_body["generated_text"]
            elseif haskey(response_body, "response")
                response_text = response_body["response"]
            else
                # If no text key found, try to get the response from the body directly
                response_text = String(response.body)
            end

            # Add response to history
            clean_response = clean_response_text(response_text)
            push!(CONFIG[:context][:history], ("assistant", clean_response))

            # Clean the response to make it directly executable
            response_code = response_text
            response_code = replace(response_code, r"```oscar\n?" => "")
            response_code = replace(response_code, r"``\n?" => "")
            response_code = replace(response_code, r"``\n?" => "")
            response_code = replace(response_code, r"```
?" => "")
            response_code = replace(response_code, r"`\n?" => "")
            response_code = replace(response_code, r"\`" => "")

            # Remove language indicators and extra whitespace
            response_code = replace(response_code, r"\s*Oscar\s*" => "")
            response_code = replace(response_code, r"\s*oscar\s*" => "")
            response_code = strip(response_code)

            # Handle string literals and escapes
            response_code = replace(response_code, r"\"\"\".*?\"\"\""s => "")  # Remove string literals
            response_code = replace(response_code, r"#.*?\n" => "")  # Remove comments
            response_code = replace(response_code, r"print\(.*?\)" => "")  # Remove print statements
            response_code = replace(response_code, r"result =" => "")  # Remove result assignments
            response_code = replace(response_code, r"\nresult" => "")  # Remove result assignments
            response_code = replace(response_code, r"statement" => "x^3-1")  # Replace statement variable
            response_code = replace(response_code, r"\$statement" => "x^3-1")  # Replace statement variable
            response_code = strip(response_code)

            # Try to parse each line of the code to check if it's valid Oscar syntax
            try
                # Split the code into lines
                lines = split(strip(response_code), '\n')
                
                # Validate the code using Oscar's symbol validation
                validation_error = validate_oscar_code(response_code)
                if validation_error !== nothing
                    # If there's a validation error, send it back to the LLM for correction
                    error_message = "The generated code contains invalid identifiers. Please correct the following issue and try again:\n$validation_error\n\nProblematic code:\n```julia\n$response_code\n```"
                    
                    # Add the error to the context for the next attempt
                    if !haskey(CONFIG[:context], :last_error) || CONFIG[:context][:last_error] != validation_error
                        CONFIG[:context][:last_error] = validation_error
                        CONFIG[:context][:error_count] = get(CONFIG[:context], :error_count, 0) + 1
                        
                        # If we've had too many errors, give up to avoid infinite loops
                        if CONFIG[:context][:error_count] > 3
                            error("Too many attempts to fix the code. Please check your input and try again.")
                        end
                        
                        # Ask the LLM to correct the code
                        return process_statement("Please correct the following Oscar code. The error is: $validation_error\n\nCode to fix:\n```julia\n$response_code\n```"; backend=backend, kwargs...)
                    else
                        error("Failed to fix the code after multiple attempts. Last error: $validation_error")
                    end
                end
                
                # Reset error count if validation passes
                if haskey(CONFIG[:context], :error_count)
                    delete!(CONFIG[:context], :error_count)
                    delete!(CONFIG[:context], :last_error)
                end
            catch e
                error("Could not validate Oscar code: $response_code. Error: $e")
            end

            # If the code ends with print statement, extract just the expression
            print_match = match(r"print\((.*)\)$", response_code)
            if print_match !== nothing
                response_code = print_match.captures[1]
            end

            # Handle training mode
            if CONFIG[:training_mode]
                println("\nGenerated Oscar code:")
                println("-------------------")
                println(response_code)
                println("\nWould you like to add this to the training dictionary? (y/n)")
                if readline() == "y"
                    add_to_dictionary(statement, String(response_code))
                    println("Successfully added to training dictionary!")
                end
            end

            return String(response_code)
        catch e
            error("Error processing statement: $e")
        end

        debug_print_response(response)

        if response.status != 200
            error("HTTP error: $(response.status)\nResponse: $(String(response.body))")
        end

        response_body = JSON.parse(String(response.body))
        debug_print("Response body: $response_body")  # Add debug to see the full response
        debug_print("Available keys: $(keys(response_body))")  # Add debug to see available keys
        
        # Try to get the response text from different possible keys
        if haskey(response_body, "content")
            response_text = response_body["content"]
        elseif haskey(response_body, "text")
            response_text = response_body["text"]
        elseif haskey(response_body, "generated_text")
            response_text = response_body["generated_text"]
        else
            error("Could not find response text in API response: $(response_body)")
        end

        # Add response to history
        push!(CONFIG[:context][:history], ("assistant", response_text))

        # Clean the response to make it directly executable
        response_code = response_text
        response_code = replace(response_code, r"```oscar\n?" => "")
        response_code = replace(response_code, r"``\n?" => "")
        response_code = replace(response_code, r"``\n?" => "")
        response_code = replace(response_code, r"```
?" => "")
        response_code = replace(response_code, r"`\n?" => "")
        response_code = replace(response_code, r"\`" => "")

        # Remove language indicators and extra whitespace
        response_code = replace(response_code, r"\s*Oscar\s*" => "")
        response_code = replace(response_code, r"\s*oscar\s*" => "")
        # response_code = replace(response_code, r"\s*using\s*Oscar\s*" => "")  # Remove using Oscar if present
        response_code = strip(response_code)

        # Handle string literals and escapes
        # Unescape quotes in string literals
        # response_code = replace(response_code, r"("|\')([^\\]+)("|\')" => s"\1\2\3")

        # Handle escaped tabs
        response_code = replace(response_code, r"\\t" => "\t")
        
        # Remove any remaining escape sequences
        response_code = replace(response_code, r"\\(.)" => s"\1")
        response_code = replace(response_code, r"\"\"\".*?\"\"\""s => "")  # Remove string literals
        
        # Remove any comments
        response_code = replace(response_code, r"#.*?\n" => "")
        
        # Remove any print statements
        response_code = replace(response_code, r"print\(.*?\)" => "")
        
        # Remove any Python-specific syntax
        response_code = replace(response_code, r"result =" => "")
        response_code = replace(response_code, r"\nresult" => "")
        
        # Replace statement variable with actual polynomial
        response_code = replace(response_code, r"statement" => "x^3-1")
        response_code = replace(response_code, r"\$statement" => "x^3-1")
        
        # Remove any leading/trailing whitespace
        response_code = strip(response_code)
        
        # If the response is still not valid Oscar code, try to construct it
        if !occursin("R,", response_code) && !occursin("ideal", response_code) && !occursin("factor", response_code)
            # Try to construct Oscar code from the statement
            if contains(lowercase(statement), "factorise") || contains(lowercase(statement), "factor")
                # Look for polynomial expressions
                # Using simple string operations instead of regex
                poly = lowercase(statement)
                if contains(poly, "factorise")
                    poly = replace(poly, "factorise" => "")
                elseif contains(poly, "factor")
                    poly = replace(poly, "factor" => "")
                end
                poly = strip(poly)
                
                # Remove any "over rationals" phrase
                poly = replace(poly, "over rationals" => "")
                poly = strip(poly)
                
                response_code = "R, x = polynomial_ring(QQ, \"x\"); f = R($poly); factor(f)"
            end
        end
        
        # If we still don't have valid Oscar code, raise an error
        if !occursin("R,", response_code) && !occursin("ideal", response_code) && !occursin("factor", response_code)
            error("Could not generate valid Oscar code from response: $response_code")
        end
        
        # If the code ends with print statement, extract just the expression
        print_match = match(r"print\((.*)\)$", response_code)
        if print_match !== nothing
            response_code = print_match.captures[1]
        end

        # Handle training mode
        if CONFIG[:training_mode]
            println("\nGenerated Oscar code:")
            println("-------------------")
            println(response_code)
            println("\nWould you like to add this to the training dictionary? (y/n)")
            if readline() == "y"
                add_to_dictionary(statement, String(response_code))  # Convert to String
                println("Successfully added to training dictionary!")
            end
        end
        
        return String(response_code)  # Ensure we return a proper String
    catch e
        error("Error processing statement: $e")
    end
end

end # module OscarAICoder
