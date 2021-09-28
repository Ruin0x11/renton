fun = require("thirdparty.fun")
inspect = require("thirdparty.inspect")
class = require("src.class")

local ffi = require("ffi")
if ffi.os == "Windows" then
   package.path = package.path .. ";lib\\luasocket\\?.lua"
   package.cpath = package.cpath .. ";lib\\?.dll;lib\\luasocket\\?.dll;lib\\lua-zlib\\?.dll"
end

package.path = package.path .. ";./?/init.lua;./src/?.lua;./src/?/init.lua"
package.path = package.path .. ";./thirdparty/?.lua;./thirdparty/?/init.lua"

-- TODO: temporary
package.path = package.path .. ";../elona-next/src/?.lua"

require("ext")

app = nil
config = require("config")

function wxT(s)
   return s
end

require("thirdparty.strict")

app = require("app"):new()
app:run()
