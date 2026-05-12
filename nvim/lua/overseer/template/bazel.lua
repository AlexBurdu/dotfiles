-- Bazel templates for :OverseerRun picker.
-- For direct keybindings (<leader>bb / <leader>bt) see lua/keymap/build.lua.

local build = require("util.build")

return {
  generator = function(opts, cb)
    local workspace_root = build.find_bazel_root(opts.dir)
    if not workspace_root then
      cb({})
      return
    end

    cb({
      {
        name = "bazel build",
        desc = "Build a Bazel target",
        params = {
          target = {
            type = "string",
            desc = "Target label (e.g. //foo/bar:baz)",
            default = "",
          },
        },
        builder = function(params)
          return {
            cmd = { "bazel", "build", params.target },
            cwd = workspace_root,
          }
        end,
      },
      {
        name = "bazel test",
        desc = "Test a Bazel target",
        params = {
          target = {
            type = "string",
            desc = "Target label (e.g. //foo/bar:baz)",
            default = "",
          },
        },
        builder = function(params)
          return {
            cmd = { "bazel", "test", params.target, "--test_output=streamed" },
            cwd = workspace_root,
          }
        end,
      },
    })
  end,
}
