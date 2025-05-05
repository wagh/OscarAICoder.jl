using Oscar
using Base.Meta

"""
    execute_statement(oscar_code::String)

Execute Oscar code and return the result.
"""

function execute_statement(oscar_code::String)
    
    # Execute the code and capture the result
    try
        # Split the code into lines
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
