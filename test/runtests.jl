using OscarAICoder
using OscarAICoder.TestHelpers
using OscarAICoder.Validator
using OscarAICoder.History
using OscarAICoder.Config

include("unit/validator_tests.jl")
include("integration/core_tests.jl")

# Run all tests
@testset "OscarAICoder Tests" begin
    @testset "Validator Tests" begin
        include("unit/validator_tests.jl")
    end
    
    @testset "Core Tests" begin
        include("integration/core_tests.jl")
    end
end

# Test local backend
try
    println("Local backend:")
    oscar_code = OscarAICoder.Core.process_statement(statement)
    println(oscar_code)
catch e
    println("Local backend failed: ", e)
end

# Disable external backend tests
println("\nExternal backend tests disabled")

# Test statements
known_statement = "Factor the polynomial x^2 - 5x + 6 over the integers."
unknown_statement = "Solve the equation x^3 + 2x^2 - 5x + 1 = 0 over the complex numbers."

println("\nTesting offline and dictionary modes:")

# Test offline mode
println("\n1. Offline mode:")
OscarAICoder.Config.CONFIG.training_mode = true
try
    println("Known statement in offline mode:")
    oscar_code = OscarAICoder.Core.process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement in offline mode:")
    oscar_code = OscarAICoder.Core.process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test dictionary-only mode
println("\n2. Dictionary-only mode:")
OscarAICoder.Config.CONFIG.training_mode = false
OscarAICoder.Config.configure_dictionary_mode(:only)
try
    println("Known statement:")
    oscar_code = OscarAICoder.Core.process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement:")
    oscar_code = OscarAICoder.Core.process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test dictionary mode
println("\n3. Dictionary mode:")
new_config = OscarAICoder.Config.ConfigType(
    OscarAICoder.Config.CONFIG.default_backend,
    OscarAICoder.Config.CONFIG.backend_settings,
    OscarAICoder.Config.CONFIG.training_mode,
    :enabled,
    OscarAICoder.Config.CONFIG.context,
    OscarAICoder.Config.CONFIG.debug
)
OscarAICoder.Config.CONFIG = new_config
try
    println("Known statement:")
    oscar_code = OscarAICoder.Core.process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement:")
    oscar_code = OscarAICoder.Core.process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test fallback behavior with connection error
println("\n4. Testing connection error fallback:")
configure_dictionary_mode(:priority)
configure_default_backend(:remote, Dict(:url => "http://nonexistent-server:11434"))
try
    println("Known statement with bad connection (should fallback to dictionary):")
    oscar_code = OscarAICoder.Core.process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement with bad connection:")
    oscar_code = OscarAICoder.Core.process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error (expected for unknown statement): ", e)
end

# Test normal online mode
println("\n5. Normal online mode:")
println("\n4. Normal online mode:")
configure_offline_mode(false)
configure_dictionary_mode(:priority)
configure_default_backend(:remote, Dict(:url => "http://server01.mydomain.net:11434"))
try
    println("Known statement (will use dictionary):")
    println("Currently disabled")
    # oscar_code = process_statement(known_statement)
    println(oscar_code)
    
    println("\nUnknown statement (will use LLM):")
    println("Currently disabled")
    # oscar_code = process_statement(unknown_statement)
    println(oscar_code)
catch e
    println("Error: ", e)
end
