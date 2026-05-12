-- Build, test, and debug keybindings with Bazel/Gradle auto-detection.
--
-- Build & test (<leader>b*):
--   bb  build project
--   bt  test under cursor (source: method, BUILD/gradle: file under cursor)
--   bT  all tests (source: class, BUILD/gradle: all targets in file)
--   br  rerun last task
--   bl  toggle Overseer task list
--   bJ  toggle JetBrains Kotlin LSP
--
-- Debug (<leader>d*):
--   dt  debug test under cursor (same cursor-awareness as bt)
--   dT  debug all tests (same as bT but with JDWP + -Xdebug)
--
-- Bazel tests use --test_filter for cursor targeting; Gradle uses --tests.
-- Debug mode adds JDWP flags and polls port 5005 until the JVM is listening,
-- then attaches DAP. For Gradle, an init script injects -Xdebug to disable
-- coroutine variable spilling (makes locals inspectable after suspend points).

local KOTLIN_EFM = table.concat({
  "%f:%l:%c: error: %m",
  "%f:%l:%c: warning: %m",
  "%f:%l: error: %m",
  "e: %f: (%l\\, %c): %m",
  "w: %f: (%l\\, %c): %m",
}, ",")

-- Kill the overseer task whose output buffer was just closed.
-- Overseer sets vim.b[bufnr].overseer_task = task.id on all OverseerOutput buffers,
-- and the window handle is still valid during WinClosed so nvim_win_get_buf works.
vim.api.nvim_create_autocmd("WinClosed", {
  group = vim.api.nvim_create_augroup("BuildKillOnClose", { clear = true }),
  callback = function(ev)
    -- Don't kill tasks while a DAP session is active: dapui.open() rearranges
    -- windows on event_initialized and would trigger this handler spuriously,
    -- killing the test process before it has a chance to run.
    local dap_ok, dap = pcall(require, "dap")
    if dap_ok and dap.session() then return end

    local win = tonumber(ev.match)
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if not ok then return end
    local task_id = vim.b[buf].overseer_task
    if not task_id then return end
    local overseer = require("overseer")
    for _, task in ipairs(overseer.list_tasks()) do
      if task.id == task_id and task:is_running() then
        task:stop()
        break
      end
    end
  end,
})

local QUICKFIX_COMPONENT = {
  "on_output_quickfix",
  errorformat    = KOTLIN_EFM,
  tail           = true,
  open_on_match  = true,
  open_on_exit   = "failure",
  open_height    = 12,
  focus          = false,
}

-- ── Filetype detection ──────────────────────────────────────────────────────

local function is_build_file()
  local name = vim.api.nvim_buf_get_name(0)
  return name:match("BUILD%.bazel$") or name:match("/BUILD$")
end

local function is_gradle_file()
  local name = vim.api.nvim_buf_get_name(0)
  return name:match("%.gradle%.kts$") or name:match("%.gradle$")
end

-- In BUILD/gradle files, extract a class name from a quoted source filename
-- on the current line (e.g. "commonTest/Foo.kt" → "Foo").
local function source_class_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local path = line:match('"([^"]+%.kt)"')
    or line:match('"([^"]+%.java)"')
  if not path then return nil end
  return vim.fn.fnamemodify(path, ":t:r")
end

local function open_task_output(overseer, task)
  if task then overseer.open({ direction = "bottom", enter = false }) end
end

-- ── Bazel helpers ────────────────────────────────────────────────────────────

local function bazel_run_task(overseer, root, args, label)
  local task = overseer.new_task({
    name       = "bazel " .. args[1] .. " " .. label,
    cmd        = vim.list_extend({ "bazel" }, args),
    cwd        = root,
    components = { "default", QUICKFIX_COMPONENT },
  })
  task:start()
  open_task_output(overseer, task)
end

local function bazel_build(overseer, root)
  local build = require("util.build")
  build.resolve_bazel_target(root, function(target)
    bazel_run_task(overseer, root, { "build", target }, target)
  end)
end

local function bazel_test_target(overseer, root, target, filter)
  local args = { "test", target, "--test_output=streamed" }
  if filter then args[#args + 1] = "--test_filter=" .. filter end
  bazel_run_task(overseer, root, args, target .. (filter and ("#" .. filter) or ""))
end

local function bazel_test_cursor(overseer, root)
  local build = require("util.build")
  if is_build_file() then
    local src_class = source_class_under_cursor()
    build.resolve_bazel_target(root, function(target)
      bazel_test_target(overseer, root, target, src_class)
    end)
  else
    local class_name, method_name = build.test_at_cursor()
    local filter = class_name and method_name and (class_name .. "#" .. method_name)
      or class_name or method_name
    build.resolve_bazel_target(root, function(target)
      bazel_test_target(overseer, root, target, filter)
    end, { only_tests = true })
  end
end

local function bazel_test_all(overseer, root)
  local build = require("util.build")
  if is_build_file() then
    local bufname = vim.api.nvim_buf_get_name(0)
    local typed   = build.targets_in_build_file_typed(root, bufname)
    local tests   = vim.tbl_filter(function(t) return t.is_test end, typed)
    if #tests == 0 then
      vim.notify("No test targets found in BUILD file", vim.log.levels.WARN)
      return
    end
    for _, t in ipairs(tests) do
      bazel_test_target(overseer, root, t.label, nil)
    end
  else
    local class_name = build.test_at_cursor()
    build.resolve_bazel_target(root, function(target)
      bazel_test_target(overseer, root, target, class_name)
    end, { only_tests = true })
  end
end

-- ── Gradle helpers ───────────────────────────────────────────────────────────

local function gradle_run_task(overseer, root, args, label)
  local task = overseer.new_task({
    name       = "gradle " .. label,
    cmd        = vim.list_extend({ require("util.build").gradlew(root) }, args),
    cwd        = root,
    components = { "default", QUICKFIX_COMPONENT },
  })
  task:start()
  open_task_output(overseer, task)
end

local function gradle_build(overseer, root)
  local build  = require("util.build")
  local module = build.gradle_module(root)
  gradle_run_task(overseer, root, { module .. ":build" }, module .. ":build")
end

local function gradle_test_cursor(overseer, root)
  local build     = require("util.build")
  local module    = build.gradle_module(root)
  local test_task = module .. ":" .. build.gradle_test_task(root)
  if is_build_file() or is_gradle_file() then
    local src_class = source_class_under_cursor()
    if src_class then
      gradle_run_task(overseer, root,
        { test_task, "--tests", "*" .. src_class },
        test_task .. " --tests *" .. src_class)
    else
      gradle_run_task(overseer, root, { test_task }, test_task)
    end
  else
    local class_name, method_name = build.test_at_cursor()
    local pkg        = build.get_package()
    local full_class = (pkg ~= "" and (pkg .. ".") or "") .. (class_name or "*")
    local filter     = method_name and (full_class .. "." .. method_name) or full_class
    gradle_run_task(overseer, root,
      { test_task, "--tests", filter },
      test_task .. " --tests " .. filter)
  end
end

local function gradle_test_all(overseer, root)
  local build     = require("util.build")
  local module    = build.gradle_module(root)
  local test_task = module .. ":" .. build.gradle_test_task(root)
  if is_build_file() or is_gradle_file() then
    gradle_run_task(overseer, root, { test_task }, test_task)
  else
    local class_name = build.test_at_cursor()
    local pkg        = build.get_package()
    local full_class = (pkg ~= "" and (pkg .. ".") or "") .. (class_name or "*")
    gradle_run_task(overseer, root,
      { test_task, "--tests", full_class },
      test_task .. " --tests " .. full_class)
  end
end

-- ── Debug helpers ────────────────────────────────────────────────────────────

-- Poll port 5005 until the JVM is listening (max 5 min), then attach DAP.
-- Uses lsof instead of a TCP probe because JDWP accepts only one connection —
-- connecting+closing would corrupt the handshake for the real adapter.
-- Aborts early if the build task exits without ever opening the port (build
-- failure, no matching tests, --debug-jvm not honored, etc.).
local function attach_dap_to_test(root, task)
  local dap         = require("dap")
  local interval_ms = 500
  local max_ms      = 300000
  local elapsed     = 0
  local done        = false
  local timer       = vim.uv.new_timer()

  -- Async lsof: vim.fn.system blocks the main loop for ~50ms each tick, which
  -- resets the cursor blink animation and looks like flicker in the editor.
  local probing = false
  timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
    if done then return end
    elapsed = elapsed + interval_ms
    if not probing then
      probing = true
      vim.system({ "lsof", "-i:5005", "-sTCP:LISTEN" }, { text = true }, function(res)
        probing = false
        if done then return end
        if res.stdout and res.stdout:find("%S") then
          vim.schedule(function()
            if done then return end
            done = true
            timer:stop()
            timer:close()
            dap.run({
              type        = "kotlin",
              name        = "Debug test",
              request     = "attach",
              hostName    = "localhost",
              port        = 5005,
              timeout     = 15000,
              projectRoot = root,
            })
          end)
        end
      end)
    end
    if task and task:is_complete() then
      done = true
      timer:stop()
      timer:close()
      vim.notify(
        "DAP: build task exited (" .. tostring(task.status) .. ") without opening port 5005. "
          .. "Check the task output for build errors, or whether tests matched the filter.",
        vim.log.levels.ERROR
      )
    elseif elapsed >= max_ms then
      done = true
      timer:stop()
      timer:close()
      vim.notify("DAP: timed out after " .. (max_ms / 1000) .. "s waiting for JVM on port 5005", vim.log.levels.WARN)
    end
  end))
end

local function bazel_debug_target(overseer, root, target, filter)
  local jdwp = "transport=dt_socket,server=y,suspend=y,address=5005"
  local java_opts = "-agentlib:jdwp=" .. jdwp .. " -Djdk.attach.allowAttachSelf=true"
  local args = {
    "test", target,
    "--test_env=JAVA_TOOL_OPTIONS=" .. java_opts,
    "--test_output=streamed",
  }
  if filter then args[#args + 1] = "--test_filter=" .. filter end
  local task = overseer.new_task({
    name       = "bazel debug test " .. target .. (filter and ("#" .. filter) or ""),
    cmd        = vim.list_extend({ "bazel" }, args),
    cwd        = root,
    components = { "default", QUICKFIX_COMPONENT },
  })
  task:start()
  open_task_output(overseer, task)
  attach_dap_to_test(root, task)
end

local function bazel_debug_test(overseer, root)
  local build = require("util.build")
  if is_build_file() then
    local src_class = source_class_under_cursor()
    build.resolve_bazel_target(root, function(target)
      bazel_debug_target(overseer, root, target, src_class)
    end)
  else
    local class_name, method_name = build.test_at_cursor()
    local filter = class_name and method_name and (class_name .. "#" .. method_name)
      or class_name or method_name
    build.resolve_bazel_target(root, function(target)
      bazel_debug_target(overseer, root, target, filter)
    end, { only_tests = true })
  end
end

local function bazel_debug_test_all(overseer, root)
  local build = require("util.build")
  if is_build_file() then
    local bufname = vim.api.nvim_buf_get_name(0)
    local typed   = build.targets_in_build_file_typed(root, bufname)
    local tests   = vim.tbl_filter(function(t) return t.is_test end, typed)
    if #tests == 0 then
      vim.notify("No test targets found in BUILD file", vim.log.levels.WARN)
      return
    end
    for _, t in ipairs(tests) do
      bazel_debug_target(overseer, root, t.label, nil)
    end
  else
    local class_name = build.test_at_cursor()
    build.resolve_bazel_target(root, function(target)
      bazel_debug_target(overseer, root, target, class_name)
    end, { only_tests = true })
  end
end

-- Run a Gradle task in debug mode: injects -Xdebug via init script (disables
-- coroutine variable spilling) and --no-configuration-cache (init scripts are
-- incompatible with config cache). Polls for JDWP and attaches DAP.
local function gradle_debug_run(overseer, root, args, label)
  local build   = require("util.build")
  local wrapper = build.gradlew(root)
  local init_script = vim.fn.stdpath("config") .. "/lua/util/gradle-debug-init.gradle"
  local cmd = { wrapper, "--init-script", init_script, "--no-configuration-cache" }
  vim.list_extend(cmd, args)
  local task = overseer.new_task({
    name       = "gradle debug " .. label,
    cmd        = cmd,
    cwd        = root,
    env        = { JAVA_TOOL_OPTIONS = "-Djdk.attach.allowAttachSelf=true" },
    components = { "default", QUICKFIX_COMPONENT },
  })
  task:start()
  open_task_output(overseer, task)
  attach_dap_to_test(root, task)
end

-- Compute the clean task that pairs with a given test task:
--   ":a:b:jvmTest" → ":a:b:cleanJvmTest"
--   "test"          → "cleanTest"
local function clean_task_for(test_task)
  return test_task:gsub("([^:]+)$", function(name)
    return "clean" .. name:sub(1, 1):upper() .. name:sub(2)
  end)
end

local function gradle_debug_test(overseer, root)
  local build     = require("util.build")
  local module    = build.gradle_module(root)
  local test_task = module .. ":" .. build.gradle_test_task(root)
  -- JDWP wiring goes through both --debug-jvm and the init script's
  -- taskGraph.beforeTask hook (see gradle-debug-init.gradle). --debug-jvm is
  -- the canonical Gradle flag and works for any Test task; the init script
  -- hook is a backup for environments where --debug-jvm is honored but
  -- coroutine-related flags aren't propagated. Either one alone suffices to
  -- open port 5005.
  -- Prepend cleanTest so Gradle never skips the test as UP-TO-DATE — without
  -- this, repeat invocations don't fork a JVM and the debug port never opens.
  -- "--rerun" is a per-task flag (Gradle 7.6+) that forces this specific
  -- test task to execute even when its inputs are UP-TO-DATE. cleanTest
  -- alone isn't enough for KMP test tasks that cache on input hashes.
  local args = { clean_task_for(test_task), test_task, "--rerun", "--debug-jvm" }
  if is_build_file() or is_gradle_file() then
    local src_class = source_class_under_cursor()
    if src_class then
      vim.list_extend(args, { "--tests", "*" .. src_class })
    end
  else
    local class_name, method_name = build.test_at_cursor()
    local pkg        = build.get_package()
    local full_class = (pkg ~= "" and (pkg .. ".") or "") .. (class_name or "*")
    local filter     = method_name and (full_class .. "." .. method_name) or full_class
    vim.list_extend(args, { "--tests", filter })
  end
  gradle_debug_run(overseer, root, args, module)
end

local function gradle_debug_test_all(overseer, root)
  local build     = require("util.build")
  local module    = build.gradle_module(root)
  local test_task = module .. ":" .. build.gradle_test_task(root)
  -- "--rerun" is a per-task flag (Gradle 7.6+) that forces this specific
  -- test task to execute even when its inputs are UP-TO-DATE. cleanTest
  -- alone isn't enough for KMP test tasks that cache on input hashes.
  local args = { clean_task_for(test_task), test_task, "--rerun", "--debug-jvm" }
  if not (is_build_file() or is_gradle_file()) then
    local class_name = build.test_at_cursor()
    local pkg        = build.get_package()
    local full_class = (pkg ~= "" and (pkg .. ".") or "") .. (class_name or "*")
    vim.list_extend(args, { "--tests", full_class })
  end
  gradle_debug_run(overseer, root, args, module)
end

-- ── Unified dispatch ─────────────────────────────────────────────────────────

local function dispatch(action)
  return function()
    local build   = require("util.build")
    local overseer = require("overseer")
    local system, root = build.detect()
    if not system then
      vim.notify("No build system detected", vim.log.levels.WARN)
      return
    end
    if system == "bazel" then
      if     action == "build"       then bazel_build(overseer, root)
      elseif action == "test"        then bazel_test_cursor(overseer, root)
      elseif action == "test_all"    then bazel_test_all(overseer, root)
      elseif action == "debug_test"      then bazel_debug_test(overseer, root)
      elseif action == "debug_test_all"  then bazel_debug_test_all(overseer, root)
      end
    elseif system == "gradle" then
      if     action == "build"           then gradle_build(overseer, root)
      elseif action == "test"            then gradle_test_cursor(overseer, root)
      elseif action == "test_all"        then gradle_test_all(overseer, root)
      elseif action == "debug_test"      then gradle_debug_test(overseer, root)
      elseif action == "debug_test_all"  then gradle_debug_test_all(overseer, root)
      end
    end
  end
end

local function rerun_last()
  local overseer = require("overseer")
  local tasks    = overseer.list_tasks({ recent_first = true })
  if #tasks == 0 then
    vim.notify("No recent tasks", vim.log.levels.WARN)
    return
  end
  tasks[1]:restart(true)
end

-- ── Keybindings ──────────────────────────────────────────────────────────────

vim.keymap.set("n", "<leader>bb", dispatch("build"),    { desc = "Build (Bazel/Gradle)" })
vim.keymap.set("n", "<leader>bt", dispatch("test"),     { desc = "Test under cursor" })
vim.keymap.set("n", "<leader>bT", dispatch("test_all"), { desc = "All tests in file/target" })
vim.keymap.set("n", "<leader>br", rerun_last,           { desc = "Rerun last build task" })
vim.keymap.set("n", "<leader>dt", dispatch("debug_test"),     { desc = "Debug test under cursor" })
vim.keymap.set("n", "<leader>dT", dispatch("debug_test_all"), { desc = "Debug all tests in file/target" })
vim.keymap.set("n", "<leader>bl", "<cmd>OverseerToggle<cr>", { desc = "Toggle build task list" })

vim.keymap.set("n", "<leader>bJ", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "kotlin_lsp_jb" })
  if #clients > 0 then
    for _, c in ipairs(clients) do c.stop() end
    vim.notify("JetBrains Kotlin LSP stopped", vim.log.levels.INFO)
  else
    local ok, lspconfig = pcall(require, "lspconfig")
    if ok and lspconfig.kotlin_lsp_jb and lspconfig.kotlin_lsp_jb.manager then
      lspconfig.kotlin_lsp_jb.manager:try_add(vim.api.nvim_get_current_buf())
      vim.notify("JetBrains Kotlin LSP starting…", vim.log.levels.INFO)
    end
  end
end, { desc = "Toggle JetBrains Kotlin LSP (full type-checking)" })
