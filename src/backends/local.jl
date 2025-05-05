module Local

using HTTP, JSON
using OscarAICoder
using OscarAICoder: SEED_DICTIONARY

const DEFAULT_LLM_URL = "http://localhost:11434/api/generate"
const DEFAULT_MODEL = "llama3.3"

"""
    process_statement_local(statement::String; llm_url=DEFAULT_LLM_URL, model=DEFAULT_MODEL)

Send the statement to a local LLM server and return the generated Oscar code.
"""
function process_statement_local(statement::String; llm_url=DEFAULT_LLM_URL, model=DEFAULT_MODEL)
    debug_print("=== Debugging Local Backend ===")
    debug_print("Input statement: $statement")
    debug_print("Provided llm_url: $llm_url")
    debug_print("Provided model: $model")
    
    prompt = """
You are an expert Oscar programmer. Given the following mathematical statement in English,
generate idiomatic Oscar code using the Oscar.jl package. The code should be valid
Oscar code that can be executed directly. Do NOT include any markdown formatting,
backticks (`), or language indicators like 'julia'. Just output the plain code.

Statement: $statement
"""
    debug_print("Generated prompt: $prompt")
    
    data = Dict(
        "model" => model,
        "prompt" => prompt,
        "stream" => false,
        "n_predict" => 256,  # Number of tokens to generate
        "temperature" => 0.7,  # Temperature for sampling
        "stop" => ["\n"]  # Stop generation at newline
    )
    debug_print("Request data: $data")
    
    response = nothing
    try
        # Ensure we have a trailing slash in the URL
        url = llm_url
        if !endswith(url, '/')
            url = url * "/"
        end
        
        debug_print("Final URL: $url")
        debug_print("Making request...")
        
        # Make the request with proper URL construction
        response = HTTP.request("POST", url, ["Content-Type" => "application/json"], JSON.json(data))
        debug_print("Response received", prefix="[INFO]")
        debug_print("Response status: $(response.status)", prefix="[INFO]")
        debug_print("Response headers: $(Dict(response.headers))", prefix="[INFO]")
        # Parse the response once
        response_body = String(response.body)
        debug_print("Response body: $response_body", prefix="[INFO]")
        
        try
            result = JSON.parse(response_body)
            debug_print("Parsed result: $result", prefix="[INFO]")
            
            # Ollama returns the response in the "response" field
            if haskey(result, "response")
                code = result["response"]
                debug_print("Generated code: $code", prefix="[INFO]")
                return code
            else
                debug_print("Error: Response does not contain 'response' field", prefix="[ERROR]")
                debug_print("Available fields: $(keys(result))", prefix="[ERROR]")
                throw(ErrorException("Response format unexpected"))
            end
        catch e
            debug_print("Error parsing JSON: $e", prefix="[ERROR]")
            debug_print("Raw response body length: $(length(response_body))", prefix="[ERROR]")
            debug_print("First 100 characters: $(response_body[1:100])", prefix="[ERROR]")
            throw(e)
        end
    catch e
        debug_print("Error in local backend: $e", prefix="[ERROR]")
        if response !== nothing
            debug_print("Response status: $(response.status)", prefix="[ERROR]")
            debug_print("Response body: $(String(response.body))", prefix="[ERROR]")
        end
        rethrow(e)
    end
end

end # module Local
