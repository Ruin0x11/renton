local wx = require("wx")
local wxaui = require("wxaui")

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

   self.pages = {}

   self:add_page("new")

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
   local tree = wx.wxTreeCtrl(self.panel, wx.wxID_ANY,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER)

   local imglist = wx.wxImageList(16, 16, true, 2);
   imglist:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_OTHER, wx.wxSize(16,16)));
   imglist:Add(wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_OTHER, wx.wxSize(16,16)));
   tree:AssignImageList(imglist);

   local page_bmp = wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_OTHER, wx.wxSize(16,16));

   self:build_tree(tree)
   self.notebook:AddPage(tree, filename, false, page_bmp)

   self.pages[#self.pages+1] = {
      filename = filename,
      tree = tree
   }
end

function hierarchy:build_tree(tree)
    local root = tree:AddRoot(wxT("wxAUI Project"), 0);
    local items = {} --local items = wx.wxArrayTreeItemIds();

    items[#items+1] = tree:AppendItem(root, wxT("Item 1"), 0); --items:Add(tree:AppendItem(root, wxT("Item 1"), 0));
    items[#items+1] = tree:AppendItem(root, wxT("Item 2"), 0); --items:Add(tree:AppendItem(root, wxT("Item 2"), 0));
    items[#items+1] = tree:AppendItem(root, wxT("Item 3"), 0); --items:Add(tree:AppendItem(root, wxT("Item 3"), 0));
    items[#items+1] = tree:AppendItem(root, wxT("Item 4"), 0); --items:Add(tree:AppendItem(root, wxT("Item 4"), 0));
    items[#items+1] = tree:AppendItem(root, wxT("Item 5"), 0); --items:Add(tree:AppendItem(root, wxT("Item 5"), 0));

    local i, count;
    count = #items --items:Count()
    for i = 1, count do --for i = 0, count-1 do
        local id = items[i]; --local id = items:Item(i);
        tree:AppendItem(id, wxT("Subitem 1"), 1);
        tree:AppendItem(id, wxT("Subitem 2"), 1);
        tree:AppendItem(id, wxT("Subitem 3"), 1);
        tree:AppendItem(id, wxT("Subitem 4"), 1);
        tree:AppendItem(id, wxT("Subitem 5"), 1);
    end

    tree:Expand(root);
end

--
-- Events
--

-- function input:on_combobox()
--    local idx = self.history_box:GetSelection()
--    local text = self.history[idx+1]
--    self:set_text(text)
--    self:send_to_lexer(true)
-- end

return hierarchy
