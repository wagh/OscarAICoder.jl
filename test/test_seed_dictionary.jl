using OscarAICoder
using Test

@testset "SeedDictionary Tests" begin
    @testset "Validation Tests" begin
        # Valid entry
        valid_entry = Dict(
            "input" => "Define a polynomial ring",
            "output" => "R = polynomial_ring(QQ, [\"x\"]\)"
        )
        @test OscarAICoder.Core.SeedDictionary.validate_dictionary_entry(valid_entry) === nothing
        
        # Missing input
        @test_throws ErrorException OscarAICoder.Core.SeedDictionary.validate_dictionary_entry(Dict(
            "output" => "R = polynomial_ring(QQ, [\"x\"]\)"
        ))
        
        # Missing output
        @test_throws ErrorException OscarAICoder.Core.SeedDictionary.validate_dictionary_entry(Dict(
            "input" => "Define a polynomial ring"
        ))
        
        # Invalid input type
        @test_throws ErrorException OscarAICoder.Core.SeedDictionary.validate_dictionary_entry(Dict(
            "input" => 123,
            "output" => "R = polynomial_ring(QQ, [\"x\"]\)"
        ))
        
        # Invalid output type
        @test_throws ErrorException OscarAICoder.Core.SeedDictionary.validate_dictionary_entry(Dict(
            "input" => "Define a polynomial ring",
            "output" => 123
        ))
        
        # Invalid Oscar code
        @test_throws ErrorException Core.SeedDictionary.validate_dictionary_entry(Dict(
            "input" => "Define a polynomial ring",
            "output" => "invalid code"
        ))
    end

    @testset "File Operations Tests" begin
        tmp_file = tempname()
        
        # Test saving and loading
        entries = [
            Dict(
                "input" => "Test statement",
                "output" => "test_code()"
            )
        ]
        
        try
            Core.SeedDictionary.save_seed_dictionary(tmp_file, entries)
            loaded_entries = Core.SeedDictionary.load_seed_dictionary(tmp_file)
            @test length(loaded_entries) == 1
            @test loaded_entries[1]["input"] == "Test statement"
            @test loaded_entries[1]["output"] == "test_code()"
        finally
            rm(tmp_file; force=true)
        end
        
        # Test invalid file content
        invalid_file = tempname()
        try
            open(invalid_file, "w") do io
                write(io, "invalid json")
            end
            
            @test_throws ErrorException Core.SeedDictionary.load_seed_dictionary(invalid_file)
        finally
            rm(invalid_file; force=true)
        end
    end
end
