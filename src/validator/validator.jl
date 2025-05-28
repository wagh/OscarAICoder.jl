module Validator

# Core dependencies
using Oscar
using ..Debug
using ..Config

# Constants
const OSCAR_IDENTIFIERS = names(Oscar, all=false)
const declared_vars = Set{Symbol}()

# Helper functions
function collect_declarations(expr, vars::Set{Symbol})
    debug_print("Processing declaration expression: $(string(expr))")
    
    if expr isa Expr
        debug_print("Expression head: $(expr.head)")
        
        if expr.head == :(=) || expr.head == :global || expr.head == :local || expr.head == :const
            debug_print("Found declaration/assignment expression")
            
            # Handle polynomial ring declarations specially
            if expr.args[2] isa Expr && expr.args[2].head == :call && 
               expr.args[2].args[1] == :polynomial_ring
                debug_print("Found polynomial ring declaration")
                # For polynomial_ring(R, (x,y,z)), we need to handle both R and (x,y,z)
                lhs = expr.args[1]
                if lhs isa Expr && lhs.head == :tuple
                    debug_print("Found tuple declaration in polynomial ring")
                    # Handle tuple case: (R, (x,y,z))
                    for elem in lhs.args
                        collect_lhs_vars(elem, vars)
                    end
                else
                    debug_print("Found single variable in polynomial ring")
                    # Handle single variable case: R
                    collect_lhs_vars(lhs, vars)
                end
            else
                debug_print("Found regular assignment/declaration")
                # Regular assignment/declaration
                lhs = expr.args[1]
                collect_lhs_vars(lhs, vars)
            end
        elseif expr.head == :for
            debug_print("Found for loop declaration")
            # For loop: first arg is the loop variable (Symbol or destructuring)
            loopvar = expr.args[1]
            collect_lhs_vars(loopvar, vars)
            # Recurse into the body of the loop
            collect_declarations(expr.args[end], vars)
        elseif expr.head == :block
            debug_print("Found block expression")
            # Multiple expressions in a block
            for subexpr in expr.args
                collect_declarations(subexpr, vars)
            end
        end
    else
        debug_print("Expression is not an Expr: $(typeof(expr))")
    end
end

function collect_lhs_vars(expr, vars::Set{Symbol})
    if expr isa Symbol
        push!(vars, expr)
    elseif expr isa Expr && expr.head == :tuple
        for elem in expr.args
            collect_lhs_vars(elem, vars)
        end
    end
end

# Validation functions
function validate_oscar_code(code::Union{String, SubString{String}})::Bool
    # Convert SubString to String if needed
    code_str = String(code)
    debug_print("Validating Oscar code: $code_str")
   
    try
        # First, check if the code is empty
        isempty(strip(code_str)) && return false
        
        # Step 1: Syntax check        
        # Parse the code (syntax check)
        debug_print("Parsing code...")
        parsed = Base.Meta.parseall(code)
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
        for (role, code) in Config.CONFIG.context.history
            if role == "assistant" && !isempty(code)
                try
                    parsed = Base.Meta.parseall(code)
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
            return false
        end
        debug_print("All identifiers are valid")

        debug_print("Validation successful")
        return true
    catch e
        debug_print("Error in validation: $e")
        return false
    end
end

# Export validator
export validate_oscar_code

end # module Validator
