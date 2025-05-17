module HistoryManipulationTests

using OscarAICoder
using Test

@testset "History Manipulation Tests" begin
    clear_context!()
    debug_mode!(true)

    @test isempty(view_entries())

    # Test matrix calculations
    process_statement("Calculate the determinant of the matrix [[1, 2], [3, 4]]")
    history = view_entries()
    @test length(history) == 1
    @test history[1].content == "Calculate the determinant of the matrix [[1, 2], [3, 4]]"
    @test history[1].role == "user"
    
    # Test the actual Oscar code generation
    response = process_statement("Calculate the determinant of the matrix [[1, 2], [3, 4]]")
    @test occursin("det", response)
    @test occursin("[1, 2; 3, 4]", response)
    
    clear_context!()
    
    # Test polynomial and calculus operations
    process_statement("Find the roots of x^2 - 4x + 4 = 0")
    process_statement("Calculate the integral of x^2 from 0 to 1")
    process_statement("Prove that sin^2(x) + cos^2(x) = 1")
    
    history = view_entries()
    @test length(history) == 3
    @test history[1].content == "Find the roots of x^2 - 4x + 4 = 0"
    @test history[2].content == "Calculate the integral of x^2 from 0 to 1"
    @test history[3].content == "Prove that sin^2(x) + cos^2(x) = 1"
    
    # Test the actual Oscar code generation
    response1 = process_statement("Find the roots of x^2 - 4x + 4 = 0")
    @test occursin("solve", response1)
    @test occursin("x^2 - 4*x + 4", response1)
    
    response2 = process_statement("Calculate the integral of x^2 from 0 to 1")
    @test occursin("integrate", response2)
    @test occursin("x^2", response2)
    @test occursin("0..1", response2)
    
    response3 = process_statement("Prove that sin^2(x) + cos^2(x) = 1")
    @test occursin("sin", response3)
    @test occursin("cos", response3)
    @test occursin("==", response3)
    
    clear_context!()
    debug_mode!(false)

    @testset "Deletion Tests" begin
        process_statement("Calculate 2 + 2")
        process_statement("Find the derivative of x^2")
        @test length(view_entries()) == 2

        # Check the responses
        history = view_entries()
        @test history[1].content == "Calculate 2 + 2"
        @test history[2].content == "Find the derivative of x^2"

        # Test the actual Oscar code generation
        response1 = process_statement("Calculate 2 + 2")
        @test occursin("2 + 2", response1)
        
        response2 = process_statement("Find the derivative of x^2")
        @test occursin("derivative", response2)
        @test occursin("x^2", response2)

        @test_throws ErrorException delete_entry(0)
        @test_throws ErrorException delete_entry(4)
        @test_throws ErrorException delete_entry(-1)

        delete_entry(1)
        history = view_entries()
        @test length(history) == 1
        @test history[1].content == "Find the derivative of x^2"
        
        delete_entry(2)
        @test isempty(view_entries())
    end

    @testset "Editing Tests" begin
        clear_context!()
        process_statement("Calculate 2 + 2")
        
        @test_throws ErrorException edit_entry(0)
        @test_throws ErrorException edit_entry(2)

        edit_entry(1, content="Updated 2 + 2")
        history = view_entries()
        @test history[1].content == "Updated 2 + 2"
    end

    @testset "Persistence Tests" begin
        clear_context!()
        process_statement("Calculate the determinant of [[1, 2], [3, 4]]")
        process_statement("Find the roots of x^2 - 4x + 4 = 0")
        
        temp_file = tempname()
        save_to_file(temp_file)
        
        clear_context!()
        load_from_file(temp_file)
        
        history = view_entries()
        @test length(history) == 2
        @test history[1].content == "Calculate the determinant of [[1, 2], [3, 4]]"
        @test history[2].content == "Find the roots of x^2 - 4x + 4 = 0"
        
        # Verify that the Oscar code is still valid after loading
        response1 = process_statement(history[1].content)
        @test occursin("det", response1)
        @test occursin("[1, 2; 3, 4]", response1)
        
        response2 = process_statement(history[2].content)
        @test occursin("solve", response2)
        @test occursin("x^2 - 4*x + 4", response2)
        
        # Clean up
        rm(temp_file)
    end
end

end # module
