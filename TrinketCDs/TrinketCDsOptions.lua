local ADDON_NAME = "TrinketCDs"
local ADDON = _G[ADDON_NAME]
local DB = _G.TrinketCDsDB
local FRAMES = ADDON.FRAMES
local SETTINGS = ADDON.SETTINGS
local SWITCHES = SETTINGS.SWITCHES
local DEFAULT_TRINKET_SWAP_LINK = "|cffffffff|Hitem:10725:0:0:0:0:0:0:0:80|h[Gnomish Battle Chicken]|h|r"

local OPTIONS = CreateFrame("Frame")
ADDON.OPTIONS = OPTIONS

local HDR, WHITE, GREEN, GOLD, GRAY, R = "|cff4fc3f7", "|cffffffff", "|cff00ff00", "|cffFFD700", "|cffaaaaaa", "|r"
local FONT = "Fonts\\FRIZQT__.TTF"
local panelBg     = { 0.00, 0.03, 0.11, 0.96 }
local panelBorder = { 0.22, 0.48, 0.90, 1.00 }
local titleBg     = { 0.02, 0.07, 0.20, 0.97 }
local titleBorder = { 0.28, 0.52, 0.92, 0.95 }
local bdPanel = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local bdTitle = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}
local PANEL_W, PANEL_H = 560, 450
local TITLE = WHITE .. "TrinketCDs" .. R .. GREEN .. " Enhanced" .. R

local L = {
    en = {
        tab_general = "General", tab_items = "My items", tab_units = "Arena / Party",
        arena = "Arena", party = "Party",
        display = "Display", lock_frame = "Lock frames", locked = "Frames locked",
        test = "Test mode", test_on = "Stop test",
        COMBAT_ONLY = "Hide out of combat", HIDE_READY = "Hide if ready",
        USE_ON_CLICK = "Use item on click (/reload)", STACKS_BOTTOM = "Stacks at the bottom",
        SHOW_DECIMALS = "Show cooldown decimals", FORCE30 = "Force 30 sec iCD on swap",
        SHOW_PROC_ICON = "Proc icon while active", scale = "Scale", font = "Font",
        default = "Default", swap = "Trinket to swap with Ctrl",
        swap_hint = "Click the box, then click a trinket in your bags.",
        items_hdr = "Items  (show  ·  glow style  ·  glow  ·  item level)",
        glow_short = "Glow", ilvl_short = "iLvl", for_all = "For all items",
        ICON_SIZE = "Icon size", ZOOM = "Icon zoom %",
        BORDER_MARGIN = "Border margin", EDGE_SIZE = "Border edge", ILVL_SIZE = "Item level font %",
        STACKS_SIZE = "Stacks font %", CD_SIZE = "Cooldown font %",
        advanced = "Advanced", back = "Back to items",
        arena_enable = "Show enemy trinkets", party_enable = "Show party trinkets",
        arena_only = "Only inside arena", show_pvp = "Show PvP trinket (medallion)",
        spacing = "Icon spacing", grow = "Grow to", style_pvp = "PvP style",
        right = "Right", left = "Left", glow = "Glow", glow_on = "Glow on trinkets",
        glow_pvp = "Glow on PvP trinket", style = "Style", main_style = "Main style",
        same = "Same as main", outside = "Glow outside the border", offset = "Outside offset",
        glow_enable = "Enable proc glow",
        arena_hint = "Hidden outside arena. Use Test mode or unlock to see them.",
        party_hint = "Party trinkets show when they proc. Unlock to drag each member.",
        profile = "Profile", pick = "Pick", none = "(no profiles)",
        save = "Save", load = "Load", delete = "Delete",
        Trinket1 = "Trinket 1", Trinket2 = "Trinket 2", Ring = "Ring", Belt = "Belt",
        Boots = "Boots", Hands = "Hands", Cloak = "Cloak", Weapon = "Weapon",
    },
    es = {
        tab_general = "General", tab_items = "Mis objetos", tab_units = "Arena / Grupo",
        arena = "Arena", party = "Grupo",
        display = "Pantalla", lock_frame = "Bloquear íconos", locked = "Íconos bloqueados",
        test = "Modo prueba", test_on = "Terminar prueba",
        COMBAT_ONLY = "Ocultar fuera de combate", HIDE_READY = "Ocultar si está listo",
        USE_ON_CLICK = "Usar objeto con clic (/reload)", STACKS_BOTTOM = "Cargas abajo",
        SHOW_DECIMALS = "Mostrar decimales del CD", FORCE30 = "Forzar 30 s de CD al cambiar",
        SHOW_PROC_ICON = "Ícono del proc mientras dura", scale = "Escala", font = "Letra",
        default = "Por defecto", swap = "Abalorio para cambiar con Ctrl",
        swap_hint = "Clic en el cuadro y luego en un abalorio de la bolsa.",
        items_hdr = "Objetos  (mostrar  ·  estilo de brillo  ·  brillo  ·  nivel)",
        glow_short = "Brillo", ilvl_short = "Nivel", for_all = "Para todos",
        ICON_SIZE = "Tamaño de ícono", ZOOM = "Zoom del ícono %",
        BORDER_MARGIN = "Margen del borde", EDGE_SIZE = "Grosor del borde", ILVL_SIZE = "Letra nivel %",
        STACKS_SIZE = "Letra cargas %", CD_SIZE = "Letra del CD %",
        advanced = "Avanzado", back = "Volver a objetos",
        arena_enable = "Mostrar abalorios enemigos", party_enable = "Mostrar abalorios del grupo",
        arena_only = "Solo dentro de arena", show_pvp = "Mostrar abalorio PvP (medallón)",
        spacing = "Separación de íconos", grow = "Crecer hacia", style_pvp = "Estilo PvP",
        right = "Derecha", left = "Izquierda", glow = "Brillo", glow_on = "Brillo en abalorios",
        glow_pvp = "Brillo en abalorio PvP", style = "Estilo", main_style = "Estilo general",
        same = "Igual al general", outside = "Brillo por fuera del borde", offset = "Distancia afuera",
        glow_enable = "Activar brillo",
        arena_hint = "Se oculta fuera de arena. Usa Modo prueba o desbloquea para verlos.",
        party_hint = "Se ven cuando se activan. Desbloquea para mover cada compañero.",
        profile = "Perfil", pick = "Elegir", none = "(sin perfiles)",
        save = "Guardar", load = "Cargar", delete = "Borrar",
        Trinket1 = "Abalorio 1", Trinket2 = "Abalorio 2", Ring = "Anillo", Belt = "Cinturón",
        Boots = "Botas", Hands = "Manos", Cloak = "Capa", Weapon = "Arma",
    },
}

local LANG = (GetLocale() or ""):match("^es") and "es" or "en"

local function T(key)
    return L[LANG][key] or L.en[key] or key
end

local function redraw_items()
    for _, frame in pairs(FRAMES) do frame:RedrawFrame() end
end

local function refresh_procs()
    for _, frame in pairs(FRAMES) do
        if frame.AuraCheck then frame:AuraCheck(true) end
    end
end

local function redraw_units()
    if ADDON.UNITS and ADDON.UNITS.RedrawAll then ADDON.UNITS:RedrawAll() end
end

local widgets = {}
local syncing = false
local counter = 0

local function next_name(kind)
    counter = counter + 1
    return "TrinketCDsOpt" .. kind .. counter
end

local function ApplyBackdrop(f, bd, bg, border)
    f:SetBackdrop(bd)
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    f:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

local function Header(parent, x, y, key)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetFont(FONT, 12, "OUTLINE")
    fs.refresh = function() fs:SetText(HDR .. T(key) .. R) end
    widgets[#widgets + 1] = fs
    return fs
end

local function Hint(parent, x, y, key, w)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(w or 220)
    fs:SetJustifyH("LEFT")
    fs.refresh = function() fs:SetText(GRAY .. T(key) .. R) end
    widgets[#widgets + 1] = fs
    return fs
end

local function Check(parent, x, y, key, get, set)
    local name = next_name("Check")
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local fs = _G[name .. "Text"]
    fs:SetFont(FONT, 12, "")
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and 1 or 0)
        OPTIONS:Refresh()
    end)
    cb.refresh = function()
        fs:SetText(WHITE .. T(key) .. R)
        cb:SetChecked(get() ~= 0)
    end
    widgets[#widgets + 1] = cb
    return cb
end

local function Slider(parent, x, y, key, minV, maxV, step, get, set, range)
    local name = next_name("Slider")
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetWidth(190)
    s:SetHeight(14)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:EnableMouseWheel(true)

    local title = _G[name .. "Text"]
    title:ClearAllPoints()
    title:SetPoint("BOTTOM", s, "TOP", 0, 1)
    title:SetFont(FONT, 11, "")
    local low, high = _G[name .. "Low"], _G[name .. "High"]
    local val = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    val:SetPoint("TOP", s, "BOTTOM", 0, -1)
    val:SetFont(FONT, 12, "")

    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        val:SetText(WHITE .. v .. R)
        if not syncing then set(v) end
    end)

    s:SetScript("OnMouseWheel", function(self, d)
        self:SetValue(self:GetValue() + d * step)
    end)
    s.refresh = function()
        local a, b = minV, maxV
        if range then a, b = range() end
        s:SetMinMaxValues(a, b)
        title:SetText(HDR .. T(key) .. R)
        low:SetText(GRAY .. a .. R)
        high:SetText(GRAY .. b .. R)
        local v = get()
        s:SetValue(v)
        val:SetText(WHITE .. v .. R)
    end
    widgets[#widgets + 1] = s
    return s
end

local function Btn(parent, x, y, w, h, label, onClick, selected)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    b:SetPoint("TOPLEFT", x, y)
    ApplyBackdrop(b, bdTitle, titleBg, titleBorder)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local fs = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetFont(FONT, 11, "")
    fs:SetPoint("LEFT", 6, 0)
    fs:SetPoint("RIGHT", -6, 0)
    local function paint(hover)
        local sel = selected and selected()
        fs:SetText(((hover or sel) and WHITE or GOLD) .. label() .. R)
        if sel then
            b:SetBackdropBorderColor(0.31, 0.76, 0.97, 1)
        else
            b:SetBackdropBorderColor(titleBorder[1], titleBorder[2], titleBorder[3], titleBorder[4])
        end
    end
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.15, 0.30, 0.90)
        paint(true)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(titleBg[1], titleBg[2], titleBg[3], titleBg[4])
        paint(false)
    end)
    b:SetScript("OnClick", function(self, button)
        onClick(button)
        OPTIONS:Refresh()
    end)
    b.refresh = function() paint(false) end
    widgets[#widgets + 1] = b
    return b
end

local function Cycle(parent, x, y, w, key, list, get, set)
    local function index()
        local cur = get()
        local items = list()
        for i, item in ipairs(items) do
            if item.value == cur then return i, items end
        end
        return 1, items
    end
    local function step(d)
        local i, items = index()
        if #items == 0 then return end
        i = (i - 1 + d) % #items + 1
        set(items[i].value)
    end
    local b = Btn(parent, x, y, w, 22, function()
        local i, items = index()
        local item = items[i]
        return T(key) .. ": " .. (item and item.text() or "-")
    end, function(button) step(button == "RightButton" and -1 or 1) end)
    b:EnableMouseWheel(true)
    b:SetScript("OnMouseWheel", function(self, d)
        step(d > 0 and -1 or 1)
        OPTIONS:Refresh()
    end)
    return b
end

local function LockBox(parent, x, y, w)
    local box = CreateFrame("Frame", nil, parent)
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(w, 30)
    box:EnableMouse(true)
    local bg = box:CreateTexture(nil, "ARTWORK")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetAllPoints()
    local edges = {}
    for i = 1, 4 do
        local t = box:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        edges[i] = t
    end
    edges[1]:SetPoint("TOPLEFT"); edges[1]:SetPoint("TOPRIGHT"); edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT"); edges[3]:SetPoint("BOTTOMLEFT"); edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT"); edges[4]:SetWidth(1)
    local label = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER")
    label:SetFont(FONT, 13, "")
    local function edge_color(r, g, b, a)
        for i = 1, 4 do edges[i]:SetVertexColor(r, g, b, a) end
    end
    box.refresh = function()
        if ADDON.DRAG_UNLOCK then
            label:SetText(HDR .. T("lock_frame") .. R)
            bg:SetVertexColor(0.03, 0.08, 0.20, 0.95)
            edge_color(0.25, 0.55, 0.90, 0.80)
        else
            label:SetText("|cffff4444" .. T("locked") .. R)
            bg:SetVertexColor(0.20, 0.02, 0.02, 0.95)
            edge_color(0.90, 0.20, 0.20, 1.00)
        end
    end
    box:SetScript("OnMouseUp", function()
        ADDON:ToggleDragUnlock()
        OPTIONS:Refresh()
    end)
    box:SetScript("OnEnter", function() edge_color(0.60, 0.85, 1.00, 1.00) end)
    box:SetScript("OnLeave", function() box.refresh() end)
    widgets[#widgets + 1] = box
    return box
end

local function TestBtn(parent, x, y, w)
    return Btn(parent, x, y, w, 24,
        function() return ADDON.TEST_MODE and T("test_on") or T("test") end,
        function() ADDON:SetTestMode(not ADDON.TEST_MODE) end,
        function() return ADDON.TEST_MODE end)
end

local function Fixed(text)
    return function() return text end
end

local function Tr(key)
    return function() return T(key) end
end

local panel, pages, current_page = nil, {}, 1
local TAB_KEYS = { "tab_general", "tab_items", "tab_units" }
local PAGE_TOP = -82

local function new_page()
    local p = CreateFrame("Frame", nil, panel)
    p:SetPoint("TOPLEFT", 0, PAGE_TOP)
    p:SetPoint("BOTTOMRIGHT", 0, 0)
    p:Hide()
    pages[#pages + 1] = p
    return p
end

local function show_page(i)
    current_page = i
    for n, p in ipairs(pages) do
        if n == i then p:Show() else p:Hide() end
    end
end

local function DimWhen(parent, list, active)
    local d = CreateFrame("Frame", nil, parent)
    d.refresh = function()
        local a = active() and 1 or 0.4
        for _, w in ipairs(list) do w:SetAlpha(a) end
    end
    widgets[#widgets + 1] = d
end

local function style_list(with_same)
    local items = {}
    if with_same then items[1] = { value = 0, text = Tr("same") } end
    items[#items + 1] = { value = 1, text = Fixed("Action Button") }
    items[#items + 1] = { value = 2, text = Fixed("Pixel") }
    items[#items + 1] = { value = 3, text = Fixed("Proc Glow") }
    return function() return items end
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function font_list()
    local items = { { value = ADDON.DEFAULT_FONT, text = Tr("default") } }
    if LSM then
        local fonts = LSM:HashTable("font")
        local names = {}
        for font_name in pairs(fonts) do names[#names + 1] = font_name end
        table.sort(names)
        for _, font_name in ipairs(names) do
            items[#items + 1] = { value = fonts[font_name], text = Fixed(font_name) }
        end
    end
    return items
end

local function build_swap(p, x, y)
    Header(p, x, y, "swap")
    local eb = CreateFrame("EditBox", "TrinketCDsOptSwap", p, "InputBoxTemplate")
    eb:SetPoint("TOPLEFT", x + 8, y - 18)
    eb:SetSize(230, 20)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEditFocusGained", function(self)
        self:RegisterEvent("CURSOR_UPDATE")
        self:RegisterEvent("ITEM_LOCKED")
    end)
    eb:SetScript("OnEditFocusLost", function(self) self:UnregisterEvent("CURSOR_UPDATE") end)
    eb:SetScript("OnEvent", function(self, event)
        if event == "ITEM_LOCKED" then
            self:UnregisterEvent("ITEM_LOCKED")
            ClearCursor()
        end
        local _, item_id, item_link = GetCursorInfo()
        if not item_id then return end
        self:UnregisterEvent("CURSOR_UPDATE")
        self:ClearFocus()
        if select(9, GetItemInfo(item_id)) ~= "INVTYPE_TRINKET" then return end
        self:SetText(item_link)
        _G.TrinketCDsProfileChar = _G.TrinketCDsProfileChar or {}
        _G.TrinketCDsProfileChar.trinket_swap_link = item_link
        ADDON.TRINKET_SWAP_ID = item_id
    end)
    eb.refresh = function()
        if eb:HasFocus() then return end
        local char = _G.TrinketCDsProfileChar
        eb:SetText(char and char.trinket_swap_link or DEFAULT_TRINKET_SWAP_LINK)
        eb:SetCursorPosition(0)
    end
    widgets[#widgets + 1] = eb
    Hint(p, x, y - 44, "swap_hint", 240)
end

local function build_profiles(p, y)
    Header(p, 16, y, "profile")
    local eb = CreateFrame("EditBox", "TrinketCDsOptProfile", p, "InputBoxTemplate")
    eb:SetPoint("TOPLEFT", 24, y - 20)
    eb:SetSize(180, 20)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)

    Cycle(p, 216, y - 19, 140, "pick", function()
        local items = {}
        for _, name in ipairs(ADDON:GetProfileList()) do
            items[#items + 1] = { value = name, text = Fixed(name) }
        end
        if #items == 0 then items[1] = { value = "", text = Tr("none") } end
        return items
    end, function() return eb:GetText() end, function(v) eb:SetText(v) end)

    local function with_name(fn)
        return function()
            local name = strtrim(eb:GetText() or "")
            if name == "" then return end
            fn(name)
        end
    end
    Btn(p, 362, y - 18, 58, 22, Tr("save"), with_name(function(n) ADDON:SaveCurrentProfile(n) end))
    Btn(p, 424, y - 18, 58, 22, Tr("load"), with_name(function(n) ADDON:LoadProfile(n) end))
    Btn(p, 486, y - 18, 60, 22, Tr("delete"), with_name(function(n) ADDON:DeleteProfile(n) end))
end

local function build_general(p)
    Header(p, 16, -6, "display")
    local y = -24
    for _, key in ipairs({ "COMBAT_ONLY", "HIDE_READY", "USE_ON_CLICK" }) do
        Check(p, 14, y, key,
            function() return SWITCHES[key] end,
            function(v) SWITCHES[key] = v; redraw_items() end)
        y = y - 26
    end

    Slider(p, 315, -24, "scale", 50, 200, 5,
        function() return SWITCHES.SCALE end,
        function(v) SWITCHES.SCALE = v; redraw_items() end)
    Cycle(p, 290, -60, 240, "font", font_list,
        function() return SWITCHES.FONT_FILE end,
        function(v) SWITCHES.FONT_FILE = v; redraw_items(); redraw_units() end)

    build_swap(p, 290, -100)
    build_profiles(p, -200)

    local fs = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", 16, -262)
    fs:SetText(GRAY .. "/tcd   ·   /tcd drag   ·   /tcd test   ·   /tcd help" .. R)
end

local REF_SLOT = 13

local function all_get(key)
    return function()
        local f = FRAMES[REF_SLOT]
        return f and f.settings[key] or 0
    end
end

local function all_set(key)
    return function(v)
        for _, f in pairs(FRAMES) do
            f.settings[key] = v
            f:RedrawFrame()
        end
    end
end

local function glow_on(frame)
    local v = frame.settings.PROC_GLOW
    return v == nil or v ~= 0
end

local function build_items(p)
    local list = CreateFrame("Frame", nil, p)
    list:SetAllPoints()
    local adv = CreateFrame("Frame", nil, p)
    adv:SetAllPoints()
    adv:Hide()

    Header(list, 16, -4, "items_hdr")
    for i, slot_ID in ipairs(ADDON.SORTED_ITEMS) do
        local frame = FRAMES[slot_ID]
        local s = frame.settings
        local y = -20 - (i - 1) * 24
        Check(list, 14, y, DB.ITEM_GROUP[slot_ID],
            function() return s.SHOW end,
            function(v) s.SHOW = v; frame:ToggleVisibility() end)
        local style = Cycle(list, 190, y - 2, 180, "style", style_list(true),
            function() return s.GLOW_STYLE or 0 end,
            function(v) s.GLOW_STYLE = v; frame:RedrawFrame(); refresh_procs() end)
        Check(list, 380, y, "glow_short",
            function() return glow_on(frame) and 1 or 0 end,
            function(v) s.PROC_GLOW = v; frame:RedrawFrame(); refresh_procs() end)
        Check(list, 466, y, "ilvl_short",
            function() return s.SHOW_ILVL end,
            function(v) s.SHOW_ILVL = v; frame:RedrawFrame() end)
        DimWhen(list, { style }, function() return SWITCHES.SHOW_PROC_GLOW ~= 0 and glow_on(frame) end)
    end

    local y0 = -222
    Header(list, 16, y0, "for_all")
    Check(list, 14, y0 - 18, "glow_enable",
        function() return SWITCHES.SHOW_PROC_GLOW end,
        function(v) SWITCHES.SHOW_PROC_GLOW = v; refresh_procs() end)
    local sub = {
        Cycle(list, 16, y0 - 46, 240, "main_style", style_list(false),
            function() return SWITCHES.PROC_GLOW_STYLE or 1 end,
            function(v) SWITCHES.PROC_GLOW_STYLE = v; refresh_procs(); redraw_units() end),
        Check(list, 14, y0 - 72, "outside",
            function() return SWITCHES.GLOW_OUTSIDE end,
            function(v) SWITCHES.GLOW_OUTSIDE = v; refresh_procs() end),
    }
    local off = Slider(list, 315, y0 - 70, "offset", 0, 10, 1,
        function() return SWITCHES.GLOW_OFFSET end,
        function(v) SWITCHES.GLOW_OFFSET = v; refresh_procs() end)
    DimWhen(list, sub, function() return SWITCHES.SHOW_PROC_GLOW ~= 0 end)
    DimWhen(list, { off }, function() return SWITCHES.SHOW_PROC_GLOW ~= 0 and SWITCHES.GLOW_OUTSIDE ~= 0 end)
    Slider(list, 315, y0 - 24, "ICON_SIZE", 20, 75, 1, all_get("ICON_SIZE"), all_set("ICON_SIZE"))

    Btn(list, 16, y0 - 104, 160, 22, function() return T("advanced") .. "  >" end,
        function() list:Hide(); adv:Show() end)

    Header(adv, 16, -4, "advanced")
    local sliders = {
        { "ZOOM", -200, 300, 5 }, { "CD_SIZE", 0, 100, 5 },
        { "BORDER_MARGIN", -5, 5, 1 }, { "ILVL_SIZE", 0, 100, 5 },
        { "EDGE_SIZE", 1, 30, 1 }, { "STACKS_SIZE", 0, 100, 5 },
    }
    for i, def in ipairs(sliders) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        Slider(adv, 30 + col * 270, -40 - row * 48, def[1], def[2], def[3], def[4],
            all_get(def[1]), all_set(def[1]))
    end
    local keys = { "STACKS_BOTTOM", "SHOW_DECIMALS", "FORCE30", "SHOW_PROC_ICON" }
    for i, key in ipairs(keys) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        Check(adv, 14 + col * 270, -176 - row * 26, key,
            function() return SWITCHES[key] end,
            function(v)
                SWITCHES[key] = v
                if key ~= "SHOW_DECIMALS" and key ~= "FORCE30" then redraw_items() end
                if key == "SHOW_PROC_ICON" then refresh_procs() end
            end)
    end
    Btn(adv, 16, -240, 160, 22, function() return "<  " .. T("back") end,
        function() adv:Hide(); list:Show() end)
end

local unit_key = "arena"

local function build_group(p, key)
    local c = key == "arena" and SETTINGS.ARENA or SETTINGS.PARTY
    local function get(k) return function() return c[k] end end
    local function set(k) return function(v) c[k] = v; redraw_units() end end
    local function on() return c.ENABLED ~= 0 end

    Check(p, 14, -4, key == "arena" and "arena_enable" or "party_enable", get("ENABLED"), set("ENABLED"))
    local main = {}
    local y = -30
    if key == "party" then
        main[#main + 1] = Check(p, 14, y, "arena_only", get("ARENA_ONLY"), set("ARENA_ONLY"))
        y = y - 26
    end
    main[#main + 1] = Check(p, 14, y, "show_pvp", get("SHOW_PVP"), set("SHOW_PVP"))
    main[#main + 1] = Slider(p, 30, -100, "scale", 50, 200, 5, get("SCALE"), set("SCALE"))
    main[#main + 1] = Slider(p, 30, -146, "ICON_SIZE", 16, 64, 1, get("ICON_SIZE"), set("ICON_SIZE"))
    main[#main + 1] = Slider(p, 30, -192, "spacing", 0, 20, 1, get("SPACING"), set("SPACING"))
    main[#main + 1] = Cycle(p, 16, -226, 240, "grow",
        function() return { { value = 0, text = Tr("right") }, { value = 1, text = Tr("left") } } end,
        get("GROW_LEFT"), set("GROW_LEFT"))
    DimWhen(p, main, on)
    Hint(p, 16, -258, key == "arena" and "arena_hint" or "party_hint", 520)

    Header(p, 292, -6, "glow")
    local g1 = Check(p, 290, -24, "glow_on", get("GLOW"), set("GLOW"))
    local s1 = Cycle(p, 292, -52, 250, "style", style_list(true), get("GLOW_STYLE"), set("GLOW_STYLE"))
    local g2 = Check(p, 290, -80, "glow_pvp", get("GLOW_PVP"), set("GLOW_PVP"))
    local s2 = Cycle(p, 292, -108, 250, "style_pvp", style_list(true), get("GLOW_STYLE_PVP"), set("GLOW_STYLE_PVP"))
    local out = Check(p, 290, -136, "outside", get("GLOW_OUTSIDE"), set("GLOW_OUTSIDE"))
    local off = Slider(p, 315, -182, "offset", 0, 10, 1, get("GLOW_OFFSET"), set("GLOW_OFFSET"))
    DimWhen(p, { g1, out }, on)
    DimWhen(p, { s1 }, function() return on() and c.GLOW ~= 0 end)
    DimWhen(p, { g2 }, function() return on() and c.SHOW_PVP ~= 0 end)
    DimWhen(p, { s2 }, function() return on() and c.SHOW_PVP ~= 0 and c.GLOW_PVP ~= 0 end)
    DimWhen(p, { off }, function() return on() and c.GLOW_OUTSIDE ~= 0 end)
end

local function build_units(p)
    local subs = {}
    for i, key in ipairs({ "arena", "party" }) do
        Btn(p, 16 + (i - 1) * 104, -4, 100, 22, Tr(key),
            function()
                unit_key = key
                for k, f in pairs(subs) do
                    if k == key then f:Show() else f:Hide() end
                end
            end,
            function() return unit_key == key end)
        local f = CreateFrame("Frame", nil, p)
        f:SetPoint("TOPLEFT", 0, -34)
        f:SetPoint("BOTTOMRIGHT")
        if key ~= unit_key then f:Hide() end
        subs[key] = f
        build_group(f, key)
    end
end

local function create_panel()
    panel = CreateFrame("Frame", "TrinketCDsOptionsPanel", UIParent)
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetPoint("CENTER")

    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetToplevel(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    ApplyBackdrop(panel, bdPanel, panelBg, panelBorder)

    local bar = CreateFrame("Frame", nil, panel)
    bar:SetHeight(26)
    bar:SetPoint("LEFT", panel, "TOP", -110, 0)
    bar:SetPoint("RIGHT", panel, "TOP", 110, 0)
    bar:SetFrameLevel(panel:GetFrameLevel() + 2)
    ApplyBackdrop(bar, bdTitle, titleBg, titleBorder)
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 0, 1)
    title:SetFont(FONT, 13, "OUTLINE")
    title:SetText(TITLE)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetFrameLevel(panel:GetFrameLevel() + 5)

    LockBox(panel, 14, -18, 240)
    TestBtn(panel, 262, -21, 160)

    local tab_w = math.floor((PANEL_W - 28) / #TAB_KEYS)
    for i, key in ipairs(TAB_KEYS) do
        Btn(panel, 14 + (i - 1) * tab_w, -54, tab_w - 4, 22, Tr(key),
            function() show_page(i) end,
            function() return current_page == i end)
    end

    build_general(new_page())
    build_items(new_page())
    build_units(new_page())

    panel:SetScript("OnShow", function() OPTIONS:Refresh() end)

    panel:SetScript("OnHide", function()
        if ADDON.TEST_MODE then ADDON:SetTestMode(false) end
    end)
    show_page(1)
    panel:Hide()
end

function OPTIONS:Refresh()
    if not panel or not panel:IsShown() then return end
    syncing = true
    for _, w in ipairs(widgets) do w.refresh() end
    syncing = false
end

function OPTIONS:Toggle()
    if not panel then create_panel() end
    if panel:IsShown() then panel:Hide() else panel:Show() end
end
