-- Kotlin and Java: language servers, debugger, Android attach.
--
-- Optional: linked only where machine.sh has `enable jvm` (see
-- nvim/manifest.sh). Each spec below extends a common one beside it,
-- which is why none of it lives in those.
--
-- LSP (extends plugins/lsp.lua through its opts):
--   kotlin_lsp     Hessesian/kotlin-lsp, fast, no JVM; starts on its own
--   kotlin_lsp_jb  JetBrains kotlin-lsp, full type-checking, on demand
--   <Leader>bJ     start / stop kotlin_lsp_jb
--
-- DAP (extends plugins/dap.lua):
--   kotlin-debug-adapter, built from a fork by lazy.nvim, used by
--   <Leader>dt/dT for JVM tests and by <Leader>da, which attaches to a
--   running Android app over ADB.
return {
  {
    "neovim/nvim-lspconfig",
    -- Maps, which lazy.nvim merges into lsp.lua's opts; it loads this
    -- file first, so an opts function would find them not there yet.
    opts = {
      ensure_installed = { kotlin_lsp = true },
      servers = {
        kotlin = function(capabilities)
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")

          -- Hessesian/kotlin-lsp: fast Rust-based LSP (no JVM), replaces JetBrains kotlin_lsp
          configs.kotlin_lsp = {
            default_config = {
              cmd       = { vim.fn.expand("~/.cargo/bin/kotlin-lsp") },
              filetypes = { "kotlin", "java", "swift" },
              root_dir  = lspconfig.util.root_pattern(
                "build.gradle", "build.gradle.kts", "pom.xml", "settings.gradle", "Package.swift", ".git"
              ),
              settings  = {},
            },
          }
          lspconfig.kotlin_lsp.setup { capabilities = capabilities }

          -- JetBrains kotlin_lsp: full type-checking, started on demand via <leader>bJ
          configs.kotlin_lsp_jb = {
            default_config = {
              cmd       = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp" },
              filetypes = { "kotlin", "java" },
              root_dir  = lspconfig.util.root_pattern(
                "build.gradle", "build.gradle.kts", "pom.xml", "settings.gradle", ".git"
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

          vim.keymap.set("n", "<leader>bJ", function()
            local clients = vim.lsp.get_clients({ bufnr = 0, name = "kotlin_lsp_jb" })
            if #clients > 0 then
              for _, c in ipairs(clients) do c.stop() end
              vim.notify("JetBrains Kotlin LSP stopped", vim.log.levels.INFO)
            elseif lspconfig.kotlin_lsp_jb.manager then
              lspconfig.kotlin_lsp_jb.manager:try_add(vim.api.nvim_get_current_buf())
              vim.notify("JetBrains Kotlin LSP starting…", vim.log.levels.INFO)
            end
          end, { desc = "Toggle JetBrains Kotlin LSP (full type-checking)" })
        end,
      },
    },
  },

  {
    "AlexBurdu/kotlin-debug-adapter",
    branch = "custom",
    build = "./build.sh",
    dependencies = { "mfussenegger/nvim-dap" },
    lazy = false,

    config = function()
      local dap = require("dap")
      local dap_attach = require("util.dap_attach")

      -- Fix KDA source path resolution for non-standard layouts (KMP, deep nesting)
      require("util.dap_kotlin_proxy").install_interceptor()

      -- ── Kotlin/Java adapter (JDWP) ─────────────────────────────────────────
      local kda_dir = vim.fn.stdpath("data") .. "/lazy/kotlin-debug-adapter"
      dap.adapters.kotlin = {
        type = "executable",
        command = kda_dir .. "/adapter/build/install/adapter/bin/kotlin-debug-adapter",
        options = {
          auto_continue_if_many_stopped = false,
          initialize_timeout_sec = 30,
          disconnect_timeout_sec = 0,
        },
      }

      local android_attach_config = {
        type = "kotlin",
        name = "Attach to Android app",
        request = "attach",
        hostName = "localhost",
        port = 5005,
        timeout = 10000,
        projectRoot = "${workspaceFolder}",
      }

      dap.configurations.kotlin = { android_attach_config }
      dap.configurations.java = { android_attach_config }

      local is_mac = vim.fn.has("mac") == 1
      local tool_hints = {
        ["adb"] = is_mac
          and "brew install android-platform-tools"
          or "sudo apt install android-tools-adb",
      }

      -- ── Android attach flow ──────────────────────────────────────────────────

      local function find_project_root()
        local markers = { "settings.gradle.kts", "settings.gradle", "gradlew", ".git" }
        local path = vim.fn.expand("%:p:h")
        while path ~= "/" do
          for _, marker in ipairs(markers) do
            if vim.fn.filereadable(path .. "/" .. marker) == 1
              or vim.fn.isdirectory(path .. "/" .. marker) == 1 then
              return path
            end
          end
          path = vim.fn.fnamemodify(path, ":h")
        end
        return vim.fn.getcwd()
      end

      -- Detect Android package names: gradle applicationId + LAUNCHER manifests.
      local function detect_packages(callback)
        local found = {}
        local seen = {}
        local root = find_project_root()
        local pending = 2

        local function on_done()
          pending = pending - 1
          if pending == 0 then callback(found) end
        end

        -- 1. Search gradle files for applicationId
        vim.fn.jobstart(
          { "grep", "-r", "--include=*.gradle", "--include=*.gradle.kts",
            "--exclude-dir=build", "--exclude-dir=.gradle", "-h", "applicationId", root },
          {
            stdout_buffered = true,
            on_stdout = function(_, data)
              for _, line in ipairs(data) do
                local id = line:match('applicationId%s*[=%(]?%s*"([^"]+)"')
                  or line:match("applicationId%s*[=%(]?%s*'([^']+)'")
                if id and not seen[id] then
                  seen[id] = true
                  table.insert(found, id)
                end
              end
            end,
            on_exit = function() on_done() end,
          }
        )

        -- 2. Find manifests with LAUNCHER intent (actual apps), extract package
        vim.fn.jobstart(
          { "grep", "-rl", "--include=AndroidManifest.xml", "--exclude-dir=build",
            "--exclude-dir=.gradle", "android.intent.category.LAUNCHER", root },
          {
            stdout_buffered = true,
            on_stdout = function(_, data)
              for _, file in ipairs(data) do
                if file ~= "" then
                  local content = vim.fn.readfile(file)
                  for _, line in ipairs(content) do
                    local pkg = line:match('package%s*=%s*"([^"]+)"')
                    if pkg and not seen[pkg] then
                      seen[pkg] = true
                      table.insert(found, pkg)
                    end
                  end
                end
              end
            end,
            on_exit = function() on_done() end,
          }
        )
      end

      local recent_packages = {}

      local function do_attach_kotlin(package)
        -- Move to front of recents
        for i, p in ipairs(recent_packages) do
          if p == package then table.remove(recent_packages, i) break end
        end
        table.insert(recent_packages, 1, package)

        local fidget = require("fidget")
        local handle = fidget.progress.handle.create({
          title = "Connecting to " .. package .. "...",
          lsp_client = { name = "dap" },
        })

        vim.fn.jobstart({ "adb", "forward", "--remove-all" }, {
          on_exit = function()
            vim.fn.jobstart({ "adb", "shell", "pidof", package }, {
              stdout_buffered = true,
              on_stdout = function(_, data)
                local pid = (data[1] or ""):gsub("%s+", "")
                if pid == "" then
                  vim.schedule(function()
                    handle:finish()
                    vim.notify("No running process for " .. package, vim.log.levels.ERROR)
                  end)
                  return
                end

                vim.fn.jobstart({ "adb", "forward", "tcp:5005", "jdwp:" .. pid }, {
                  on_exit = function()
                    vim.defer_fn(function()
                      handle:finish()
                      vim.notify("Forwarding port 5005 → JDWP pid " .. pid)
                      dap.run({
                        type = "kotlin",
                        name = "Attach to " .. package,
                        request = "attach",
                        hostName = "localhost",
                        port = 5005,
                        timeout = 10000,
                        projectRoot = find_project_root(),
                      })
                    end, 1000)
                  end,
                })
              end,
            })
          end,
        })
      end

      local function telescope_pick(items, prompt, on_select)
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers.new({}, {
          prompt_title = prompt,
          finder = finders.new_table({ results = items }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(bufnr)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(bufnr)
              if selection then on_select(selection[1]) end
            end)
            return true
          end,
        }):find()
      end

      local function show_full_picker()
        local fidget = require("fidget")
        local handle = fidget.progress.handle.create({
          title = "Searching for packages...",
          lsp_client = { name = "dap" },
        })

        detect_packages(vim.schedule_wrap(function(packages)
          handle:finish()
          if #packages == 0 then
            local package = vim.fn.input("Package: ", "")
            if package ~= "" then do_attach_kotlin(package) end
          else
            telescope_pick(packages, "Select package", do_attach_kotlin)
          end
        end))
      end

      local function attach_kotlin()
        -- Build list: recents first, then search option
        local items = {}
        for _, p in ipairs(recent_packages) do
          table.insert(items, p)
        end

        if #items == 0 then
          show_full_picker()
          return
        end

        table.insert(items, "Search project...")
        telescope_pick(items, "Select package", function(choice)
          if choice == "Search project..." then
            show_full_picker()
          else
            do_attach_kotlin(choice)
          end
        end)
      end

      dap_attach.register({ "kotlin", "java" }, function()
        dap_attach.check_tools({ "kotlin-debug-adapter", "adb" }, attach_kotlin,
          { hints = tool_hints })
      end)
    end,
  },
}
