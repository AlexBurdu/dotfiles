-- nvim-lspconfig is a Neovim plugin that provides configurations for various
-- language servers.
--
-- The servers are data in `opts`, so an optional spec can add to them
-- without replacing `config` (plugins/jvm.lua does):
--   ensure_installed  Mason servers to install, name = true
--   handlers          per-server setup, function(capabilities)
--   servers           servers Mason does not manage, function(capabilities)
-- All three are maps rather than lists: lazy.nvim merges maps from every
-- spec, whichever order it loads them in, but replaces lists.
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "j-hui/fidget.nvim",
    "onsails/lspkind.nvim",
  },

  opts = {
    -- See complete list of Mason supported servers: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
    ensure_installed = {
      ast_grep = true,
      bashls = true,
      buf_ls = true,
      clangd = true,
      docker_compose_language_service = true,
      dockerls = true,
      gopls = true,
      gradle_ls = true,
      jsonls = true,
      lua_ls = true,
      marksman = true,
      pyright = true,
      starpls = true,
    },
    handlers = {
      zls = function()
        local lspconfig = require("lspconfig")
        lspconfig.zls.setup({
          root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
          settings = {
            zls = {
              enable_inlay_hints = true,
              enable_snippets = true,
              warn_style = true,
            },
          },
        })
        vim.g.zig_fmt_parse_errors = 0
        vim.g.zig_fmt_autosave = 0
      end,
      -- Mason's kotlin_lsp is JetBrains' JVM server. Never auto-start it:
      -- optional `jvm` registers it as kotlin_lsp_jb, started on demand,
      -- and a machine without `jvm` may still have it installed from
      -- before.
      kotlin_lsp = function() end,
      lua_ls = function(capabilities)
        require("lspconfig").lua_ls.setup {
          capabilities = capabilities,
          settings = {
            Lua = {
              runtime = { version = "Lua 5.1" },
              diagnostics = {
                globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
              }
            }
          }
        }
      end,
    },
    servers = {},
  },

  config = function(_, opts)
    local cmp = require('cmp')
    local cmp_lsp = require("cmp_nvim_lsp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities())

    require("fidget").setup({})
    require("mason").setup()
    local handlers = {
      function(server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {
          capabilities = capabilities
        }
      end,
    }
    for name, setup in pairs(opts.handlers) do
      handlers[name] = function() setup(capabilities) end
    end
    require("mason-lspconfig").setup({
      automatic_installation = true,
      ensure_installed = vim.tbl_keys(opts.ensure_installed),
      handlers = handlers,
    })
    for _, setup in pairs(opts.servers) do
      setup(capabilities)
    end

    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    -- Minuet ghost text is optional (plugins/minuet.lua). Every key
    -- below that drives it asks for it here first, and falls through to
    -- its popup or default behaviour on a machine without it, or while
    -- minuet has no provider configured.
    local function minuet_vt()
      local ok, minuet = pcall(require, 'minuet')
      if not ok or not minuet.config then return nil end
      return require('minuet.virtualtext')
    end

    -- Accept one word from minuet ghost text (not built into minuet)
    local function accept_word()
      local vt_mod = minuet_vt()
      if not vt_mod or not vt_mod.action.is_visible() then return false end
      local extmark = vim.api.nvim_buf_get_extmark_by_id(
        0, vt_mod.ns_id, 1, { details = true }
      )
      if not extmark or not extmark[3] or not extmark[3].virt_text then return false end
      local text = extmark[3].virt_text[1][1]
      -- Match a word: non-space chars, or leading whitespace if at a boundary
      local word = text:match('^([%w_]+)') or text:match('^(%S+)') or text:match('^(%s+)')
      if not word or word == '' then return false end
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line, col = cursor[1] - 1, cursor[2]
      vim.api.nvim_buf_set_text(0, line, col, line, col, { word })
      vim.api.nvim_win_set_cursor(0, { cursor[1], col + #word })
      return true
    end

    cmp.setup({
      performance = {
        fetching_timeout = 2000,
      },
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
      },
      formatting = {
        format = require('lspkind').cmp_format({
          mode = 'symbol_text',
          menu = {
            nvim_lsp = '[LSP]',
            luasnip = '[Snip]',
            buffer = '[Buf]',
          },
        }),
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping(function(fallback)
          local vt = minuet_vt()
          if cmp.visible() then cmp.select_prev_item(cmp_select)
          elseif vt then vt.action.prev()
          else fallback() end
        end, { 'i' }),
        ['<C-n>'] = cmp.mapping(function(fallback)
          local vt = minuet_vt()
          if cmp.visible() then cmp.select_next_item(cmp_select)
          elseif vt then vt.action.next()
          else fallback() end
        end, { 'i' }),
        ['<C-k>'] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_prev_item(cmp_select)
          else cmp.complete() end
        end, { 'i' }),
        ['<C-j>'] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item(cmp_select)
          else cmp.complete() end
        end, { 'i' }),
        ['<C-y>'] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.confirm({ select = true })
          elseif not accept_word() then fallback() end
        end, { 'i' }),
        ['<C-h>'] = cmp.mapping(function(fallback)
          local vt = minuet_vt()
          if vt and vt.action.is_visible() then vt.action.accept_line()
          else fallback() end
        end, { 'i' }),
        ['<C-u>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 10 do cmp.select_prev_item(cmp_select) end
          else fallback() end
        end, { 'i' }),
        ['<C-d>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            for _ = 1, 10 do cmp.select_next_item(cmp_select) end
          else fallback() end
        end, { 'i' }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          local vt = minuet_vt()
          if vt and vt.action.is_visible() then vt.action.accept()
          else fallback() end
        end, { 'i' }),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
      }, {
        { name = 'buffer' },
      })
    })

    vim.diagnostic.config({
      -- update_in_insert = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
  end
}
