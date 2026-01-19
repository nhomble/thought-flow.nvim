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

## Usage

The plugin provides user commands for easy access:

- `:ThoughtFlowCapture` - Capture a thought at the current cursor position
- `:ThoughtFlowReview` - Review all captured thoughts in a menu
- `:ThoughtFlowRemoveLine` - Remove thought at current cursor line
- `:ThoughtFlowClear` - Clear all thoughts

You can bind these to keymaps in your config:
```lua
vim.keymap.set('n', '<leader>tc', ':ThoughtFlowCapture<CR>', { desc = "Capture thought" })
vim.keymap.set('n', '<leader>tv', ':ThoughtFlowReview<CR>', { desc = "Review thoughts" })
vim.keymap.set('n', '<leader>td', ':ThoughtFlowRemoveLine<CR>', { desc = "Delete thought" })
vim.keymap.set('n', '<leader>tD', ':ThoughtFlowClear<CR>', { desc = "Clear all thoughts" })
```

**Menu Actions (in Review mode):**
- `<Space>` - Show full thought text in popup (supports visual mode, yank, search)
- `<CR>` - Navigate to file/line number where thought was captured
- `D` - Delete the selected thought
- `j`/`k` or arrow keys - Navigate thoughts
- `/` - Search forward through thoughts
- `?` - Search backward through thoughts
- `n` - Jump to next search match
- `N` - Jump to previous search match
- `<Esc>` or `<C-c>` - Close menu

Long thoughts are automatically truncated with "..." in the menu list.

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
