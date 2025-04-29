module Online

using HTTP, JSON

const DEFAULT_HF_ENDPOINT = "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2"
const DEFAULT_GITHUB_API = "https://api.github.com"

"""
    process_statement_online(statement::String; api_key::String, endpoint::String=DEFAULT_HF_ENDPOINT)

Send the statement to Hugging Face Inference API and return the generated Oscar code.
Requires a Hugging Face API key.
"""
function process_statement_online(statement::String; api_key::String, endpoint::String=DEFAULT_HF_ENDPOINT)
    prompt = "You are an expert Julia/Oscar programmer. Given the following mathematical statement in English, generate idiomatic Oscar code in Julia. Only output the code.\nStatement: $statement"
    headers = [
        "Authorization" => "Bearer $api_key",
        "Content-Type" => "application/json"
    ]
    data = Dict("inputs" => prompt)
    try
        response = HTTP.post(endpoint, headers, JSON.json(data))
        result = JSON.parse(String(response.body))
        # Hugging Face returns a list of generated texts
        if isa(result, Vector) && haskey(result[1], "generated_text")
            return result[1]["generated_text"]
        elseif haskey(result, "error")
            error("Hugging Face API error: $(result["error"])")
        else
            error("Unexpected Hugging Face API response format.")
        end
    catch e
        error("Failed to contact Hugging Face API: $e")
    end
end

"""
    process_statement_github(statement::String; repo::String, model::String, token::String, branch::String="main", api_url::String=DEFAULT_GITHUB_API)

Use a GitHub-hosted LLM to process the mathematical statement.
Parameters:
- repo: GitHub repository in format "owner/repo"
- model: Name of the model file in the repository
- token: GitHub Personal Access Token
- branch: Repository branch (default: "main")
- api_url: GitHub API URL (default: https://api.github.com)
"""
function process_statement_github(statement::String; repo::String, model::String, token::String, branch::String="main", api_url::String=DEFAULT_GITHUB_API)
    # Construct the GitHub API URL for the model file
    model_url = "$api_url/repos/$repo/contents/$model?ref=$branch"
    
    # Headers for GitHub API
    headers = [
        "Authorization" => "token $token",
        "Accept" => "application/vnd.github.v3.raw",
        "User-Agent" => "OscarAICoder"
    ]
    
    try
        # First, get the model file
        model_response = HTTP.get(model_url, headers)
        if model_response.status != 200
            error("Failed to fetch model: HTTP $(model_response.status)")
        end
        
        # Load the model (implementation depends on model format)
        # This is a placeholder - actual implementation would depend on the model type
        model_data = model_response.body
        
        # Prepare the prompt
        prompt = "You are an expert Julia/Oscar programmer. Given the following mathematical statement in English, generate idiomatic Oscar code in Julia. Only output the code.\nStatement: $statement"
        
        # Process the statement using the loaded model
        # This is a placeholder - actual implementation would depend on how the model should be used
        inference_url = "$api_url/repos/$repo/actions/workflows/inference.yml/dispatches"
        inference_data = Dict(
            "ref" => branch,
            "inputs" => Dict(
                "prompt" => prompt,
                "model" => model
            )
        )
        
        # Send inference request
        inference_response = HTTP.post(
            inference_url,
            headers,
            JSON.json(inference_data)
        )
        
        if inference_response.status != 204  # GitHub Actions accepts with 204
            error("Failed to start inference: HTTP $(inference_response.status)")
        end
        
        # Poll for results (simplified - actual implementation would need proper polling)
        sleep(5)  # Wait for inference to complete
        results_url = "$api_url/repos/$repo/actions/runs/latest/artifacts"
        results_response = HTTP.get(results_url, headers)
        
        if results_response.status != 200
            error("Failed to get results: HTTP $(results_response.status)")
        end
        
        # Parse and return results
        results = JSON.parse(String(results_response.body))
        if haskey(results, "artifacts") && length(results["artifacts"]) > 0
            return download_and_parse_result(results["artifacts"][1]["url"], headers)
        else
            error("No results found")
        end
        
    catch e
        error("GitHub backend error: $e")
    end
end

"""
Helper function to download and parse inference results
"""
function download_and_parse_result(url::String, headers::Vector{Pair{String,String}})
    try
        response = HTTP.get(url, headers)
        result = JSON.parse(String(response.body))
        return result["code"]
    catch e
        error("Failed to download results: $e")
    end
end

end # module Online
