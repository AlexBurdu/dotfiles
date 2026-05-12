-- nvim-lspconfig is a Neovim plugin that provides configurations for various
-- language servers.
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
    "milanglacier/minuet-ai.nvim",
  },

  config = function()
    local cmp = require('cmp')
    local cmp_lsp = require("cmp_nvim_lsp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities())

    require("fidget").setup({})
    require("mason").setup()
    require("mason-lspconfig").setup({
      automatic_installation = true,
      -- See complete list of Mason supported servers: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
      ensure_installed = {
        "ast_grep",
        "bashls",
        "buf_ls",
        "clangd",
        "docker_compose_language_service",
        "dockerls",
        "gopls",
        "gradle_ls",
        "jsonls",
        "kotlin_lsp",
        "lua_ls",
        "marksman",
        "pyright",
        "starpls",
      },
      handlers = {
        function(server_name) -- default handler (optional)
          require("lspconfig")[server_name].setup {
            capabilities = capabilities
          }
        end,

        -- Suppress auto-start: JetBrains kotlin_lsp is registered manually as
        -- kotlin_lsp_jb with autostart=false, started on demand via <leader>bJ
        kotlin_lsp = function() end,

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
        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup {
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
      }
    })

    -- Hessesian/kotlin-lsp: fast Rust-based LSP (no JVM), replaces JetBrains kotlin_lsp
    local configs = require('lspconfig.configs')
    configs.kotlin_lsp = {
      default_config = {
        cmd       = { vim.fn.expand('~/.cargo/bin/kotlin-lsp') },
        filetypes = { 'kotlin', 'java', 'swift' },
        root_dir  = require('lspconfig').util.root_pattern(
          'build.gradle', 'build.gradle.kts', 'pom.xml', 'settings.gradle', 'Package.swift', '.git'
        ),
        settings  = {},
      },
    }
    require('lspconfig').kotlin_lsp.setup { capabilities = capabilities }

    -- JetBrains kotlin_lsp: full type-checking, started on demand via <leader>lJ
    local lspconfig = require('lspconfig')
    configs.kotlin_lsp_jb = {
      default_config = {
        cmd       = { vim.fn.stdpath('data') .. '/mason/bin/kotlin-lsp' },
        filetypes = { 'kotlin', 'java' },
        root_dir  = lspconfig.util.root_pattern(
          'build.gradle', 'build.gradle.kts', 'pom.xml', 'settings.gradle', '.git'
        ),
        settings  = {},
      },
    }
    lspconfig.kotlin_lsp_jb.setup {
      capabilities = capabilities,
      autostart    = false,
      -- Record exit time so ensure_jetbrains_lsp() won't immediately restart
      -- while the JVM process is still holding its TCP port.
      on_exit = function(_, _, _)
        -- Expose via a global so keymap/build.lua can read it without a shared module.
        vim.g._kotlin_lsp_jb_exited_at = vim.uv.now()
      end,
    }

    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    -- Accept one word from minuet ghost text (not built into minuet)
    local function accept_word()
      local vt_mod = require('minuet.virtualtext')
      if not vt_mod.action.is_visible() then return false end
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
          local vt = require('minuet.virtualtext').action
          if cmp.visible() then cmp.select_prev_item(cmp_select)
          elseif require('minuet').config then vt.prev()
          else fallback() end
        end, { 'i' }),
        ['<C-n>'] = cmp.mapping(function(fallback)
          local vt = require('minuet.virtualtext').action
          if cmp.visible() then cmp.select_next_item(cmp_select)
          elseif require('minuet').config then vt.next()
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
          local vt = require('minuet.virtualtext').action
          if vt.is_visible() then vt.accept_line()
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
          local vt = require('minuet.virtualtext').action
          if vt.is_visible() then vt.accept()
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
