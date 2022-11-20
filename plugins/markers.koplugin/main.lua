local Device = require("device")
local Dispatcher = require("dispatcher")  -- luacheck:ignore
local Font = require("ui/font")
local InfoMessage = require("ui/widget/infomessage")
local logger = require("logger")
local Screen = Device.screen
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local T = require("ffi/util").template

local Markers = WidgetContainer:extend{
    name = "markers",
    is_doc_only = false,
}

function Markers:init()
    self.icons = {}
    self.font = Font:getFace("nerdfonts/symbols.ttf", 16)

    -- TODO: make these customizable lists per book
    self.targets = {
        {
            glyph = "",
            search_term = "Duncan"
        },
        {
            glyph = "",
            search_term = "Macbeth"
        }
    }

    self.ui.menu:registerToMainMenu(self)
    self.view:registerViewModule("markers", self)
end

function Markers:addToMainMenu(menu_items)
    menu_items.markers = {
        text = _("Markers"),
        -- in which menu this should be appended
        sorting_hint = "more_tools",
        -- a callback when tapping
        callback = function()
            UIManager:show(InfoMessage:new{
                text = _("Hello, plugin world"),
            })
        end,
    }
end

function Markers:paintTo(bb, x, y)
    print("Markers:paintTo====================")
    for i, value in ipairs(self.icons) do
        logger.dbg("icons=============", i, value)
        value.widget:paintTo(bb, value.x_off, value.y_off)
    end
end

function Markers:onViewUpdate(i)
    self.icons = {}

    print("===============onViewUpdate", i)
    local page = self.view.state.page
    for _, target in ipairs(self.targets) do
        -- TODO: only search pages n-1, n and n+1
        local search_results, words_found = self.ui.document:findText(target.search_term, 0, 0, false, page, nil, 10)
        self.ui.highlight:clear()
        logger.dbg("=============onViewUpdate", search_results)
        for i, found in ipairs(search_results) do
            local boxes = self.ui.document:getScreenBoxesFromPositions(found["start"], found["end"], true)
            for j, box in ipairs(boxes) do
                logger.dbg("=============onViewUpdate found", j, box)
                self.icons[i+j - 1] = {
                    widget = TextWidget:new{
                        text = target.glyph,
                        face = self.font
                    },
                    x_off = box.x + (box.w / 2) - Screen:scaleBySize(8), -- half of icon
                    y_off = box.y - Screen:scaleBySize(12)
                }
            end
        end
    end
end

function Markers:onPosUpdate(pos, pageno)
    self:onViewUpdate(1)
end

function Markers:onPageUpdate(pageno)
    self:onViewUpdate(2)
end

function Markers:onDocumentRerendered()
    self:onViewUpdate(3)
end

return Markers
