module GitHub

using HTTP, JSON
using ..Config
using ..Validator
using ..Debug

const DEFAULT_REPO = "username/repo"
const DEFAULT_BRANCH = "main"
const DEFAULT_API_URL = "https://api.github.com"
const DEFAULT_RAW_URL = "https://raw.githubusercontent.com"

"""
    process_statement_github(statement::String; kwargs...)

Process a mathematical statement using a GitHub-hosted LLM model.
Keyword arguments:
- repo: GitHub repository path (e.g., "username/repo")
- token: GitHub personal access token
- model: Model name to use
- branch: Repository branch (default: "main")
- api_url: GitHub API URL (default: "https://api.github.com")
- raw_url: GitHub raw content URL (default: "https://raw.githubusercontent.com")
"""
function process_statement_github(statement::String; 
    repo::String,
    token::String,
    model::String,
    branch::String=DEFAULT_BRANCH,
    api_url::String=DEFAULT_API_URL,
    raw_url::String=DEFAULT_RAW_URL
)
    debug_print("=== Debugging GitHub Backend ===")
    debug_print("Input statement: $statement")
    debug_print("Provided repo: $repo")
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
        # Get the model file from GitHub
        model_url = "$raw_url/$repo/$branch/models/$model"
        debug_print("Fetching model from: $model_url")
        
        # Download and load the model
        model_content = String(HTTP.get(model_url, [
            "Authorization" => "token $token"
        ]).body)
        
        debug_print("Model loaded successfully")
        
        # Make the API request
        response = HTTP.post("$api_url/$repo/$branch/predict", [
            "Authorization" => "token $token",
            "Content-Type" => "application/json"
        ], JSON.json(Dict(
            "prompt" => prompt
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
        debug_print("Error in process_statement_github: $e")
        rethrow()
    end
end

export process_statement_github

end # module GitHub
