-- Loads all the keymap files in the current directory and its subdirectories
local current_dir = vim.fn.expand("<sfile>:p:h")
local files = vim.fn.glob(current_dir .. "/**/*", true, true)
for _, file in ipairs(files) do
  if file:match("%.vim$") then
    vim.cmd("source " .. file)
  elseif file:match("%.lua$") then
    -- if the file is not init.lua
    if not file:match("init%.lua$") then
      dofile(file)
    end
  end
end

