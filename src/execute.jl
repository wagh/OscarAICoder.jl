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

function execute_statement(oscar_code::String)
    
    # Load Oscar only when needed
    Oscar = load_oscar()
    debug_print("Starting Oscar execution")
    
    # Execute the code and capture the result
    try
        # Ensure Oscar is imported
        eval(Meta.parse("using Oscar"))
        
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
        return eval(Meta.parse(lines[end]))
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
