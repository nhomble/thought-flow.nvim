-- Luacheck configuration for Neovim plugin
std = "lua51+luajit"

-- Ignore vim global
globals = {
	"vim",
}

-- Read-only vim global (don't warn about not setting it)
read_globals = {
	"vim",
}

-- Exclude directories
exclude_files = {
}

-- Warnings to ignore
ignore = {
	"212", -- Unused argument
}
