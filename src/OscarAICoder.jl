module OscarAICoder

# Core dependencies
import Oscar
using HTTP, JSON
using Dates

# Internal modules and constants
include("internal/configuration.jl")
include("internal/history_management.jl")
include("internal/processing.jl")
include("internal/validator.jl")

# Backend modules
include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")

# External modules
include("execute.jl")

# Export public API
export process_statement, debug_mode!, debug_print, view_entries,
       append_entry, delete_entry, clear_entries, edit_entry, save_to_file,
       load_from_file, execute_statement, execute_statement_with_format, SEED_DICTIONARY, validate_oscar_code

# Internal utilities
function clean_response_text(text::String)
    # Remove ```oscar and ``` markers
    text = replace(text, r"```(?:oscar)?\s*" => "")
    # Remove any remaining backticks
    text = replace(text, r"`" => "")
    
    # Replace Python-style power operator with Oscar's power operator
    text = replace(text, r"(\w+)\*\*(\d+)" => s"\1^\2")
    
    # Find the ring variable from the polynomial ring declaration
    ring_var = nothing
    m = match(r"([a-zA-Z_][a-zA-Z_0-9]*)\s*,\s*\([^)]+\)\s*=\s*polynomial_ring", text)
    if m !== nothing
        ring_var = m.captures[1]
    end
    
    # Fix Ideal syntax: convert Ideal(...) to ideal(R, [...]) using the correct ring variable
    ring = ring_var !== nothing ? ring_var : "R"
    text = replace(text, r"Ideal\s*\(([^)]+)\)" => s"ideal($ring, [\1])")
    
    # Remove extra whitespace around operators
    text = replace(text, r"\s*([+-/*=])\s*" => s"\1")
    
    # Trim whitespace and remove empty lines
    text = strip(text)
    text = replace(text, r"\s+" => " ")
    
    return text
end

function current_timestamp()
    return Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
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
    process_statement(statement::String)

Process a mathematical statement and generate Oscar code.

# Arguments
- `statement::String`: The mathematical statement to process

# Returns
- `String`: The generated Oscar code

# Throws
- `ErrorException`: If invalid backend is specified or if Oscar code generation fails
"""
function process_statement(statement::String; backend=nothing, clear_context=false, kwargs...)
    try
        # Clear context if requested
        if clear_context
            clear_context!()
        end

        # Check if this is the first statement in context mode
        is_first_statement = isempty(CONFIG[:context][:history])
        debug_print("Context state BEFORE adding user entry: $(CONFIG[:context][:history])")

        # Add current statement to history
        append_entry("user", statement)
        debug_print("Context state AFTER adding user entry: $(CONFIG[:context][:history])")
        
        # Keep only last N interactions
        if length(CONFIG[:context][:history]) > CONFIG[:context][:max_history]
            CONFIG[:context][:history] = CONFIG[:context][:history][end-CONFIG[:context][:max_history]+1:end]
        end
        debug_print("Context state AFTER truncating history: $(CONFIG[:context][:history])")

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
                append_entry("assistant", clean_response)
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
            "n_predict" => get(params, "n_predict", 128),
            "temperature" => get(params, "temperature", 0.1),
            "top_k" => get(params, "top_k", 5),
            "top_p" => get(params, "top_p", 0.9),
            "repeat_penalty" => get(params, "repeat_penalty", 1.05),
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
            debug_print("Response status: $(response.status)")
            
            # Parse response and handle different response formats
            json_response = JSON.parse(String(response.body))
            debug_print("JSON response: $json_response")
            debug_print("Available keys: $(keys(json_response))")
            
            # Try to get the response text from different possible keys
            if haskey(json_response, "content")
                code = json_response["content"]
            elseif haskey(json_response, "text")
                code = json_response["text"]
            elseif haskey(json_response, "generated_text")
                code = json_response["generated_text"]
            elseif haskey(json_response, "response")
                code = json_response["response"]
            else
                # If no text key found, try to get the response from the body directly
                code = String(response.body)
            end
            debug_print("Extracted code: $code")
            
            # Clean the code
            response_code = clean_response_text(code)
            debug_print("Cleaned code: $response_code")
            
            # Validate the code
            validation_error = validate_oscar_code(response_code)
            if validation_error !== nothing
                error("Generated Oscar code is invalid: $validation_error")
            end
            debug_print("Code validation successful")
            
            # Clean up any remaining whitespace
            response_code = strip(response_code)

            # Return the cleaned code
            return response_code
        catch e
            error("Could not parse Oscar code: $(response.status). Error: $e")
        finally
            debug_print("API request processing completed")
        end
    catch e
        error("Error processing API response: $e")
    finally
        debug_print("process_statement function completed")
    end
end

# Call training mode function if needed
if CONFIG[:training_mode]
    process_training_mode(String(response.status), statement)
end

function process_training_mode(response_code::String, statement::String)
    println("\nGenerated Oscar code:")
    println("-------------------")
    println(response_code)
    println("-------------------")
    println("\nWould you like to add this to the training dictionary? (y/n)")
    if readline() == "y"
        add_to_dictionary(statement, String(response_code))
        println("Successfully added to training dictionary!")
    end
end

end # module OscarAICoder
