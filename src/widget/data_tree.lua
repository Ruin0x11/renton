local wx = require("wx")
local icons = require("lib.icons")

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

-- Apostrophizes the string if it has quotes, but not aphostrophes
-- Otherwise, it returns a regular quoted string
local function smart_quote(str)
   if str:match('"') and not str:match("'") then
      return "'" .. str .. "'"
   end
   return '"' .. str:gsub('"', '\\"') .. '"'
end

-- \a => '\\a', \0 => '\\0', 31 => '\31'
local short_control_char_escapes = {
   ["\a"] = "\\a",  ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r",  ["\t"] = "\\t", ["\v"] = "\\v"
}
local long_control_char_escapes = {} -- \a => nil, \0 => \000, 31 => \031
for i=0, 31 do
   local ch = string.char(i)
   if not short_control_char_escapes[ch] then
      short_control_char_escapes[ch] = "\\"..i
      long_control_char_escapes[ch]  = string.format("\\%03d", i)
   end
end

local function escape(str)
   return (str:gsub("\\", "\\\\")
              :gsub("(%c)%f[0-9]", long_control_char_escapes)
              :gsub("%c", short_control_char_escapes))
end

local function is_identifier(val)
   return val[1] == 206 and val[2]:match("^[_%a][_%a%d]*$")
end

local function is_simple_key(val)
   local t = val[1]
   return t < 192 or t == 202 or t == 203 or t == 204 or t == 205 or t == 206 or t == 210 or t == 212
end

local function print_val(val)
   local t = val[1]

   if t == 206 then
      return smart_quote(escape(val[2]))
   elseif is_simple_key(val) then
      return tostring(val[2])
   end

   return "X" .. inspect(val):sub(1, 30)
end

local function print_key(key)
   if is_identifier(key) then
      return key[2]
   end

   return ("[%s]"):format(print_val(key))
end

local function print_kv(key, value, name)
   if name then
      name = name .. " "
   else
      name = ""
   end
   return ("%s = %s%s"):format(print_key(key), name, print_val(value))
end

local function build_item(tree, key, val, visited, parent_id, extra)
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
   extra_data.type = ty

   extra[item_id:GetValue()] = extra_data

   return item_id
end

local leaf = function(icon)
   return function(tree, parent_id, key, val)
      return tree:AppendItem(parent_id, print_kv(key, val), ICON_IDS[icon])
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
   local new_id = tree:AppendItem(parent_id, ("%s (%d elements)"):format(print_key(key), #val[2]), ICON_IDS.Table)
   local extra = { data = {} }

   for _, kv in ipairs(val[2]) do
      local k, v = kv[1], kv[2]
      if type(k) == "number" then
         k = { 212, k }
      end
      if is_simple_key(k) then
         build_item(tree, k, v, visited, new_id, extra)
      else
      end
      extra.data[k] = v
   end

   return new_id, extra
end

-- REFERENCE = 208
cbs[208] = function(tree, parent_id, key, val, visited)
   return tree:AppendItem(parent_id, ("%s: Reference (%d)"):format(print_key(key), tostring(val[2])), ICON_IDS.Reference)
end

-- CONSTRUCTOR = 209
cbs[209] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("Custom (%d arguments)"):format(#val[2]), ICON_IDS.Custom)

   local extra = { data = {} }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id, extra)
      extra.data[i] = v
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
   local new_id = tree:AppendItem(parent_id, ("%s (%d elements)"):format(print_key(key), #val[2]), ICON_IDS.TableWithMeta)
   local extra = { data = {} }

   for _, kv in ipairs(val[2]) do
      local k, v = kv[1], kv[2]
      if is_simple_key(k) then
         build_item(tree, k, v, visited, new_id, extra)
      else
      end
      extra.data[k] = v
   end

   return new_id, extra
end

-- OBJECT/MAP OBJECT = 214
cbs[214] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s = <object (%s)>"):format(print_key(key), val[2]), ICON_IDS.OBJECT)

   local extra = { data = {} }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id, extra)
      extra.data[i] = v
   end

   return new_id, extra
end

-- CLASS OBJECT = 215
cbs[215] = function(tree, parent_id, key, val, visited)
   local new_id = tree:AppendItem(parent_id, ("%s = <(%s)>"):format(print_key(key), tostring(val[2])), ICON_IDS.ClassInstance)

   local extra = { data = {} }

   for i, v in ipairs(val.args) do
      build_item(tree, { 212, i }, v, visited, new_id, extra)
      extra.data[i] = v
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
   local extra = {}

   for _, val in ipairs(vals) do
      build_item(tree, { 206, "Root" }, val, visited, root, extra)
   end

   tree:Expand(root)

   tree.extra = extra
   tree.vals = vals
   tree.visited = visited

   return tree
end

return data_tree
