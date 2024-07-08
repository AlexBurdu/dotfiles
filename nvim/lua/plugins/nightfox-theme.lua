return {
  "EdenEast/nightfox.nvim",

  config = function()
    -- To easily customize the theme, copy the below in a new .lua file
    -- Run :NightfoxInteractive and start modifying
local black = "#000000"
local blue = "#2985FF"
local magenta = "#E554BA"
local yellow = "#FFCC00"

require('nightfox').setup({
  palettes =  {
    carbonfox = {
      bg1 = black, -- Black background
      blue = blue,
      magenta = magenta,
    },
  },
  specs = {
    carbonfox = {
      -- https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/palette/carbonfox.lua
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
    }
  }

})
  end
}
