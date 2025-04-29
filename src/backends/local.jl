module Local

using HTTP, JSON

const DEFAULT_LLM_URL = "http://localhost:11434/v1/chat/completions"
const DEFAULT_MODEL = "mistral"

"""
    process_statement_local(statement::String; llm_url=DEFAULT_LLM_URL, model=DEFAULT_MODEL)

Send the statement to a local LLM server and return the generated Oscar code.
"""
function process_statement_local(statement::String; llm_url=DEFAULT_LLM_URL, model=DEFAULT_MODEL)
    prompt = "You are an expert Julia/Oscar programmer. Given the following mathematical statement in English, generate idiomatic Oscar code in Julia. Only output the code.\nStatement: $statement"
    data = Dict(
        "model" => model,
        "messages" => [Dict("role" => "user", "content" => prompt)],
        "max_tokens" => 256
    )
    response = HTTP.post(llm_url, ["Content-Type" => "application/json"], JSON.json(data))
    result = JSON.parse(String(response.body))
    # Adjust for the response format of your local LLM server
    code = result["choices"][1]["message"]["content"]
    return code
end

end # module Local
