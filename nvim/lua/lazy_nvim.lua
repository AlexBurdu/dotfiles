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

-- Every spec in plugins/ is loaded. Which optional specs are there is
-- decided by nvim/manifest.sh, which links them only where machine.sh
-- enables them; plugins/ is a real directory, so a spec dropped there by
-- an overlay repo or by hand is loaded the same way.
local spec = {
  -- import your plugins
  { import = "plugins" },
}

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
