module Prompts

using ..Config
using ..Debug
using ..History

export get_prompt

"""
    get_prompt(statement::String, use_history::Bool)

Get the appropriate prompt for the given statement and history usage.
"""
function get_prompt(statement::String, use_history::Bool, training_mode::Bool)
    # Read base prompt
    base_prompt = read("$(Config.CONFIG.base_dir)/prompts/prompt_base.txt", String)
    
    # Get history entries
    history_entries = History.get_entries()
    
    # Determine which prompt to use
    if isempty(history_entries)
        # No history - use simple prompt
        prompt = base_prompt * "Statement: $statement\nOscar code:\n"
    elseif use_history
        # Use history - include previous context
        context = read("$(Config.CONFIG.base_dir)/prompts/prompt_context.txt", String)
        if !training_mode
            for entry in history_entries
                context *= "Statement: $(entry.original_statement)\nOscar code: $(entry.generated_code)\n\n"
            end
        end
        prompt = base_prompt * context * "Statement: $statement\nOscar code:\n"
    else
        # Don't use history - explicitly tell LLM to ignore context
        ignore_context = read("$(Config.CONFIG.base_dir)/prompts/prompt_ignore_context.txt", String)
        prompt = base_prompt * ignore_context * "Statement: $statement\nOscar code:\n"
    end

    debug_print("Final prompt:\n$prompt")
    return prompt
end

end # module Prompts
