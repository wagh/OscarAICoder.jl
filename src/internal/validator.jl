const OSCAR_IDENTIFIERS = names(Oscar, all=false)
const declared_vars = Set{Symbol}()

"""
    validate_oscar_code(code::String)

Validate Oscar code for syntax and semantic correctness.

# Returns
- `Nothing`: If the code is valid
- `String`: Error message if the code is invalid
"""
function validate_oscar_code(code::Union{String, SubString{String}})::Union{Nothing,String}
    # Convert SubString to String if needed
    code_str = String(code)
    debug_print("Validating Oscar code: $code_str")
   
    # First, check if the code is empty
    isempty(strip(code_str)) && return "Code is empty"
    
    # Step 1: Syntax check        
    # Parse the code (syntax check)
    debug_print("Parsing code...")
    parsed = try
                Meta.parseall(code)
            catch e
                return "Syntax error: $e"
            end
    debug_print("Parsed expression: $parsed")

    # Collect all identifiers from the parsed expression
    debug_print("Collecting all identifiers...")
    identifiers = Set{String}()
    
    # Function to collect identifiers from an expression
    function collect_identifiers(expr)
        if expr isa Symbol
            push!(identifiers, string(expr))
        elseif expr isa Expr
            for arg in expr.args
                collect_identifiers(arg)
            end
        end
    end
    collect_identifiers(parsed)
    debug_print("Collected identifiers: $(join(collect(identifiers), ", "))")

    # Collect declarations
    debug_print("Collecting declarations...")
    local_vars = Set{Symbol}()  # Use a local variable instead of global
    collect_declarations(parsed, local_vars)
    debug_print("Collected declared variables: $(join(map(string, collect(local_vars)), ", "))")

    # Update global declared_vars for this validation
    empty!(declared_vars)
    union!(declared_vars, local_vars)

    # Add identifiers from context history
    debug_print("Collecting identifiers from context history...")
    for (role, code) in CONFIG[:context][:history]
        if role == "assistant" && !isempty(code)
            try
                parsed = Meta.parseall(code)
                collect_identifiers(parsed)
            catch
                continue
            end
        end
    end
    debug_print("Total identifiers from history: $(length(identifiers))")

    # Create a set of all valid identifiers (Oscar + declared + history)
    debug_print("Creating set of all valid identifiers...")
    valid_identifiers = Set{String}()
    union!(valid_identifiers, map(string, collect(OSCAR_IDENTIFIERS)))
    union!(valid_identifiers, map(string, collect(declared_vars)))
    union!(valid_identifiers, identifiers)  # Add identifiers from history
    debug_print("Total valid identifiers: $(length(valid_identifiers))")

    # Check if all identifiers are valid
    debug_print("Validating identifiers...")
    invalid_identifiers = filter(id -> !in(id, valid_identifiers), identifiers)
    if !isempty(invalid_identifiers)
        debug_print("Found invalid identifiers: $(join(invalid_identifiers, ", "))")
        return "Invalid Oscar code: Undefined identifiers: $(join(invalid_identifiers, ", "))"
    end
    debug_print("All identifiers are valid")

    debug_print("Validation successful")
    return nothing

end

function collect_declarations(expr, vars::Set{Symbol})
    if expr isa Expr
        if expr.head == :(=) || expr.head == :global || expr.head == :local || expr.head == :const
            # Handle polynomial ring declarations specially
            if expr.args[2] isa Expr && expr.args[2].head == :call && 
               expr.args[2].args[1] == :polynomial_ring
                # For polynomial_ring(R, (x,y,z)), we need to handle both R and (x,y,z)
                lhs = expr.args[1]
                if lhs isa Expr && lhs.head == :tuple
                    # Handle tuple case: (R, (x,y,z))
                    for elem in lhs.args
                        collect_lhs_vars(elem, vars)
                    end
                else
                    # Handle single variable case: R
                    collect_lhs_vars(lhs, vars)
                end
            else
                # Regular assignment/declaration
                lhs = expr.args[1]
                collect_lhs_vars(lhs, vars)
            end
        elseif expr.head == :for
            # For loop: first arg is the loop variable (Symbol or destructuring)
            loopvar = expr.args[1]
            collect_lhs_vars(loopvar, vars)
            # Recurse into the body of the loop
            collect_declarations(expr.args[end], vars)
        elseif expr.head == :block
            # Multiple expressions in a block
            for subexpr in expr.args
                collect_declarations(subexpr, vars)
            end
        else
            # Recursively process all arguments
            for arg in expr.args
                collect_declarations(arg, vars)
            end
        end
    end
end

function collect_lhs_vars(lhs::Any, vars::Set{Symbol})
    if lhs isa Symbol
        push!(vars, lhs)
    elseif lhs isa Expr && lhs.head == :tuple
        for elem in lhs.args
            collect_lhs_vars(elem, vars)
        end
    end
end

"""
    has_in_dictionary(statement::String)

Check if a statement contains only valid identifiers.
"""
function has_in_dictionary(statement::String)::Bool
    # Parse the statement to get identifiers
    parsed = Meta.parseall(statement)
    identifiers = Set{String}()
    
    function collect_identifiers(expr)
        if expr isa Symbol
            push!(identifiers, string(expr))
        elseif expr isa Expr
            for arg in expr.args
                collect_identifiers(arg)
            end
        end
    end
    collect_identifiers(parsed)
    
    # Create a set of all valid identifiers
    valid_identifiers = Set{String}()
    union!(valid_identifiers, map(string, collect(OSCAR_IDENTIFIERS)))
    union!(valid_identifiers, map(string, collect(declared_vars)))
    
    # Check if all identifiers are valid
    return all(id -> in(id, valid_identifiers), identifiers)
end
