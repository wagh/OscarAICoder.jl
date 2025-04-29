module HuggingFace

using HTTP
using JSON

"""
    process_statement_huggingface(statement::String; kwargs...)

Process a statement using the HuggingFace API.
Keyword arguments:
- api_key: HuggingFace API key
- model: Model name to use
- endpoint: API endpoint URL
"""
function process_statement_huggingface(statement::String; 
    api_key::String, model::String, endpoint::String
)
    headers = Dict(
        "Authorization" => "Bearer $api_key",
        "Content-Type" => "application/json"
    )
    
    payload = Dict(
        "inputs" => statement,
        "model" => model
    )
    
    try
        response = HTTP.post(
            "$endpoint/$model",
            headers,
            JSON.json(payload)
        )
        
        if response.status != 200
            error("HuggingFace API error: $(response.status)")
        end
        
        result = JSON.parse(String(response.body))
        return result["outputs"][1]
    catch e
        error("Failed to process statement with HuggingFace backend: $e")
    end
end

end # module HuggingFace
