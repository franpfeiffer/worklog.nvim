local M = {}

M.config = {
    repoPath = nil,
    log_file = 'WORK_SUMMARY.md',
    commit_interval = 1800, --> 30min
}

M.state = {
    timer = nil,
    last_commit_time = nil,
    is_running = false,
}

local function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

local function format_time_remaining(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d min %02d sec", minutes, secs)
end

function M.capture_work_log()
    local log = {}

    if not M.config.repoPath or M.config.repoPath == "" then
        vim.notify("Repository path not set. Please configure repoPath.", vim.log.levels.ERROR)
        return nil
    end

    if vim.fn.isdirectory(M.config.repoPath) == 0 then
        vim.notify("Repository path does not exist: " .. M.config.repoPath, vim.log.levels.ERROR)
        return nil
    end

    local modified_files_cmd = string.format("cd %s && git status --porcelain", M.config.repoPath)
    local modified_files = execute_command(modified_files_cmd) or "No modified files"

    local recent_changes_cmd = string.format(
    "cd %s && git diff --stat HEAD $(git log -1 --format='%%H' 2>/dev/null || echo HEAD)",
    M.config.repoPath
    )
    local recent_changes = execute_command(recent_changes_cmd) or "No recent changes"
    local current_file = vim.fn.expand('%:p')
    local buffer_content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    table.insert(log, "# Work Summary")
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
    -- Validate repo path
    if not M.config.repoPath or M.config.repoPath == "" then
        vim.notify("Repository path not set. Please configure repoPath.", vim.log.levels.ERROR)
        return
    end

    local log_path = string.format("%s/%s", M.config.repoPath, M.config.log_file)

    local log = M.capture_work_log()
    if not log then return end

    local file = io.open(log_path, "a")
    if file then
        file:write(log .. "\n\n")
        file:close()
    else
        vim.notify("Failed to open log file: " .. log_path, vim.log.levels.ERROR)
        return
    end

    local git_add_cmd = string.format("cd %s && git add %s", M.config.repoPath, M.config.log_file)
    local git_commit_cmd = string.format(

    "cd %s && git commit -m 'Work log at %s'",
    M.config.repoPath,
    os.date("%d-%m-%Y %H:%M:%S")
    )

    local add_result = execute_command(git_add_cmd)
    local commit_result = execute_command(git_commit_cmd)

    M.state.last_commit_time = os.time()

    vim.notify("Work log committed:\n" .. (commit_result or "No changes to commit"), vim.log.levels.INFO)
end


function M.stop()
    if M.state.timer then
        M.state.timer:stop()
        M.state.timer:close()
        M.state.timer = nil
        M.state.is_running = false
        vim.notify("Worklog timer stopped", vim.log.levels.INFO)
    end
end


function M.status()
    if not M.state.is_running then
        vim.notify("Worklog is not running", vim.log.levels.WARN)
        return
    end

    if not M.state.last_commit_time then
        vim.notify("Worklog initialized, first commit pending", vim.log.levels.INFO)
        return
    end

    local time_elapsed = os.time() - M.state.last_commit_time
    local time_remaining = M.config.commit_interval - time_elapsed

    if time_remaining > 0 then
        vim.notify(string.format(
        "Next work log in: %s\nRepository: %s",
        format_time_remaining(time_remaining),
        M.config.repoPath
        ), vim.log.levels.INFO)
    else
        vim.notify("Commit is due. Run commit manually or wait for next interval.", vim.log.levels.WARN)
    end
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if not M.config.repoPath or M.config.repoPath == "" then
        vim.notify("Error: repoPath must be set in configuration", vim.log.levels.ERROR)
        return

    end

    M.stop()
    M.state.timer = vim.loop.new_timer()
    M.state.timer:start(
    M.config.commit_interval * 1000,
    M.config.commit_interval * 1000,
    vim.schedule_wrap(function()
        M.commit_log()
    end)
    )

    M.state.is_running = true
    M.state.last_commit_time = os.time()

    vim.api.nvim_create_user_command('Worklog', M.commit_log, {})
    vim.api.nvim_create_user_command('WorklogStatus', M.status, {})
    vim.api.nvim_create_user_command('WorklogStop', M.stop, {})

    vim.api.nvim_set_keymap('n', '<leader>sw', 
    '<cmd>lua require("worklog").commit_log()<CR>',
    { noremap = true, silent = true, desc = 'Commit Work Summary' }
    )

    vim.api.nvim_set_keymap('n', '<leader>ss', 
    '<cmd>lua require("worklog").status()<CR>',
    { noremap = true, silent = true, desc = 'Check Worklog Status' }
    )

    vim.notify(string.format(
    "Worklog plugin initialized\nRepository: %s\nInterval: %d seconds",
    M.config.repoPath,
    M.config.commit_interval
    ), vim.log.levels.INFO)
end

return M
