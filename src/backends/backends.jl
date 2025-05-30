module Backends

using HTTP, JSON
using ..Config
using ..Validator
using ..Debug
using ..Prompts

# Re-export Prompts module
export Prompts

# Include backend implementations
include("local.jl")
include("huggingface.jl")
include("github.jl")

# Export backend functions
export process_statement_local, process_statement_huggingface, process_statement_github

end # module Backends
