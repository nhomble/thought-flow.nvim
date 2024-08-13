# thought flow (plugin)

draught down some notes (with context) that don't belong as actual `TODOs` in your VCS.

## Installation

[lazy](https://github.com/folke/lazy.nvim)

```lua
{
  "nhomble/thought-flow.nvim"
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

### Menu Actions

- `<CR>` to open file/line number where thought was captured
- `D` to remove the thought

## Configuration

The options are available in [config.lua](./lua/thought-flow/config.lua). You can override the configuration there with `require("thought-flow").setup({})`.
