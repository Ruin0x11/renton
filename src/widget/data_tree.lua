local wx = require("wx")

local data_tree = {}

local cbs = {}

local ICON_FOLDER = 0
local ICON_FILE = 1

local function build_item(tree, key, val, visited, parent_id, extra)
   local t = val[1]
   print("T: " .. t)

   local item_id, extra_data
   local ty

   if t < 128 then
      ty = "byte"
   elseif t < 192 then
      ty = "short"
   else
      ty = t
   end

   item_id, extra_data = cbs[ty](tree, parent_id, key, val, visited)

   extra_data = extra_data or {}
   extra_data.type = ty

   extra[item_id:GetValue()] = extra_data

   return item_id
end

local function is_simple_key(val)
   local t = val[1]
   return t == 202 or t == 203 or t == 204 or t == 205 or t == 206 or t == 210
end

local leaf = function(tree, parent_id, key, val)
   return tree:AppendItem(parent_id, ("%s: %s"):format(tostring(key[2]), tostring(val[2])), ICON_FILE)
end

-- BYTE = 0-127
cbs.byte = leaf

-- SHORT = 128-191
cbs.short = leaf

-- NIL = 202
cbs[202] = leaf

-- FLOAT = 203
cbs[203] = leaf

-- TRUE = 204
cbs[204] = leaf

-- FALSE = 205
cbs[205] = leaf

-- STRING = 206
cbs[206] = leaf

-- TABLE = 207
cbs[207] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, key .. " (table)", ICON_FOLDER)
   local extra = {}

   for _, kv in ipairs(val.kvs) do
      local k, v = kv[1], kv[2]
      print(inspect(k))
      print(inspect(v))

      if is_simple_key(k) then
         build_item(tree, new_id, k, v, visited)
      else
      end
      extra[k] = v
   end

   return new_id, extra
end

-- REFERENCE = 208
cbs[208] = function(tree, parent_id, key, val, visited)
   return tree:AppendItem(parent_id, ("%s: Reference (%d)"):format(tostring(key), tostring(val)), ICON_FILE)
end

-- CONSTRUCTOR = 209
cbs[209] = function()
end

-- FUNCTION = 210
cbs[210] = leaf

-- RESOURCE = 211
cbs[211] = leaf

-- INT64 = 212
cbs[212] = leaf

-- TABLE WITH META = 213
cbs[213] = function()
end

-- OBJECT/MAP OBJECT = 214
cbs[214] = function()
end

-- CLASS OBJECT = 215
cbs[215] = function()
end

function data_tree.create(panel, vals, visited)
   local tree = wx.wxTreeCtrl(panel, wx.wxID_ANY,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER)

   local imglist = wx.wxImageList(16, 16, true, 2)
   imglist:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_OTHER, wx.wxSize(16,16)))
   imglist:Add(wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_OTHER, wx.wxSize(16,16)))
   tree:AssignImageList(imglist)

   local root = tree:AddRoot(wxT("Save Data"), 0)
   local extra = {}

   for _, val in ipairs(vals) do
      build_item(tree, { 206, "Root" }, val, visited, root, extra)
   end

   tree:Expand(root)

   return tree, extra
end

return data_tree
