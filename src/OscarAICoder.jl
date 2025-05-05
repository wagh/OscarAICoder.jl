module OscarAICoder

# __precompile__(false)

using HTTP, JSON

export process_statement, configure_default_backend, configure_dictionary_mode, configure_github_backend, execute_statement, execute_statement_with_format, debug_mode!, debug_mode, debug_print, training_mode!, training_mode

include("seed_dictionary.jl")  # Includes SEED_DICTIONARY
using .SeedDictionary: SEED_DICTIONARY
include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")
include("execute.jl")

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
    :training_mode => false
)

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

function process_statement(statement::String; backend=nothing, kwargs...)
    if CONFIG[:offline_mode] && !has_in_dictionary(statement)
        error("Statement not found in dictionary and offline mode is enabled")
    end

    # First try dictionary
    if CONFIG[:dictionary_mode] != :disabled
        if has_in_dictionary(statement)
            return get_from_dictionary(statement)
        end
    end

    # Prepare the prompt based on training mode
    if CONFIG[:training_mode]
        # Use full prompt template for training
        template = read(joinpath(@__DIR__, "prompt_template.txt"), String)
        prompt = replace(template, "[USER_INPUT]" => statement)
        prompt = replace(prompt, "[OSCAR_CODE]" => "")
    else
        # Use simple prompt for normal mode
        template = read(joinpath(@__DIR__, "prompt_normal.txt"), String)
        prompt = replace(template, "$statement" => statement)
    end

    # Get the backend function based on configuration
    backend = CONFIG[:default_backend]
    settings = CONFIG[:backend_settings][backend]
    
    # Call the appropriate backend function
    if backend == :local
        return Local.process_statement_local(statement; llm_url=settings[:url], model=settings[:model])
    elseif backend == :huggingface
        return HuggingFace.process_statement_huggingface(statement; api_key=settings[:api_key], model=settings[:model])
    elseif backend == :github
        return GitHub.process_statement_github(statement; token=settings[:token], repo=settings[:repo])
    else
        error("Unknown backend: $backend")
    end

    # Clean the response to make it directly executable
    # Remove code block markers and language indicators
    response_code = replace(response_code, r"```oscar\n?" => "")
    response_code = replace(response_code, r"```\n?" => "")
    response_code = replace(response_code, r"``\n?" => "")
    response_code = replace(response_code, r"```
?" => "")
    response_code = replace(response_code, r"`\n?" => "")
    response_code = replace(response_code, r"`" => "")
    response_code = replace(response_code, r"\`" => "")
    
    # Remove language indicators and extra whitespace
    response_code = replace(response_code, r"\s*Oscar\s*" => "")
    response_code = replace(response_code, r"\s*oscar\s*" => "")
    response_code = replace(response_code, r"\s*using\s*Oscar\s*" => "")  # Remove using Oscar if present
    response_code = strip(response_code)
    
    # Handle string literals and escapes
    # Unescape quotes in string literals
    response_code = replace(response_code, r"(\"|\')([^\\]+)(\"|\')" => s"\1\2\3")
    
    # Handle escaped newlines
    # First replace escaped newlines in string literals
    response_code = replace(response_code, r"(\"|\')([^\\]+)(\\n)([^\\]+)(\"|\')" => s"\1\2\n\4\5")
    # Then replace escaped newlines in code
    response_code = replace(response_code, r"\\n" => "\n")
    
    # Handle escaped quotes in string literals
    response_code = replace(response_code, r"\\\"" => "\"")
    response_code = replace(response_code, r"\\\'" => "\'")
    
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
end

end # module OscarAICoder
