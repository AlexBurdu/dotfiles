-- Debug Adapter Protocol (DAP) configuration.
--
-- Supported languages:
--   Kotlin/Java — kotlin-debug-adapter (built from fork via lazy.nvim)
--   Python      — debugpy (pip install debugpy in your project venv)
--
-- Workflows:
--   <Leader>dt/dT  debug test under cursor / all tests (see keymap/build.lua)
--   <Leader>da      attach to running process (Android via ADB, Python via port)
--   <Leader>dc      continue (or start debug test if no session)
--   <Leader>db/dB   toggle / conditional breakpoint
--   <Leader>do/di/dO step over / into / out (;  repeats last step)
--   <Leader>dh      eval expression under cursor or selection
--   <Leader>de      add expression to watches (word or selection)
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    { "AlexBurdu/kotlin-debug-adapter", branch = "custom", build = "./build.sh" },
  },

  lazy = false,

  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- Fix KDA source path resolution for non-standard layouts (KMP, deep nesting)
    require("util.dap_kotlin_proxy").install_interceptor()

    dapui.setup({
      mappings = {
        remove = "dd",
      },
    })

    vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError" })
    vim.fn.sign_define("DapBreakpointCondition",  { text = "◆", texthl = "DiagnosticWarn" })
    vim.fn.sign_define("DapBreakpointRejected",   { text = "○", texthl = "DiagnosticHint" })
    vim.fn.sign_define("DapStopped",              { text = "▶", texthl = "DiagnosticOk", linehl = "CursorLine", numhl = "DiagnosticOk" })
    vim.fn.sign_define("DapLogPoint",             { text = "◈", texthl = "DiagnosticInfo" })

    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    -- ── Kotlin/Java adapter (JDWP) ─────────────────────────────────────────
    local kda_dir = vim.fn.stdpath("data") .. "/lazy/kotlin-debug-adapter"
    dap.adapters.kotlin = {
      type = "executable",
      command = kda_dir .. "/adapter/build/install/adapter/bin/kotlin-debug-adapter",
      options = {
        auto_continue_if_many_stopped = false,
        initialize_timeout_sec = 30,
        disconnect_timeout_sec = 0,
      },
    }

    -- Suppress "exited with 130" (SIGINT on disconnect) — expected behavior
    local dap_notify = require("dap.utils").notify
    require("dap.utils").notify = function(msg, level, ...)
      if type(msg) == "string" and msg:match("exited with 130") then return end
      return dap_notify(msg, level, ...)
    end

    local android_attach_config = {
      type = "kotlin",
      name = "Attach to Android app",
      request = "attach",
      hostName = "localhost",
      port = 5005,
      timeout = 10000,
      projectRoot = "${workspaceFolder}",
    }

    dap.configurations.kotlin = { android_attach_config }
    dap.configurations.java = { android_attach_config }

    -- ── Python adapter (debugpy) ───────────────────────────────────────────

    dap.adapters.python = {
      type = "executable",
      command = "python3",
      args = { "-m", "debugpy.adapter" },
    }

    dap.configurations.python = {
      {
        type = "python",
        name = "Launch file",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
      },
      {
        type = "python",
        name = "Attach to process",
        request = "attach",
        connect = { host = "localhost", port = 5678 },
        cwd = "${workspaceFolder}",
      },
    }

    -- ── Prerequisite checks ──────────────────────────────────────────────────

    local mason_packages = {
      ["kotlin-debug-adapter"] = nil, -- built from fork via lazy.nvim
      ["debugpy"] = "debugpy",
    }

    local is_mac = vim.fn.has("mac") == 1
    local manual_hints = {
      ["adb"] = is_mac
        and "brew install android-platform-tools"
        or "sudo apt install android-tools-adb",
    }

    local function mason_install(tool, on_success)
      local pkg_name = mason_packages[tool]
      local registry = require("mason-registry")
      local pkg = registry.get_package(pkg_name)
      vim.notify("Installing " .. pkg_name .. " via Mason...")
      pkg:install():once("closed", vim.schedule_wrap(function()
        if pkg:is_installed() then
          vim.notify(pkg_name .. " installed successfully.")
          if on_success then on_success() end
        else
          vim.notify(pkg_name .. " installation failed.", vim.log.levels.ERROR)
        end
      end))
    end

    local function check_tools(tools, on_ready)
      for _, tool in ipairs(tools) do
        local found = vim.fn.executable(tool) == 1
          or vim.fn.filereadable(mason_bin .. tool) == 1
        if not found then
          if mason_packages[tool] then
            vim.ui.select({ "Yes", "No" }, {
              prompt = tool .. " is not installed. Install via Mason?",
            }, function(choice)
              if choice == "Yes" then
                mason_install(tool, function()
                  check_tools(tools, on_ready)
                end)
              end
            end)
          else
            vim.notify(
              tool .. " not found. Install with:\n  " .. (manual_hints[tool] or tool),
              vim.log.levels.ERROR
            )
          end
          return false
        end
      end
      if on_ready then on_ready() end
      return true
    end

    -- ── Android attach flow ──────────────────────────────────────────────────

    local function find_project_root()
      local markers = { "settings.gradle.kts", "settings.gradle", "gradlew", ".git" }
      local path = vim.fn.expand("%:p:h")
      while path ~= "/" do
        for _, marker in ipairs(markers) do
          if vim.fn.filereadable(path .. "/" .. marker) == 1
            or vim.fn.isdirectory(path .. "/" .. marker) == 1 then
            return path
          end
        end
        path = vim.fn.fnamemodify(path, ":h")
      end
      return vim.fn.getcwd()
    end

    -- Detect Android package names: gradle applicationId + LAUNCHER manifests.
    local function detect_packages(callback)
      local found = {}
      local seen = {}
      local root = find_project_root()
      local pending = 2

      local function on_done()
        pending = pending - 1
        if pending == 0 then callback(found) end
      end

      -- 1. Search gradle files for applicationId
      vim.fn.jobstart(
        { "grep", "-r", "--include=*.gradle", "--include=*.gradle.kts",
          "--exclude-dir=build", "--exclude-dir=.gradle", "-h", "applicationId", root },
        {
          stdout_buffered = true,
          on_stdout = function(_, data)
            for _, line in ipairs(data) do
              local id = line:match('applicationId%s*[=%(]?%s*"([^"]+)"')
                or line:match("applicationId%s*[=%(]?%s*'([^']+)'")
              if id and not seen[id] then
                seen[id] = true
                table.insert(found, id)
              end
            end
          end,
          on_exit = function() on_done() end,
        }
      )

      -- 2. Find manifests with LAUNCHER intent (actual apps), extract package
      vim.fn.jobstart(
        { "grep", "-rl", "--include=AndroidManifest.xml", "--exclude-dir=build",
          "--exclude-dir=.gradle", "android.intent.category.LAUNCHER", root },
        {
          stdout_buffered = true,
          on_stdout = function(_, data)
            for _, file in ipairs(data) do
              if file ~= "" then
                local content = vim.fn.readfile(file)
                for _, line in ipairs(content) do
                  local pkg = line:match('package%s*=%s*"([^"]+)"')
                  if pkg and not seen[pkg] then
                    seen[pkg] = true
                    table.insert(found, pkg)
                  end
                end
              end
            end
          end,
          on_exit = function() on_done() end,
        }
      )
    end

    local recent_packages = {}

    local function do_attach_kotlin(package)
      -- Move to front of recents
      for i, p in ipairs(recent_packages) do
        if p == package then table.remove(recent_packages, i) break end
      end
      table.insert(recent_packages, 1, package)

      local fidget = require("fidget")
      local handle = fidget.progress.handle.create({
        title = "Connecting to " .. package .. "...",
        lsp_client = { name = "dap" },
      })

      vim.fn.jobstart({ "adb", "forward", "--remove-all" }, {
        on_exit = function()
          vim.fn.jobstart({ "adb", "shell", "pidof", package }, {
            stdout_buffered = true,
            on_stdout = function(_, data)
              local pid = (data[1] or ""):gsub("%s+", "")
              if pid == "" then
                vim.schedule(function()
                  handle:finish()
                  vim.notify("No running process for " .. package, vim.log.levels.ERROR)
                end)
                return
              end

              vim.fn.jobstart({ "adb", "forward", "tcp:5005", "jdwp:" .. pid }, {
                on_exit = function()
                  vim.defer_fn(function()
                    handle:finish()
                    vim.notify("Forwarding port 5005 → JDWP pid " .. pid)
                    dap.run({
                      type = "kotlin",
                      name = "Attach to " .. package,
                      request = "attach",
                      hostName = "localhost",
                      port = 5005,
                      timeout = 10000,
                      projectRoot = find_project_root(),
                    })
                  end, 1000)
                end,
              })
            end,
          })
        end,
      })
    end

    local function telescope_pick(items, prompt, on_select)
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      pickers.new({}, {
        prompt_title = prompt,
        finder = finders.new_table({ results = items }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(bufnr)
            if selection then on_select(selection[1]) end
          end)
          return true
        end,
      }):find()
    end

    local function show_full_picker()
      local fidget = require("fidget")
      local handle = fidget.progress.handle.create({
        title = "Searching for packages...",
        lsp_client = { name = "dap" },
      })

      detect_packages(vim.schedule_wrap(function(packages)
        handle:finish()
        if #packages == 0 then
          local package = vim.fn.input("Package: ", "")
          if package ~= "" then do_attach_kotlin(package) end
        else
          telescope_pick(packages, "Select package", do_attach_kotlin)
        end
      end))
    end

    local function attach_kotlin()
      -- Build list: recents first, then search option
      local items = {}
      for _, p in ipairs(recent_packages) do
        table.insert(items, p)
      end

      if #items == 0 then
        show_full_picker()
        return
      end

      table.insert(items, "Search project...")
      telescope_pick(items, "Select package", function(choice)
        if choice == "Search project..." then
          show_full_picker()
        else
          do_attach_kotlin(choice)
        end
      end)
    end

    local function attach_python()
      local port = vim.fn.input("Port (default 5678): ", "5678")
      if port == "" then return end
      dap.run({
        type = "python",
        name = "Attach to process",
        request = "attach",
        connect = { host = "localhost", port = tonumber(port) },
        cwd = vim.fn.getcwd(),
      })
    end

    local function smart_attach()
      local ft = vim.bo.filetype

      if ft == "kotlin" or ft == "java" then
        check_tools({ "kotlin-debug-adapter", "adb" }, attach_kotlin)
      elseif ft == "python" then
        check_tools({ "debugpy" }, attach_python)
      else
        vim.notify(
          "No debug adapter for filetype: " .. ft .. "\nSupported: kotlin, java, python",
          vim.log.levels.WARN
        )
      end
    end

    -- ── Keymaps ─────────────────────────────────────────────────────────────

    vim.keymap.set("n", "<Leader>da", smart_attach, { desc = "Attach debugger (language-aware)" })
    vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<Leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Conditional breakpoint" })
    vim.keymap.set("n", "<Leader>dc", function()
      if dap.session() then
        dap.continue()
      else
        -- No active session — launch debug test (same as <Leader>dt)
        -- Re-uses the build keybinding which handles detection + overseer + DAP attach
        local keys = vim.api.nvim_replace_termcodes("<Leader>dt", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end
    end, { desc = "Continue / start debugging" })
    vim.keymap.set("n", "<Leader>do", dap.step_over, { desc = "Step over" })
    vim.keymap.set("n", "<Leader>di", dap.step_into, { desc = "Step into" })
    vim.keymap.set("n", "<Leader>dO", dap.step_out, { desc = "Step out" })
    vim.keymap.set("n", "<Leader>df", dap.focus_frame, { desc = "Focus current frame" })
    vim.keymap.set("n", "<Leader>dr", dap.restart, { desc = "Restart" })
    vim.keymap.set("n", "<Leader>dx", function()
      dap.disconnect({ terminateDebuggee = false })
      dapui.close()
    end, { desc = "Disconnect and close UI" })
    vim.keymap.set("n", "<Leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
    vim.keymap.set({ "n", "v" }, "<Leader>dh", function() dapui.eval() end, { desc = "Eval under cursor (repeat to focus)" })
    vim.keymap.set("n", "<Leader>de", function()
      local expr = vim.fn.expand("<cword>")
      if expr ~= "" then
        dapui.elements.watches.add(expr)
      end
    end, { desc = "Add word to watches" })
    vim.keymap.set("v", "<Leader>de", function()
      local start = vim.fn.getpos("v")
      local finish = vim.fn.getpos(".")
      local lines = vim.fn.getregion(start, finish)
      local expr = table.concat(lines, "\n")
      if expr ~= "" then
        dapui.elements.watches.add(expr)
      end
    end, { desc = "Add selection to watches" })
  end,
}
