# Worklog

## Overview
worklog.md is a Neovim plugin automatically captures and commits a summary of 
your work to a specified Git repository every 30 minutes.

## Features
- Captures modified files
- Tracks recent changes
- Logs current buffer content
- Automatically commits summary to Git repository

## Installation

### Using packer
```lua
use {
  'franpfeiffer/worklog.nvim',
  config = function()
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })
  end
}
```

### Using lazy
```lua
{
  'franpfeiffer/worklog.nvim',
  config = function()
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
    })
  end
}
```

# Advanced config
```lua
-- Packer
use {
  'franpfeiffer/worklog.nvim',
  config = function()
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
    })
  end

}
```
```lua
-- Lazy
{
  'franpfeiffer/worklog.nvim',
  config = function()
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })
  end
}
```

## Multiple project support
```lua
-- Packer
use {
  'franpfeiffer/worklog.nvim',
  config = function()
    -- Project 1
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })

    -- Project 2
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })
  end
}
```

```lua
-- Lazy
{
  'yourusername/worklog.nvim',
  config = function()
    -- Project 1
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })

    -- Project 2 
    require('worklog').setup({
      repoPath = '/path/to/your/project/repo'
      logFile = 'yourlogfile.md' -- Optional (default: 'WORKLOG.md')
      commitInterval = 420 -- Optional (default: 1800)
    })
  end
}
```

## Manual Triggering
You can manually trigger a work summary commit using the `:Worklog` command.

## Requirements
- Neovim 0.7+
- Git installed and configured
- A Git repository initialized at the specified path

