-- AI code completion via MLX, Ollama, Claude, Gemini, or Codestral
-- https://github.com/milanglacier/minuet-ai.nvim
-- Shows inline ghost text; accept with Tab/C-y/C-h, cycle with C-n/C-p.
-- Switch providers with :MinuetProvider <name> (persisted across sessions).
local state_file = vim.fn.stdpath('state') .. '/minuet-provider'

local function mlx_base_url()
  return os.getenv('MLX_API_BASE')
end

local function ollama_available()
  local h = io.popen('curl -sf http://localhost:11434/api/tags 2>/dev/null')
  if not h then return false end
  local out = h:read('*a')
  h:close()
  return out and #out > 10
end

local function default_provider()
  if mlx_base_url() then return 'mlx' end
  if ollama_available() then return 'ollama' end
  if os.getenv('GEMINI_API_KEY') then return 'gemini' end
  if os.getenv('ANTHROPIC_API_KEY') then return 'claude' end
  if os.getenv('CODESTRAL_API_KEY') then return 'codestral' end
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
  mlx = 'openai_compatible',
  ollama = 'openai_compatible',
}

local function resolve_provider(name)
  return provider_map[name] or name
end

local openai_compatible_presets = {
  mlx = {
    api_key = 'TERM',
    name = 'MLX',
    end_point = (mlx_base_url() or '') .. '/v1/chat/completions',
    model = 'mlx-community/gemma-4-26b-a4b-it-4bit',
    stream = true,
    optional = { max_tokens = 100, thinking = { type = 'disabled' } },
  },
  ollama = {
    api_key = 'TERM',
    name = 'Ollama',
    end_point = 'http://localhost:11434/v1/chat/completions',
    model = 'codegemma:7b',
    stream = true,
    optional = { max_tokens = 100 },
  },
}

local function apply_openai_preset(name)
  local preset = openai_compatible_presets[name]
  if not preset then return end
  local cfg = require('minuet').config.provider_options.openai_compatible
  for k, v in pairs(preset) do
    cfg[k] = v
  end
end

return {
  "milanglacier/minuet-ai.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },

  config = function()
    local initial = read_provider()

    if not initial then
      vim.api.nvim_create_user_command('MinuetProvider', function(opts)
        vim.notify('No AI provider available — set an API key or start a local server', vim.log.levels.WARN)
      end, { nargs = 1, complete = function() return vim.tbl_keys(provider_map) end })
      return
    end

    require('minuet').setup({
      provider = resolve_provider(initial),
      notify = 'warn',
      request_timeout = 4,
      n_completions = 3,
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
          max_tokens = 100,
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
        openai_compatible = openai_compatible_presets[initial] or openai_compatible_presets.ollama,
      },
    })

    -- :MinuetProvider <name> — switch and persist
    vim.api.nvim_create_user_command('MinuetProvider', function(opts)
      local name = opts.args
      if not provider_map[name] then
        vim.notify('Unknown provider: ' .. name, vim.log.levels.ERROR)
        return
      end
      require('minuet').config.provider = resolve_provider(name)
      apply_openai_preset(name)
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
