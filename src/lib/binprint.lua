local binprint = {}

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

function binprint.is_identifier(val)
   return val[1] == 206 and val[2]:match("^[_%a][_%a%d]*$")
end

function binprint.is_simple_key(val)
   local t = (type(val) == "number" and val) or val[1]
   return t < 192 or t == 202 or t == 203 or t == 204 or t == 205 or t == 206 or t == 210 or t == 212
end

function binprint.is_numeric(val)
   local t = (type(val) == "number" and val) or val[1]
   return t < 192 or t == 202 or t == 203 or t == 212
end

function binprint.is_boolean(val)
   local t = (type(val) == "number" and val) or val[1]
   return t == 204 or t == 205
end

function binprint.is_string(val)
   local t = (type(val) == "number" and val) or val[1]
   return t == 206
end

function binprint.is_table(val)
   local t = (type(val) == "number" and val) or val[1]
   return t == 207 or t == 213
end

function binprint.is_constructor(val)
   local t = (type(val) == "number" and val) or val[1]
   return t == 214 or t == 215
end

function binprint.print_val(val)
   local t = val[1]

   if t == 206 then
      return smart_quote(escape(val[2]))
   elseif binprint.is_simple_key(val) then
      return tostring(val[2])
   end

   return "X" .. inspect(val):sub(1, 30)
end

function binprint.print_key(key)
   local ident = binprint.is_identifier(key)
   if ident then
      return ident
   end

   return ("[%s]"):format(binprint.print_val(key))
end

function binprint.print_kv(key, value, name)
   if name then
      name = name .. " "
   else
      name = ""
   end
   return ("%s = %s%s"):format(binprint.print_key(key), name, binprint.print_val(value))
end

return binprint
