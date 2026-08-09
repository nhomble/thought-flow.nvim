# thought flow (plugin)

draught down some notes (with context) that don't belong as actual `TODOs` in your VCS.

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim)

Review runs as a `neo-tree.nvim` source, so it's a hard dependency alongside
`nui.nvim` (used by capture and the help popup) — both declared under
`dependencies` below, with `neo-tree.nvim` registering the `"thought-flow"`
source via its `opts`.

**Minimal setup (uses defaults):**
```lua
{
  "nhomble/thought-flow.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "nvim-neo-tree/neo-tree.nvim",
      opts = function(_, opts)
        table.insert(opts.sources, "thought-flow")
      end,
    },
  },
  opts = {}
}
```

**With custom configuration:**
```lua
{
  "nhomble/thought-flow.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "nvim-neo-tree/neo-tree.nvim",
      opts = function(_, opts)
        table.insert(opts.sources, "thought-flow")
      end,
    },
  },
  config = function()
    require("thought-flow").setup({
      -- your custom config here
      annotations = {
        text = "▪",
        color = "#808080"
      }
    })
  end
}
```

## Usage

Commands: `:ThoughtFlowCapture`, `:ThoughtFlowReview` (toggle the neo-tree
window), `:ThoughtFlowRemoveLine`, `:ThoughtFlowClear`, `:ThoughtFlowNext` /
`:ThoughtFlowPrev` (jump between thoughts in the current file, no
wraparound), `:ThoughtFlowShow` (reveal this line's thought(s) in the tree),
`:ThoughtFlowExport` (copy all thoughts as markdown to the clipboard, with
a preview split), `:ThoughtFlowHelp` (command popup). Bind whatever you like:

```lua
vim.keymap.set('n', '<leader>tc', ':ThoughtFlowCapture<CR>', { desc = "Capture thought" })
vim.keymap.set('n', '<leader>tv', ':ThoughtFlowReview<CR>', { desc = "Review thoughts" })
vim.keymap.set('n', '<leader>td', ':ThoughtFlowRemoveLine<CR>', { desc = "Delete thought" })
vim.keymap.set('n', '<leader>tD', ':ThoughtFlowClear<CR>', { desc = "Clear all thoughts" })
vim.keymap.set('n', ']t', ':ThoughtFlowNext<CR>', { desc = "Next thought in file" })
vim.keymap.set('n', '[t', ':ThoughtFlowPrev<CR>', { desc = "Previous thought in file" })
vim.keymap.set('n', '<leader>ts', ':ThoughtFlowShow<CR>', { desc = "Show thought on this line" })
vim.keymap.set('n', '<leader>t?', ':ThoughtFlowHelp<CR>', { desc = "Thought-flow help" })
```

Export groups by file/line, each with a 3-line blockquote of context around
the annotated line, a `thoughts:` bullet list (multiple thoughts on one line
become multiple bullets), and `---` between entries.

In the neo-tree window: `<CR>`/`o` on a thought jumps to its file/line and
opens an editable scratch buffer at the bottom (`:w` saves, `q` closes
without saving); on a file node it expands/collapses. `<Space>` previews
the full text, `d` deletes. Orphaned thoughts (file/line gone) show `[!]`
and can't be navigated to. A line with multiple thoughts gets one marker
suffixed `xN`.

## Status Line Integration

You can display your thought count in your status line. The plugin provides a `statistics()` function that returns thought statistics.

**Lualine:**
```lua
require('lualine').setup({
  sections = {
    lualine_x = {
      function()
        local stats = require('thought-flow').statistics()
        local count = stats.global_count
        return count > 0 and ("▪ " .. count) or ""
      end,
      color = { fg = '#808080' },
    }
  }
})
```

**Heirline (AstroNvim):**
```lua
-- In lua/plugins/heirline.lua
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require("astroui.status")
    opts.statusline[#opts.statusline + 1] = status.component.builder({
      provider = function()
        local stats = require('thought-flow').statistics()
        local count = stats.global_count
        return count > 0 and ("▪ " .. count) or ""
      end,
      hl = { fg = "gray" },
    })
    return opts
  end,
}
```

**Native statusline:**
```lua
vim.o.statusline = vim.o.statusline .. '%{luaeval("(function() local s = require(\\'thought-flow\\').statistics(); return s.global_count > 0 and (\\'▪ \\' .. s.global_count) or \\'\\'  end)()")}'
```

The `statistics()` function returns a table with:
- `global_count` - Total number of thoughts across all files

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
    max_thought_display_width = 50,  -- Truncate long thoughts in menu
  },
  notifications = {
    error = function(msg)
      vim.notify(msg, vim.log.levels.ERROR, { title = "thought-flow" })
    end,
  },
  annotations = {
    text = "▪",
    namespace = "thought-flow-namespace",
    color = "#808080"
  },
  orphaned = {
    indicator = "[!] ",  -- Prefix for orphaned thoughts
    color = "#ff0000"    -- Color for orphaned indicator (future use)
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
