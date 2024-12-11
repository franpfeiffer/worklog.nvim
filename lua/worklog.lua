local M = {}

M.config = {
    repo_path = nil,
    log_file = 'WORKLOG.md',
    commit_interval = 1800,
}

local function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

function M.capture_worklog()
    local log = {}
    local modified_files_cmd = string.format("cd %s && git status --porcelain", M.config.repo_path)
    local modified_files = execute_command(modified_files_cmd)
    local recent_changes_cmd = string.format(
        "cd %s && git diff --stat HEAD $(git log -1 --format='%%H')",
        M.config.repo_path
    )
    local recent_changes = execute_command(recent_changes_cmd)
    local current_file = vim.fn.expand('%:p')
    local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    table.insert(log, "# Work log")
    table.insert(log, string.format("**Timestamp:** %s", os.date("%d-%m-%Y %H:%M:%S")))
    table.insert(log, "\n## Modified Files")
    table.insert(log, modified_files)
    table.insert(log, "\n## Recent Changes")
    table.insert(log, recent_changes)
    table.insert(log, "\n## Current File")
    table.insert(log, string.format("**Path:** %s", current_file))
    table.insert(log, "\n### Current Buffer Snippet")
    table.insert(log, "```")
    table.insert(log, buffer_content:sub(1, 500) .. (#buffer_content > 500 and "..." or ""))
    table.insert(log, "```")
    return table.concat(log, "\n")
end

function M.commit_log()
    local worklog_path = string.format("%s/%s", M.config.repo_path, M.config.log_file)
    local file = io.open(worklog_path, "a")
    if file then
        file:write(M.capture_worklog() .. "\n\n")
        file:close()
    end

    execute_command(string.format(
        "cd %s && git add %s && git commit -m 'worklog at %s'",
        M.config.repo_path,
        M.config.log_file,
        os.date("%d-%m-%Y %H:%M:%S")
    ))
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    if not M.config.repo_path then
        print("Error: repo_path must be set in configuration")
        return
    end

    local timer = vim.loop.new_timer()
    timer:start(
    M.config.commit_interval * 1000,
    M.config.commit_interval * 1000,
    vim.schedule_wrap(function()
        M.commit_log()
    end)
    )
    vim.api.nvim_create_user_command('WorkLog', M.commit_log, {})
    vim.api.nvim_set_keymap('n', '<leader>sw',
        '<cmd>lua require("worklog").commit_log()<CR>',
        { noremap = true, silent = true, desc = 'commit to worklog' }
    )
end

return M

