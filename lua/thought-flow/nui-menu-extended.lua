local Menu = require("nui.menu")
local ExtendedMenu = Menu:extend("ExtendedMenu")

function ExtendedMenu:init(popup_options, options)
  self.on_delete = function()
    local item = self.tree:get_node()
    options.on_delete(item)
    self:unmount()
  end
  ExtendedMenu.super.init(self, popup_options, options)
end

function ExtendedMenu:mount()
  self:map("n", "D", self.on_delete, { noremap = true, nowait = true })

  ExtendedMenu.super.mount(self)
end

return ExtendedMenu
