-- Debug Adapter Protocol (DAP) configuration, common to every machine.
--
-- Supported languages:
--   Python      — debugpy (pip install debugpy in your project venv)
--   Kotlin/Java — optional `jvm` (plugins/jvm.lua), which adds
--                 kotlin-debug-adapter and the Android attach flow
--
-- Workflows:
--   <Leader>dt/dT  debug test under cursor / all tests (see keymap/build.lua)
--   <Leader>da      attach to running process, per filetype (util/dap_attach)
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
  },

  lazy = false,

  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_attach = require("util.dap_attach")

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

    -- Suppress "exited with 130" (SIGINT on disconnect) — expected behavior
    local dap_notify = require("dap.utils").notify
    require("dap.utils").notify = function(msg, level, ...)
      if type(msg) == "string" and msg:match("exited with 130") then return end
      return dap_notify(msg, level, ...)
    end

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

    dap_attach.register({ "python" }, function()
      dap_attach.check_tools({ "debugpy" }, attach_python,
        { mason = { debugpy = "debugpy" } })
    end)

    -- ── Keymaps ─────────────────────────────────────────────────────────────

    vim.keymap.set("n", "<Leader>da", dap_attach.attach, { desc = "Attach debugger (language-aware)" })
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
