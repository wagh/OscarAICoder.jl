module TestHelpers

using OscarAICoder
using Test

export setup_test_environment!, teardown_test_environment!, run_test_cases

function setup_test_environment!()
    # Reset configuration to default
    OscarAICoder.Config.reset_config!()
    
    # Enable debug mode for better test output
    OscarAICoder.Debug.debug_mode!(true)
    
    # Clear history
    OscarAICoder.History.clear_entries!()
    
    # Reset context
    OscarAICoder.Config.clear_context!()
end

function teardown_test_environment!()
    # Clear history
    OscarAICoder.History.clear_entries!()
    
    # Reset configuration
    OscarAICoder.Config.reset_config!()
    
    # Reset debug mode
    OscarAICoder.Debug.debug_mode!(false)
end

function run_test_cases(test_cases::Vector{Pair{String, String}})
    for (statement, expected) in test_cases
        @test OscarAICoder.Core.process_statement(statement) == expected
    end
end

end # module TestHelpers
