const OSCAR_IDENTIFIERS = names(Oscar, all=false)

# """
#     validate_oscar_code(code::String)

# Validate Oscar code for syntax and semantic correctness.

# # Returns
# - `Nothing`: If the code is valid
# - `String`: Error message if the code is invalid
# """
# function validate_oscar_code(code::String)::Union{Nothing,String}
#     try
#         debug_print("Validating Oscar code: $code")
        
#         # First, check if the code is empty
#         isempty(strip(code)) && return "Code is empty"
        
#         # Parse the code once
#         debug_print("Parsing code...")
#         parsed = Meta.parseall(code)
#         debug_print("Parsed expression: $parsed")
        
#         # Extract all identifiers from the parsed code
#         debug_print("Extracting identifiers...")
#         identifiers = Set{String}()
#         function collect_identifiers(expr)
#             if isa(expr, Symbol)
#                 # Don't collect symbols that are numbers or special characters
#                 sym_str = string(expr)
#                 if !isdigit(sym_str[1]) && !occursin(r"^[\[\]\.\(\)\{\}\+\-\*\/%=<>!|&\$#@~^_:,;\?\"'`\\]+$", sym_str)
#                     push!(identifiers, sym_str)
#                 end
#             elseif isa(expr, Expr)
#                 for arg in expr.args
#                     collect_identifiers(arg)
#                 end
#             end
#         end
#         collect_identifiers(parsed)
#         debug_print("Found identifiers: $(join(sort(collect(identifiers)), ", "))")
        
#         # Check if all identifiers are valid Oscar identifiers
#         debug_print("Checking identifier validity...")
#         # Save Oscar identifiers to a temporary file
#         temp_file = "/tmp/oscar_identifiers.txt"
#         open(temp_file, "w") do io
#             write(io, "Oscar Identifiers:\n")
#             for id in sort(collect(oscar_identifiers))
#                 write(io, "$id\n")
#             end
#         end
#         debug_print("Oscar identifiers saved to $temp_file")
        
#         # Filter invalid identifiers
#         invalid_identifiers = filter(id -> !any(x -> string(x) == id, oscar_identifiers), identifiers)
#         if !isempty(invalid_identifiers)
#             debug_print("Found invalid identifiers: $(join(sort(collect(invalid_identifiers)), ", "))")
#             return "Invalid Oscar code: Undefined identifiers:\n\n $(join(invalid_identifiers, ", "))"
#         end
        
#         # Create a sandbox environment with Oscar loaded
#         debug_print("Creating sandbox environment...")
#         sandbox = Module()
#         Core.eval(sandbox, :(import Oscar))
        
#         # Evaluate the code in the sandbox
#         debug_print("Evaluating code in sandbox...")
#         try
#             Core.eval(sandbox, parsed)
#             debug_print("Code evaluation successful")
#         catch e
#             debug_print("Error during sandbox evaluation: $e")
#             if isa(e, MethodError)
#                 return "Runtime error: MethodError: no method matching $(e.f)($(join(map(string, e.args), ", ")))"
#             elseif isa(e, UndefVarError)
#                 return "Runtime error: $(typeof(e))"
#             else
#                 return "Runtime error: $e"
#             end
#         end
        
#         debug_print("Validation successful")
#         return nothing
#     catch e
#         debug_print("Error in validation: $e")
#         if isa(e, UndefVarError)
#             return "Invalid Oscar code: $(typeof(e))"
#         elseif isa(e, SyntaxError)
#             return "Syntax error in code: $(typeof(e))"
#         else
#             return "Error in validation: $e"
#         end
#     end
# end


# function validate_oscar_code(code::String)::Union{Nothing,String}
#     debug_print("Validating Oscar code: $code")
        
#     # First, check if the code is empty
#     isempty(strip(code)) && return "Code is empty"

#     # Step 1: Syntax check        
#     # Parse the code (syntax check)
#     debug_print("Parsing code...")
#     parsed = try
#                 Meta.parseall(code)
#             catch e
#                 return "Syntax error: $e"
#             end
#     debug_print("Parsed expression: $parsed")

#     # Step 2: Semantic check
#     # Collect identifiers from AST
#     debug_print("Collecting identifiers from AST...")
#     identifiers = Set{String}()
#     function collect_identifiers(expr)
#         if expr isa Symbol
#             sym_str = string(expr)
#             if !isdigit(sym_str[1]) && !occursin(r"^[\[\]\.\(\)\{\}\+\-\*\/%=<>!|&\$#@~^_:,;\?\"'`\\]+$", sym_str)
#                 push!(identifiers, sym_str)
#             end
#         elseif expr isa Expr
#             for arg in expr.args
#                 collect_identifiers(arg)
#             end
#         end
#     end
#     collect_identifiers(parsed)
#     debug_print("Collected identifiers: $(join(collect(identifiers), ", "))")

#     # Check if all identifiers are valid Oscar identifiers
#     debug_print("Checking identifier validity...")
#     invalid_identifiers = filter(id -> !any(x -> string(x) == id, OSCAR_IDENTIFIERS), identifiers)
#     if !isempty(invalid_identifiers)
#         debug_print("Found invalid identifiers: $(join(collect(invalid_identifiers), ", "))")
#         return "Invalid Oscar code: Undefined identifiers: $(join(invalid_identifiers, ", "))"
#     end
#     debug_print("All identifiers are valid Oscar identifiers")
        
#     # Evaluate safely in sandbox
#     debug_print("Creating sandbox environment...")
#     sandbox = Module()
#     Core.eval(sandbox, :(import Oscar))
#     debug_print("Oscar imported in sandbox")

#     try
#         debug_print("Evaluating code in sandbox...")
#         Core.eval(sandbox, parsed)
#         debug_print("Code evaluation successful")
#         catch e
#             debug_print("Error during sandbox evaluation: $e")
#             # Explicit runtime error feedback
#             return "Runtime error during evaluation: $e"
#         end

#     debug_print("Validation successful")
#     return nothing

# end

function validate_oscar_code(code::String)::Union{Nothing,String}
    debug_print("Validating Oscar code: $code")
   
    # First, check if the code is empty
    isempty(strip(code)) && return "Code is empty"
    
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
    empty!(declared_vars)
    collect_declarations(parsed)
    debug_print("Collected declared variables: $(join(map(string, collect(declared_vars)), ", "))")

    # Create a set of all valid identifiers (Oscar + declared)
    debug_print("Creating set of all valid identifiers...")
    valid_identifiers = Set{String}()
    union!(valid_identifiers, map(string, collect(OSCAR_IDENTIFIERS)))
    union!(valid_identifiers, map(string, collect(declared_vars)))
    debug_print("Total valid identifiers: $(length(valid_identifiers))")

    # Check if all identifiers are valid
    debug_print("Validating identifiers...")
    invalid_identifiers = filter(id -> !in(id, valid_identifiers), identifiers)
    if !isempty(invalid_identifiers)
        debug_print("Found invalid identifiers: $(join(invalid_identifiers, ", "))")
        return "Invalid Oscar code: Undefined identifiers: $(join(invalid_identifiers, ", "))"
    end
    debug_print("All identifiers are valid")

    # # Evaluate safely in sandbox
    # debug_print("Creating sandbox environment...")
    # sandbox = Module()
    # Core.eval(sandbox, :(import Oscar))
    # debug_print("Oscar imported in sandbox")

    # try
    #     debug_print("Evaluating code in sandbox...")
    #     Core.eval(sandbox, parsed)
    #     debug_print("Code evaluation successful")
    # catch e
    #     debug_print("Error during sandbox evaluation: $e")
    #     # Explicit runtime error feedback
    #     return "Runtime error during evaluation: $e"
    # end

    debug_print("Validation successful")
    return nothing

end


declared_vars = Set{Symbol}()

function collect_declarations(expr)
    if expr isa Expr
        if expr.head == :(=) || expr.head == :global || expr.head == :local || expr.head == :const
            # Assignment or declaration, left-hand side is a variable or tuple
            lhs = expr.args[1]
            collect_lhs_vars(lhs)
        elseif expr.head == :for
            # For loop: first arg is the loop variable (Symbol or destructuring)
            loopvar = expr.args[1]
            collect_lhs_vars(loopvar)
            # Recurse into the body of the loop
            collect_declarations(expr.args[end])
        elseif expr.head == :block
            # Multiple expressions in a block
            for subexpr in expr.args
                collect_declarations(subexpr)
            end
        else
            # Recursively process all arguments
            for arg in expr.args
                collect_declarations(arg)
            end
        end
    end
end

function collect_lhs_vars(lhs)
    if lhs isa Symbol
        push!(declared_vars, lhs)
    elseif lhs isa Expr && lhs.head == :tuple
        for elem in lhs.args
            collect_lhs_vars(elem)
        end
    end
end
