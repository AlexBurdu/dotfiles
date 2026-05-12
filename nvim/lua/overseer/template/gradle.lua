-- Gradle templates for :OverseerRun picker.
-- For direct keybindings (<leader>bB / <leader>bT) see lua/keymap/build.lua.

local build = require("util.build")

return {
  generator = function(opts, cb)
    local gradle_root = build.find_gradle_root(opts.dir)
    if not gradle_root then
      cb({})
      return
    end

    local wrapper = build.gradlew(gradle_root)

    cb({
      {
        name = "gradle build",
        desc = "Build current Gradle module",
        params = {
          module = {
            type = "string",
            desc = "Gradle module (e.g. :foo:bar, empty = root)",
            default = "",
          },
        },
        builder = function(params)
          return {
            cmd = { wrapper, params.module .. ":build", "-x", "test" },
            cwd = gradle_root,
          }
        end,
      },
      {
        name = "gradle test",
        desc = "Test current Gradle module",
        params = {
          module = {
            type = "string",
            desc = "Gradle module (e.g. :foo:bar, empty = root)",
            default = "",
          },
        },
        builder = function(params)
          return {
            cmd = { wrapper, params.module .. ":test" },
            cwd = gradle_root,
          }
        end,
      },
      {
        name = "gradle sync",
        desc = "Refresh Gradle dependencies",
        builder = function()
          return {
            cmd = { wrapper, "--refresh-dependencies" },
            cwd = gradle_root,
          }
        end,
      },
    })
  end,
}
