-- Navigation to owning BUILD file
-- <Leader>gb: Find and open nearest BUILD file, jump to current filename
vim.keymap.set("n", "<leader>gb", function()
  local current_file = vim.fn.expand("%:t")
  local dir = vim.fn.expand("%:p:h")
  while dir ~= "/" do
    for _, name in ipairs({"BUILD.bazel", "BUILD"}) do
      local path = dir .. "/" .. name
      if vim.fn.filereadable(path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        -- Try to find the filename in the buffer
        vim.fn.search(current_file)
        -- Center the screen
        vim.cmd("normal! zz")
        return
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  print("No BUILD file found")
end, { desc = "Go to owning BUILD file" })
