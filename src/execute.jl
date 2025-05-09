using Base.Meta

# Load Oscar only when needed
function load_oscar()
    global Oscar
    Oscar = Base.require(Base.PkgId(Base.UUID("f1435218-dba5-11e9-1e4d-f1a5fab5fc13"), "Oscar"))
    return Oscar
end

"""
    execute_statement(oscar_code::String)

Execute Oscar code and return the result.
"""

function execute_statement(oscar_code::String; clear_context=false)
    
    # Load Oscar only when needed
    Oscar = load_oscar()
    debug_print("Starting Oscar execution")
    
    # Execute the code and capture the result
    try
        # Ensure Oscar is imported
        eval(Meta.parse("using Oscar"))
        
        # Clear context if requested
        if clear_context
            CONFIG[:context][:history] = []
        end

        # Check if this is the first statement in context mode
        is_first_statement = isempty(CONFIG[:context][:history])

        # Add current statement to history
        push!(CONFIG[:context][:history], ("user", oscar_code))
        
        # Keep only last N interactions
        if length(CONFIG[:context][:history]) > CONFIG[:context][:max_history]
            CONFIG[:context][:history] = CONFIG[:context][:history][end-CONFIG[:context][:max_history]+1:end]
        end

        # If this is the first statement, don't use history
        if is_first_statement
            debug_print("First statement, not using history")
        else
            # Process history entries, skipping duplicates
            processed_code = Set{String}()
            for (role, code) in CONFIG[:context][:history]
                if role == "assistant" && !isempty(code) && !in(code, processed_code)
                    debug_print("Processing history code: $code")
                    # Split and evaluate each line
                    lines = split(strip(code), '\n')
                    for line in lines
                        if !isempty(strip(line))
                            eval(Meta.parse(line))
                        end
                    end
                    push!(processed_code, code)
                end
            end
        end
        
        # Split the code into lines and evaluate
        debug_print("Code: $oscar_code")
        debug_print("Splitting code into lines")
        lines = split(strip(oscar_code), '\n')
        
        # Evaluate each line separately
        for line in lines
            if !isempty(strip(line))
                eval(Meta.parse(line))
            end
        end
        
        # Return the last evaluated expression
        last_result = eval(Meta.parse(lines[end]))
        
        # Add the result to history
        push!(CONFIG[:context][:history], ("assistant", string(last_result)))
        
        return last_result
    catch e
        error("Error executing Oscar code: $e\nCode: $oscar_code")
    end
end

"""
    execute_statement(oscar_code::String; output_format=:string)

Execute Oscar code and return the result in the specified format.
Available formats: :string, :latex, :html
"""
function execute_statement_with_format(oscar_code::String; output_format=:string)
    
    # Load Oscar only when needed
    Oscar = load_oscar()
    
    # Execute the code and capture the result
    try
        # Use eval to execute the code
        result = eval(Meta.parse(oscar_code))
        
        # Format the output based on requested format
        if output_format == :latex
            return Oscar.latex(result)
        elseif output_format == :html
            return Oscar.html(result)
        else  # default to string
            return string(result)
        end
    catch e
        error("Error executing Oscar code: $e\nCode: $oscar_code")
    end
end
