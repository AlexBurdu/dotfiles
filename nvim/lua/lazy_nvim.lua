-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Plugin specs. `plugins/local` is a machine-local, gitignored
-- overlay: specs placed there load like any other but are never
-- committed. The import is added only when the directory exists,
-- so fresh checkouts work with no extra setup.
local spec = {
  -- import your plugins
  { import = "plugins" },
}
local local_overlay = vim.fn.stdpath("config") .. "/lua/plugins/local"
if (vim.uv or vim.loop).fs_stat(local_overlay) then
  table.insert(spec, { import = "plugins.local" })
end

-- Setup lazy.nvim
require("lazy").setup({
  spec = spec,
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = true,
    notify = false, -- get a notification when changes are found
  },
  -- automatically check for plugin updates
  checker = { enabled = false },
})
