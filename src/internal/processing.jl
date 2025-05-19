# Response Processing Functions

"""
    clean_response(response_code::String)

Clean the response to make it directly executable.
"""
function clean_response(response_code::String)
    # Validate the generated Oscar code
    validation_error = validate_oscar_code(response_code)
    if validation_error !== nothing
        # Instead of raising an error, return the invalid code with a comment
        return "# Invalid Oscar code: $validation_error\n$response_code"
    end

    # Remove code block markers
    response_code = replace(response_code, r"```\n?" => "")
    response_code = replace(response_code, r"``\n?" => "")
    response_code = replace(response_code, r"`\n?" => "")
    response_code = replace(response_code, r"\n?```
?" => "\n")
    response_code = replace(response_code, r"\n?``
?" => "\n")
    response_code = replace(response_code, r"\n?`
?" => "\n")
    
    # Remove language indicators and extra whitespace
    response_code = replace(response_code, r"\s*using\s*Oscar\s*" => "")  # Remove using Oscar if present
    response_code = strip(response_code)
    
    # Handle string literals and escapes
    function handle_string_literals(s)
        s = replace(s, r"\\\"" => "\"")
        s = replace(s, r"\\'" => "'")
        s = replace(s, r"\\n" => "\n")
        s = replace(s, r"\\t" => "\t")
        return s
    end
    

    return response_code
end
