local wx = require("wx")
local icons = require("lib.icons")
local binprint = require("lib.binprint")

local data_tree = {}

local cbs = {}

local ICONS = {
   "Boolean",
   "Byte",
   "ClassInstance",
   "ClassInstance2",
   "Custom",
   "Float",
   "Int",
   "Int64",
   "Nil",
   "Object",
   "Object2",
   "Reference",
   "Short",
   "String",
   "Table",
   "TableWithMeta",
}
local ICON_IDS = fun.iter(ICONS):enumerate():map(function(i, k) return k, i - 1 end):to_map()


local function build_item(tree, key, val, visited, parent_id)
   local t = val[1]

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
   extra_data.type = t
   extra_data.key = key
   extra_data.value = val

   visited.extra[item_id:GetValue()] = extra_data

   return item_id
end

local leaf = function(icon)
   return function(tree, parent_id, key, val)
      return tree:AppendItem(parent_id, binprint.print_kv(key, val), ICON_IDS[icon])
   end
end

-- BYTE = 0-127
cbs.byte = leaf("Byte")

-- SHORT = 128-191
cbs.short = leaf("Short")

-- NIL = 202
cbs[202] = leaf("Nil")

-- FLOAT = 203
cbs[203] = leaf("Float")

-- TRUE = 204
cbs[204] = leaf("Boolean")

-- FALSE = 205
cbs[205] = leaf("Boolean")

-- STRING = 206
cbs[206] = leaf("String")

-- TABLE = 207
cbs[207] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s (%d elements)"):format(binprint.print_key(key), #val[2]), ICON_IDS.Table)
   local extra = { data = val[2] }

   for _, kv in ipairs(val[2]) do
      local k, v = kv[1], kv[2]
      if type(k) == "number" then
         k = { 212, k }
      end
      -- if is_simple_key(k) then
         build_item(tree, k, v, visited, new_id)
      -- else
      -- end
   end

   return new_id, extra
end

-- REFERENCE = 208
cbs[208] = function(tree, parent_id, key, val, visited)
   local ref = val[2]
   local deref = visited[ref]
   local extra = { deref = deref }
   local item_id = tree:AppendItem(parent_id, ("%s: Reference (%d)"):format(binprint.print_key(key), tostring(val[2])), ICON_IDS.Reference)
   return item_id, extra
end

-- CONSTRUCTOR = 209
cbs[209] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s: Custom (%d arguments)"):format(binprint.print_key(key), #val[2]), ICON_IDS.Custom)

   local extra = { args = val.args }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id)
   end

   return new_id, extra
end

-- FUNCTION = 210
cbs[210] = leaf

-- RESOURCE = 211
cbs[211] = leaf

-- INT64 = 212
cbs[212] = leaf

-- TABLE WITH META = 213
cbs[213] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s (%d elements)"):format(binprint.print_key(key), #val[2]), ICON_IDS.TableWithMeta)
   local extra = { data = val[2] }

   for _, kv in ipairs(val[2]) do
      local k, v = kv[1], kv[2]
      -- if is_simple_key(k) then
         build_item(tree, k, v, visited, new_id)
      -- else
      -- end
   end

   return new_id, extra
end

-- OBJECT/MAP OBJECT = 214
cbs[214] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s = <object (%s)>"):format(binprint.print_key(key), val[2]), ICON_IDS.OBJECT)

   local extra = { args = val.args }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id)
   end

   return new_id, extra
end

-- CLASS OBJECT = 215
cbs[215] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s = <serial_id=%s>"):format(binprint.print_key(key), binprint.print_val(val[2])), ICON_IDS.ClassInstance)

   local extra = { data = {} }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id)
   end

   return new_id, extra
end

function data_tree.create(panel, vals, visited)
   local tree = wx.wxTreeCtrl(panel, wx.wxID_ANY,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER)

   local imglist = wx.wxImageList(16, 16, true, 2)
   for i, icon in ipairs(ICONS) do
      imglist:Add(icons[icon])
   end
   tree:AssignImageList(imglist)

   local root = tree:AddRoot(wxT("Save Data"), 0)

   visited.extra = {}

   for _, val in ipairs(vals) do
      local item_id = build_item(tree, { 206, "Root" }, val, visited, root)
      tree:Expand(item_id)
   end

   tree:Expand(root)

   tree.vals = vals
   tree.visited = visited

   return tree
end

return data_tree
