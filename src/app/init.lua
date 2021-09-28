local wx = require("wx")
local wxaui = require("wxaui")
local wxlua = require("wxlua")
local util = require("lib.util")
local debug_server = require("app.debug_server")
local hierarchy = require("app.hierarchy")
local repl = require("app.repl")
local config = require("config")

local ID = require("lib.ids")

--- @class app
local app = class.class("app")

function app:init()
   self.wx_app = wx.wxGetApp()

   self.name = "renton"
   self.version = "0.1.0"
   self.wx_version = util.wx_version()
   self.width = 1024
   self.height = 768

   self.config_filepath = "C:/Users/yuno/AppData/Roaming/LOVE/OpenNefia/"

   self.file_menu = wx.wxMenu()
   self.file_menu:Append(ID.OPEN, "&Open...\tCTRL+O", "Open a file in the lexer")
   self.file_menu:Append(ID.EXIT, "E&xit", "Quit the program")
   self.help_menu = wx.wxMenu()
   self.help_menu:Append(ID.ABOUT, "&About", "About this program")

   self.menu_bar = wx.wxMenuBar()
   self.menu_bar:Append(self.file_menu, "&File")
   self.menu_bar:Append(self.help_menu, "&Help")

   self.frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, self.name,
                           wx.wxDefaultPosition, wx.wxSize(self.width, self.height),
                           wx.wxDEFAULT_FRAME_STYLE)
   self.frame.MenuBar = self.menu_bar

   self.frame:CreateStatusBar(ID.STATUS_BAR)
   self.frame:SetStatusText(self:get_info())

   self:connect_frame(ID.OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, self, "on_menu_open")
   self:connect_frame(ID.EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, self, "on_menu_exit")
   self:connect_frame(ID.ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, self, "on_menu_about")

   self.wx_app.TopWindow = self.frame
   self.frame:Show(true)

   self.aui = wxaui.wxAuiManager()
   self.aui:SetManagedWindow(self.frame);

   self.widget_repl = repl:new(self, self.frame)
   self.widget_hierarchy = hierarchy:new(self, self.frame)

   self.debug_server = debug_server:new(self, config.debug_server.port)

   self.aui:Update()

   self:connect_frame(nil, wx.wxEVT_DESTROY, self, "on_destroy")

   self.widget_repl:activate()

   self:try_load_file("C:/Users/yuno/AppData/Roaming/LOVE/OpenNefia/global/config")
end

function app:add_pane(ctrl, args)
   local info = wxaui.wxAuiPaneInfo()

   for k, v in pairs(args) do
      if type(k) == "number" then
         info = info[v](info)
      else
         info = info[k](info, v)
      end
   end

   info = info:CloseButton(false)

   self.aui:AddPane(ctrl, info)

   return info
end

function app:connect(...)
   return util.connect(self.wx_app, ...)
end

function app:connect_frame(...)
   return util.connect(self.frame, ...)
end

function app:print(fmt, ...)
   if self.widget_repl then
      self.widget_repl:DisplayShellMsg(string.format(fmt, ...))
   end
end

function app:run()
   self.wx_app:MainLoop()
end

--
-- Events
--

function app:on_destroy(event)
   if (event:GetEventObject():DynamicCast("wxObject") == self.frame:DynamicCast("wxObject")) then
      -- You must ALWAYS UnInit() the wxAuiManager when closing
      -- since it pushes event handlers into the frame.
      self.aui:UnInit()
   end
end

function app:try_load_file(path)
   local ok, err = xpcall(self.widget_hierarchy.add_page, debug.traceback, self.widget_hierarchy, path)
   if not ok then
      wx.wxMessageBox(("Unable to load file '%s'.\n\n%s"):format(path, err),
         "wxLua Error",
         wx.wxOK + wx.wxCENTRE, self.frame)
   end
end

function app:on_menu_open(_)
   local file_dialog = wx.wxFileDialog(self.frame, "Load serialized file", self.config_filepath,
      "",
      "All files (*)|*",
      wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST)
   if file_dialog:ShowModal() == wx.wxID_OK then
      local path = file_dialog:GetPath()
      self.config_filepath = path
      self:try_load_file(path)
   end
   file_dialog:Destroy()
end

function app:on_menu_exit(_)
   self.frame:Close()
end

function app:get_info()
   return ("%s ver. %s\n%s built with %s\n%s %s")
      :format(self.name, self.version, wxlua.wxLUA_VERSION_STRING, wx.wxVERSION_STRING, jit.version, jit.arch)
end

function app:on_menu_about(_)
   wx.wxMessageBox(self:get_info(),
                   ("About %s"):format(self.name),
                   wx.wxOK + wx.wxICON_INFORMATION,
                   self.frame)
end

return app
