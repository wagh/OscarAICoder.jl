module Local

using HTTP, JSON
using ..Config
using ..Validator
using ..Debug
using ..Prompts

#
# Default URL for the local LLM server
# Uses Ollama's default API endpoint
#
const DEFAULT_LLM_URL = "http://localhost:11434/api/generate"
#
# Default model for code generation
# Uses Qwen's coder model optimized for code generation
#
const DEFAULT_MODEL = "qwen2.5-coder"

"""
    process_statement_local(statement::String; kwargs...)

Process a mathematical statement using a local LLM server.
Keyword arguments:
- llm_url: URL of the LLM server (default: DEFAULT_LLM_URL)
- model: Model name to use (default: DEFAULT_MODEL)
"""
function process_statement_local(statement::String; 
    llm_url::String=DEFAULT_LLM_URL, 
    model::String=DEFAULT_MODEL,
    use_history::Bool=true,
    clear_context::Bool=false
)
    debug_print("=== Debugging Local Backend ===")
    debug_print("Input statement: $statement")
    debug_print("Provided llm_url: $llm_url")
    debug_print("Provided model: $model")
    
    # Check if dictionary mode is enabled
    if Config.CONFIG.dictionary_mode == :enabled
        # Try to find a match in SEED_DICTIONARY
        for entry in Config.SEED_DICTIONARY
            if entry["input"] == statement
                debug_print("Found exact match in seed dictionary")
                return entry["output"]
            end
        end
    end
    
    debug_print("No dictionary match found, proceeding with API call")
    
    # Get the appropriate prompt
    prompt = Prompts.get_prompt(statement, use_history, Config.CONFIG.training_mode)
    
    debug_print("Final prompt:\n$prompt")
    
    try
        # Prepare the request body
        body = Dict(
            "prompt" => prompt,
            "max_tokens" => 5000, # Maximum tokens to generate
                                  # Earlier was 2000
            "temperature" => 0.2, # Lower temperature for more focused output
                                  # Earlier values were 0.7
                                  # Lower values are better for code generation
            "top_p" => 1.0, 
            "model" => model
        )
        
        # Make the API request and collect all responses
        response = HTTP.post(llm_url, [
            "Content-Type" => "application/json"
        ], JSON.json(body)).body
        
        # Parse the response - handle streaming JSON objects
        response_str = String(response)
        debug_print("Raw API response:\n$response_str")
        
        # Collect all response parts
        generated_code = ""
        json_objects = split(response_str, r"}\s*{", keepempty=false)
        
        # Parse each JSON object and concatenate responses
        for obj in json_objects
            try
                # Add back the missing braces
                if !startswith(obj, "{")
                    obj = "{" * obj
                end
                if !endswith(obj, "}")
                    obj = obj * "}"
                end
                
                result = JSON.parse(obj)
                debug_print("Parsed JSON object: $result")
                
                # Get the response from this object and append to generated code
                code = get(result, "response", "")
                generated_code *= code
            catch e
                debug_print("Error parsing JSON object: $e")
            end
        end
        
        # Remove any trailing whitespace or newlines
        generated_code = strip(generated_code)
        
        if isempty(generated_code)
            error("No valid response found in API response")
        end
        debug_print("Generated Oscar code:\n$generated_code")
        
        # Validate the generated code
        if Validator.validate_oscar_code(generated_code)
            return generated_code
        else
            error("Invalid Oscar code generated")
        end
    catch e
        debug_print("Error in process_statement_local: $e")
        rethrow()
    end
end

export process_statement_local

end # module Local
