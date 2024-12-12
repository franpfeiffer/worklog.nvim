local M = {}

M.config = {
    repoPath = nil,
    logFile = 'WORKLOG.md',
    commitInterval = 1800,
}

M.state = {
    timer = nil,
    lastCommitTime = nil,
    isRunning = false,
}

local function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

local function format_timeRemaining(seconds)
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

    local modifiedFilesCmd = string.format("cd %s && git status --porcelain", M.config.repoPath)
    local modifiedFiles = execute_command(modifiedFilesCmd) or "No modified files"
    local recentChanges_cmd = string.format(
        "cd %s && git diff --stat HEAD $(git log -1 --format='%%H' 2>/dev/null || echo HEAD)",
        M.config.repoPath
    )
    local recentChanges = execute_command(recentChanges_cmd) or "No recent changes"
    local currentFile = vim.fn.expand('%:p')
    local bufferContent = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    table.insert(log, "# Work Logs")
    table.insert(log, string.format("**Timestamp:** %s", os.date("%d-%m-%Y %H:%M:%S")))
    table.insert(log, "\n## Modified Files")
    table.insert(log, modifiedFiles)
    table.insert(log, "\n## Recent Changes")
    table.insert(log, recentChanges)
    table.insert(log, "\n## Current File")
    table.insert(log, string.format("**Path:** %s", currentFile))
    table.insert(log, "\n### Current Buffer Snippet")
    table.insert(log, "```")
    table.insert(log, bufferContent:sub(1, 500) .. (#bufferContent > 500 and "..." or ""))
    table.insert(log, "```")
    return table.concat(log, "\n")
end

function M.commitLog()
    if not M.config.repoPath or M.config.repoPath == "" then
        vim.notify("Repository path not set. Please configure repoPath.", vim.log.levels.ERROR)
        return
    end

    local logPath = string.format("%s/%s", M.config.repoPath, M.config.logFile)

    local log = M.capture_work_log()

    if not log then return end

    local file = io.open(logPath, "a")
    if file then
        file:write(log .. "\n\n")
        file:close()

    else
        vim.notify("Failed to open log file: " .. logPath, vim.log.levels.ERROR)
        return
    end

    local user_input = vim.fn.input("Commit work log? (y/n): ")
    if user_input ~= "y" and user_input ~= "Y" then
        vim.notify("Commit canceled.", vim.log.levels.INFO)
        return
    end

    local gitAddCmd = string.format("cd %s && git add %s", M.config.repoPath, M.config.logFile)
    local gitCommitCmd = string.format(

        "cd %s && git commit -m 'Work log at %s'",
        M.config.repoPath,
        os.date("%d-%m-%Y %H:%M:%S")
    )
    execute_command(gitAddCmd)
    local commitResult = execute_command(gitCommitCmd)
    M.state.lastCommitTime = os.time()
    vim.notify("Work log committed:\n" .. (commitResult or "No changes to commit"), vim.log.levels.INFO)
end

function M.stop()
    if M.state.timer then
        M.state.timer:stop()
        M.state.timer:close()
        M.state.timer = nil
        M.state.isRunning = false
        vim.notify("Worklog timer stopped", vim.log.levels.INFO)
    end
end

function M.status()
    if not M.state.isRunning then
        vim.notify("Worklog is not running", vim.log.levels.WARN)
        return
    end

    if not M.state.lastCommitTime then
        vim.notify("Worklog initialized, first commit pending", vim.log.levels.INFO)
        return
    end

    local timeElapsed = os.time() - M.state.lastCommitTime
    local timeRemaining = M.config.commitInterval - timeElapsed

    if timeRemaining > 0 then
        vim.notify(string.format(
            "Next work log in: %s\nRepository: %s",
            format_timeRemaining(timeRemaining),
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

    if M.state.timer then
        M.state.timer:start(
            M.config.commitInterval * 1000,
            M.config.commitInterval * 1000,
            function()
                vim.schedule(function()
                    M.commitLog() -- Call commitLog() directly
                end)
            end
        )
    end

    M.state.isRunning = true
    M.state.lastCommitTime = os.time()

    vim.api.nvim_create_user_command('Worklog', M.commitLog, {})
    vim.api.nvim_create_user_command('WorklogStatus', M.status, {})
    vim.api.nvim_create_user_command('WorklogStop', M.stop, {})
    vim.notify(string.format(
        "Worklog plugin initialized\nRepository: %s\nInterval: %d seconds",
        M.config.repoPath,
        M.config.commitInterval
    ), vim.log.levels.INFO)

end

return M
