-- ; repeats any last custom keymap globally
-- Preserves native f/t/F/T repeat when those were used last

local last_keys = nil
local last_was_ft = false

-- Track all key presses via on_key callback
vim.on_key(function(key, typed)
  if not typed or typed == "" then return end
  -- Ignore ; itself to avoid recursion
  if typed == ";" then return end

  local mode = vim.api.nvim_get_mode().mode
  if mode ~= "n" and mode ~= "x" and mode ~= "v" then return end

  -- Check if this is an f/t/F/T motion
  local byte = string.byte(typed)
  local char = byte and string.char(byte)
  if char == "f" or char == "t" or char == "F" or char == "T" then
    last_was_ft = true
    last_keys = nil
    return
  end

  -- For mapped sequences (Leader+key combos), typed contains the full sequence
  -- Only track sequences that start with the leader key
  local leader = vim.g.mapleader or "\\"
  if typed:sub(1, #leader) == leader and #typed > #leader then
    last_was_ft = false
    last_keys = typed
  end
end)

vim.keymap.set({ "n", "x" }, ";", function()
  if last_was_ft then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(";", true, false, true), "nt", false)
  elseif last_keys then
    vim.api.nvim_feedkeys(last_keys, "m", false)
  end
end)
