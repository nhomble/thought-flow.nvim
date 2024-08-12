# thought flow (plugin)

draught down some notes (with context) that don't belong as actual `TODOs` in your VCS.

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
- `D` to demove the thought
