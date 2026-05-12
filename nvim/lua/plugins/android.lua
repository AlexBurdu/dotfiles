-- Android development tools (logcat, adb, gradle)
-- https://github.com/iamironz/android-nvim-plugin
return {
  "iamironz/android-nvim-plugin",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "AndroidLogcat", "AndroidMenu", "AndroidActions", "AndroidBuild", "AndroidBuildPrompt", "AndroidRun", "AndroidSelectDevice" },
  keys = {
    { "<Leader>al", "<cmd>AndroidLogcat<CR>", desc = "Open Android logcat" },
    { "<Leader>am", "<cmd>AndroidMenu<CR>", desc = "Android menu" },
    { "<Leader>aa", "<cmd>AndroidActions<CR>", desc = "Android actions" },
    { "<Leader>ab", "<cmd>AndroidBuild<CR>", desc = "Android build" },
    { "<Leader>ar", "<cmd>AndroidRun<CR>", desc = "Android run" },
    { "<Leader>ad", "<cmd>AndroidSelectDevice<CR>", desc = "Select Android device" },
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

    -- Allow logcat/device-picker to run outside a Gradle project. The plugin's
    -- context.workspace() returns nil + warns when no Gradle root is detected;
    -- fall back to a synthetic workspace rooted at cwd so adb-based actions
    -- (logcat, device selection) work anywhere. SDK paths resolve from
    -- ANDROID_HOME/$ANDROID_SDK_ROOT or the default SDK location, not from
    -- workspace.root, so this only affects state-file location.
    local context = require("android.actions.context")
    local project = require("android.project.detect")
    context.workspace = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      local cwd = vim.fn.getcwd()
      local path = (buf_name ~= nil and buf_name ~= "") and buf_name or cwd
      local detected = project.detect(path)
      if detected and detected.gradle then
        return detected
      end
      return { root = cwd }
    end

    -- Direct user command for device selection (the plugin only exposes it via
    -- the actions menu, and gates it on a Gradle workspace).
    vim.api.nvim_create_user_command("AndroidSelectDevice", function()
      require("android.actions.devices").select_device()
    end, { desc = "Pick default adb device" })

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
