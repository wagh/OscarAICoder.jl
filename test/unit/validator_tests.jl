using OscarAICoder
using Test
using .TestHelpers

@testset "Validator Tests" begin
    setup_test_environment!()
    
    @testset "Valid Oscar Code" begin
        valid_statements = [
            "R, (x, y) = polynomial_ring(QQ, [\"x\", \"y\"])" => true,
            "A = matrix(QQ, [1 2; 3 4])" => true,
            "I = ideal(R, x^2 + y^2 - 1)" => true
        ]
        
        for (statement, expected) in valid_statements
            @test OscarAICoder.Validator.validate_oscar_code(statement) == expected
        end
    end
    
    @testset "Invalid Oscar Code" begin
        invalid_statements = [
            "R, (x, y) = polynomial_ring(ZZ, [\"x\", \"y\"])" => false,  # ZZ not allowed for polynomial ring
            "A = matrix(RR, [1 2; 3 4])" => false,  # RR not defined
            "I = ideal(R, x^2 + y^2 - 1)" => false,  # R not defined
            "invalid_code()" => false
        ]
        
        for (statement, expected) in invalid_statements
            @test OscarAICoder.Validator.validate_oscar_code(statement) == expected
        end
    end
    
    @testset "Context Validation" begin
        # Test with context history
        process_statement("R, (x, y) = polynomial_ring(QQ, [\"x\", \"y\"])")
        @test OscarAICoder.Validator.validate_oscar_code("I = ideal(R, x^2 + y^2 - 1)")
        
        # Test with invalid context
        process_statement("invalid_declaration")
        @test !OscarAICoder.Validator.validate_oscar_code("use_invalid_var")
    end
    
    teardown_test_environment!()
end
