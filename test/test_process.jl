using OscarAICoder
using Test

@testset "OscarAICoder Tests" begin
    @testset "process_statement Tests" begin
        # Test with dictionary match
        statement = "Define a polynomial ring R with variables x0, x1, x2, and x3 over the rational numbers QQ."
        code = OscarAICoder.Core.process_statement(statement)
        @test code == "R, (x0, x1, x2, x3) = polynomial_ring(QQ, [\"x0\", \"x1\", \"x2\", \"x3\"])"
        
        # Test with invalid input
        @test_throws ErrorException OscarAICoder.Core.process_statement("")
        @test_throws ErrorException OscarAICoder.Core.process_statement(123)
        
        # Test with invalid backend
        @test_throws ErrorException OscarAICoder.Core.process_statement("test", backend=:INVALID)
        
        # Test with missing credentials
        # External backends disabled
        # @test_throws ErrorException OscarAICoder.Core.process_statement("test", backend=:HUGGINGFACE)
        # @test_throws ErrorException OscarAICoder.Core.process_statement("test", backend=:GITHUB)
        
        # Test with invalid Oscar code
        invalid_statement = "This is not a valid mathematical statement"
        try
            OscarAICoder.Core.process_statement(invalid_statement)
            error("Expected error was not thrown")
        catch e
            @test occursin("Invalid Oscar code", string(e))
        end
        
        # Test with training mode
        Config.CONFIG.training_mode = true
        try
            process_statement(statement)
            @test Config.CONFIG.context.is_first_statement
            @test isempty(Config.CONFIG.context.history)
        finally
            Config.CONFIG.training_mode = false
        end
        
        # Test dictionary mode disabled
        Config.CONFIG.dictionary_mode = :disabled
        try
            process_statement(statement)
            @test Config.CONFIG.dictionary_mode == :disabled
        finally
            Config.CONFIG.dictionary_mode = :enabled
        end
        
        # Test history tracking
        process_statement("test statement")
        history = Types.get_entries(Types.HISTORY_STORE)
        @test length(history) > 0
        @test history[end].original_statement == "test statement"
    end
end
