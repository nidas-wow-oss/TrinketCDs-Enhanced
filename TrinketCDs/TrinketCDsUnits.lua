local ADDON = _G.TrinketCDs
local DB = _G.TrinketCDsDB
local SETTINGS = ADDON.SETTINGS
local SWITCHES = SETTINGS.SWITCHES

local GetTime = GetTime
local UnitGUID = UnitGUID
local GetItemIcon = GetItemIcon
local GetSpellInfo = GetSpellInfo

local UNITS = CreateFrame("Frame")
ADDON.UNITS = UNITS

local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local PVP_ICON = select(3, GetSpellInfo(42292)) or "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
local SAMPLE_ICONS = { 50363, 47131, 50365, 54590, 50348 }
local GROUP_KEYS = { "arena", "party" }
local MAX_UNITS = { arena = 5, party = 4 }

local SETUP_UNITS = { arena = 3, party = 2 }
local LABEL = { arena = "Arena", party = "Party" }

local GLOW_FALLBACK = 20
local GLOW_PVP = 3

local ACCEPT = {
    SPELL_AURA_APPLIED = true,
    SPELL_CAST_SUCCESS = true,
    SPELL_DAMAGE = true,
    SPELL_HEAL = true,
    SPELL_ENERGIZE = true,
    SPELL_SUMMON = true,
}

local GROUPS = {}
local guid_to_unit = {}
local active = {}
local in_arena = false
local bracket
local unlocked = false
local testing = false

local function cfg(key)
    return key == "arena" and SETTINGS.ARENA or SETTINGS.PARTY
end

local function glow_style(c, is_pvp)
    local style = is_pvp and c.GLOW_STYLE_PVP or c.GLOW_STYLE
    if style and style ~= 0 then return style end
    return SWITCHES.PROC_GLOW_STYLE or 1
end

local function icons_of(m)
    return { m.pvp, m.t1, m.t2 }
end

local function cd_text_update(self, elapsed)
    self.tick = (self.tick or 0) + elapsed
    if self.tick < 0.1 then return end
    self.tick = 0
    local icon = self:GetParent()
    local left = icon.cdEnd and (icon.cdEnd - GetTime())
    if not left or left <= 0 then
        self.text:SetText()
        return
    end
    if left > 60 then
        self.text:SetFormattedText("%dm", left / 60 + 0.5)
    else
        self.text:SetFormattedText("%d", left + 0.5)
    end
end

local function new_icon(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.texture = f:CreateTexture(nil, "ARTWORK")
    f.texture:SetAllPoints()
    f.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    f.border = CreateFrame("Frame", nil, f)
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f.border:SetBackdropBorderColor(0, 0, 0, 1)

    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints()

    if not OmniCC then
        local holder = CreateFrame("Frame", nil, f)
        holder:SetAllPoints()
        holder:SetFrameLevel(f.cooldown:GetFrameLevel() + 2)
        holder.text = holder:CreateFontString(nil, "OVERLAY")
        holder.text:SetPoint("CENTER")
        holder.text:SetShadowOffset(1, -1)
        holder:SetScript("OnUpdate", cd_text_update)
        f.cd_text = holder
    end
    return f
end

local function set_font(icon, size)
    if not icon.cd_text then return end
    local font = SWITCHES.FONT_FILE or ADDON.DEFAULT_FONT
    local px = math.floor(size * 0.45 + 1)
    if not icon.cd_text.text:SetFont(font, px, "OUTLINE") then
        icon.cd_text.text:SetFont(ADDON.DEFAULT_FONT, px, "OUTLINE")
    end
end

local function clear_icon(icon, texture)
    ADDON.GlowStop(icon)
    icon.cooldown:SetCooldown(0, 0)
    icon.texture:SetTexture(texture)
    icon.texture:SetDesaturated(false)
    icon.itemID, icon.spell, icon.cdEnd, icon.glowUntil = nil, nil, nil, nil
    active[icon] = nil
end

local function reset_member(m)
    clear_icon(m.pvp, PVP_ICON)
    clear_icon(m.t1, QUESTION)
    clear_icon(m.t2, QUESTION)
    m.guid = nil
end

local ticker = CreateFrame("Frame")
local tick = 0
local function ticker_update(self, elapsed)
    tick = tick + elapsed
    if tick < 0.2 then return end
    tick = 0
    local now = GetTime()
    local any = false
    for icon in pairs(active) do
        if icon.glowUntil and now >= icon.glowUntil then
            icon.glowUntil = nil
            ADDON.GlowStop(icon)

            if icon.cdEnd then icon.texture:SetDesaturated(true) end
        end
        if icon.cdEnd and now >= icon.cdEnd then
            icon.cdEnd = nil
            icon.texture:SetDesaturated(false)
        end
        if icon.glowUntil or icon.cdEnd then
            any = true
        else
            active[icon] = nil
        end
    end
    if not any then self:SetScript("OnUpdate", nil) end
end

local function activate(icon)
    active[icon] = true
    ticker:SetScript("OnUpdate", ticker_update)
end

local function apply_glow(icon, c, is_pvp)
    if c.GLOW ~= 0 and (not is_pvp or c.GLOW_PVP ~= 0) then
        ADDON.GlowStart(icon, glow_style(c, is_pvp), c.GLOW_OUTSIDE, c.GLOW_OFFSET)
        return true
    end
    ADDON.GlowStop(icon)
    return false
end

local function start_icon(icon, key, spell_ID, texture, cd, is_pvp, item_ID)
    local now = GetTime()

    if icon.spell == spell_ID and (icon.glowUntil or (icon.cdEnd and now < icon.cdEnd - 2)) then return end

    icon.itemID = item_ID
    icon.spell = spell_ID
    icon.texture:SetTexture(texture or QUESTION)
    icon.texture:SetDesaturated(false)
    if cd and cd > 0 then
        icon.cooldown:SetCooldown(now, cd)
        icon.cdEnd = now + cd
    else
        icon.cooldown:SetCooldown(0, 0)
        icon.cdEnd = nil
    end

    if apply_glow(icon, cfg(key), is_pvp) then
        icon.glowUntil = now + (is_pvp and GLOW_PVP or GLOW_FALLBACK)
    else
        icon.glowUntil = nil
        if icon.cdEnd then icon.texture:SetDesaturated(true) end
    end
    activate(icon)
end

local function save_position(m)
    local c = cfg(m.key)
    local scale = m:GetEffectiveScale()
    local ui = UIParent:GetEffectiveScale()
    local cx, cy = m:GetCenter()
    local ux, uy = UIParent:GetCenter()
    c["POS_X" .. m.index] = math.floor((cx * scale - ux * ui) / ui + 0.5)
    c["POS_Y" .. m.index] = math.floor((cy * scale - uy * ui) / ui + 0.5)
end

local function create_member(key, i)
    local m = CreateFrame("Frame", "TrinketCDs_" .. LABEL[key] .. i, UIParent)
    m.key, m.index = key, i
    m:SetMovable(true)
    m:SetClampedToScreen(true)
    m:RegisterForDrag("LeftButton")
    m:SetScript("OnDragStart", function(self) if unlocked then self:StartMoving() end end)
    m:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        save_position(self)
        UNITS:Layout(self.key)
    end)

    m.drag_bg = m:CreateTexture(nil, "BACKGROUND")
    m.drag_bg:SetPoint("TOPLEFT", -3, 3)
    m.drag_bg:SetPoint("BOTTOMRIGHT", 3, -3)
    m.drag_bg:SetTexture(0.22, 0.48, 0.90, 0.35)
    m.drag_label = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    m.drag_label:SetPoint("BOTTOM", m, "TOP", 0, 4)
    m.drag_label:SetText("|cffffffff" .. LABEL[key] .. "|r |cff00ff00" .. i .. "|r")
    m.drag_bg:Hide()
    m.drag_label:Hide()

    m.pvp = new_icon(m)
    m.t1 = new_icon(m)
    m.t2 = new_icon(m)
    reset_member(m)
    m:Hide()
    return m
end

function UNITS:Layout(key)
    local g = GROUPS[key]
    if not g then return end
    local c = cfg(key)
    local scale = (c.SCALE or 100) / 100
    local size, gap = c.ICON_SIZE, c.SPACING
    local show_pvp = c.SHOW_PVP ~= 0
    local count = show_pvp and 3 or 2
    local width = count * size + (count - 1) * gap

    for i, m in ipairs(g) do
        m:SetScale(scale)
        m:SetSize(width, size)
        m:ClearAllPoints()
        m:SetPoint("CENTER", UIParent, "CENTER", (c["POS_X" .. i] or 0) / scale, (c["POS_Y" .. i] or 0) / scale)
        local order = show_pvp and { m.pvp, m.t1, m.t2 } or { m.t1, m.t2 }
        if show_pvp then m.pvp:Show() else m.pvp:Hide() end
        for j, icon in ipairs(order) do
            icon:SetSize(size, size)
            icon:ClearAllPoints()
            local x = (j - 1) * (size + gap)
            if c.GROW_LEFT ~= 0 then
                icon:SetPoint("TOPRIGHT", m, "TOPRIGHT", -x, 0)
            else
                icon:SetPoint("TOPLEFT", m, "TOPLEFT", x, 0)
            end
            set_font(icon, size)
        end
    end
end

local function update_guids()
    wipe(guid_to_unit)
    for _, key in ipairs(GROUP_KEYS) do
        for i = 1, MAX_UNITS[key] do
            local unit = key .. i
            local g = UnitGUID(unit)
            if g then guid_to_unit[g] = { key = key, index = i, unit = unit } end
        end
    end
end

local function setup_mode()
    return unlocked or testing
end

local function check_party_members()
    local g = GROUPS.party
    if not g or setup_mode() then return end
    for i, m in ipairs(g) do
        local guid = UnitGUID("party" .. i)
        if m.guid ~= guid then
            reset_member(m)
            m.guid = guid
        end
    end
end

local function fill_party_items(i)
    local m = GROUPS.party and GROUPS.party[i]
    if not m or setup_mode() then return end
    local unit = "party" .. i
    for slot, icon in pairs({ [13] = m.t1, [14] = m.t2 }) do
        local item_ID = GetInventoryItemID(unit, slot)
        if item_ID and not icon.spell then
            icon.itemID = item_ID
            icon.texture:SetTexture(GetItemIcon(item_ID) or QUESTION)
        end
    end
end

local function get_bracket()
    for i = 1, MAX_BATTLEFIELD_QUEUES do
        local status, _, _, _, _, team_size = GetBattlefieldStatus(i)
        if status == "active" and team_size and team_size > 0 then
            return team_size
        end
    end

    return math.min(GetNumPartyMembers() + 1, MAX_UNITS.arena)
end

local function group_active(key)
    local c = cfg(key)
    if c.ENABLED == 0 then return false end
    if setup_mode() then return true end
    if key == "arena" then return in_arena end
    if c.ARENA_ONLY ~= 0 then return in_arena end
    return GetNumPartyMembers() > 0 and GetNumRaidMembers() == 0
end

local function unit_count(key)
    if setup_mode() then return SETUP_UNITS[key] end
    if key == "arena" then
        local n = bracket or 0
        for i = 1, MAX_UNITS.arena do
            if UnitExists("arena" .. i) and i > n then n = i end
        end
        return n
    end
    return math.min(GetNumPartyMembers(), MAX_UNITS.party)
end

function UNITS:UpdateVisibility()
    local listen = false
    for key, g in pairs(GROUPS) do
        local on = group_active(key)
        local n = on and unit_count(key) or 0
        for i, m in ipairs(g) do
            if i <= n then m:Show() else m:Hide() end
        end
        if on then listen = true end
    end

    if listen and not setup_mode() then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

local function pick_item(info, items)
    if #items == 1 then return items[1] end

    if info.key == "party" then
        for slot = 13, 14 do
            local equipped = GetInventoryItemID(info.unit, slot)
            for _, item_ID in ipairs(items) do
                if item_ID == equipped then return item_ID end
            end
        end
    end
    return items[1]
end

local function holds(icon, items)
    if not icon.itemID then return false end
    for _, item_ID in ipairs(items) do
        if icon.itemID == item_ID then return true end
    end
    return false
end

local function pick_slot(m, items)
    if holds(m.t1, items) then return m.t1 end
    if holds(m.t2, items) then return m.t2 end
    if not m.t1.itemID then return m.t1 end
    return m.t2
end

local function on_combat_log(timestamp, event, src_GUID, src_name, src_flags, dst_GUID, dst_name, dst_flags, spell_ID)
    if event == "SPELL_AURA_REMOVED" then
        local info = guid_to_unit[dst_GUID]
        if not info then return end
        local m = GROUPS[info.key][info.index]
        for _, icon in ipairs({ m.t1, m.t2 }) do
            if icon.spell == spell_ID and icon.glowUntil then
                icon.glowUntil = GetTime()
            end
        end
        return
    end
    if not ACCEPT[event] then return end

    local pvp_cd = DB.UNIT_PVP_SPELLS[spell_ID]
    local items = not pvp_cd and DB.UNIT_SPELL_TO_ITEM[spell_ID]
    if not pvp_cd and not items then return end

    local info = guid_to_unit[src_GUID]
    if not info then
        update_guids()
        info = guid_to_unit[src_GUID]
        if not info then return end
    end
    if cfg(info.key).ENABLED == 0 then return end
    local m = GROUPS[info.key][info.index]

    if pvp_cd then
        start_icon(m.pvp, info.key, spell_ID, select(3, GetSpellInfo(spell_ID)), pvp_cd, true)
        return
    end

    local item_ID = pick_item(info, items)
    local icon = pick_slot(m, items)
    local cd = DB.TRINKET_PROC_CD[item_ID] or DB.UNIT_SPELL_CD[spell_ID] or 45
    start_icon(icon, info.key, spell_ID, GetItemIcon(item_ID), cd, false, item_ID)
end

local function fill_sample(key)
    local c = cfg(key)
    local now = GetTime()
    for i, m in ipairs(GROUPS[key]) do
        reset_member(m)
        local id = SAMPLE_ICONS[i] or SAMPLE_ICONS[1]
        m.t1.texture:SetTexture(GetItemIcon(id) or QUESTION)
        m.t1.itemID = id
        if testing then

            m.t1.cooldown:SetCooldown(now, 45)
            m.t1.cdEnd = now + 45
            apply_glow(m.t1, c, false)
            m.pvp.cooldown:SetCooldown(now, 120)
            m.pvp.cdEnd = now + 120
            apply_glow(m.pvp, c, true)
        end
    end
end

local function clear_all()
    for _, g in pairs(GROUPS) do
        for _, m in ipairs(g) do reset_member(m) end
    end
end

local function back_to_real()
    clear_all()
    update_guids()
    check_party_members()
    for i = 1, MAX_UNITS.party do fill_party_items(i) end
end

local function refresh_setup()
    for _, key in ipairs(GROUP_KEYS) do
        local g = GROUPS[key]
        if g then
            for _, m in ipairs(g) do
                m:EnableMouse(unlocked)
                if unlocked then
                    m.drag_bg:Show()
                    m.drag_label:Show()
                else
                    m.drag_bg:Hide()
                    m.drag_label:Hide()
                end
            end
            if setup_mode() then fill_sample(key) end
        end
    end
end

function UNITS:SetUnlocked(on)
    local was = setup_mode()
    unlocked = on and true or false
    refresh_setup()
    if was and not setup_mode() then back_to_real() end
    self:UpdateVisibility()
end

function UNITS:SetTestMode(on)
    local was = setup_mode()
    testing = on and true or false
    refresh_setup()
    if was and not setup_mode() then back_to_real() end
    self:UpdateVisibility()
end

function UNITS:RedrawAll()
    for _, key in ipairs(GROUP_KEYS) do
        local g = GROUPS[key]
        if g then
            self:Layout(key)
            local c = cfg(key)
            if setup_mode() then
                fill_sample(key)
            else
                for _, m in ipairs(g) do
                    for _, icon in ipairs(icons_of(m)) do
                        if icon.glowUntil then
                            ADDON.GlowStop(icon)
                            apply_glow(icon, c, icon == m.pvp)
                        end
                    end
                end
            end
        end
    end
    self:UpdateVisibility()
end

local function zone_changed()
    local was = in_arena
    in_arena = select(2, IsInInstance()) == "arena"
    if in_arena ~= was and not setup_mode() then

        clear_all()
    end
    bracket = in_arena and get_bracket() or nil
    update_guids()
    check_party_members()
    UNITS:UpdateVisibility()
end

UNITS:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        on_combat_log(...)
    elseif event == "ARENA_OPPONENT_UPDATE" then
        update_guids()
        self:UpdateVisibility()
    elseif event == "PARTY_MEMBERS_CHANGED" then
        if in_arena then bracket = get_bracket() end
        update_guids()
        check_party_members()
        for i = 1, MAX_UNITS.party do fill_party_items(i) end
        self:UpdateVisibility()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        local i = unit and tonumber(unit:match("^party(%d)$"))
        if i then fill_party_items(i) end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        zone_changed()
    elseif event == "PLAYER_LOGIN" then
        for _, key in ipairs(GROUP_KEYS) do
            local g = {}
            for i = 1, MAX_UNITS[key] do g[i] = create_member(key, i) end
            GROUPS[key] = g
            self:Layout(key)
        end
        unlocked = ADDON.DRAG_UNLOCK and true or false
        refresh_setup()
        zone_changed()
    end
end)

UNITS:RegisterEvent("PLAYER_LOGIN")
UNITS:RegisterEvent("PLAYER_ENTERING_WORLD")
UNITS:RegisterEvent("ZONE_CHANGED_NEW_AREA")
UNITS:RegisterEvent("ARENA_OPPONENT_UPDATE")
UNITS:RegisterEvent("PARTY_MEMBERS_CHANGED")
UNITS:RegisterEvent("UNIT_INVENTORY_CHANGED")
