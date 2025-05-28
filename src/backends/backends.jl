module Backends

using HTTP, JSON
using ..Config
using ..Validator
using OscarAICoder.Debug

# Include backend implementations
include("local.jl")
include("huggingface.jl")
include("github.jl")

# Export backend functions
export process_statement_local, process_statement_huggingface, process_statement_github

end # module Backends
