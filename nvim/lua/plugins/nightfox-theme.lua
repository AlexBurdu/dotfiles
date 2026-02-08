-- Theme: Nightfox
return {
  "EdenEast/nightfox.nvim",

  config = function()
    -- To easily customize the theme, copy the below in a new .lua file
    -- or comment the wrapping functions for the code
    -- Run :NightfoxInteractive and start modifying
    local black = "#000000"
    local blue = "#2985FF"
    local magenta = "#E554BA"
    local yellow = "#FFCC00"

    require('nightfox').setup({
      palettes =  {
        -- Examples:
        -- https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/palette/carbonfox.lua
        -- https://github.com/EdenEast/nightfox.nvim/blob/d3e8b1acc095baf57af81bb5e89fe7c4359eb619/lua/nightfox/palette/dayfox.lua
        carbonfox = {
          bg1 = black, -- Black background
          blue = blue,
          magenta = magenta,
        },
        dayfox = {
          blue = "#005f87",
          magenta = "#af005f",
          bg0 = "#e0e1e5", -- Grey Status Bar
          bg1 = "#f0f1f7", -- Light Grey background
          bg2 = "#ff2600", -- White background
          bg3 = "#e0e1e5", -- Grey cursorline
          fg2 = "#000000", -- Black status bar foreground
          fg3 = "#9a9ea5", -- Light Grey line number

          sel0 = "#e0e1e5", -- Grey Selection background
          sel1 = "#e0e1e5", -- Grey Selection background
        },
      },
      specs = {
        -- Examples:
        -- https://github.com/EdenEast/nightfox.nvim/blob/d3e8b1acc095baf57af81bb5e89fe7c4359eb619/lua/nightfox/group/editor.lua
        -- https://github.com/EdenEast/nightfox.nvim/blob/d3e8b1acc095baf57af81bb5e89fe7c4359eb619/lua/nightfox/group/syntax.lua
        carbonfox = {
          syntax = {
            bracket     = "white",           -- Brackets and Punctuation
            builtin0    = magenta,       -- Builtin variable
            builtin1    = "white",    -- Builtin type
            --        builtin2    = pal.orange.bright,  -- Builtin const
            --        builtin3    = pal.red.bright,     -- Not used
            --        comment     = pal.comment,        -- Comment
            conditional = "white", -- Conditional and loop
            const       = magenta,  -- Constants, imports and booleans
            --        dep         = spec.fg3,           -- Deprecated
            field       = blue,      -- Field
            func        = "white",    -- Functions and Titles
            ident       = blue,      -- Identifiers
            keyword     = magenta,   -- Keywords
            number      = "orange",    -- Numbers
            operator    = yellow,           -- Operators
            preproc     = blue,    -- PreProc
            --        regex       = pal.yellow.bright,  -- Regex
            statement   = magenta,   -- Statements
            --        string      = pal.green.base,     -- Strings
            type        = magenta,    -- Types
            variable    = "white",     -- Variables
          },
        },
        dayfox = {
          syntax = {
            keyword     = "#be1ddb",   -- Keywords
            ident       = blue,      -- Identifiers
          }
        }
      },
      groups = {
        -- Example: https://github.com/EdenEast/nightfox.nvim/blob/d3e8b1acc095baf57af81bb5e89fe7c4359eb619/lua/nightfox/group/editor.lua
        carbonfox = {
          -- Dropbar menu selection
          DropBarMenuCurrentContext = { bg = "#3d3d3d" },
          DropBarMenuHoverEntry = { bg = "#3d3d3d" },
        },
        dayfox = {
          -- Fix notification/message colors for accessibility
          WarningMsg = { fg = "#8a5700", bg = "#fff3cd" },
          ErrorMsg = { fg = "#842029", bg = "#f8d7da" },
          ModeMsg = { fg = "#0f5132", bg = "#d1e7dd" },
          -- Dropbar menu selection
          DropBarMenuCurrentContext = { bg = "#d0d0d0" },
          DropBarMenuHoverEntry = { bg = "#d0d0d0" },
        }
      }

    })
  end
}
