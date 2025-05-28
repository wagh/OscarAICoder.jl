module HuggingFace

using HTTP, JSON
using ..Config
using ..Validator
using ..Debug

"""
    process_statement_huggingface(statement::String; kwargs...)

Process a mathematical statement using HuggingFace API.
Keyword arguments:
- api_key: HuggingFace API key
- model: Model name to use
- api_url: HuggingFace API URL (default: "https://api-inference.huggingface.co/models")
"""
function process_statement_huggingface(statement::String; 
    api_key::String,
    model::String,
    api_url::String="https://api-inference.huggingface.co/models"
)
    debug_print("=== Debugging HuggingFace Backend ===")
    debug_print("Input statement: $statement")
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
    
    # Prepare the prompt
    prompt = "Translate the following mathematical statement into Oscar code:\n\n"
    if !Config.CONFIG.training_mode
        prompt *= "Context:\n"
        for (original, generated) in Config.CONFIG.context.history
            prompt *= "Statement: $original\nOscar code: $generated\n"
        end
        prompt *= "\n"
    end
    prompt *= "Statement: $statement\nOscar code:"
    
    debug_print("Final prompt:\n$prompt")
    
    try
        # Make the API request
        response = HTTP.post("$api_url/$model", [
            "Authorization" => "Bearer $api_key",
            "Content-Type" => "application/json"
        ], JSON.json(Dict(
            "inputs" => prompt
        ))).body
        
        # Parse the response
        result = JSON.parse(String(response))
        debug_print("API response: $result")
        
        # Extract the generated code
        generated_code = result["generated_text"]
        debug_print("Generated Oscar code:\n$generated_code")
        
        # Validate the generated code
        if Validator.validate_oscar_code(generated_code)
            return generated_code
        else
            error("Invalid Oscar code generated")
        end
    catch e
        debug_print("Error in process_statement_huggingface: $e")
        rethrow()
    end
end

export process_statement_huggingface

end # module HuggingFace
