local old_path = package.path
local function add_search_path(path)
   package.path = package.path .. ";" .. path
end
local function add_search_cpath(path)
   package.cpath = package.cpath .. ";" .. path
end

function wxT(s)
   return s
end

local function add_search_paths(thirdparty)
   local ffi = require("ffi")
   if ffi.os == "Windows" then
      add_search_path("lib/luasocket/?.lua")
      add_search_cpath("lib/?.dll")
      add_search_cpath("lib/luasocket/?.dll")
      add_search_cpath("lib/lua-zlib/?.dll")
   end

   add_search_path("./src/?.lua")
   add_search_path("./?/init.lua")
   add_search_path("./src/?/init.lua")
end

local use_opennefia_runtime = true
local opennefia_path = "../elona-next"

if use_opennefia_runtime then
    -- remove leading "?.lua", prioritize thirdparty in OpenNefia repo
   package.path = old_path:gsub("%.[/\\]%?%.lua;", "")

   add_search_path(opennefia_path .. "/src/?.lua")
   add_search_path(opennefia_path .. "/src/?/init.lua")
   add_search_path(opennefia_path .. "/lib/lia-vips/?.lua")
   add_search_cpath(opennefia_path .. "/lib/luautf8/?.dll")
   add_search_cpath(opennefia_path .. "/lib/luafilesystem/?.dll")

   require("boot")

   local fs = require("util.fs")

   local function to_open_nefia_search_path(search_path)
      search_path = fs.normalize(search_path)
      if search_path:match("^/") or search_path:match("^%./OpenNefia/src") then
         return search_path
      end

      return search_path:gsub("^%./", "./OpenNefia/src/")
   end

   local search_paths = fun.iter(string.split(package.path, ";")):map(to_open_nefia_search_path):to_list()
   search_paths[#search_paths+1] = "./?.lua"
   search_paths[#search_paths+1] = "./?/init.lua"
   package.path = table.concat(search_paths, ";")

   local search_cpaths = fun.iter(string.split(package.cpath, ";")):map(to_open_nefia_search_path):to_list()
   package.cpath = table.concat(search_cpaths, ";")

   add_search_paths()
else
   add_search_paths()

   fun = require("thirdparty.fun")
   inspect = require("thirdparty.inspect")
   class = require("src.class")

   require("ext")

   require("thirdparty.strict")
end

local _G_mt = getmetatable(_G)
local declared = _G_mt.__declared
declared["app"] = true
declared["config"] = true

----------------------------------------------------------------------------------

app = nil
config = require("config")

app = require("app"):new()
app:run()
