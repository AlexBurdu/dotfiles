-- AI code completion via Claude, Gemini, Codestral, or Ollama
-- https://github.com/milanglacier/minuet-ai.nvim
-- Shows inline ghost text; accept with Tab/C-y/C-h, cycle with C-n/C-p.
-- Switch providers with :MinuetProvider <name> (persisted across sessions).
local state_file = vim.fn.stdpath('state') .. '/minuet-provider'

local function ollama_available()
  local h = io.popen('curl -sf http://localhost:11434/api/tags 2>/dev/null')
  if not h then return false end
  local out = h:read('*a')
  h:close()
  return out and out:find('codegemma') ~= nil
end

local function default_provider()
  if os.getenv('GEMINI_API_KEY') then return 'gemini' end
  if os.getenv('ANTHROPIC_API_KEY') then return 'claude' end
  if os.getenv('CODESTRAL_API_KEY') then return 'codestral' end
  if ollama_available() then return 'ollama' end
  return nil
end

local function read_provider()
  local f = io.open(state_file, 'r')
  if f then
    local name = f:read('*l')
    f:close()
    if name and name ~= '' then return name end
  end
  return default_provider()
end

local function write_provider(name)
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ':h'), 'p')
  local f = io.open(state_file, 'w')
  if f then
    f:write(name .. '\n')
    f:close()
  end
end

-- Map friendly names to minuet provider keys
local provider_map = {
  claude = 'claude',
  gemini = 'gemini',
  codestral = 'codestral',
  ollama = 'openai_fim_compatible',
}

local function resolve_provider(name)
  return provider_map[name] or name
end

return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    local initial = read_provider()

    if not initial then
      vim.api.nvim_create_user_command('MinuetProvider', function(opts)
        vim.notify('No AI provider available — set an API key or start Ollama', vim.log.levels.WARN)
      end, { nargs = 1, complete = function() return vim.tbl_keys(provider_map) end })
      return
    end

    require('minuet').setup({
      provider = resolve_provider(initial),
      notify = 'warn',
      request_timeout = 4,
      n_completions = 1,
      virtualtext = {
        auto_trigger_ft = { '*' },
        -- Keymaps set in lsp.lua alongside cmp mappings for context-aware behavior
        keymap = {},
      },
      cmp = {
        enable_auto_complete = false,
      },
      provider_options = {
        claude = {
          model = 'claude-haiku-4-5-20251001',
          max_tokens = 256,
          api_key = 'ANTHROPIC_API_KEY',
        },
        gemini = {
          model = 'gemini-2.0-flash',
          api_key = 'GEMINI_API_KEY',
          optional = {
            generationConfig = {
              maxOutputTokens = 256,
              thinkingConfig = { thinkingBudget = 0 },
            },
          },
        },
        codestral = {
          model = 'codestral-latest',
          api_key = 'CODESTRAL_API_KEY',
          end_point = 'https://api.mistral.ai/v1/fim/completions',
          stream = false,
        },
        openai_fim_compatible = {
          api_key = 'TERM', -- any set env var; ollama needs no auth
          name = 'Ollama',
          end_point = 'http://localhost:11434/v1/completions',
          model = 'codegemma:7b',
          optional = {
            max_tokens = 256,
          },
        },
      },
    })

    -- :MinuetProvider <name> — switch and persist
    vim.api.nvim_create_user_command('MinuetProvider', function(opts)
      local name = opts.args
      local key = resolve_provider(name)
      if not provider_map[name] and not vim.tbl_contains(vim.tbl_values(provider_map), name) then
        vim.notify('Unknown provider: ' .. name, vim.log.levels.ERROR)
        return
      end
      require('minuet').config.provider = key
      write_provider(name)
      vim.notify('Minuet provider: ' .. name, vim.log.levels.INFO)
    end, {
      nargs = 1,
      complete = function()
        return vim.tbl_keys(provider_map)
      end,
    })
  end,
}
