module OscarAICoder

# Core dependencies
import Oscar
using HTTP, JSON
using Dates, Base

# Include submodules in correct order
include("types/types.jl")
include("config/config.jl")
include("debug.jl")
include("validator/validator.jl")
include("history/history.jl")
include("prompts/prompts.jl")
include("backends/backends.jl")
include("core/seed_dictionary.jl")
include("core/process.jl")

# Export public API
export process_statement, execute_statement, execute_statement_with_format
export SeedDictionary, CONFIG, get_config, set_config, get_backend_settings, set_backend_settings, get_training_mode, set_training_mode, get_dictionary_mode, set_dictionary_mode, get_debug_mode, set_debug_mode, SEED_DICTIONARY, set_local_model, get_local_model
export add_entry!, delete_entry!, clear_entries!, edit_entry!, save_history, load_history, get_entries, get_entry, display_history, current_timestamp, HistoryStore, HistoryEntry

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
set_local_model = Config.set_local_model
get_local_model = Config.get_local_model

# Re-export functions from History
get_entries = History.get_entries
delete_entry! = History.delete_entry!
display_history = History.display_history
edit_entry! = History.edit_entry!
clear_entries! = History.clear_entries!
save_history = History.save_history
load_history = History.load_history
get_entry = History.get_entry
add_entry! = History.add_entry!


# Re-export SEED_DICTIONARY
SEED_DICTIONARY = SeedDictionary.SEED_DICTIONARY

# Re-export functions from Core
execute_statement = Core.execute_statement
execute_statement_with_format = Core.execute_statement_with_format

end # module OscarAICoder
