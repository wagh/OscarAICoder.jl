module HistoryManipulationTests

using OscarAICoder
# using OscarAICoder.History # To directly use add_entry! for setup
using Test
using Dates # For current_timestamp if used directly

@testset "History Manipulation Tests" begin
    # Ensure debug mode is set (though not directly used for assertions in these history tests)
    set_debug_mode(true)

    @testset "Initial State and Basic Adding" begin
        clear_entries!()
        # Expected: History should be empty after clearing.
        @test isempty(get_entries()) # "History should be empty after clear_entries!"

        # Test adding a single entry
        ts1 = "2025-01-01_10-00-00"
        stmt1 = "Test statement 1"
        code1 = "R,x = QQ[x]; x+1"
        # Use internal History.add_entry! for controlled test setup
        add_entry!(ts1, stmt1, code1, true, nothing)
        
        history = get_entries()
        # Expected: History should contain one entry.
        @test length(history) == 1 # "History should have 1 entry after add_entry!"
        entry1 = history[1]
        @test entry1.timestamp == ts1
        @test entry1.original_statement == stmt1
        @test entry1.generated_code == code1
        @test entry1.is_valid == true
        @test entry1.validation_error === nothing
    end

    @testset "Get Entry and Multiple Entries" begin
        clear_entries!()
        ts1 = "2025-01-01_10-00-00"
        stmt1 = "Statement A"
        code1 = "code A"
        add_entry!(ts1, stmt1, code1, true)

        ts2 = "2025-01-01_10-05-00"
        stmt2 = "Statement B"
        code2 = "code B"
        add_entry!(ts2, stmt2, code2, false, "Syntax error")

        # Expected: get_entries should return all added entries.
        all_history = get_entries()
        @test length(all_history) == 2 # "Should have 2 entries"

        # Test get_entry(idx)
        # Expected: get_entry should retrieve the correct entry by 1-based index.
        retrieved_entry1 = get_entry(1)
        @test retrieved_entry1.original_statement == stmt1
        @test retrieved_entry1.generated_code == code1

        retrieved_entry2 = get_entry(2)
        @test retrieved_entry2.original_statement == stmt2
        @test retrieved_entry2.is_valid == false
        @test retrieved_entry2.validation_error == "Syntax error"

        # Expected: Accessing an out-of-bounds index should error.
        @test_throws ArgumentError get_entry(3)
        @test_throws ArgumentError get_entry(0)
    end

    @testset "Edit Entry" begin
        clear_entries!()
        add_entry!("ts_edit", "Original Stmt", "Original Code", true)
        
        # Edit the entry
        edit_entry!(1, "Edited Stmt", "Edited Code")
        edited_entry = get_entry(1)

        # Expected: Entry should be updated with new statement and code.
        # Timestamp should be preserved. Validity is reset by edit_entry!.
        @test edited_entry.original_statement == "Edited Stmt"
        @test edited_entry.generated_code == "Edited Code"
        @test edited_entry.timestamp == "ts_edit" # Timestamp should be preserved
        @test edited_entry.is_valid == true      # edit_entry! currently resets validation status to true
        @test edited_entry.validation_error === nothing

        # Expected: Editing an out-of-bounds index should error.
        @test_throws BoundsError edit_entry!(2, "foo", "bar")
    end

    @testset "Delete Entry" begin
        clear_entries!()
        add_entry!("ts1_del", "Stmt1", "Code1", true)
        add_entry!("ts2_del", "Stmt2", "Code2", true)
        add_entry!("ts3_del", "Stmt3", "Code3", true)
        
        # Delete the middle entry
        delete_entry!(2) 
        current_history = get_entries()
        # Expected: History should have 2 entries, with the second one removed.
        @test length(current_history) == 2 # "History should have 2 entries after deleting middle entry"
        @test current_history[1].original_statement == "Stmt1"
        @test current_history[2].original_statement == "Stmt3"

        # Delete the new first entry (originally Stmt1)
        delete_entry!(1) 
        current_history = get_entries()
        # Expected: History should have 1 entry (originally Stmt3).
        @test length(current_history) == 1 # "History should have 1 entry after deleting first entry"
        @test current_history[1].original_statement == "Stmt3"

        # Expected: Deleting an out-of-bounds index should error.
        @test_throws BoundsError delete_entry!(2) # Only one entry left, index 2 is out of bounds
        @test_throws BoundsError delete_entry!(0)
    end

    @testset "Clear Entries" begin
        clear_entries!()
        add_entry!("ts1_clear", "Stmt1", "Code1", true)
        add_entry!("ts2_clear", "Stmt2", "Code2", true)
        # Expected: Two entries before clearing.
        @test length(get_entries()) == 2 # "History should have 2 entries before clearing"

        clear_entries!()
        # Expected: History should be empty after clearing.
        @test isempty(get_entries()) # "History should be empty after clearing"
    end

    @testset "Save and Load History" begin
        clear_entries!()
        add_entry!("2025-02-01_12-00-00", "SaveLoad Stmt1", "SaveLoad Code1", true)
        add_entry!("2025-02-01_12-05-00", "SaveLoad Stmt2", "SaveLoad Code2", false, "Error for SL")
        
        # Use a unique test filename
        test_filename = "test_history_" * string(Dates.value(now())) * ".json"
        save_history(test_filename)
        # Expected: File should exist after saving.
        @test isfile(test_filename)

        clear_entries!() # Clear current memory to ensure loading works
        @test isempty(get_entries()) # "History should be empty after clearing"

        load_history(test_filename)
        loaded_history = get_entries()
        # Expected: History should be populated from the file.
        @test length(loaded_history) == 2 # "History should have 2 entries after loading"
        @test loaded_history[1].original_statement == "SaveLoad Stmt1"
        @test loaded_history[1].is_valid == true
        @test loaded_history[2].original_statement == "SaveLoad Stmt2"
        @test loaded_history[2].is_valid == false
        @test loaded_history[2].validation_error == "Error for SL"

        # Clean up the test file
        rm(test_filename, force=true)
        @test !isfile(test_filename) # Ensure cleanup
    end

end # @testset "History Manipulation Tests"

end # module HistoryManipulationTests
