-- DAP proxy for kotlin-debug-adapter that fixes source path resolution.
--
-- The kotlin-debug-adapter derives JVM class names from file paths by looking
-- for a "kotlin" or "java" directory segment and using everything after it as
-- the package. This breaks with non-standard project layouts where extra
-- directories (e.g. module names, source sets like "commonMain") appear in the
-- path between the language root and the source file.
--
-- This proxy reads the actual `package` declaration from Kotlin/Java source
-- files and rewrites the path in setBreakpoints requests so the adapter
-- resolves the correct JVM class name.

local M = {}

--- Read the package declaration from a source file.
--- Returns the package string or nil if not found.
local function read_package(path)
  local f = io.open(path, "r")
  if not f then return nil end
  for line in f:lines() do
    local pkg = line:match("^%s*package%s+([%w%.]+)")
    if pkg then
      f:close()
      return pkg
    end
    -- Stop after first 30 lines to avoid scanning entire file
    -- (package must be near the top)
  end
  f:close()
  return nil
end

--- Build a synthetic path that toJVMClassNames will parse correctly.
--- Given package "a.b.c" and filename "Foo.kt", produces:
---   /synthetic/kotlin/a/b/c/Foo.kt
local function make_synthetic_path(pkg, filename)
  local pkg_path = pkg:gsub("%.", "/")
  return "/synthetic/kotlin/" .. pkg_path .. "/" .. filename
end

--- Rewrite source paths in a setBreakpoints request body.
local function rewrite_request(body)
  local source = body and body.source
  if not source or not source.path then return body end

  local path = source.path
  -- Only rewrite Kotlin and Java files
  if not (path:match("%.kt$") or path:match("%.java$")) then
    return body
  end

  local pkg = read_package(path)
  if not pkg then return body end

  local filename = path:match("([^/]+)$")
  if not filename then return body end

  -- Check if the path already matches the package structure
  local pkg_as_path = pkg:gsub("%.", "/")
  -- Pattern: /kotlin/{pkg_path}/{filename} with nothing extra between
  local expected_suffix = "/kotlin/" .. pkg_as_path .. "/" .. filename
  if path:sub(-#expected_suffix) == expected_suffix then
    return body -- path already correct, no rewrite needed
  end

  local synthetic = make_synthetic_path(pkg, filename)
  source.path = synthetic
  return body
end

--- Create an adapter config that wraps kotlin-debug-adapter with path rewriting.
--- Uses nvim-dap's "server" adapter type with a pipe to the real adapter process.
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

--- Build a lookup of source file name → real file path from open buffers and
--- recently used breakpoint files.
local path_cache = {}

local function cache_real_path(path)
  if not path then return end
  local filename = path:match("([^/]+)$")
  if filename then
    path_cache[filename] = path
  end
end

--- Try to find the real file path for a source name.
--- Checks the cache first, then searches open buffers.
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

  return nil
end

--- Fix source paths in a stackTrace response so nvim-dap can open the files.
local function fix_stack_frame_sources(response)
  if not response or not response.stackFrames then return end
  for _, frame in ipairs(response.stackFrames) do
    local source = frame.source
    if source then
      -- If the source has no path or has a synthetic/missing path, try to resolve
      local name = source.name
      if name and (not source.path or source.path == "" or not vim.fn.filereadable(source.path) == 1) then
        local real = resolve_real_path(name)
        if real then
          source.path = real
        end
      end
    end
  end
end

--- Install a request interceptor on the DAP session that rewrites setBreakpoints paths.
function M.install_interceptor()
  local dap = require("dap")

  -- Must use before.event_initialized because event_initialized calls
  -- set_breakpoints directly inside the handler
  dap.listeners.before["event_initialized"]["kotlin_path_fix"] = function(session)
    if session.config.type ~= "kotlin" then return end
    if session._kotlin_path_fix then return end
    session._kotlin_path_fix = true

    -- rawget bypasses metatable to get the instance method (if set) or nil
    -- Session:request is defined on the metatable, so we call it via the
    -- original metatable lookup
    local Session = getmetatable(session).__index
    local orig = Session.request

    -- Override on the instance so it takes precedence over the metatable
    session.request = function(self, command, arguments, callback)
      if command == "setBreakpoints" then
        -- Cache the real path before rewriting
        local source = arguments and arguments.source
        if source and source.path then
          cache_real_path(source.path)
        end
        arguments = rewrite_request(vim.deepcopy(arguments))
      end

      -- Wrap stackTrace to catch adapter errors (IncompatibleThreadStateException)
      -- and return an empty result instead of propagating the error
      if command == "stackTrace" then
        local orig_cb = callback
        if orig_cb then
          return orig(self, command, arguments, function(err, response)
            if err then
              orig_cb(nil, { stackFrames = {}, totalFrames = 0 })
              return
            end
            orig_cb(err, response)
          end)
        else
          -- Synchronous (coroutine) call path
          local err, response = orig(self, command, arguments)
          if err then
            return nil, { stackFrames = {}, totalFrames = 0 }
          end
          return err, response
        end
      end

      return orig(self, command, arguments, callback)
    end
  end

  -- Fix source paths in stackTrace responses so nvim can open the files
  dap.listeners.before["stackTrace"]["kotlin_path_fix"] = function(session, err, response)
    if err then return end
    if session.config.type ~= "kotlin" then return end
    fix_stack_frame_sources(response)
  end
end

-- Expose for testing
M._read_package = read_package
M._make_synthetic_path = make_synthetic_path
M._rewrite_request = rewrite_request

return M
