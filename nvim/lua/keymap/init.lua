local current_dir = vim.fn.expand("<sfile>:p:h")
local vim_files = vim.fn.glob(current_dir .. "/**/*.vim", true, true)
for _, file in ipairs(vim_files) do
  vim.cmd("source " .. file)
end

local lua_files = vim.fn.glob(current_dir .. "/**/*.lua", true, true)
for _, file in ipairs(lua_files) do
  if file:match("keymap/init.lua") == nil then
  --  dofile(file)
  end
end

