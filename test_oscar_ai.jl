using OscarAICoder

statement = "Factor the polynomial x^2 - 5x + 6 over the integers."

# Test local backend (requires local LLM server running)
try
    println("Local backend:")
    oscar_code = process_statement(statement)
    println(oscar_code)
catch e
    println("Local backend failed: ", e)
end

# Test Hugging Face backend (requires API key)
try
    println("Hugging Face backend:")
    oscar_code = process_statement(statement; backend=:huggingface, api_key="hf_yourapikey")
    println(oscar_code)
catch e
    println("Hugging Face backend failed: ", e)
end

# Test GitHub backend
println("\nGitHub backend:")
configure_dictionary_mode(:disabled)
configure_default_backend(:github, Dict(
    :repo => "example/llm-model",
    :model => "math_model.bin",
    :token => ENV["GITHUB_TOKEN"]
))
try
    println("Processing statement with GitHub LLM:")
    oscar_code = process_statement(statement)
    println(oscar_code)
catch e
    println("GitHub backend failed: ", e)
end

# Test statements
known_statement = "Factor the polynomial x^2 - 5x + 6 over the integers."
unknown_statement = "Find all prime numbers less than 20."

println("Testing offline and dictionary modes:")

# Test offline mode
println("\n1. Offline mode:")
configure_offline_mode(true)
try
    println("Known statement in offline mode:")
    oscar_code = process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement in offline mode:")
    oscar_code = process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test dictionary-only mode
println("\n2. Dictionary-only mode:")
configure_offline_mode(false)  # Turn off offline mode
configure_dictionary_mode(:only)
try
    println("Known statement:")
    oscar_code = process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement:")
    oscar_code = process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test fallback behavior with connection error
println("\n3. Testing connection error fallback:")
configure_dictionary_mode(:priority)
configure_default_backend(:remote, Dict(:url => "http://nonexistent-server:11434"))
try
    println("Known statement with bad connection (should fallback to dictionary):")
    oscar_code = process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement with bad connection:")
    oscar_code = process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test normal online mode
println("\n4. Normal online mode:")
configure_offline_mode(false)
configure_dictionary_mode(:priority)
configure_default_backend(:remote, Dict(:url => "http://server01.mydomain.net:11434"))
try
    println("Known statement (will use dictionary):")
    oscar_code = process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement (will use LLM):")
    oscar_code = process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error: ", e)
end
