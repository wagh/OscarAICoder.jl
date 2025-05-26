using OscarAICoder
using Test

@testset "Validator Tests" begin
    # Test empty code
    @test validate_oscar_code("") !== nothing
    @test validate_oscar_code("  ") !== nothing

    # Test valid Oscar code
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\")") === nothing
    @test validate_oscar_code("f = x^2 + 2x + 1") === nothing
    @test validate_oscar_code("roots(f)") === nothing

    # Test invalid syntax and Oscar functions
    @test validate_oscar_code("R, x = polynomial_ring(QQ, x)") !== nothing
    @test validate_oscar_code("f = x^2 + 2x + 1; roots(f) = 1") !== nothing
    @test validate_oscar_code("invalid_oscar_func(1, 2)") !== nothing

    # Test undefined symbols
    @test validate_oscar_code("g = x^2 + 2x + 1") !== nothing
    @test validate_oscar_code("roots(f)") !== nothing

    # Test multiple statements
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); f = x^2 + 2x + 1") === nothing
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); f = x^2 + 2x + 1; roots(f)") === nothing

    # Test invalid assignments
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); x = 1") !== nothing
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); R = 1") !== nothing

    # Test type errors
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); f = x^2 + 2x + 1; f + 1.0") !== nothing
    @test validate_oscar_code("R, x = polynomial_ring(QQ, \"x\"); f = x^2 + 2x + 1; f * [1, 2, 3]") !== nothing

    # Test process_statement with validation
    try
        # Test valid statements
        valid_statements = [
            "Calculate the determinant of the matrix [[1, 2], [3, 4]]",
            "Find the roots of x^2 - 4x + 4 = 0"
        ]
        
        # Test each statement
        for statement in valid_statements
            response = process_statement(statement)
            if occursin("# Invalid Oscar code:", response)
                @test false "Invalid Oscar code was generated: $response"
            else
                validation_result = validate_oscar_code(response)
                @test validation_result === nothing || occursin("Invalid Oscar code", validation_result)
            end
        end
    catch e
        println("Error in test: $e")
        @test false
    end
end
