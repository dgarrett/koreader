--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

local BD = require("ui/bidi")
local Dispatcher = require("dispatcher")  -- luacheck:ignore
local IconWidget = require("ui/widget/iconwidget")
local TextWidget = require("ui/widget/textwidget")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local T = require("ffi/util").template

local RightContainer = require("ui/widget/container/rightcontainer")
local Geom = require("ui/geometry")
local Device = require("device")
local Screen = Device.screen
local logger = require("logger")
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")

local Hello = WidgetContainer:extend{
    name = "markers",
    is_doc_only = false,
}

function Hello:onDispatcherRegisterActions()
    Dispatcher:registerAction("helloworld_action", {category="none", event="HelloWorld", title=_("Hello World"), general=true,})
end

function Hello:init()
    -- self.dogear_min_size = math.ceil(math.min(Screen:getWidth(), Screen:getHeight()) * (1/40))
    self.dogear_max_size = math.ceil(math.min(Screen:getWidth(), Screen:getHeight()) * (1/32))
    self.dogear_size = nil
    self.dogear_y_offset = 0
    self.top_pad = nil
    self.y_off = 0
    self.x_off = 0

    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
    self:setupDogear()
    self.view:registerViewModule("markers", self)
end

function Hello:addToMainMenu(menu_items)
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

function Hello:paintTo(bb, x, y)
    print("Hello:paintTo====================")
    -- self[1].paintTo(bb, x, y)
    -- self.arrow:paintTo(bb, self.x_off, self.y_off)
    for i, value in ipairs(self.icons) do
        logger.dbg("icons=============", i, value)
        value.widget:paintTo(bb, value.x_off, value.y_off)
    end
end

function Hello:setupDogear(new_dogear_size)
    if not new_dogear_size then
        new_dogear_size = self.dogear_max_size
    end
    if true or new_dogear_size ~= self.dogear_size then
        self.dogear_size = new_dogear_size
        if self[1] then
            self[1]:free()
        end
        self.top_pad = VerticalSpan:new{width = self.dogear_y_offset}
        self.vgroup = VerticalGroup:new{
            self.top_pad,
            IconWidget:new{
                icon = "dogear.alpha",
                rotation_angle = BD.mirroredUILayout() and 90 or 0,
                width = self.dogear_size,
                height = self.dogear_size,
                alpha = true, -- Keep the alpha layer intact
            }
        }
        self[1] = RightContainer:new{
            dimen = Geom:new{w = Screen:getWidth(), h = self.dogear_y_offset + self.dogear_size},
            self.vgroup
        }
    end
    -- local arrow_size = Screen:scaleBySize(16)
    -- self.arrow = IconWidget:new{
    --     icon = "control.expand.alpha",
    --     width = arrow_size,
    --     height = arrow_size,
    --     alpha = true, -- Keep the alpha layer intact, the fill opacity is set at 75%
    -- }
    self.arrow = TextWidget:new{
        -- text = "🦶",
        text = "",
        face = Font:getFace("nerdfonts/symbols.ttf", 16),
        -- face = Font:getFace("cfont"),
        -- bold = true,
        -- fgcolor = Blitbuffer.COLOR_DARK_GRAY,
    }
    self.icons = {}
end


function Hello:onHelloWorld(i)
    self.icons = {}
    print("===============onHelloWorld")
    local page = self.view.state.page
    local retval, words_found = self.ui.document:findText("Duncan", 0, 0, false, page, nil, 10)
    self.ui.highlight:clear()
    logger.dbg("=============onHelloWorld", retval)
    for i, value in ipairs(retval) do
        local startPos = self.ui.document:getPosFromXPointer(retval[i]["start"])
        local endPos = self.ui.document:getPosFromXPointer(retval[i]["end"])
        local boxes = self.ui.document:getScreenBoxesFromPositions(retval[i]["start"], retval[i]["end"], true)
        logger.dbg("=============onHelloWorld loop", startPos, endPos, boxes[i])
        for j, box in ipairs(boxes) do
            logger.dbg("=============onHelloWorld found", j, box)
            self.icons[i+j - 1] = {
                widget = TextWidget:new{
                    text = "",
                    face = Font:getFace("nerdfonts/symbols.ttf", 16),
                },
                x_off = box.x + (box.w / 2) - Screen:scaleBySize(8), -- half of icon
                y_off = box.y - Screen:scaleBySize(12)
            }
        end
    end
    self.x_off = boxes[1].x + (boxes[1].w / 2) - Screen:scaleBySize(8) -- half of icon
    self.y_off = boxes[1].y - Screen:scaleBySize(12)
    local popup = InfoMessage:new{
        text = T(_("Hello World %1"), i),
    }
    -- UIManager:show(popup)
end

function Hello:onPosUpdate(pos, pageno)
    self:onHelloWorld(1)
end

function Hello:onPageUpdate(pageno)
    self:onHelloWorld(2)
end

function Hello:onDocumentRerendered()
    -- Catching the top status bar toggling with :onSetStatusLine()
    -- would be too early. But "DocumentRerendered" is sent after
    -- it has been applied
    self:onHelloWorld(3)
end

return Hello
