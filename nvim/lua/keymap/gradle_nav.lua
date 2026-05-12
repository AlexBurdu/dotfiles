-- Buffer-local gd/gf overrides for gradle.kts files: jump to source files
-- referenced in build scripts (e.g. include("Foo.kt")). Falls through to
-- LSP definition (gd) or builtin gF (gf) for non-filename strings.

local function is_source_filename(s)
  return s:match("^[%w_%-%.]+%.[%a]+$") ~= nil
end

local function filename_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for s, content, e in line:gmatch('()\"([^\"]+)\"()') do
    if col >= s and col < e and is_source_filename(content) then
      return content
    end
  end
end

local function find_source_file(buf, name)
  local gradle_dir = vim.fn.expand("#" .. buf .. ":p:h")
  local found = vim.fn.globpath(gradle_dir, "**/" .. name, false, true)
  local results = {}
  for _, path in ipairs(found) do
    if not path:match("/build/") and not path:match("/build_[^/]*/") then
      results[#results + 1] = path
    end
  end
  return results
end

local function open_results(results, name)
  if #results == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(results[1]))
  elseif #results > 1 then
    vim.ui.select(results, { prompt = "Which file?" }, function(choice)
      if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
    end)
  else
    vim.notify("File not found: " .. name, vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.gradle.kts", "*.gradle" },
  callback = function(ev)
    vim.keymap.set("n", "gd", function()
      local name = filename_under_cursor()
      if not name then
        vim.lsp.buf.definition()
        return
      end
      open_results(find_source_file(ev.buf, name), name)
    end, { buffer = ev.buf, desc = "Go to source file in gradle build" })

    vim.keymap.set("n", "gf", function()
      local name = filename_under_cursor()
      if not name then
        vim.cmd("normal! gF")
        return
      end
      open_results(find_source_file(ev.buf, name), name)
    end, { buffer = ev.buf, desc = "Go to source file in gradle build" })
  end,
})
