-- DAP proxy for kotlin-debug-adapter (KDA) source path resolution.
--
-- Problem: KDA derives JVM class names from file paths by looking for a
-- "kotlin" or "java" segment and using everything after it as the package.
-- This breaks in non-standard layouts (KMP, deep module nesting) where extra
-- directories appear between the language root and the source file.
--
-- Solution: Two-way path fixup:
--   1. setBreakpoints → rewrite paths using the actual `package` declaration
--      so KDA resolves the correct JVM class.
--   2. stackTrace responses → resolve source names back to real file paths
--      so nvim can open the files when stepping through code.

local M = {}

local function read_package(path)
  local f = io.open(path, "r")
  if not f then return nil end
  for line in f:lines() do
    local pkg = line:match("^%s*package%s+([%w%.]+)")
    if pkg then f:close(); return pkg end
  end
  f:close()
  return nil
end

-- Build a path KDA's toJVMClassNames will parse correctly:
-- "a.b.c" + "Foo.kt" → "/synthetic/kotlin/a/b/c/Foo.kt"
local function make_synthetic_path(pkg, filename)
  local pkg_path = pkg:gsub("%.", "/")
  return "/synthetic/kotlin/" .. pkg_path .. "/" .. filename
end

-- Rewrite source path in setBreakpoints so KDA maps to the right JVM class.
-- No-op if the path already ends with /kotlin/{package}/{file}.
local function rewrite_request(body)
  local source = body and body.source
  if not source or not source.path then return body end

  local path = source.path
  if not (path:match("%.kt$") or path:match("%.java$")) then return body end

  local pkg = read_package(path)
  if not pkg then return body end

  local filename = path:match("([^/]+)$")
  if not filename then return body end

  local expected_suffix = "/kotlin/" .. pkg:gsub("%.", "/") .. "/" .. filename
  if path:sub(-#expected_suffix) == expected_suffix then return body end

  source.path = make_synthetic_path(pkg, filename)
  return body
end

function M.make_adapter(real_command, opts)
  local options = opts or {}
  return {
    type = "pipe",
    pipe = "${pipe}",
    options = options,
    executable = {
      command = real_command,
      args = {},
      detached = false,
    },
  }
end

-- filename → real path cache for stackTrace source resolution
local path_cache = {}

local function cache_real_path(path)
  if not path then return end
  local filename = path:match("([^/]+)$")
  if filename then path_cache[filename] = path end
end

-- Resolve a source filename to a real path: cache → buffers → fd/find.
local function resolve_real_path(source_name)
  if not source_name then return nil end

  -- Check cache
  local cached = path_cache[source_name]
  if cached then return cached end

  -- Search open buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name and name:match("([^/]+)$") == source_name then
        path_cache[source_name] = name
        return name
      end
    end
  end

  -- Fallback: fd/find. Pass arguments as a list (no shell) so a source name
  -- containing shell metacharacters or regex/glob metas can't be misinterpreted.
  -- fd's --fixed-strings forces literal matching; find's -name uses glob, which
  -- treats * and ? specially — JVM source names shouldn't contain them, but if
  -- they do the search just won't match (no security impact).
  local cwd = vim.fn.getcwd()
  local argv
  if vim.fn.executable("fd") == 1 then
    argv = { "fd", "--type", "f", "--fixed-strings",
             "--exclude", "build", "--exclude", ".gradle", "--exclude", "bazel-*",
             "--max-results", "1", source_name, cwd }
  else
    argv = { "find", cwd, "-name", source_name,
             "-not", "-path", "*/build/*",
             "-not", "-path", "*/.gradle/*",
             "-not", "-path", "*/bazel-*/*",
             "-print", "-quit" }
  end
  local lines = vim.fn.systemlist(argv)
  local result = lines and lines[1] and lines[1]:gsub("%s+$", "") or ""
  if result ~= "" and vim.fn.filereadable(result) == 1 then
    path_cache[source_name] = result
    return result
  end

  return nil
end

-- Replace missing/synthetic source paths with real paths in stack frames.
local function fix_stack_frame_sources(response)
  if not response or not response.stackFrames then return end
  for _, frame in ipairs(response.stackFrames) do
    local source = frame.source
    if source then
      -- If the source has no path or has a synthetic/missing path, try to resolve
      local name = source.name
      if name and (not source.path or source.path == "" or vim.fn.filereadable(source.path) ~= 1) then
        local real = resolve_real_path(name)
        if real then
          source.path = real
        end
      end
    end
  end
end

-- Install request/response interceptors on DAP sessions for path fixup.
-- Hooks into event_initialized (before set_breakpoints is called).
function M.install_interceptor()
  local dap = require("dap")

  dap.listeners.before["event_initialized"]["kotlin_path_fix"] = function(session)
    if session.config.type ~= "kotlin" then return end
    if session._kotlin_path_fix then return end
    session._kotlin_path_fix = true

    -- Session:request lives on the metatable; grab it before overriding
    local Session = getmetatable(session).__index
    local orig = Session.request

    -- Pre-cache buffer paths for stack frame resolution
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        cache_real_path(vim.api.nvim_buf_get_name(buf))
      end
    end

    session.request = function(self, command, arguments, callback)
      if command == "setBreakpoints" then
        local source = arguments and arguments.source
        if source and source.path then cache_real_path(source.path) end
        arguments = rewrite_request(vim.deepcopy(arguments))
      end

      -- stackTrace: fix source paths + swallow IncompatibleThreadStateException
      if command == "stackTrace" then
        local orig_cb = callback
        if orig_cb then
          return orig(self, command, arguments, function(err, response)
            if err then
              orig_cb(nil, { stackFrames = {}, totalFrames = 0 })
              return
            end
            fix_stack_frame_sources(response)
            orig_cb(err, response)
          end)
        else
          -- Synchronous (coroutine) call path
          local err, response = orig(self, command, arguments)
          if err then
            return nil, { stackFrames = {}, totalFrames = 0 }
          end
          fix_stack_frame_sources(response)
          return err, response
        end
      end

      return orig(self, command, arguments, callback)
    end
  end

  -- Also fix paths via the listener (covers cases not going through our override)
  dap.listeners.before["stackTrace"]["kotlin_path_fix"] = function(session, err, response)
    if err then return end
    if session.config.type ~= "kotlin" then return end
    fix_stack_frame_sources(response)
  end
end

return M
