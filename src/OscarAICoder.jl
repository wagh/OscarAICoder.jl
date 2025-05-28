module OscarAICoder

# Core dependencies
import Oscar
using HTTP, JSON
using Dates, Base

# Include submodules in correct order
include("constants/constants.jl")
include("config/config.jl")
include("debug.jl")
include("types/types.jl")
include("validator/validator.jl")
include("history/history.jl")
include("backends/backends.jl")
include("core/seed_dictionary.jl")
include("core/process.jl")

# Export public API
export process_statement
export SeedDictionary, CONFIG, get_config, set_config, get_backend_settings, set_backend_settings, get_training_mode, set_training_mode, get_dictionary_mode, set_dictionary_mode, get_debug_mode, set_debug_mode, SEED_DICTIONARY

# Re-export functions from Core and Config
process_statement = Core.process_statement
get_config = Config.get_config
set_config = Config.set_config
get_backend_settings = Config.get_backend_settings
set_backend_settings = Config.set_backend_settings
get_training_mode = Config.get_training_mode
set_training_mode = Config.set_training_mode
get_dictionary_mode = Config.get_dictionary_mode
set_dictionary_mode = Config.set_dictionary_mode
get_debug_mode = Config.get_debug_mode
set_debug_mode = Config.set_debug_mode

# Re-export SEED_DICTIONARY
SEED_DICTIONARY = SeedDictionary.SEED_DICTIONARY

# Re-export process_statement from Core
process_statement = Core.process_statement

end # module OscarAICoder
