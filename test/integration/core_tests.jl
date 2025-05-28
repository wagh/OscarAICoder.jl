using OscarAICoder
using Test
using .TestHelpers

@testset "Core Functionality Tests" begin
    setup_test_environment!()
    
    @testset "Basic Operations" begin
        test_cases = [
            "Calculate the determinant of the matrix [[1, 2], [3, 4]]" => "A = matrix(QQ, [1 2; 3 4]); det(A)",
            "Find the roots of x^2 - 4x + 4 = 0" => "R, (x,) = polynomial_ring(QQ, [\"x\"]); f = x^2 - 4*x + 4; roots(f)",
            "Calculate the integral of x^2 from 0 to 1" => "R, (x,) = polynomial_ring(QQ, [\"x\"]); f = x^2; integrate(f, x, 0, 1)",
            "Prove that sin^2(x) + cos^2(x) = 1" => "R, (x,) = polynomial_ring(QQ, [\"x\"]); f = sin(x)^2 + cos(x)^2 - 1; f"
        ]
        
        run_test_cases(test_cases)
    end
    
    @testset "Context Management" begin
        # Test variable persistence
        process_statement("R, (x, y) = polynomial_ring(QQ, [\"x\", \"y\"])")
        @test occursin("R", process_statement("Calculate the determinant of the matrix [[x, y], [y, x]]"))
        
        # Test history tracking
        process_statement("test statement")
        history = OscarAICoder.History.view_entries()
        @test length(history) == 1
        @test history[1].content == "test statement"
        @test history[1].role == "user"
    end
    
    @testset "Backend Tests" begin
        # Test local backend
        @test occursin("matrix", process_statement("Calculate the determinant of the matrix [[1, 2], [3, 4]]", backend=:local))
        
        # Test dictionary mode
        Config.CONFIG.dictionary_mode = :only
        try
            @test occursin("polynomial_ring", process_statement("Define a polynomial ring R with variables x0, x1, x2, and x3 over the rational numbers QQ."))
        finally
            Config.CONFIG.dictionary_mode = :enabled
        end
    end
    
    teardown_test_environment!()
end
