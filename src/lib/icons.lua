local wx = require("wx")

local icons = {}

local function index(_, id)
   local icon = icons[id]
   if icon then
      return icon
   end

   local filepath = ("resources/icons/%s.png"):format(id)

   if not wx.wxFile.Exists(filepath) then
      error("Could not find icon " .. filepath)
   end

   icon = wx.wxBitmap(wx.wxImage(filepath):Scale(16, 16, wx.wxIMAGE_QUALITY_NEAREST))
   icons[id] = icon

   return icon
end

return setmetatable({}, {
  __index = index
})
