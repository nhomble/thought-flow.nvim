# thought flow (plugin)

draught down some notes (with context) that don't belong as actual `TODOs` in your VCS.

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim)

**Minimal setup (uses defaults):**
```lua
{
  "nhomble/thought-flow.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {}
}
```

**With custom configuration:**
```lua
{
  "nhomble/thought-flow.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  config = function()
    require("thought-flow").setup({
      -- your custom config here
      annotations = {
        text = "💭",
        color = "#00bfff"
      }
    })
  end
}
```

## API

**capture**

capture your thought

```lua
require("thought-flow").capture()
```

**review**

review your thoughts

```lua
require("thought-flow").review()
```

**clear**

clear your thoughts

```lua
require("thought-flow").clear()
```

### Menu Actions

- `<CR>` to open file/line number where thought was captured
- `D` to remove the thought

## Configuration

The plugin must be configured by calling `setup()` (shown in Installation above). Available options with their defaults:

```lua
require("thought-flow").setup({
  path = vim.fn.stdpath("data") .. "/thought-flow.json",
  ui = {
    prompt = "> ",
  },
  notifications = {
    error = function(msg)
      vim.notify(msg, vim.log.levels.ERROR, { title = "thought-flow" })
    end,
  },
  annotations = {
    text = "💭",
    namespace = "thought-flow-namespace",
    color = "#00bfff"
  },
  json = {
    decode = function(s) return vim.json.decode(s) end,
    encode = function(o) return vim.json.encode(o) end,
  },
  autocmd = {
    group = "thought-flow",
    pattern = "*",
  },
})
```

See [config.lua](./lua/thought-flow/config.lua) for more details.
