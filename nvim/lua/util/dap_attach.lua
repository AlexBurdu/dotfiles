-- Language-aware attach for <Leader>da, and the tool checks it needs.
--
-- The common dap spec registers Python. Optional specs (plugins/jvm.lua)
-- register their own filetypes, so an attach flow exists only on the
-- machines that enable its language.
local M = {}

local handlers = {}
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

-- register({ "kotlin", "java" }, fn): <Leader>da in those filetypes runs fn.
function M.register(filetypes, fn)
  for _, ft in ipairs(filetypes) do
    handlers[ft] = fn
  end
end

function M.attach()
  local ft = vim.bo.filetype
  if handlers[ft] then
    handlers[ft]()
    return
  end
  local supported = vim.tbl_keys(handlers)
  table.sort(supported)
  vim.notify(
    "No debug adapter for filetype: " .. ft
      .. "\nSupported: " .. table.concat(supported, ", "),
    vim.log.levels.WARN
  )
end

local function mason_install(pkg_name, on_success)
  local pkg = require("mason-registry").get_package(pkg_name)
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

-- Run on_ready once every tool is on PATH or in Mason's bin. A missing
-- tool is offered for install when opts.mason names its package, and
-- otherwise reported with opts.hints[tool] as the install command.
function M.check_tools(tools, on_ready, opts)
  opts = opts or {}
  local mason = opts.mason or {}
  local hints = opts.hints or {}
  for _, tool in ipairs(tools) do
    local found = vim.fn.executable(tool) == 1
      or vim.fn.filereadable(mason_bin .. tool) == 1
    if not found then
      if mason[tool] then
        vim.ui.select({ "Yes", "No" }, {
          prompt = tool .. " is not installed. Install via Mason?",
        }, function(choice)
          if choice == "Yes" then
            mason_install(mason[tool], function()
              M.check_tools(tools, on_ready, opts)
            end)
          end
        end)
      else
        vim.notify(
          tool .. " not found. Install with:\n  " .. (hints[tool] or tool),
          vim.log.levels.ERROR
        )
      end
      return false
    end
  end
  if on_ready then on_ready() end
  return true
end

return M
