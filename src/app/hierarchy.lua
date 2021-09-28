local wx = require("wx")
local wxaui = require("wxaui")
local zlib = require("zlib")
local binser = require("thirdparty.binser")
local util = require("lib.util")
local data_tree = require("widget.data_tree")

local hierarchy = class.class("input")

function hierarchy:init(app, frame)
   self.app = app

   self.history = {}

   self.panel = wx.wxPanel(frame, wx.wxID_ANY)
   self.sizer = wx.wxBoxSizer(wx.wxVERTICAL)

   local notebook_style = wxaui.wxAUI_NB_DEFAULT_STYLE
      + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
      + wx.wxNO_BORDER
   self.notebook = wxaui.wxAuiNotebook(self.panel, wx.wxID_ANY,
                                       wx.wxDefaultPosition,
                                       wx.wxDefaultSize,
                                       notebook_style)
   self.sizer:Add(self.notebook, 1, wx.wxEXPAND, 5)

   self.page_data = {}

   self.panel:SetSizer(self.sizer)
   self.sizer:SetSizeHints(self.panel)

   -- util.connect(self.history_box, wx.wxEVT_COMBOBOX, self, "on_combobox")

   self.pane = self.app:add_pane(self.panel,
                                 {
                                    Name = wxT("Data Hierarchy"),
                                    Caption = wxT("Data Hierarchy"),
                                    MinSize = wx.wxSize(200, 100),
                                    "CenterPane",
                                    PaneBorder = false
                                 })
end

function hierarchy:add_page(filename)
   local input = util.read_file(filename)
   local deflated = zlib.inflate()(input, "full")
   local vals, _len, visited = binser.deserializeRaw(deflated)

   local tree, extra = data_tree.create(self.panel, vals, visited)
   util.connect(tree, wx.wxEVT_COMMAND_TREE_SEL_CHANGED, self, "on_tree_sel_changed")

   local page_bmp = wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_OTHER, wx.wxSize(16,16))

   self.notebook:AddPage(tree, filename, false, page_bmp)

   self.page_data[tree:GetId()] = {
      filename = filename,
      tree = tree,
      extra = extra
   }
end

--
-- Events
--

function hierarchy:on_tree_sel_changed(event)
   local item_id = event:GetItem()
   local page = self.page_data[self.notebook:GetCurrentPage():GetId()]

   if page == nil then
      return
   end

   self.app:print("Item changed: %s", item_id)
end

return hierarchy
