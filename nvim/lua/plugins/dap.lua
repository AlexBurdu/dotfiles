-- Debug Adapter Protocol support
--
-- Kotlin/Java (Android):
--   Prerequisites: :MasonInstall kotlin-debug-adapter
--   1. Build & run app in debug mode: ./gradlew installDebug
--   2. Set breakpoints with <Leader>db
--   3. Attach with <Leader>da (prompts for package, handles ADB port forwarding)
--
-- Python:
--   Prerequisites: pip install debugpy (in your project venv)
--   1. Set breakpoints with <Leader>db
--   2. Launch with <Leader>dc (runs current file) or <Leader>da (attach to running process)
--
-- All languages:
--   Step through code: <Leader>do (over), di (into), dO (out)
--   ; repeats the last step command
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },

  lazy = false,

  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- Fix source path resolution for non-standard project layouts
    -- (reads package declaration from source files instead of deriving from path)
    require("util.dap_kotlin_proxy").install_interceptor()

    dapui.setup({
      mappings = {
        remove = "dd",
      },
    })

    -- Auto open/close DAP UI
    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

    -- Kotlin debug adapter (connects to JVM debug port via ADB)
    -- Works for both Kotlin and Java (same JDWP protocol)
    -- Installed via Mason (:MasonInstall kotlin-debug-adapter)
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"
    dap.adapters.kotlin = {
      type = "executable",
      command = mason_bin .. "kotlin-debug-adapter",
      options = {
        auto_continue_if_many_stopped = false,
        initialize_timeout_sec = 30,
        disconnect_timeout_sec = 0,
      },
    }

    -- Suppress "exited with 130" (SIGINT on disconnect) — expected for kotlin adapter
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

    -- Register for both Kotlin and Java filetypes
    dap.configurations.kotlin = { android_attach_config }
    dap.configurations.java = { android_attach_config }

    -- Python debug adapter (debugpy)
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

    -- Mason package names (nil = not available via Mason)
    local mason_packages = {
      ["kotlin-debug-adapter"] = "kotlin-debug-adapter",
      ["debugpy"] = "debugpy",
    }

    -- Fallback install instructions for tools not in Mason
    local is_mac = vim.fn.has("mac") == 1
    local manual_hints = {
      ["adb"] = is_mac
        and "brew install android-platform-tools"
        or "sudo apt install android-tools-adb",
    }

    -- Install a tool via Mason, then run callback on success
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

    -- Check prerequisites, return true if all present.
    -- If a Mason-installable tool is missing, prompt to install and retry.
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

    -- Find project root by walking up from the current buffer
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

    -- Detect Android app package names (async)
    -- Searches both gradle applicationId and manifests with LAUNCHER activity
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

    -- Attach: language-aware, checks prerequisites per filetype
    local recent_packages = {}

    local function do_attach_kotlin(package)
      -- Update recents (move to front, deduplicate)
      for i, p in ipairs(recent_packages) do
        if p == package then table.remove(recent_packages, i) break end
      end
      table.insert(recent_packages, 1, package)

      local fidget = require("fidget")
      local handle = fidget.progress.handle.create({
        title = "Connecting to " .. package .. "...",
        lsp_client = { name = "dap" },
      })

      -- Run all ADB commands async to never block the UI
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
                  -- Wait for JDWP tunnel to stabilize, then attach
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

    -- Keymaps (Leader+d prefix for debug)
    vim.keymap.set("n", "<Leader>da", smart_attach, { desc = "Attach debugger (language-aware)" })
    vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<Leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Conditional breakpoint" })
    vim.keymap.set("n", "<Leader>dc", dap.continue, { desc = "Continue / start debugging" })
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
    vim.keymap.set("n", "<Leader>de", dapui.eval, { desc = "Evaluate expression" })
    vim.keymap.set("v", "<Leader>de", dapui.eval, { desc = "Evaluate selection" })
  end,
}
