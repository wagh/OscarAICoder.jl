module Local

using HTTP, JSON
using OscarAICoder.Utils: debug_print

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
        println("Response received")
        println("Response status: ", response.status)
        println("Response headers: ", response.headers)
        # Parse the response once
        response_body = String(response.body)
        println("Response body: ", response_body)
        
        try
            result = JSON.parse(response_body)
            println("Parsed result: ", result)
            
            # Ollama returns the response in the "response" field
            if haskey(result, "response")
                code = result["response"]
                println("Generated code: ", code)
                return code
            else
                println("Error: Response does not contain 'response' field")
                println("Available fields: ", keys(result))
                throw(ErrorException("Response format unexpected"))
            end
        catch e
            println("Error parsing JSON: ", e)
            println("Raw response body length: ", length(response_body))
            println("First 100 characters: ", response_body[1:100])
            throw(e)
        end
    catch e
        println("Error in local backend: ", e)
        if response !== nothing
            println("Response status: ", response.status)
            println("Response body: ", String(response.body))
        end
        rethrow(e)
    end
end

end # module Local
