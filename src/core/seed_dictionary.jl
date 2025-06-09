module SeedDictionary

using OscarAICoder.Constants
using OscarAICoder.Validator

"""
    validate_dictionary_entry(entry::Dict)

Validate that a dictionary entry has the correct structure.
"""
function validate_dictionary_entry(entry::Dict)
    required_keys = Set(["input", "output"])
    has_keys = Set(keys(entry))
    
    # Check required keys
    if !issubset(required_keys, has_keys)
        missing_keys = setdiff(required_keys, has_keys)
        error("Dictionary entry is missing required keys: $(join(missing_keys, ", "))")
    end
    
    # Validate input is a string
    if !(entry["input"] isa String)
        error("Input must be a string")
    end
    
    # Validate output is a string
    if !(entry["output"] isa String)
        error("Output must be a string")
    end
    
    # Validate Oscar code
    if !Validator.is_valid_oscar_code(entry["output"])
        error("Invalid Oscar code in dictionary entry")
    end
end

"""
    load_seed_dictionary(filename::String)

Load seed dictionary from a JSON file.
"""
function load_seed_dictionary(filename::String)
    try
        # Read the file
        content = read(filename, String)
        
        # Parse JSON
        entries = JSON.parse(content)
        
        # Validate each entry
        for entry in entries
            validate_dictionary_entry(entry)
        end
        
        return entries
    catch e
        error("Error loading seed dictionary: $e")
    end
end

"""
    save_seed_dictionary(filename::String, entries::Vector{Dict})

Save seed dictionary to a JSON file.
"""
function save_seed_dictionary(filename::String, entries::Vector{Dict})
    try
        # Validate each entry before saving
        for entry in entries
            validate_dictionary_entry(entry)
        end
        
        # Write to file
        open(filename, "w") do io
            JSON.print(io, entries)
        end
    catch e
        error("Error saving seed dictionary: $e")
    end
end

"""
    add_to_dictionary(input::String, output::String)

Add a new entry to the seed dictionary
"""
function add_to_dictionary(input::String, output::String)
    push!(SEED_DICTIONARY, Dict(
        "input" => input,
        "output" => output
    ))
end

"""
    has_in_dictionary(statement::String)

Check if a statement exists in the dictionary
"""
function has_in_dictionary(statement::String)
    for entry in SEED_DICTIONARY
        if entry["input"] == statement
            return true
        end
    end
    return false
end

"""
    get_from_dictionary(statement::String)

Get the output for a given input statement from the dictionary
"""
function get_from_dictionary(statement::String)
    for entry in SEED_DICTIONARY
        if entry["input"] == statement
            return entry["output"]
        end
    end
    return nothing
end


# Export SEED_DICTIONARY
export SEED_DICTIONARY

# Default seed dictionary entries
const SEED_DICTIONARY = [
    Dict(
        "input" => "Define a polynomial ring R with variables x0, x1, x2, and x3 over the rational numbers QQ.",
        "output" => "R, (x0, x1, x2, x3) = polynomial_ring(QQ, [\"x0\", \"x1\", \"x2\", \"x3\"])",
    ),
    Dict(
        "input" => "Define a matrix A with integer entries.",
        "output" => "A = matrix(ZZ, 3, 3, [1 2 3; 4 5 6; 7 8 9])"
    ),
    Dict(
        "input" => "Compute the determinant of matrix A.",
        "output" => "det(A)"
    ),
    Dict(
        "input" => "Find the eigenvalues of matrix A.",
        "output" => "eigenvalues(A)"
    ),
    Dict(
        "input" => "Define a polynomial f with coefficients in QQ.",
        "output" => "f = QQ[x]([1, 2, 3])"
    ),
    Dict(
        "input" => "Factor the polynomial x^2 - 5x + 6 over the integers.",
        "output" => "factor(x^2 - 5*x + 6)"
    ),
    Dict(
        "input" => "Find the roots of the polynomial x^2 - 5x + 6.",
        "output" => "roots(x^2 - 5*x + 6)"
    ),
    Dict(
        "input" => "Compute the gcd of two polynomials f and g.",
        "output" => "gcd(f, g)"
    ),
    Dict(
        "input" => "Define a finite field with 7 elements.",
        "output" => "F = GF(7)"
    ),
    Dict(
        "input" => "Define a polynomial ring over the finite field F.",
        "output" => "R = F[x]"
    )
]

# Export functions
export validate_dictionary_entry, load_seed_dictionary, save_seed_dictionary, DEFAULT_DICTIONARY
export add_to_dictionary, has_in_dictionary, get_from_dictionary

end # module SeedDictionary
