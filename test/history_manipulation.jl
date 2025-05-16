module ContextManipulationTests

using OscarAICoder
using Test

# Import all necessary functions
import OscarAICoder: CONFIG, delete_history_entry, edit_history_entry, clear_context!

# Simplified process_statement for testing
function process_statement(statement::String; kwargs...)
    push!(CONFIG[:context][:history], ("user", statement))
    CONFIG[:context][:is_first_statement] = length(CONFIG[:context][:history]) == 1
    
    # Enforce max history
    if length(CONFIG[:context][:history]) > CONFIG[:context][:max_history]
        # Keep the first entry and the last max_history-1 entries
        CONFIG[:context][:history] = vcat(
            CONFIG[:context][:history][1:1],  # Keep first entry
            CONFIG[:context][:history][end-(CONFIG[:context][:max_history]-2):end]  # Keep last max_history-1 entries
        )
        CONFIG[:context][:is_first_statement] = false  # Reset is_first_statement after truncation
    end
    
    return nothing
end

@testset "History Manipulation Tests" begin
    # Initialize history with two entries
    clear_context!()
    CONFIG[:context][:max_history] = 10  # Set default max history
    
    # Test empty history
    history = get_history()
    @test length(history) == 0
    @test is_first_statement() == true
    
    # Add first statement
    process_statement("First statement")
    history = get_history()
    @test length(history) == 1
    @test history[1].content == "First statement"
    @test history[1].role == "user"
    @test is_first_statement() == true
    clear_context!()  # Clear after test
    
    # Add more statements
    process_statement("First")
    process_statement("Second")
    process_statement("Third")
    
    # Verify initial state
    history = get_history()
    @test length(history) == 3
    @test history[1].content == "First"
    @test history[1].role == "user"
    @test history[2].content == "Second"
    @test history[2].role == "user"
    @test history[3].content == "Third"
    @test history[3].role == "user"
    @test is_first_statement() == false
    clear_context!()  # Clear after test

    # Test max history
    clear_context!()
    CONFIG[:context][:max_history] = 2
    process_statement("First")
    process_statement("Second")
    process_statement("Third")
    
    history = get_history()
    @test length(history) == 2
    @test history[1].content == "First"
    @test history[1].role == "user"
    @test history[2].content == "Third"
    @test history[2].role == "user"
    @test is_first_statement() == false
    clear_context!()  # Clear after test

    # Test deletion
    clear_context!()
    CONFIG[:context][:max_history] = 10
    process_statement("First")
    process_statement("Second")
    history = get_history()
    @test length(history) == 2
    @test history[1].content == "First"
    @test history[1].role == "user"
    @test history[2].content == "Second"
    @test history[2].role == "user"
    @test is_first_statement() == false

    @testset "Deletion Tests" begin
        # Invalid indices
        @test_throws ErrorException delete_history_entry(0)  # Invalid index
        @test_throws ErrorException delete_history_entry(4)  # Out of bounds
        @test_throws ErrorException delete_history_entry(-1) # Negative index
        
        # Cannot delete first entry
        @test_throws ErrorException delete_history_entry(1)
        
        # Delete middle entry
        delete_history_entry(2)
        history = get_history()
        @test length(history) == 2
        @test history[1].content == "First"
        @test history[1].role == "user"
        @test history[2].content == "Third"
        @test history[2].role == "user"
        
        # Delete last entry
        delete_history_entry(2)
        history = get_history()
        @test length(history) == 1
        @test history[1].content == "First"
        @test history[1].role == "user"
        @test is_first_statement() == true
        
        # Clear context
        clear_context!()
        @test is_first_statement() == true
        
        # Test invalid index after clearing
        @test_throws ErrorException delete_history_entry(2)  # Invalid index after clearing
        
        # Test cannot delete from empty history
        @test_throws ErrorException delete_history_entry(1)  # Cannot delete from empty history
    end
    clear_context!()  # Clear after deletion tests

    # Test editing
    clear_context!()
    CONFIG[:context][:max_history] = 10
    process_statement("First")
    process_statement("Second")
    history = get_history()
    @test length(history) == 2
    @test history[1].content == "First"
    @test history[1].role == "user"
    @test history[2].content == "Second"
    @test history[2].role == "user"
    @test is_first_statement() == false

    @testset "Editing Tests" begin
        # Invalid indices
        @test_throws ErrorException edit_history_entry(0, "user", "Test")  # Invalid index
        @test_throws ErrorException edit_history_entry(3, "user", "Test")  # Out of bounds
        @test_throws ErrorException edit_history_entry(-1, "user", "Test") # Negative index
        
        # Invalid roles
        @test_throws ErrorException edit_history_entry(1, "invalid_role", "Test")
        @test_throws ErrorException edit_history_entry(1, "", "Test")
        
        # Cannot change first entry role
        @test_throws ErrorException edit_history_entry(1, "assistant", "Test")
        
        # Valid edit
        original = edit_history_entry(2, "user", "Updated")
        @test original.content == "Second"
        @test original.role == "user"
        history = get_history()
        @test history[2].content == "Updated"
        @test history[2].role == "user"
        @test is_first_statement() == false
    end
    clear_context!()  # Clear after editing tests
end

        # Invalid indices
        @test_throws ErrorException delete_history_entry(0)  # Invalid index
        @test_throws ErrorException delete_history_entry(4)  # Out of bounds
        @test_throws ErrorException delete_history_entry(-1) # Negative index

        # Cannot delete first entry
        @test_throws ErrorException delete_history_entry(1)
        
        debug_mode!(true)
        # Delete middle entry
        delete_history_entry(2)
        @test length(CONFIG[:context][:history]) == 2
        @test CONFIG[:context][:history][1] == ("user", "First statement")
        @test CONFIG[:context][:history][2] == ("user", "Third statement")

        # Try to delete first entry - should fail
        @test_throws ErrorException delete_history_entry(1)
        
        # Delete last entry
        delete_history_entry(2)
        @test length(CONFIG[:context][:history]) == 1
        @test CONFIG[:context][:history][1] == ("user", "First statement")
        @test CONFIG[:context][:is_first_statement] == false
        debug_mode!(false)

        # Delete last remaining entry
        delete_history_entry(1)
        @test length(CONFIG[:context][:history]) == 0
        @test CONFIG[:context][:is_first_statement] == true
        clear_context!()  # Clear after deletion tests
    end

    # Test editing
    @testset "Editing Tests" begin
        # Invalid indices
        @test_throws ErrorException edit_history_entry(0, "user", "Test")  # Invalid index
        @test_throws ErrorException edit_history_entry(2, "user", "Test")  # Out of bounds
        @test_throws ErrorException edit_history_entry(-1, "user", "Test") # Negative index
        
        # Invalid roles
        @test_throws ErrorException edit_history_entry(1, "invalid_role", "Test")
        @test_throws ErrorException edit_history_entry(1, "", "Test")
        
        # Cannot change first entry role
        @test_throws ErrorException edit_history_entry(1, "assistant", "Test")
        
        # Valid edit
        original = edit_history_entry(1, "user", "Updated first statement")
        @test original == ("user", "First statement")
        @test CONFIG[:context][:history][1] == ("user", "Updated first statement")
        
        # Edit with different content
        original = edit_history_entry(1, "user", "Another update")
        @test original == ("user", "Updated first statement")
        @test CONFIG[:context][:history][1] == ("user", "Another update")
        
        # Clear and add entries
        clear_context!()
        process_statement("First")
        process_statement("Second")
        
        # Edit first entry
        original = edit_history_entry(1, "user", "Updated First")
        @test original == ("user", "First")
        @test CONFIG[:context][:history][1] == ("user", "Updated First")
        @test CONFIG[:context][:is_first_statement] == false
        
        # Edit second entry
        original = edit_history_entry(2, "user", "Updated Second")
        @test original == ("user", "Second")
        @test CONFIG[:context][:history][2] == ("user", "Updated Second")
        
        # Try to edit non-existent entry
        @test_throws ErrorException edit_history_entry(3, "user", "Should fail")
        clear_context!()  # Clear after editing tests
    end

    # Test max history
    @testset "Max History Tests" begin
        # Clear and set max history to 2
        clear_context!()
        CONFIG[:context][:max_history] = 2
        
        # Add more entries than max history
        process_statement("First")
        process_statement("Second")
        process_statement("Third")
        
        # Verify history maintains first entry and last max_history-1 entries
        @test length(CONFIG[:context][:history]) == 2
        @test CONFIG[:context][:history][1] == ("user", "First")
        @test CONFIG[:context][:history][2] == ("user", "Third")
        
        # Delete an entry
        delete_history_entry(2)
        @test length(CONFIG[:context][:history]) == 1
        @test CONFIG[:context][:history][1] == ("user", "First")
        
        # Add another entry
        process_statement("Fourth")
        @test length(CONFIG[:context][:history]) == 2
        @test CONFIG[:context][:history][1] == ("user", "First")
        @test CONFIG[:context][:history][2] == ("user", "Fourth")
        
        # Verify is_first_statement flag
        @test CONFIG[:context][:is_first_statement] == false
        clear_context!()  # Clear after max history tests
    end

    # Test edge cases
    @testset "Edge Case Tests" begin
        # Clear and add single entry
        clear_context!()
        process_statement("Only entry")
        
        # Try to delete only entry
        @test_throws ErrorException delete_history_entry(1)
        
        # Try to edit only entry
        original = edit_history_entry(1, "user", "Updated only")
        @test original == ("user", "Only entry")
        @test CONFIG[:context][:history][1] == ("user", "Updated only")
        
        # Clear and set max history to 1
        clear_context!()
        CONFIG[:context][:max_history] = 1
        
        # Add multiple entries
        process_statement("One")
        process_statement("Two")
        
        # Verify only last entry remains
        @test length(CONFIG[:context][:history]) == 1
        @test CONFIG[:context][:history][1] == ("user", "Two")
        @test CONFIG[:context][:is_first_statement] == false
        clear_context!()  # Clear after edge case tests
    end
end

end # module
