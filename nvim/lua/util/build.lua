-- Build system detection and target resolution for Bazel and Gradle.
-- Used by keymap/build.lua for test/debug dispatch.

local M = {}

function M.find_bazel_root(dir)
  dir = dir or vim.fn.expand("%:p:h")
  while dir ~= "/" do
    for _, name in ipairs({ "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" }) do
      if vim.fn.filereadable(dir .. "/" .. name) == 1 then
        return dir
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
end

function M.find_gradle_root(dir)
  dir = dir or vim.fn.expand("%:p:h")
  while dir ~= "/" do
    if vim.fn.filereadable(dir .. "/settings.gradle.kts") == 1
      or vim.fn.filereadable(dir .. "/settings.gradle") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
end

-- Parse all target labels ("//pkg:name") from a BUILD file.
function M.targets_in_build_file(workspace_root, build_file)
  local package = vim.fn.fnamemodify(build_file, ":h"):sub(#workspace_root + 2)
  local targets = {}
  for line in io.lines(build_file) do
    local name = line:match('name%s*=%s*"([^"]+)"')
    if name then
      targets[#targets + 1] = "//" .. package .. ":" .. name
    end
  end
  return targets
end

-- In a BUILD file, walk backward from cursor to the nearest name = "...".
function M.target_under_cursor(workspace_root)
  local filepath = vim.api.nvim_buf_get_name(0)
  local build_dir = vim.fn.fnamemodify(filepath, ":p:h")
  local package = build_dir:sub(#workspace_root + 2)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, cursor_line, false)
  for i = #lines, 1, -1 do
    local name = lines[i]:match('name%s*=%s*"([^"]+)"')
    if name then
      return "//" .. package .. ":" .. name
    end
  end
end

-- Resolve a Bazel target for the current buffer (async, calls cb(target)).
-- BUILD file: target under cursor.
-- Source file: nearest BUILD, with resolution priority:
--   1. Target whose name matches the filename stem (Foo.kt → :Foo)
--   2. Sole test target (when opts.only_tests = true)
--   3. Picker (filtered to test targets if available)
function M.resolve_bazel_target(workspace_root, cb, opts)
  opts = opts or {}
  local bufname = vim.api.nvim_buf_get_name(0)
  local is_build = bufname:match("BUILD%.bazel$") or bufname:match("/BUILD$")

  if is_build then
    local target = M.target_under_cursor(workspace_root)
    if target then
      cb(target)
    else
      vim.notify("No Bazel target found under cursor", vim.log.levels.WARN)
    end
    return
  end

  -- Filename stem: "SyncControllerTest" from "SyncControllerTest.kt"
  local file_stem = vim.fn.fnamemodify(bufname, ":t:r")

  -- Source file: find nearest BUILD
  local dir = vim.fn.expand("%:p:h")
  while dir ~= workspace_root and dir ~= "/" do
    for _, bname in ipairs({ "BUILD.bazel", "BUILD" }) do
      local path = dir .. "/" .. bname
      if vim.fn.filereadable(path) == 1 then
        local typed = M.targets_in_build_file_typed(workspace_root, path)

        -- Priority 1: exact name match regardless of rule type.
        for _, t in ipairs(typed) do
          if t.label:match(":" .. vim.pesc(file_stem) .. "$") then
            cb(t.label)
            return
          end
        end

        -- Priority 2+: use rule-type filter when requested.
        local candidates
        if opts.only_tests then
          local test_typed = vim.tbl_filter(function(t) return t.is_test end, typed)
          candidates = #test_typed > 0
            and vim.tbl_map(function(t) return t.label end, test_typed)
            or  vim.tbl_map(function(t) return t.label end, typed)
        else
          candidates = vim.tbl_map(function(t) return t.label end, typed)
        end

        if #candidates == 0 then
          vim.notify("No targets found in " .. path, vim.log.levels.WARN)
        elseif #candidates == 1 then
          cb(candidates[1])
        else
          vim.ui.select(candidates, { prompt = "Bazel target:" }, function(choice)
            if choice then cb(choice) end
          end)
        end
        return
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  vim.notify("No BUILD file found", vim.log.levels.WARN)
end

local function has_gradle_build(dir)
  if vim.fn.filereadable(dir .. "/build.gradle.kts") == 1
    or vim.fn.filereadable(dir .. "/build.gradle") == 1 then
    return true
  end
  -- <name>.build.gradle.kts pattern used in this project
  local files = vim.fn.glob(dir .. "/*.build.gradle.kts", false, true)
  return #files > 0
end

-- Gradle module prefix for the current file (e.g. ":app:core").
function M.gradle_module(gradle_root)
  local dir = vim.fn.expand("%:p:h")
  while dir ~= gradle_root and dir ~= "/" do
    if has_gradle_build(dir) then
      local rel = dir:sub(#gradle_root + 2)
      return rel ~= "" and (":" .. rel:gsub("/", ":")) or ""
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return ""
end

-- Test task name: "jvmTest" for KMP (multiplatform), "test" otherwise.
function M.gradle_test_task(gradle_root)
  local dir = vim.fn.expand("%:p:h")
  while dir ~= gradle_root and dir ~= "/" do
    -- Check *.build.gradle.kts (generated KMP pattern)
    local kmp_files = vim.fn.glob(dir .. "/*.build.gradle.kts", false, true)
    for _, f in ipairs(kmp_files) do
      for line in io.lines(f) do
        if line:match("multiplatform") then return "jvmTest" end
      end
    end
    -- Check build.gradle.kts
    local build_file = dir .. "/build.gradle.kts"
    if vim.fn.filereadable(build_file) == 1 then
      for line in io.lines(build_file) do
        if line:match("multiplatform") then return "jvmTest" end
      end
      return "test"
    end
    build_file = dir .. "/build.gradle"
    if vim.fn.filereadable(build_file) == 1 then
      return "test"
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return "test"
end

function M.gradlew(gradle_root)
  local w = gradle_root .. "/gradlew"
  return vim.fn.filereadable(w) == 1 and w or "gradle"
end

-- Parse targets with rule types. Returns { label, is_test } list.
function M.targets_in_build_file_typed(workspace_root, build_file)
  local package = vim.fn.fnamemodify(build_file, ":h"):sub(#workspace_root + 2)
  local results = {}
  local current_rule_type = nil
  for line in io.lines(build_file) do
    local rule = line:match("^([%w_]+)%s*%(")
    if rule then current_rule_type = rule end
    local name = line:match('name%s*=%s*"([^"]+)"')
    if name and current_rule_type then
      results[#results + 1] = {
        label = "//" .. package .. ":" .. name,
        is_test = current_rule_type:lower():find("test") ~= nil,
      }
    end
  end
  return results
end

function M.get_package()
  local lines = vim.api.nvim_buf_get_lines(0, 0, 15, false)
  for _, line in ipairs(lines) do
    local pkg = line:match("^package%s+([%w%.]+)")
    if pkg then return pkg end
  end
  return ""
end

-- Enclosing class and method at cursor (tree-sitter, regex fallback).
function M.test_at_cursor()
  local bufnr = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- Tree-sitter path
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if ok and parser then
    local root = parser:parse()[1]:root()
    local node = root:named_descendant_for_range(row, 0, row, 0)
    local class_name, method_name
    local n = node
    while n do
      local t = n:type()
      if not method_name and t == "function_declaration" then
        for child in n:iter_children() do
          if child:type() == "simple_identifier" then
            method_name = vim.treesitter.get_node_text(child, bufnr):gsub("^`(.+)`$", "%1")
            break
          end
        end
      end
      if not class_name and t == "class_declaration" then
        for child in n:iter_children() do
          if child:type() == "type_identifier" then
            class_name = vim.treesitter.get_node_text(child, bufnr)
            break
          end
        end
      end
      n = n:parent()
    end
    if class_name or method_name then
      return class_name, method_name
    end
  end

  -- Regex fallback: scan backward from cursor
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
  local class_name, method_name
  for i = #lines, 1, -1 do
    local line = lines[i]
    if not method_name then
      method_name = line:match("%s*fun%s+(%w+)%s*%(")
    end
    if not class_name then
      class_name = line:match("%s*class%s+(%w+)")
    end
    if class_name and method_name then break end
  end
  return class_name, method_name
end

-- kmp_* rules generate Gradle projects — prefer Gradle for these.
local function build_file_uses_kmp(path)
  for line in io.lines(path) do
    if line:match("^kmp_[%w_]*%s*%(") then
      return true
    end
  end
  return false
end

-- Detect build system by walking up to the nearest build file.
-- BUILD files with kmp_* rules are treated as Gradle (they generate Gradle projects).
function M.detect(start_dir)
  local dir = start_dir or vim.fn.expand("%:p:h")
  local bazel_root = M.find_bazel_root(dir)
  local gradle_root = M.find_gradle_root(dir)

  -- Walk up and return whichever build file we hit first.
  local d = dir
  while d ~= "/" do
    for _, name in ipairs({ "BUILD.bazel", "BUILD" }) do
      local path = d .. "/" .. name
      if vim.fn.filereadable(path) == 1 then
        if gradle_root and build_file_uses_kmp(path) then
          return "gradle", gradle_root
        end
        return "bazel", bazel_root
      end
    end
    if has_gradle_build(d) then
      return "gradle", gradle_root
    end
    d = vim.fn.fnamemodify(d, ":h")
  end

  -- Fallback: whichever root exists
  if bazel_root then return "bazel", bazel_root end
  if gradle_root then return "gradle", gradle_root end
end

return M
