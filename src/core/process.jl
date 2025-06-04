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

export process_statement, execute_statement, execute_statement_with_format, execute_all_statements, format_oscar_code

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
#
# Main function to process a user statement and generate Oscar code
# Arguments:
# - statement: The user input statement to process
# - backend: Which backend to use for code generation
# - model: Specific model to use (optional)
# Returns:
# - Generated Oscar code as a string
# Throws:
# - ErrorException if code generation fails
#
function process_statement(statement::String; 
    backend::Config.BackendType=Config.CONFIG.default_backend,
    model::String="",
    api_key::Union{String,Nothing}=nothing,
    token::Union{String,Nothing}=nothing,
    use_history::Bool=true,
    clear_context::Bool=false,
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
    if clear_context
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
                clear_context=clear_context
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
            
            # The code is already formatted from the backend
            debug_print("Received formatted Oscar code:\n$code")
            
            # Add code to history
            History.add_entry!(string(Dates.now()), statement, String(code), true, nothing)
            return String(code)
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
#
# Execute the most recent statement from history
# Returns:
# - Result of executing the most recent statement
# Throws:
# - ErrorException if no history entries are available
#
function execute_all_statements()
    return execute_statement()  # Call the main function with default parameter
end

"""
    execute_statement(oscar_code::String)

Execute Oscar code and return the result.
"""
#
# Execute Oscar code and return the result
# Arguments:
# - oscar_code: The Oscar code to execute
# - clear_context: Whether to clear the execution context
# Returns:
# - Result of executing the Oscar code
# Throws:
# - ErrorException if execution fails
#
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
        results = []
        lines = split(strip(code_str), '\n')
        for line in lines
            try
                result = eval(Meta.parse(line))
                push!(results, result)
            catch e
                debug_print("Error executing line: $line")
                debug_print("Error: $e")
                throw(e)
            end
        end
        
        debug_print("Oscar evaluation completed successfully")
        
        # Clear context if requested (Note: Oscar.jl doesn't have a built-in context clearing function)
        if clear_context
            debug_print("Clearing Oscar context requested but not supported")
        end
        
        debug_print("=== Oscar Execution End ===")
        
        # Return the last result if there's only one line, otherwise return all results
        # return length(results) == 1 ? results[1] : results
        return results[end]

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

"""
    format_oscar_code(code::String)

Format Oscar code to be more readable.
To be used after code generation. 
For example:
```
format_oscar_code("\"\"\"\nfunction f(x)\n    return x + 1\nend\n\"\"\"");
format_oscar_code(process_statement( stmt ));
```
"""

function format_oscar_code(code::String)::Vector{String}
    debug_print("--- format_oscar_code called ---")
    debug_print("Input code (raw): '$(repr(code))'")

    # Step 1: Unescape string literals.
    # This converts sequences like "\n", "\"", etc., from a raw string
    # (often returned by LLMs) into their actual character representations.
    # For example, a string "f(x) = x\nreturn x" becomes "f(x) = x\nreturn x".
    interpreted_code = Base.unescape_string(code)
    debug_print("Interpreted code: '$(repr(interpreted_code))'")

    # Step 2: Split the code into individual lines.
    source_lines = split(interpreted_code, '\n')
    debug_print("Source lines ($(length(source_lines)) lines): $source_lines")

    # Step 3: Initialize variables for formatting logic.
    formatted_lines = String[]  # Array to hold the processed, indented lines.
    current_indent_level = 0    # Tracks the current indentation level.
    indent_step = 4             # Number of spaces per indentation level.
    debug_print("Initial indent_level: $current_indent_level, indent_step: $indent_step")

    # Regex to identify keywords that typically increase indentation.
    keywords_increase_indent = r"^\s*(function|for|while|if|begin|let|struct|mutable struct|try|module|do)\b"
    # Regex to identify keywords that typically decrease indentation (before the line is added).
    keywords_decrease_indent = r"^\s*(end|else|elseif|catch|finally)\b"
    # Regex to identify keywords that decrease indentation *after* the line is added (e.g. `else` in an `if-else` block that itself is not indented).
    # This is a simpler heuristic; more complex cases might need full parsing.

    debug_print("Starting line processing loop...")
    # Process each line to apply indentation.
    for (i, line) in enumerate(source_lines)
        debug_print("  [Line $i Original]: '$(repr(line))'")
        # Remove leading/trailing whitespace for consistent keyword matching and clean output.
        stripped_line = strip(line)
        debug_print("  [Line $i Stripped]: '$(repr(stripped_line))'")

        # If the line is empty after stripping, preserve it as an empty line (or skip if desired).
        # Here, we'll add it as an empty line to preserve spacing, but without extra indentation.
        if isempty(stripped_line)
            push!(formatted_lines, "")
            debug_print("  [Line $i Action]: Added empty line.")
            continue
        end

        # Adjust indentation level *before* adding the current line.
        # If the line starts with a keyword that closes a block (e.g., `end`, `else`),
        # decrease the indent level first.
        if occursin(keywords_decrease_indent, stripped_line)
            old_indent = current_indent_level
            current_indent_level = max(current_indent_level - 1, 0) # Prevent negative indentation.
            debug_print("  [Line $i Indent]: Decreased indent from $old_indent to $current_indent_level (due to: $stripped_line)")
        end

        # Construct the indented line.
        indentation = " " ^ (current_indent_level * indent_step)
        final_line = indentation * stripped_line
        push!(formatted_lines, final_line)
        debug_print("  [Line $i Action]: Added indented line: '$(repr(final_line))' (indent: $current_indent_level)")

        # Adjust indentation level *after* adding the current line.
        # If the line starts with a keyword that opens a new block (e.g., `function`, `if`),
        # increase the indent level for subsequent lines.
        if occursin(keywords_increase_indent, stripped_line)
            old_indent = current_indent_level
            current_indent_level += 1
            debug_print("  [Line $i Indent]: Increased indent from $old_indent to $current_indent_level (due to: $stripped_line)")
        end
    end
    debug_print("Line processing loop finished.")

    # Step 4: Return the array of formatted lines.
    debug_print("Returning array of formatted lines: $formatted_lines")
    return formatted_lines
end


end # module Core
