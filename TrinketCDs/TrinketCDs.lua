local ADDON_NAME = "TrinketCDs"
local ADDON = CreateFrame("Frame")
_G[ADDON_NAME] = ADDON

local DB = _G.TrinketCDsDB
local SETTINGS = DB.DEFAULT_SETTINGS
local SWITCHES = SETTINGS.SWITCHES
ADDON.FRAMES = {}
ADDON.SETTINGS = SETTINGS
ADDON.ITEM_GROUP = DB.ITEM_GROUP
ADDON.SORTED_ITEMS = {13, 14, 11, 15, 16, 10, 8, 6}
ADDON.TRINKET_SWAP_ID = 10725

local ITEMS_CACHE = {}
local PRECISION_FORMAT = {[0] = "%d", [1] = "%.1f"}
local ADDON_PROFILE = format("%sProfile", ADDON_NAME)
local ADDON_NAME_COLOR = "|cffffffff[TrinketCDs|r|cff00ff00 Enhanced|r|cffffffff]|r: "
local ADDON_MEDIA = format("Interface\\Addons\\%s\\Media\\%%s", ADDON_NAME)
local BORDER_TEXTURE = ADDON_MEDIA:format("BigBorder.blp")
local DEFAULT_FONT_FILE = "Emblem.ttf"
local DEFAULT_FONT = ADDON_MEDIA:format(DEFAULT_FONT_FILE)
ADDON.DEFAULT_FONT = DEFAULT_FONT
ADDON.BORDER_TEXTURE = BORDER_TEXTURE
ADDON.NAME_COLOR = ADDON_NAME_COLOR
SWITCHES.FONT_FILE = DEFAULT_FONT

local GetTime = GetTime
local UnitBuff = UnitBuff
local UnitGUID = UnitGUID
local InCombatLockdown = InCombatLockdown
local IsModifierKeyDown = IsModifierKeyDown
local UnitAffectingCombat = UnitAffectingCombat
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetContainerNumFreeSlots = GetContainerNumFreeSlots or (C_Container and C_Container.GetContainerNumFreeSlots)

ADDON.DRAG_UNLOCK = false
ADDON.TEST_MODE = false

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

local GLOW_STYLE_BUTTON = 1
local GLOW_STYLE_PIXEL = 2
local GLOW_STYLE_PROC = 3
local GLOW_FREQUENCY = 0.25
local GLOW_FRAMELEVEL = 8
local PIXEL_KEY = "TCD"
local PIXEL_LINES = 8
local PIXEL_LENGTH = 10
local PIXEL_THICKNESS = 1

local TEXT_OVERLAY_FRAMELEVEL = 30

local function GlowExtra(outside, offset)
    if outside and outside ~= 0 then return offset or 0 end
    return 0
end

local function ButtonGlow_Update(r, extra)
    local f = r and r._ButtonGlow
    if not f then return end
    extra = extra or r._tcd_glow_extra or 0

    local width, height = r:GetSize()
    local dx, dy = width * 0.2 + extra, height * 0.2 + extra
    f:SetFrameLevel(r:GetFrameLevel() + GLOW_FRAMELEVEL)
    f:SetSize(width + dx * 2, height + dy * 2)
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", r, "TOPLEFT", -dx, dy)
    f:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", dx, -dy)

    if f.ants then
        f.ants:SetSize((width + dx * 2) * 0.85, (height + dy * 2) * 0.85)
    end

    f.throttle = (GLOW_FREQUENCY and GLOW_FREQUENCY > 0) and (0.25 / GLOW_FREQUENCY * 0.01) or 0.01
end

function ADDON.GlowStop(self)
    if not (LCG and self and self._tcd_glow_active) then return end

    local style = self._tcd_glow_style_active
    if style == GLOW_STYLE_PIXEL then
        if LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(self, PIXEL_KEY) end
    elseif style == GLOW_STYLE_PROC then
        if LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(self, PIXEL_KEY) end
    else
        if LCG.ButtonGlow_Stop then LCG.ButtonGlow_Stop(self) end
    end

    self._tcd_glow_active = false
    self._tcd_glow_style_active = nil
    self._tcd_glow_extra = nil
end

function ADDON.GlowStart(self, style, outside, offset)
    if not (LCG and self) then return end
    style = style or GLOW_STYLE_BUTTON
    local extra = GlowExtra(outside, offset)

    if self._tcd_glow_active then
        if self._tcd_glow_style_active == style and self._tcd_glow_extra == extra then
            if style == GLOW_STYLE_BUTTON then ButtonGlow_Update(self, extra) end
            return
        end
        ADDON.GlowStop(self)
    end

    if style == GLOW_STYLE_PIXEL then
        if not LCG.PixelGlow_Start then return end

        local off = extra > 0 and (extra + PIXEL_THICKNESS) or 0
        LCG.PixelGlow_Start(self, nil, PIXEL_LINES, GLOW_FREQUENCY, PIXEL_LENGTH, PIXEL_THICKNESS, off, off, nil, PIXEL_KEY, GLOW_FRAMELEVEL)
    elseif style == GLOW_STYLE_PROC then
        if not LCG.ProcGlow_Start then return end
        LCG.ProcGlow_Start(self, {
            color = nil,
            startAnim = true,
            duration = 1,
            key = PIXEL_KEY,
            frameLevel = GLOW_FRAMELEVEL,
            xOffset = extra,
            yOffset = extra,
        })
    else
        if not LCG.ButtonGlow_Start then return end
        LCG.ButtonGlow_Start(self, nil, GLOW_FREQUENCY, GLOW_FRAMELEVEL)
        ButtonGlow_Update(self, extra)
    end

    self._tcd_glow_active = true
    self._tcd_glow_style_active = style
    self._tcd_glow_extra = extra
end

local StopGlow = ADDON.GlowStop

function ADDON.ItemGlowStyle(self)
    local style = self.settings and self.settings.GLOW_STYLE
    if style and style ~= 0 then return style end
    return SWITCHES.PROC_GLOW_STYLE or GLOW_STYLE_BUTTON
end

local function TestGlow(self)
    if SWITCHES.SHOW_PROC_GLOW ~= 0 and (self.settings.PROC_GLOW == nil or self.settings.PROC_GLOW ~= 0) then
        ADDON.GlowStart(self, ADDON.ItemGlowStyle(self), SWITCHES.GLOW_OUTSIDE, SWITCHES.GLOW_OFFSET)
    else
        StopGlow(self)
    end
end

function ADDON.ApplyTestVisual(self)
    if not self.item then return end
    TestGlow(self)
    local now = GetTime()
    self.texture:SetDesaturated(false)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(now, 20)
    self.cooldown_current_end = now + 20
end

local function ShowProcVisuals(self, procSpellID)
    local wantGlow = (SWITCHES.SHOW_PROC_GLOW ~= 0)
        and (self.item and self.item.applied)
        and (self.settings.PROC_GLOW == nil or self.settings.PROC_GLOW ~= 0)

    if LCG and wantGlow then
        ADDON.GlowStart(self, ADDON.ItemGlowStyle(self), SWITCHES.GLOW_OUTSIDE, SWITCHES.GLOW_OFFSET)
    else
        StopGlow(self)
    end

    if SWITCHES.SHOW_PROC_ICON ~= 0 and procSpellID then
        local procIcon = select(3, GetSpellInfo(procSpellID))
        if procIcon then
            self.texture:SetTexture(procIcon)
            return
        end
    end

    if self.item and self.item.texture then
        self.texture:SetTexture(self.item.texture)
    end
end

local function HideProcVisuals(self)
    StopGlow(self)
    if self.item and self.item.texture then
        self.texture:SetTexture(self.item.texture)
    end
end

local function new_item(item_ID)
    if not item_ID then return end
    local _, _, item_quality, item_level, _, _, _, _, _, item_texture = GetItemInfo(item_ID)
    if not item_quality then return end

    local item = {
        ID = item_ID,
        ilvl = item_level,
        quality = item_quality,
        texture = item_texture,
    }
    ITEMS_CACHE[item_ID] = item
    return item
end

local function get_buff_IDs(item_ID)
    local spell_IDs = DB.TRINKET_PROC_MULTIBUFF[item_ID]
    if not spell_IDs then return end

    local buff_IDs = {}
    for _, spell_ID in pairs(spell_IDs) do
        buff_IDs[spell_ID] = true
    end
    return buff_IDs
end

local function new_trinket(item_ID)
    local item = new_item(item_ID)
    if not item then return end

    local buff_ID = DB.TRINKET_PROC_ID[item_ID]
    local buff_IDs = get_buff_IDs(item_ID)
    item.spell_ID = buff_ID
    item.spell_IDs = buff_IDs
    item.stacks_ID = DB.TRINKET_PROC_STACKS[buff_ID]
    if buff_ID or buff_IDs then
        item.proc_in_DB = true
        item.CD = DB.TRINKET_PROC_CD[item_ID] or 45
    end
    return item
end

local function new_not_trinket(item_ID, buff_ID)
    local item = new_item(item_ID)
    if not item then return end

    item.spell_ID = buff_ID
    item.proc_in_DB = true
    item.CD = DB.ENCHANT_PROC_CD[buff_ID] or 60
    return item
end

local function check_other_ring(self)
    local slot_ID = self.slot_ID == 11 and 12 or 11
    local item_ID = GetInventoryItemID("player", slot_ID)
    local buff_ID = DB.ASHEN_RINGS[item_ID]
    if buff_ID then
        self.slot_ID = slot_ID
        return item_ID, buff_ID
    end
end

local function get_item(self)
    local item_ID = GetInventoryItemID("player", self.slot_ID)
    local item = ITEMS_CACHE[item_ID]

    if self.item_proc_type == "enchant" then
        local item_link = GetInventoryItemLink("player", self.slot_ID)
        if not item_link then return end

        local ench_ID = item_link:match("%d:(%d+)")
        local buff_ID = DB.ENCHANTS[ench_ID]
        if item and item.spell_ID == buff_ID then return item end

        if not buff_ID then
            local _, _, has_cd = GetInventoryItemCooldown("player", self.slot_ID)
            if has_cd == 0 then return end
        end

        return new_not_trinket(item_ID, buff_ID)

    elseif item then
        return item

    elseif self.item_proc_type == "trinket" then
        return new_trinket(item_ID)

    elseif self.item_proc_type == "ring" then
        local buff_ID = DB.ASHEN_RINGS[item_ID]
        if not buff_ID then
            item_ID, buff_ID = check_other_ring(self)
        end
        return buff_ID and new_not_trinket(item_ID, buff_ID)
    end
end

local function ResetFrame(self)
    HideProcVisuals(self)
    self.cooldown_current_end = nil
    self.stacks_text:SetText()
    self.texture:SetDesaturated(false)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
    self:ToggleVisibility()
end

local function ApplyItemCD(self, dur)
    if self.item.applied then return end

    dur = dur or self.item.CD
    self.stacks_text:SetText()
    self.texture:SetDesaturated(true)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(self.item.cd_start, dur)
    self.cooldown_current_end = self.item.cd_start + dur
    self:ToggleVisibility()
end

local function ItemUsedCheck(self)
    if not self.is_usable then return end

    local cdStart, cdDur = GetInventoryItemCooldown("player", self.slot_ID)
    if cdDur == 0 then return end

    if cdDur > 30 then
        self.item.CD = cdDur
        if self.item.ID == ADDON.TRINKET_SWAP_ID and self.item_ID_before_swap and GetTime() - cdStart < 5 then
            EquipItemByName(self.item_ID_before_swap, self.slot_ID)
        end
    end

    self.item.cd_start = cdStart
    self.item.cd_end = cdStart + cdDur
    self:ApplyItemCD(cdDur)
end

local GetPlayerBuff = (function()
    local function retail(buff_index)
        local _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = UnitBuff("player", buff_index)
        return stacks, duration, expirationTime, buffSpellID
    end
    local function old(buff_index)
        local _, _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = UnitBuff("player", buff_index)
        return stacks, duration, expirationTime, buffSpellID
    end
    local _, _, _, tocVersion = GetBuildInfo()
    local isRetail = tocVersion and tocVersion > 40000
    return isRetail and retail or old
end)()

local function player_buff(spell_ID)
    local buff_index = 1
    repeat
        local stacks, duration, expirationTime, buffSpellID = GetPlayerBuff(buff_index)
        if buffSpellID == spell_ID then
            return stacks, duration, expirationTime, buffSpellID
        end
        buff_index = buff_index + 1
    until not buffSpellID
end

local function player_buff_multi(spell_IDs)
    local buff_index = 1
    repeat
        local stacks, duration, expirationTime, buffSpellID = GetPlayerBuff(buff_index)
        if spell_IDs[buffSpellID] then
            return stacks, duration, expirationTime, buffSpellID
        end
        buff_index = buff_index + 1
    until not buffSpellID
end

local function player_buff_stacks(spell_ID, stacks_ID)
    local _stacks, _duration, _expiration, _main_stacks
    local buff_index = 1
    repeat
        local stacks, duration, expirationTime, buffSpellID = GetPlayerBuff(buff_index)
        if buffSpellID == spell_ID then
            _duration = duration
            _expiration = expirationTime
            _main_stacks = stacks
            if _stacks then
                return _stacks, _duration, _expiration
            end
        elseif buffSpellID == stacks_ID then
            _stacks = stacks
            if _duration then
                return _stacks, _duration, _expiration
            end
        end
        buff_index = buff_index + 1
    until not buffSpellID

    if _duration then
        return _main_stacks or 0, _duration, _expiration
    end
end

local function check_proc(item)
    if item.stacks_ID then
        return player_buff_stacks(item.spell_ID, item.stacks_ID)
    elseif item.spell_ID then
        return player_buff(item.spell_ID)
    elseif item.spell_IDs then
        return player_buff_multi(item.spell_IDs)
    end
end

local function ItemBuffApplied(self, duration, expirationTime, procSpellID)
    local cd_start = expirationTime - duration
    local item = self.item
    item.applied = true
    if not item.cd_start or cd_start > item.cd_start then
        item.cd_start = cd_start
        item.buff_end = expirationTime
        item.cd_end = self.no_swap_cd and expirationTime or cd_start + item.CD
    end
    self.texture:SetDesaturated(false)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
    self.cooldown_current_end = expirationTime
    self.last_proc_spell_id = procSpellID
    self:ToggleVisibility()
    ShowProcVisuals(self, procSpellID)
end

local function ItemBuffFaded(self)
    self.item.applied = false
    HideProcVisuals(self)
    if self.no_swap_cd then
        self:ResetFrame()
    elseif self.is_usable then
        self:ItemUsedCheck()
    else
        self:ApplyItemCD()
    end
end

local function AuraCheck(self, swapped)
    if not self.item or ADDON.TEST_MODE then return end

    local stacks, duration, expiration, procSpellID = check_proc(self.item)
    if duration == 0 then
        self.item.applied = true
        self.stacks_text:SetText(stacks)
        self.last_proc_spell_id = procSpellID
        ShowProcVisuals(self, procSpellID)
    elseif duration then
        if stacks ~= 0 then
            self.stacks_text:SetText(stacks)
        end
        if swapped or expiration ~= self.item.buff_end then
            self:ItemBuffApplied(duration, expiration, procSpellID)
        else
            self.last_proc_spell_id = procSpellID
            ShowProcVisuals(self, procSpellID)
        end
    elseif self.item.applied then
        self:ItemBuffFaded()
    end
end

local function OnUpdate(self)
    if self.item.cd_end and GetTime() > self.item.cd_end then
        self.item.cd_end = nil
        self.cooldown_current_end = nil
        self.texture:SetDesaturated(false)
        if SWITCHES.HIDE_READY ~= 0 then

            self:ToggleVisibility()
        end
    end
end

local function ToggleButton(self)

    if not self.button or InCombatLockdown() then return end

    if (SWITCHES.USE_ON_CLICK ~= 0 and self.is_usable)
    or (self.item and self.item.ID == ADDON.TRINKET_SWAP_ID) then
        self.button:Show()
    else
        self.button:Hide()
    end
end

local function ItemUpdate(self)
    local old_ID = self.item and self.item.ID
    if old_ID and old_ID ~= ADDON.TRINKET_SWAP_ID then
        self.item_ID_before_swap = old_ID
    end

    local item = get_item(self)
    if item and item == self.item then return end
    self.item = item
    if not item then return self:ToggleVisibility() end

    self.texture:SetTexture(item.texture)
    self.ilvl_text:SetText(item.ilvl)
    local rgb = DB.ITEM_QUALITY[item.quality] or DB.ITEM_QUALITY[1]
    self.ilvl_text:SetTextColor(rgb())

    self.no_swap_cd = item.CD == 0
    self:SetScript("OnUpdate", item.CD ~= 0 and OnUpdate or nil)

    local _, _, is_usable = GetInventoryItemCooldown("player", self.slot_ID)
    self.is_usable = is_usable == 1

    self:ResetFrame()
    self:AuraCheck(true)
    self:ItemUsedCheck()
    self:ToggleButton()
end

local function ItemChanged(self)
    if not self.item or self.no_swap_cd or self.is_usable or not self.item.proc_in_DB then return end

    local now = GetTime()
    if SWITCHES.FORCE30 == 0 then
        self.item.cd_start = now
        self.item.cd_end = now + self.item.CD
        self:ApplyItemCD()
    elseif self.item.cd_end and self.item.cd_end - now > 30 then
        self:ApplyItemCD()
    else
        self.item.cd_start = now
        self.item.cd_end = now + 30
        self:ApplyItemCD(30)
    end
end

local function OnDragStart(self)
    if InCombatLockdown() then return end
    if not ADDON.DRAG_UNLOCK then return end
    self:StartMoving()
    self.isMoving = true
end

local function OnDragStop(self)
    if not self.isMoving then return end
    self:StopMovingOrSizing()
    self.isMoving = false

    local scale = self:GetEffectiveScale()
    local uiScale = UIParent:GetEffectiveScale()
    local cx, cy = self:GetCenter()
    local ux, uy = UIParent:GetCenter()

    local posX = (cx * scale - ux * uiScale) / uiScale
    local posY = (cy * scale - uy * uiScale) / uiScale

    self.settings.POS_X = floor(posX + 0.5)
    self.settings.POS_Y = floor(posY + 0.5)

    self:RedrawFrame()
    if ADDON.OPTIONS and ADDON.OPTIONS.Refresh then
        ADDON.OPTIONS:Refresh()
    end
end

local function SetupDragForFrame(self)
    self:SetMovable(true)
    self:SetClampedToScreen(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", OnDragStart)
    self:SetScript("OnDragStop", OnDragStop)
end

local function OnMouseDown(self, button)
    self = self.parent or self
    if ADDON.DRAG_UNLOCK then return end
    if InCombatLockdown() then
        return
    elseif button == "LeftButton" then
        if IsControlKeyDown() then
            self.swap_back_item_id = self.item.ID
            for i=0,4 do
                local free_slots, bag_type = GetContainerNumFreeSlots(i)
                if bag_type == 0 and free_slots > 0 then
                    PickupInventoryItem(self.slot_ID)
                    return i == 0 and PutItemInBackpack() or PutItemInBag(i+CONTAINER_BAG_OFFSET)
                end
            end
        elseif IsShiftKeyDown() then
            if self.slot_ID == 13 then
                EquipItemByName(self.item.ID, 14)
            elseif self.slot_ID == 14 then
                EquipItemByName(self.item.ID, 13)
            end
        elseif IsAltKeyDown() then
            local item_name = GetItemInfo(self.item.ID)
            EquipItemByName(item_name, self.slot_ID)
        end
    elseif button == "RightButton" then
        if IsControlKeyDown() then
            if self.item.ID == ADDON.TRINKET_SWAP_ID then
                if not self.item_ID_before_swap then return end
                EquipItemByName(self.item_ID_before_swap, self.slot_ID)
            else
                EquipItemByName(ADDON.TRINKET_SWAP_ID, self.slot_ID)
            end
        end
    end
end

local function PlayerInCombat()
    return UnitAffectingCombat("player") or UnitGUID("boss1")
end

local function ToggleVisibility(self)
    if self.button and InCombatLockdown() then return end

    if ADDON.DRAG_UNLOCK or ADDON.TEST_MODE then
        if self.item and self.settings.SHOW ~= 0 then
            self:Show()
        else
            self:Hide()
        end
        return
    end

    if not self.item then
        self:Hide()
        return
    end

    if self.settings.SHOW == 0
    or (SWITCHES.COMBAT_ONLY ~= 0 and not PlayerInCombat())
    or (SWITCHES.HIDE_READY ~= 0 and not self.cooldown_current_end) then
        self:Hide()
    else
        self:Show()
    end
end

local function OnEvent(self, event, arg1, arg2)
    if event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        self:AuraCheck()
    elseif event == "ARENA_TEAM_ROSTER_UPDATE" then
        self:ResetFrame()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:ItemUsedCheck()
    elseif event == "MODIFIER_STATE_CHANGED" then
        if InCombatLockdown() then return end
        if ADDON.DRAG_UNLOCK then return end
        self:EnableMouse(arg2 == 1)
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:ToggleVisibility()
        self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:ToggleButton()
        self:ToggleVisibility()
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
    elseif event == "ITEM_UNLOCKED" then
        if not self.swap_back_item_id then return end
        EquipItemByName(self.swap_back_item_id, self.slot_ID)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if DB.ITEM_GROUP[arg1] ~= self.item_group then return end
        if self.swap_back_item_id == GetInventoryItemID("player", self.slot_ID) then
            self.swap_back_item_id = false
        end
        local item = self.item
        local slot = self.slot_ID
        self:ItemUpdate()
        if item == self.item and slot == self.slot_ID then return end
        self:ItemChanged()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if self.item then return end
        self:ItemUpdate()
    elseif event == "UNIT_NAME_UPDATE" then
        if arg1 ~= "player" then return end
        if not self.item then
            self:ItemUpdate()
        end
        self:ItemChanged()
    end
end

local function new_font_overlay(parent)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetShadowColor(0, 0, 0, 1)
    font:SetShadowOffset(1, -1)
    return font
end

local function add_cooldown_text(self)
    if OmniCC then return end

    self.cooldown.text = new_font_overlay(self.cooldown)
    self.cooldown.text:SetPoint("CENTER")
    self.cooldown:SetScript("OnUpdate", function()
        if not self.cooldown_current_end then return end
        local diff = self.cooldown_current_end - GetTime()
        if diff > 100 then
            self.cooldown.text:SetFormattedText("%dm", diff/60)
        elseif diff < 0.1 then
            self.cooldown_current_end = nil
            self.cooldown.text:SetText()
        else
            self.cooldown.text:SetFormattedText(PRECISION_FORMAT[SWITCHES.SHOW_DECIMALS], diff)
        end
    end)
end

local function add_text_layer(self)
    self.text_overlay = CreateFrame("Frame", nil, self)
    self.text_overlay:SetAllPoints()
    self.text_overlay:SetFrameLevel(self:GetFrameLevel() + TEXT_OVERLAY_FRAMELEVEL)

    self.stacks_text = new_font_overlay(self.text_overlay)
    self.stacks_text:SetWidth(self.settings.ICON_SIZE)

    self.ilvl_text = new_font_overlay(self.text_overlay)
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
end

local function set_new_font(text, icon_size, text_size)
    if not text then return end

    local fontsize = icon_size / 100 * text_size + 1
    local success = text:SetFont(SWITCHES.FONT_FILE, floor(fontsize), "OUTLINE")

    if success == 1 or success == true then return success end

    SWITCHES.FONT_FILE = DEFAULT_FONT
    text:SetFont(DEFAULT_FONT, floor(fontsize), "OUTLINE")
end

local function RedrawFrame(self)
    local zoom = self.settings.ZOOM / 100
    local mooz = 1 - zoom
    self.texture:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    local border_margin = self.settings.BORDER_MARGIN
    self.border:SetPoint("TOPLEFT", self, -border_margin, border_margin)
    self.border:SetPoint("BOTTOMRIGHT", self, border_margin, -border_margin)
    self.border:SetBackdrop({edgeFile=BORDER_TEXTURE, edgeSize=self.settings.EDGE_SIZE})
    self.border:SetBackdropBorderColor(0, 0, 0, 1)

    if self.settings.SHOW_ILVL ~= 0 then
        self.ilvl_text:Show()
    else
        self.ilvl_text:Hide()
    end

    local _icon_size = self.settings.ICON_SIZE
    local stacks_pos = SWITCHES.STACKS_BOTTOM == 0 and 1 or -1
    self.stacks_text:SetPoint("CENTER", 0, _icon_size/2 * stacks_pos)

    set_new_font(self.stacks_text, _icon_size, self.settings.STACKS_SIZE)
    set_new_font(self.ilvl_text, _icon_size, self.settings.ILVL_SIZE)
    set_new_font(self.cooldown.text, _icon_size, self.settings.CD_SIZE)

    if InCombatLockdown() then return end

    local scale = (SWITCHES.SCALE or 100) / 100
    self:SetScale(scale)
    self:SetSize(_icon_size, _icon_size)
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", self.settings.POS_X / scale, self.settings.POS_Y / scale)

    if self.text_overlay then
        self.text_overlay:SetFrameLevel(self:GetFrameLevel() + TEXT_OVERLAY_FRAMELEVEL)
    end

    if ADDON.TEST_MODE then
        if self.item then TestGlow(self) end
    elseif self._tcd_glow_active and self._tcd_glow_style_active == GLOW_STYLE_BUTTON then
        ButtonGlow_Update(self)
    end

    self:ToggleButton()
    self:ToggleVisibility()
end

local function add_functions(self)
    self.ApplyItemCD = ApplyItemCD
    self.AuraCheck = AuraCheck
    self.ItemBuffApplied = ItemBuffApplied
    self.ItemBuffFaded = ItemBuffFaded
    self.ItemChanged = ItemChanged
    self.ItemUsedCheck = ItemUsedCheck
    self.ItemUpdate = ItemUpdate
    self.RedrawFrame = RedrawFrame
    self.ResetFrame = ResetFrame
    self.ToggleButton = ToggleButton
    self.ToggleVisibility = ToggleVisibility

    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("ITEM_UNLOCKED")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")

    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnMouseDown", OnMouseDown)
end

local function add_button(self)
    if SWITCHES.HIDE_READY ~= 0 then return end

    local frame_name = ADDON_NAME .. self.slot_ID
    self.button = CreateFrame("Button", frame_name.."Button", self, "SecureActionButtonTemplate")
    self.button:SetAttribute("type1", "item")
    self.button:SetAttribute("item", self.slot_ID)
    self.button:SetAllPoints()
    self.button:SetScript("OnMouseDown", OnMouseDown)
    self.button.parent = self
end

local function CreateNewItemFrame(slot_ID)
    local frame_name = ADDON_NAME..slot_ID
    local self = CreateFrame("Frame", frame_name, UIParent)

    self.slot_ID = slot_ID
    self.item_group = DB.ITEM_GROUP[slot_ID]
    self.item_proc_type = DB.ITEM_PROC_TYPES[slot_ID]
    self.settings = SETTINGS.ITEMS[slot_ID]

    self.texture = self:CreateTexture(frame_name.."Background", "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")

    self.border = CreateFrame("Frame", frame_name.."Border", self, BackdropTemplateMixin and "BackdropTemplate")
    self.border:SetFrameStrata("MEDIUM")

    self.cooldown = CreateFrame("Cooldown", frame_name.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()
    if self.cooldown.SetEdgeScale then self.cooldown:SetEdgeScale(0) end

    add_button(self)
    add_cooldown_text(self)
    add_text_layer(self)
    add_functions(self)

    SetupDragForFrame(self)

    self:RedrawFrame()

    return self
end

local function update_settings(svars_table, settings_table)
    if not svars_table then return end
    for old_table_key in pairs(settings_table) do
        local new_table_value = svars_table[old_table_key]
        if new_table_value ~= nil then
            settings_table[old_table_key] = new_table_value
        end
    end
end

local function update_nested_settings(svars, key)
    local _svars = svars[key]
    if not _svars then return end
    for item_slot_id, settings_item in pairs(SETTINGS[key]) do
        update_settings(_svars[item_slot_id], settings_item)
    end
end

local function is_trinket(item_id)
    return item_id and select(9, GetItemInfo(item_id)) == "INVTYPE_TRINKET"
end

local function set_trinket_swap_id()
    local char_profile = _G["TrinketCDsProfileChar"]
    if not char_profile then return end

    local trinket_swap_link = char_profile["trinket_swap_link"]
    if not trinket_swap_link then return end

    local item_id = trinket_swap_link:match("item:(%d+):")
    if not is_trinket(item_id) then return end

    ADDON.TRINKET_SWAP_ID = tonumber(item_id)
end

local function copy_flat(src)
    local out = {}
    for k, v in pairs(src) do out[k] = v end
    return out
end

function ADDON:CopySettings()
    local saved = { ITEMS = {} }
    for slot_ID, settings in pairs(SETTINGS.ITEMS) do
        saved.ITEMS[slot_ID] = copy_flat(settings)
    end
    saved.SWITCHES = copy_flat(SWITCHES)
    saved.ARENA = copy_flat(SETTINGS.ARENA)
    saved.PARTY = copy_flat(SETTINGS.PARTY)
    return saved
end

function ADDON:SaveCurrentProfile(profileName)
    if not profileName then return end
    if not _G.TrinketCDsProfiles then
        _G.TrinketCDsProfiles = {}
    end
    local profiles = _G.TrinketCDsProfiles
    profiles[profileName] = ADDON:CopySettings()
end

function ADDON:LoadProfile(profileName)
    if not profileName then return end
    local profiles = _G.TrinketCDsProfiles
    if not profiles or not profiles[profileName] then return end

    local saved = profiles[profileName]
    if saved.ITEMS then
        for slot_ID, saved_settings in pairs(saved.ITEMS) do
            if SETTINGS.ITEMS[slot_ID] then
                for k, v in pairs(saved_settings) do
                    SETTINGS.ITEMS[slot_ID][k] = v
                end
            end
        end
    end
    if saved.SWITCHES then
        for k, v in pairs(saved.SWITCHES) do
            SWITCHES[k] = v
        end
    end
    update_settings(saved.ARENA, SETTINGS.ARENA)
    update_settings(saved.PARTY, SETTINGS.PARTY)

    for _, frame in pairs(self.FRAMES) do
        frame:RedrawFrame()
        frame:AuraCheck(true)
    end
    if self.UNITS then self.UNITS:RedrawAll() end
end

function ADDON:DeleteProfile(profileName)
    if not profileName then return end
    local profiles = _G.TrinketCDsProfiles
    if not profiles or not profiles[profileName] then return end
    profiles[profileName] = nil
end

function ADDON:GetProfileList()
    local profiles = _G.TrinketCDsProfiles
    if not profiles then return {} end
    local list = {}
    for name in pairs(profiles) do
        list[#list+1] = name
    end
    sort(list)
    return list
end

function ADDON:SetUnlocked(on)
    if InCombatLockdown() then return end
    on = on and true or false
    ADDON.DRAG_UNLOCK = on
    SWITCHES.LOCKED = on and 0 or 1

    for _, frame in pairs(self.FRAMES) do
        frame:EnableMouse(on)
        if on then
            if not frame.drag_highlight then
                frame.drag_highlight = frame:CreateTexture(nil, "OVERLAY")
                frame.drag_highlight:SetAllPoints()
                frame.drag_highlight:SetTexture(0.22, 0.48, 0.90, 0.35)
            end
            frame.drag_highlight:Show()
        elseif frame.drag_highlight then
            frame.drag_highlight:Hide()
        end
        frame:ToggleVisibility()
    end

    if self.UNITS then self.UNITS:SetUnlocked(on) end
    if self.OPTIONS and self.OPTIONS.Refresh then self.OPTIONS:Refresh() end
end

function ADDON:ToggleDragUnlock()
    self:SetUnlocked(not ADDON.DRAG_UNLOCK)
end

function ADDON:SetTestMode(on)
    if InCombatLockdown() then return end
    ADDON.TEST_MODE = on and true or false

    for _, frame in pairs(self.FRAMES) do
        if ADDON.TEST_MODE then
            ADDON.ApplyTestVisual(frame)
        elseif frame.item then
            frame:ResetFrame()
            frame:AuraCheck(true)
            frame:ItemUsedCheck()
        end
        frame:ToggleVisibility()
    end

    if self.UNITS then self.UNITS:SetTestMode(ADDON.TEST_MODE) end
    if self.OPTIONS and self.OPTIONS.Refresh then self.OPTIONS:Refresh() end
end

function ADDON:OnEvent(event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end

        if not _G.TrinketCDsProfiles then
            _G.TrinketCDsProfiles = {}
        end

        if not _G.TrinketCDsProfileChar then
            _G.TrinketCDsProfileChar = {}
        end

        local char_settings = _G.TrinketCDsProfileChar.SETTINGS
        local svars = char_settings or _G[ADDON_PROFILE]

        if svars then
            update_nested_settings(svars, "ITEMS")
            update_settings(svars.SWITCHES, SWITCHES)
            if svars.SWITCHES and svars.SWITCHES.SHOW_GLOW ~= nil and svars.SWITCHES.SHOW_PROC_GLOW == nil then
                SWITCHES.SHOW_PROC_GLOW = svars.SWITCHES.SHOW_GLOW
            end
            update_settings(svars.ARENA, SETTINGS.ARENA)
            update_settings(svars.PARTY, SETTINGS.PARTY)
        end

        _G[ADDON_PROFILE] = SETTINGS

        for _, slot_ID in ipairs(self.SORTED_ITEMS) do
            self.FRAMES[slot_ID] = CreateNewItemFrame(slot_ID)
        end

        set_trinket_swap_id()

        if SWITCHES.LOCKED == 0 then self:SetUnlocked(true) end

    elseif event == "PLAYER_LOGOUT" then
        if not _G.TrinketCDsProfileChar then
            _G.TrinketCDsProfileChar = {}
        end
        _G.TrinketCDsProfileChar.SETTINGS = ADDON:CopySettings()
    end
end

ADDON:RegisterEvent("ADDON_LOADED")
ADDON:RegisterEvent("PLAYER_LOGOUT")
ADDON:SetScript("OnEvent", ADDON.OnEvent)

SLASH_RIDEPAD_TRINKETS1 = "/tcd"
function SlashCmdList.RIDEPAD_TRINKETS(arg)
    arg = strtrim(arg or "")
    if arg == "" or arg == "o" or arg == "opt" or arg == "options" or arg == "config" then
        if ADDON.OPTIONS and ADDON.OPTIONS.Toggle then ADDON.OPTIONS:Toggle() end
    elseif arg == "help" then
        print(ADDON_NAME_COLOR .. "Available commands:")
        print("|cFFFFFF00/tcd|r - opens options window")
        print("|cFFFFFF00p|r || |cFFFFFF00cpu|r - prints cpu usage")
        print("|cFFFFFF00unlock|r || |cFFFFFF00lock|r || |cFFFFFF00drag|r - move icons")
        print("|cFFFFFF00test|r - preview icons with glow")
        print("|cFFFFFF00save <name>|r - save current layout as profile")
        print("|cFFFFFF00load <name>|r - load profile")
        print("|cFFFFFF00delete <name>|r - delete profile")
        print("|cFFFFFF00profiles|r || |cFFFFFF00list|r - list saved profiles")
    elseif arg == "p" or arg == "cpu" then
        if GetCVarInfo('scriptProfile') == "0" then
            print(ADDON_NAME_COLOR .. "To check cpu usage, type in chat and reload\n|cFFFFFF00/console scriptProfile 1|r")
            return
        end
        UpdateAddOnCPUUsage()
        local msg = ADDON_NAME_COLOR .. "Total seconds in addon:"
        msg = format("%s\n%.3fs", msg, GetAddOnCPUUsage(ADDON_NAME) / 1000)
        for _, frame in pairs(ADDON.FRAMES) do
            local t, c = GetFrameCPUUsage(frame)
            msg = format("%s\n%.3fs | %d function calls", msg, t / 1000, c)
        end
        print(msg)
    elseif arg == "unlock" then
        ADDON:SetUnlocked(true)
    elseif arg == "lock" then
        ADDON:SetUnlocked(false)
    elseif arg == "drag" or arg == "move" then
        ADDON:ToggleDragUnlock()
    elseif arg == "test" then
        ADDON:SetTestMode(not ADDON.TEST_MODE)
    elseif arg:match("^save ") then
        local profileName = arg:match("^save (.+)$")
        ADDON:SaveCurrentProfile(strtrim(profileName))
    elseif arg:match("^load ") then
        local profileName = arg:match("^load (.+)$")
        ADDON:LoadProfile(strtrim(profileName))
    elseif arg:match("^delete ") then
        local profileName = arg:match("^delete (.+)$")
        ADDON:DeleteProfile(strtrim(profileName))
    elseif arg == "profiles" or arg == "list" then
        local list = ADDON:GetProfileList()
        if #list == 0 then
            print(ADDON_NAME_COLOR .. "No saved profiles.")
        else
            print(ADDON_NAME_COLOR .. "Saved profiles:")
            for _, name in ipairs(list) do
                print("  |cFF00FF00" .. name .. "|r")
            end
        end
    else
        print(ADDON_NAME_COLOR .. "Unknown command. Type |cFFFFFF00/tcd help|r.")
    end
end
