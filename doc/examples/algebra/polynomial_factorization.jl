using OscarAICoder

# Configure dictionary mode
configure_dictionary_mode(:priority)

# Example polynomial factorization
statements = [
    "Factor the polynomial x^2 - 5x + 6 over the integers",
    "Factor the polynomial x^3 - 2x^2 - 5x + 6 over the integers",
    "Factor the polynomial x^4 - 1 over the integers"
]

for statement in statements
    println("Processing statement: $statement")
    try
        oscar_code = process_statement(statement)
        println("Generated Oscar code:")
        println(oscar_code)
        println("-"^80)
    catch e
        println("Error processing statement: $e")
    end
end
