-- Android development tools (logcat, adb, gradle)
-- https://github.com/iamironz/android-nvim-plugin
return {
  "iamironz/android-nvim-plugin",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "AndroidLogcat", "AndroidMenu", "AndroidBuild", "AndroidBuildPrompt", "AndroidRun" },
  keys = {
    { "<Leader>dl", "<cmd>AndroidLogcat<CR>", desc = "Open Android logcat" },
  },
  config = function()
    -- Patch the command runner to use a timeout so ADB calls don't hang nvim
    local runner = require("android.command.runner")
    local original_new = runner.new
    runner.new = function(exec)
      local custom_exec = exec or function(cmd, opts)
        local options = opts or {}
        local result = vim.system(cmd, {
          cwd = options.cwd,
          env = options.env,
          timeout = 5000,
        }):wait()
        return {
          code = result and result.code or 1,
          stdout = result and result.stdout or "",
          stderr = result and result.stderr or "",
        }
      end
      return original_new(custom_exec)
    end

    -- Patch list_packages to prepend a "Clear filter" option before setup()
    -- so the local function reference in controls.lua picks it up
    local processes = require("android.logcat.processes")
    local original_list_packages = processes.list_packages
    processes.list_packages = function(runner, adb_path, serial)
      local names = original_list_packages(runner, adb_path, serial)
      table.insert(names, 1, { label = "All (clear filter)", value = "" })
      return names
    end

    require("android").setup()

    -- Override the plugin's highlight.setup to use Diagnostic-linked colors
    -- instead of raw Red/Yellow/Blue/Green
    local highlight = require("android.logcat.highlight")
    highlight.setup = function()
      vim.api.nvim_set_hl(0, "AndroidLogcatError", { link = "DiagnosticError" })
      vim.api.nvim_set_hl(0, "AndroidLogcatWarn", { link = "DiagnosticWarn" })
      vim.api.nvim_set_hl(0, "AndroidLogcatInfo", { link = "Comment" })
      vim.api.nvim_set_hl(0, "AndroidLogcatDebug", { fg = "#6a6e78" })
    end
    highlight.setup()
  end,
}
