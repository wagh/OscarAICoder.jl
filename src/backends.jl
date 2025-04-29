module Backends

include("backends/local.jl")
include("backends/huggingface.jl")
include("backends/github.jl")

# Re-export specific functions
using .Local: process_statement_local
using .HuggingFace: process_statement_huggingface
using .GitHub: process_statement_github

end # module Backends
