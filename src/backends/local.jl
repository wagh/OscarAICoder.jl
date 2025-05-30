module Local

using HTTP, JSON
using ..Config
using ..Validator
using ..Debug
using ..Prompts

const DEFAULT_LLM_URL = "http://localhost:11434/api/generate"
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
    use_history::Bool=true
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
            "max_tokens" => 2000,
            "temperature" => 0.7,
            "top_p" => 1.0,
            "model" => model
        )
        
        # Make the API request
        response = HTTP.post(llm_url, [
            "Content-Type" => "application/json"
        ], JSON.json(body)).body
        
        # Parse the response
        result = JSON.parse(String(response))
        debug_print("API response: $result")
        
        # Extract the generated code
        generated_code = get(result, "response", "")
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
