--[[
==================================================================================================
   SWIFT UI LIBRARY  ·  v2.6  (IMGUI-polished)
   A fully self-contained, loadstring-able Roblox UI library.
   Pixel-faithful recreation of the SWIFT menu mockup, generalised into a component library.
   v2.5: refined palette, larger radii, circular slider thumb, softer shadows,
         improved typography rhythm, smoother hover/press curves.
--------------------------------------------------------------------------------------------------
   USAGE

      local SWIFT = loadstring(game:HttpGet("<raw-url-to-this-file>"))()

      local Window = SWIFT:CreateWindow({ Title = "SWIFT" })
      local Tab    = Window:AddTab({ Name = "Aim", Icon = "lucide-crosshair" })
      local Card   = Tab:AddCard({ Title = "Aimbot", Tag = "MAIN MODULE" })

      Card:AddToggle({ Name = "Enable Aimbot", Default = true, Flag = "aim",
                       Callback = function(v) print(v) end })

      -- Always present, for free, with zero extra code:
      --   * a show/hide hotkey (default F1) - no on-screen button, the bind is the bind
      --   * a hard-coded "Settings" tab (Menu / Window / Config cards)
      --   * UI settings that save to SWIFT/<ConfigName>.json and reload on next run
      Window:SettingsCard({ Title = "My Script" })   -- add your own rows to that tab

--------------------------------------------------------------------------------------------------
   DESIGN RULES BAKED INTO THIS LIBRARY
     • NO text glyphs. Every non-word mark is a Lucide icon (ImageLabel).
     • Every object carrying a UIGradient uses a WHITE base colour, because a UIGradient
       MULTIPLIES with BackgroundColor3 (dark base x bright gradient = black).
     • The shell is an unscaled CanvasGroup; a child "scaler" Frame carries the UIScale, so
       drag maths stays 1:1 with pixels no matter what Scale the user picks.
     • rbxthumb only accepts fixed sizes: GameIcon 50/150, AvatarHeadShot 48/60/150.
==================================================================================================
]]

local SWIFT = {}
SWIFT.__index = SWIFT
SWIFT.Version = "2.6.0"
SWIFT.Flags   = {}
SWIFT.Windows = {}

--================================================================================================
-- SERVICES
--================================================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local WHITE       = Color3.fromRGB(255, 255, 255)

--================================================================================================
-- ICON REGISTRY  —  Lucide, packaged as Roblox asset IDs (Tarmac manifest).
-- Anything not found here falls through to "" (invisible) rather than erroring.
--================================================================================================
local ICONS = {
        ["lucide-crosshair"]          = "rbxassetid://10709818534",
        ["lucide-eye"]                = "rbxassetid://10723346959",
        ["lucide-eye-off"]            = "rbxassetid://10723346871",
        ["lucide-users"]              = "rbxassetid://10747373426",
        ["lucide-user"]               = "rbxassetid://10747373176",
        ["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
        ["lucide-sliders"]            = "rbxassetid://10734963400",
        ["lucide-settings"]           = "rbxassetid://10734950309",
        ["lucide-settings-2"]         = "rbxassetid://10734950020",
        ["lucide-check"]              = "rbxassetid://10709790644",
        ["lucide-check-square"]       = "rbxassetid://10709790537",
        ["lucide-square"]             = "rbxassetid://10734965702",
        ["lucide-chevron-down"]       = "rbxassetid://10709790948",
        ["lucide-chevron-up"]         = "rbxassetid://10709791523",
        ["lucide-chevron-right"]      = "rbxassetid://10709791437",
        ["lucide-pipette"]            = "rbxassetid://10734922497",
        ["lucide-palette"]            = "rbxassetid://10734910430",
        ["lucide-keyboard"]           = "rbxassetid://10723416765",
        ["lucide-text-cursor-input"]  = "rbxassetid://10734982297",
        ["lucide-hash"]               = "rbxassetid://10723405975",
        ["lucide-x"]                  = "rbxassetid://10747384394",
        ["lucide-x-circle"]           = "rbxassetid://10747383819",
        ["lucide-minus"]              = "rbxassetid://10734896206",
        ["lucide-plus"]               = "rbxassetid://10734924532",
        ["lucide-move"]               = "rbxassetid://10734900011",
        ["lucide-list-checks"]        = "rbxassetid://10734884548",
        ["lucide-zap"]                = "rbxassetid://10723345749",
        ["lucide-shield"]             = "rbxassetid://10734951847",
        ["lucide-shield-alert"]       = "rbxassetid://10734951173",
        ["lucide-swords"]             = "rbxassetid://10734975692",
        ["lucide-target"]             = "rbxassetid://10734977012",
        ["lucide-map"]                = "rbxassetid://10734886202",
        ["lucide-gamepad-2"]          = "rbxassetid://10723395215",
        ["lucide-bell"]               = "rbxassetid://10709775704",
        ["lucide-info"]               = "rbxassetid://10723415903",
        ["lucide-alert-triangle"]     = "rbxassetid://10709753149",
        ["lucide-check-circle"]       = "rbxassetid://10709790387",
        ["lucide-folder"]             = "rbxassetid://10723387563",
        ["lucide-save"]               = "rbxassetid://10734941499",
        ["lucide-trash-2"]            = "rbxassetid://10747362241",
        ["lucide-refresh-cw"]         = "rbxassetid://10734933222",
        ["lucide-power"]              = "rbxassetid://10734930466",
        ["lucide-monitor"]            = "rbxassetid://10734896881",
        ["lucide-wrench"]             = "rbxassetid://10747383470",
        ["lucide-flame"]              = "rbxassetid://10723376114",
        ["lucide-skull"]              = "rbxassetid://10734962068",
        ["lucide-radar"]              = "rbxassetid://10734931596",
        ["lucide-navigation"]         = "rbxassetid://10734906744",
        ["lucide-box"]                = "rbxassetid://10709782497",
        ["lucide-star"]               = "rbxassetid://10734966248",
        ["lucide-heart"]              = "rbxassetid://10723406885",
        ["lucide-lock"]               = "rbxassetid://10723434711",
        ["lucide-unlock"]             = "rbxassetid://10747366027",
        ["lucide-search"]             = "rbxassetid://10734943674",
        ["lucide-filter"]             = "rbxassetid://10723375128",
        ["lucide-clock"]              = "rbxassetid://10709805144",
        ["lucide-mouse-pointer"]      = "rbxassetid://10734898476",
        ["lucide-git-branch"]         = "rbxassetid://10723396676",
        ["lucide-terminal"]           = "rbxassetid://10734982144",
        ["lucide-image"]              = "rbxassetid://10723415040",
        ["lucide-layers"]             = "rbxassetid://10723424505",
        ["lucide-activity"]           = "rbxassetid://10709752035",
        ["lucide-cpu"]                = "rbxassetid://10709813383",
        ["lucide-globe"]              = "rbxassetid://10723404337",
        ["lucide-volume-2"]           = "rbxassetid://10747375679",
        ["lucide-sun"]                = "rbxassetid://10734974297",
        ["lucide-moon"]               = "rbxassetid://10734897102",
        ["lucide-menu"]               = "rbxassetid://10734887784",
        ["lucide-rotate-ccw"]         = "rbxassetid://10734940376",
        ["lucide-undo-2"]             = "rbxassetid://10747365359",
        ["lucide-download"]           = "rbxassetid://10723344270",
        ["lucide-upload"]             = "rbxassetid://10747366434",
        ["lucide-log-out"]            = "rbxassetid://10723434906",
        ["lucide-grip-vertical"]      = "rbxassetid://10723405236",
        ["lucide-maximize"]           = "rbxassetid://10734886735",
        ["lucide-minimize"]           = "rbxassetid://10734895698",
        ["lucide-circle"]             = "rbxassetid://10709798174",
        ["lucide-copy"]               = "rbxassetid://10709812159",
        ["lucide-file-text"]          = "rbxassetid://10723367380",
        ["lucide-pin"]                = "rbxassetid://10734922324",
        ["lucide-toggle-left"]        = "rbxassetid://10734984834",
        ["lucide-toggle-right"]       = "rbxassetid://10734985040",
        ["lucide-hard-drive"]         = "rbxassetid://10723405749",
        ["lucide-database"]           = "rbxassetid://10709818996",
        ["lucide-list"]               = "rbxassetid://10723433811",
        ["lucide-more-horizontal"]    = "rbxassetid://10734897250",
        ["lucide-type"]               = "rbxassetid://10747364761",
}
SWIFT.Icons = ICONS

--  Register your own icons (or override):  SWIFT:AddIcons({ ["my-icon"] = "rbxassetid://123" })
function SWIFT:AddIcons(map)
        for k, v in pairs(map or {}) do ICONS[k] = v end
        return self
end

-- Accepts:  "lucide-eye"  |  "rbxassetid://123"  |  123  |  "123"
local function resolveIcon(id)
        if id == nil or id == "" then return "" end
        if typeof(id) == "number" then return "rbxassetid://" .. id end
        id = tostring(id)
        if ICONS[id] then return ICONS[id] end
        if id:match("^rbx") then return id end
        if id:match("^%d+$") then return "rbxassetid://" .. id end
        return ""
end

--================================================================================================
-- HEADER ARTWORK PRESETS
--   Real, verified Roblox image assets. "Phantom Forces" is the platform's flagship military
--   FPS (universe 113491250) — its approved store media are public image assets, which is the
--   closest fit to the mockup's `thumb.jpg` CS2/COD-style banner.
--   rbxthumb sizes are strict: GameIcon = 50 or 150 ONLY. Anything else throws
--   "invalid thumbnail size for type GameIcon".
--================================================================================================
local HEADER_PRESETS = {
        fps       = "rbxassetid://84002005539076",   -- Phantom Forces media #1 (military FPS scene)
        fps2      = "rbxassetid://121151855138844",  -- Phantom Forces media #2
        fps3      = "rbxassetid://92914209541816",   -- Phantom Forces media #3
        fps4      = "rbxassetid://114367387424044",  -- Phantom Forces media #4
        fps5      = "rbxassetid://124665374954961",  -- Phantom Forces media #5
        warzone   = "rbxassetid://140122780081981",  -- Phantom Forces media #6
        combat    = "rbxassetid://87026675997537",   -- Phantom Forces media #7
        pficon    = "rbxthumb://type=GameIcon&id=113491250&w=150&h=150",
        gameicon  = "AUTO_GAME",                     -- resolved at runtime from game.GameId
        avatar    = "AUTO_AVATAR",                   -- resolved at runtime from LocalPlayer.UserId
        none      = "",
}
SWIFT.HeaderPresets = HEADER_PRESETS

local function resolveHeaderImage(v)
        if v == nil then return HEADER_PRESETS.fps end
        if typeof(v) == "number" then return "rbxassetid://" .. v end
        v = tostring(v)
        if HEADER_PRESETS[v] then v = HEADER_PRESETS[v] end
        if v == "AUTO_GAME" then
                local id = tonumber(game.GameId) or 0
                -- GameIcon supports 50 and 150 only
                return id > 0 and ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(id) or ""
        elseif v == "AUTO_AVATAR" then
                local id = tonumber(LocalPlayer and LocalPlayer.UserId) or 0
                -- AvatarHeadShot supports 48, 60, 150 only
                return id > 0 and ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(id) or ""
        end
        if v == "" or v:match("^rbx") then return v end
        if v:match("^%d+$") then return "rbxassetid://" .. v end
        return v
end

--================================================================================================
-- THEMES  —  pick by name or pass a table; any missing key inherits from Midnight.
--================================================================================================
local THEMES = {}

THEMES.Midnight = {                                    -- v2.5 refined palette — richer, softer, more depth
        Background        = Color3.fromRGB( 22,  22,  28),   -- slightly deeper shell for more contrast
        Border            = Color3.fromRGB( 46,  46,  56),   -- softer outer border
        HeaderBorder      = Color3.fromRGB( 40,  40,  50),
        Row               = Color3.fromRGB( 30,  30,  38),   -- card row surface
        RowHover          = Color3.fromRGB( 38,  38,  48),   -- clearer hover lift
        Text              = Color3.fromRGB(228, 228, 234),   -- brighter primary text
        SubText           = Color3.fromRGB(192, 192, 202),
        Label             = Color3.fromRGB(168, 168, 180),
        Muted             = Color3.fromRGB(124, 124, 136),
        Accent            = Color3.fromRGB(232,  56,  95),   -- more vibrant accent
        AccentDark        = Color3.fromRGB(108,  22,  44),
        ToggleOff         = Color3.fromRGB( 40,  40,  48),
        TrackEmpty        = Color3.fromRGB( 52,  52,  62),
        Control           = Color3.fromRGB( 36,  36,  44),
        ControlHover      = Color3.fromRGB( 46,  46,  56),
        ControlPress      = Color3.fromRGB( 28,  28,  36),
        ControlBorder     = Color3.fromRGB( 48,  48,  58),
        ControlBorderHover= Color3.fromRGB( 72,  72,  86),
        Caret             = Color3.fromRGB(136, 136, 150),
        NavInactive       = Color3.fromRGB(140, 140, 152),
        NavActive         = Color3.fromRGB(244, 244, 248),
        RangeLabel        = Color3.fromRGB(162, 162, 174),
        RangeValue        = Color3.fromRGB(172, 172, 184),
        ControlText       = Color3.fromRGB(202, 202, 212),
        DropdownBg        = Color3.fromRGB( 18,  18,  24),   -- deeper, near-black menu surface
        DropdownBorder    = Color3.fromRGB( 44,  44,  54),
        MenuText          = Color3.fromRGB(156, 156, 168),
        MenuTextHover     = Color3.fromRGB(255, 255, 255),
        MenuHover         = Color3.fromRGB(255, 255, 255),
        PickerA           = Color3.fromRGB( 50,  50,  60),
        PickerB           = Color3.fromRGB( 26,  26,  34),
        PickerBorder      = Color3.fromRGB( 78,  78,  92),
        Divider           = Color3.fromRGB( 56,  56,  66),
        Thumb             = Color3.fromRGB(232, 232, 236),
}

local function derive(base, over)
        local t = {}
        for k, v in pairs(base) do t[k] = v end
        for k, v in pairs(over) do t[k] = v end
        return t
end

THEMES.Obsidian = derive(THEMES.Midnight, {
        Background = Color3.fromRGB(16, 16, 19), Row = Color3.fromRGB(25, 25, 30),
        RowHover = Color3.fromRGB(31, 31, 37), Control = Color3.fromRGB(28, 28, 34),
        ControlHover = Color3.fromRGB(37, 37, 44), Accent = Color3.fromRGB(120, 190, 255),
        AccentDark = Color3.fromRGB(20, 60, 100), Border = Color3.fromRGB(38, 38, 46),
})
THEMES.Crimson = derive(THEMES.Midnight, {
        Accent = Color3.fromRGB(226, 46, 62), AccentDark = Color3.fromRGB(94, 14, 22),
})
THEMES.Emerald = derive(THEMES.Midnight, {
        Accent = Color3.fromRGB(52, 208, 130), AccentDark = Color3.fromRGB(14, 78, 52),
})
THEMES.Amethyst = derive(THEMES.Midnight, {
        Accent = Color3.fromRGB(162, 60, 225), AccentDark = Color3.fromRGB(62, 20, 92),
})
THEMES.Ocean = derive(THEMES.Midnight, {
        Background = Color3.fromRGB(18, 24, 33), Row = Color3.fromRGB(26, 34, 46),
        RowHover = Color3.fromRGB(32, 42, 56), Control = Color3.fromRGB(29, 38, 51),
        ControlHover = Color3.fromRGB(38, 50, 66), Accent = Color3.fromRGB(56, 170, 226),
        AccentDark = Color3.fromRGB(16, 60, 88), Border = Color3.fromRGB(40, 52, 68),
})
THEMES.Sandstorm = derive(THEMES.Midnight, {
        Background = Color3.fromRGB(30, 27, 22), Row = Color3.fromRGB(41, 37, 30),
        RowHover = Color3.fromRGB(49, 44, 36), Control = Color3.fromRGB(45, 40, 32),
        ControlHover = Color3.fromRGB(56, 50, 40), Accent = Color3.fromRGB(228, 160, 54),
        AccentDark = Color3.fromRGB(92, 60, 14), Border = Color3.fromRGB(58, 52, 42),
})
THEMES.Monochrome = derive(THEMES.Midnight, {
        Accent = Color3.fromRGB(226, 226, 232), AccentDark = Color3.fromRGB(90, 90, 96),
})
SWIFT.Themes = THEMES

function SWIFT:AddTheme(name, tbl)
        THEMES[name] = derive(THEMES.Midnight, tbl or {})
        return self
end

--================================================================================================
-- SMALL HELPERS
--================================================================================================
local function inst(class, props, parent)
        local o = Instance.new(class)
        if props then for k, v in pairs(props) do o[k] = v end end
        if parent then o.Parent = parent end
        return o
end

local function getViewport()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function pointIn(gui, x, y)
        local p, s = gui.AbsolutePosition, gui.AbsoluteSize
        return x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y
end

local function hsvToColor(h, s, v) return Color3.fromHSV(h % 1, s, v) end

local function hslToColor(h, s, l)
        local c = (1 - math.abs(2 * l - 1)) * s
        local hp = (h % 360) / 60
        local x = c * (1 - math.abs((hp % 2) - 1))
        local r, g, b
        if     hp < 1 then r, g, b = c, x, 0
        elseif hp < 2 then r, g, b = x, c, 0
        elseif hp < 3 then r, g, b = 0, c, x
        elseif hp < 4 then r, g, b = 0, x, c
        elseif hp < 5 then r, g, b = x, 0, c
        else               r, g, b = c, 0, x end
        local m = l - c / 2
        return Color3.new(r + m, g + m, b + m)
end

local function toHex(c)
        return ("#%02X%02X%02X"):format(
                math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local MOUSE_NAMES = {
        [Enum.UserInputType.MouseButton1] = "MOUSE 1",
        [Enum.UserInputType.MouseButton2] = "MOUSE 2",
        [Enum.UserInputType.MouseButton3] = "MOUSE 3",
}
--  Left and right modifiers are DISTINCT bindings and must have distinct labels.
--  They used to share one ("SHIFT"), which round-tripped through a save as LeftShift —
--  so a script that bound RightShift lost its toggle key the moment a config existed.
local PRETTY_KEYS = {
        LeftControl = "LCTRL",  RightControl = "RCTRL",
        LeftShift   = "LSHIFT", RightShift   = "RSHIFT",
        LeftAlt     = "LALT",   RightAlt     = "RALT",
        LeftSuper   = "LWIN",   RightSuper   = "RWIN",
        Return = "ENTER", KeypadEnter = "NUMENTER", Backspace = "BACK", Delete = "DEL",
        Insert = "INSERT", PageUp = "PG UP", PageDown = "PG DN", Escape = "ESC",
        CapsLock = "CAPS", Tab = "TAB", Home = "HOME", End = "END",
        Up = "UP", Down = "DOWN", Left = "LEFT", Right = "RIGHT",
}
local function keyName(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
                local k = input.KeyCode.Name
                if k == "Unknown" then return nil end
                if k == "Escape" then return false end           -- false = cancel
                if k == "Space" then return "SPACE" end
                return PRETTY_KEYS[k] or k:upper()
        end
        return MOUSE_NAMES[input.UserInputType]
end

--  The inverse of keyName(): "F1" / "CTRL" / "MOUSE 2" -> Enum.KeyCode | Enum.UserInputType.
--  Needed because saved configs store the PRETTY label, and the toggle-key binding has
--  to be reconstructed from it on load.
--  Built by inverting PRETTY_KEYS, so the two tables can never drift apart. The bare
--  "SHIFT"/"CTRL"/"ALT" forms are kept as legacy input aliases (they map to the left-hand
--  key) so older saved configs and hand-written strings still load.
local KEY_ALIASES = {
        SPACE = "Space",
        CTRL = "LeftControl", SHIFT = "LeftShift", ALT = "LeftAlt", WIN = "LeftSuper",
}
for enumName, label in pairs(PRETTY_KEYS) do KEY_ALIASES[label] = enumName end
local function keyFromName(name)
        if typeof(name) == "EnumItem" then return name end
        if type(name) ~= "string" or name == "" or name:upper() == "NONE" then return nil end
        local n = name:upper()
        for ut, label in pairs(MOUSE_NAMES) do if label == n then return ut end end
        local alias = KEY_ALIASES[n]
        if alias then return Enum.KeyCode[alias] end
        local ok, item = pcall(function() return Enum.KeyCode[name] end)
        if ok and item then return item end
        for _, k in ipairs(Enum.KeyCode:GetEnumItems()) do
                if k.Name:upper() == n then return k end
        end
        return nil
end
local function prettyKey(k)
        if typeof(k) == "EnumItem" then
                if k.EnumType == Enum.UserInputType then return MOUSE_NAMES[k] or k.Name:upper() end
                if k.Name == "Space" then return "SPACE" end
                return PRETTY_KEYS[k.Name] or k.Name:upper()
        end
        return tostring(k or "NONE"):upper()
end

local function round(n, dp)
        local m = 10 ^ (dp or 0)
        return math.floor(n * m + 0.5) / m
end

local function fmtNumber(n, dp)
        if (dp or 0) <= 0 then return tostring(math.floor(n + 0.5)) end
        return string.format("%." .. dp .. "f", n)
end

-- safest available parent for the ScreenGui
local function guiParent()
        local ok, res = pcall(function()
                if gethui then return gethui() end
                if RunService:IsStudio() then
                        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
                end
                return CoreGui
        end)
        if ok and res then return res end
        return LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
end

--================================================================================================
-- PERSISTENCE  —  the UI settings save themselves, with no work from the host script.
--
--   Executors expose  writefile / readfile / isfile / makefolder / isfolder / delfile.
--   Studio exposes none of them, so we transparently fall back to an in-memory store
--   (settings then survive :SetTheme etc. for the session but not a rejoin) and, when
--   available, to the player's local `plugin`-free alternative: nothing. Studio users
--   simply get session-only persistence, which is the correct silent degradation.
--
--   Layout:  SWIFT/<Namespace>.json      Namespace defaults to the window Title.
--================================================================================================
local FS = {}
do
        local function has(fn) return typeof(fn) == "function" end
        FS.write   = has(writefile)   and writefile   or nil
        FS.read    = has(readfile)    and readfile    or nil
        FS.isfile  = has(isfile)      and isfile      or nil
        FS.isdir   = has(isfolder)    and isfolder    or nil
        FS.mkdir   = has(makefolder)  and makefolder  or nil
        FS.delete  = has(delfile)     and delfile     or nil
        FS.Available = (FS.write ~= nil and FS.read ~= nil)
end

local MEMSTORE = {}          -- fallback when the executor has no filesystem
SWIFT.ConfigFolder = "SWIFT"

local function cfgPath(ns)
        return SWIFT.ConfigFolder .. "/" .. tostring(ns):gsub("[^%w_%-%. ]", "_") .. ".json"
end

local function ensureFolder()
        if not FS.Available or not FS.mkdir then return end
        pcall(function()
                if FS.isdir and not FS.isdir(SWIFT.ConfigFolder) then FS.mkdir(SWIFT.ConfigFolder) end
        end)
end

--  Color3 is not JSON-serialisable; encode it as a tagged table so a round-trip is lossless.
local function encodeValue(v)
        if typeof(v) == "Color3" then
                return { __t = "Color3", r = v.R, g = v.G, b = v.B }
        elseif typeof(v) == "EnumItem" then
                return { __t = "Enum", e = tostring(v.EnumType), n = v.Name }
        elseif type(v) == "table" then
                local out = {}
                for k, sub in pairs(v) do out[tostring(k)] = encodeValue(sub) end
                return out
        end
        return v
end

local function decodeValue(v)
        if type(v) == "table" then
                if v.__t == "Color3" then return Color3.new(v.r or 0, v.g or 0, v.b or 0) end
                if v.__t == "Enum" then
                        local ok, item = pcall(function()
                                return Enum[(v.e or ""):gsub("^Enum%.", "")][v.n]
                        end)
                        if ok then return item end
                        return nil
                end
                local out = {}
                for k, sub in pairs(v) do out[k] = decodeValue(sub) end
                return out
        end
        return v
end

--  Both return (ok, errOrData). Never throw — a broken/locked file must not kill the script.
local function saveJSON(ns, tbl)
        local ok, encoded = pcall(function()
                return HttpService:JSONEncode(encodeValue(tbl))
        end)
        if not ok then return false, encoded end
        MEMSTORE[ns] = encoded
        if not FS.Available then return true, "memory" end
        ensureFolder()
        local wrote = pcall(FS.write, cfgPath(ns), encoded)
        return wrote, wrote and "file" or "write failed"
end

local function loadJSON(ns)
        local raw = nil
        if FS.Available then
                local ok, exists = pcall(function() return FS.isfile and FS.isfile(cfgPath(ns)) end)
                if not ok or exists ~= false then
                        local rok, data = pcall(FS.read, cfgPath(ns))
                        if rok and type(data) == "string" and data ~= "" then raw = data end
                end
        end
        if raw == nil then raw = MEMSTORE[ns] end
        if raw == nil then return nil end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(decoded) ~= "table" then return nil end
        return decodeValue(decoded)
end

local function deleteJSON(ns)
        MEMSTORE[ns] = nil
        if FS.Available and FS.delete then pcall(FS.delete, cfgPath(ns)) end
end

--  Public: read/scrub a saved UI config without owning a window.
function SWIFT:GetSavedConfig(ns) return loadJSON(ns) end
function SWIFT:DeleteSavedConfig(ns) deleteJSON(ns); return self end

--================================================================================================
-- WINDOW
--================================================================================================
local Window = {}
Window.__index = Window

--[[  SWIFT:CreateWindow{
        Title="SWIFT", SubTitle="BETA"(default nil = hidden), Theme="Midnight",
        Size=UDim2/Vector2, Scale=1.42, Accent=Color3, ToggleKey=Enum.KeyCode.F1,
        HeaderImage="fps"|assetid|false, HeaderImageTransparency=0.72,
        Draggable=true, ShowPageTitle=false, Center=true, Position=UDim2
      }  ]]
function SWIFT:CreateWindow(cfg)
        cfg = cfg or {}

        local self = setmetatable({}, Window)

        -- ---------- SAVED UI CONFIG -------------------------------------------------------
        --  Loaded FIRST so the window is built at the saved theme/scale/position instead of
        --  being built at the defaults and then visibly snapping into place.
        --  Namespace: cfg.ConfigName -> cfg.Name -> cfg.Title -> "SWIFT".
        --  Opt out entirely with SaveConfig = false.
        local origCfg = {}
        for k, v in pairs(cfg) do origCfg[k] = v end

        self.ConfigName  = cfg.ConfigName or cfg.Name or cfg.Title or "SWIFT"
        self.SaveEnabled = cfg.SaveConfig ~= false
        self.AutoSave    = cfg.AutoSave ~= false
        local saved = (self.SaveEnabled and cfg.LoadConfig ~= false) and loadJSON(self.ConfigName) or nil
        self.SavedConfig = saved
        if saved then
                if type(saved.Theme) == "string" and THEMES[saved.Theme] then cfg.Theme = saved.Theme end
                if typeof(saved.Accent) == "Color3" then cfg.Accent = saved.Accent end
                if tonumber(saved.Scale) then cfg.Scale = tonumber(saved.Scale) end
                if saved.HeaderImage ~= nil then cfg.HeaderImage = saved.HeaderImage end
                if saved.ToggleKey ~= nil then cfg.ToggleKey = keyFromName(saved.ToggleKey) or cfg.ToggleKey end
                if type(saved.Position) == "table" and saved.Position.XO then
                        cfg.Position = UDim2.new(saved.Position.XS or 0.5, saved.Position.XO or 0,
                                                 saved.Position.YS or 0.5, saved.Position.YO or 0)
                end
                if saved.AutoSave ~= nil then cfg.AutoSave = saved.AutoSave end
        end
        if cfg.AutoSave ~= nil then self.AutoSave = cfg.AutoSave ~= false end

        -- ---------- theme ----------
        local theme
        if typeof(cfg.Theme) == "table" then      theme = derive(THEMES.Midnight, cfg.Theme)
        elseif THEMES[cfg.Theme] then             theme = derive(THEMES[cfg.Theme], {})
        else                                      theme = derive(THEMES.Midnight, {}) end
        self.ThemeName = (type(cfg.Theme) == "string" and THEMES[cfg.Theme]) and cfg.Theme or "Midnight"
        if cfg.Accent then theme.Accent = cfg.Accent end
        if cfg.AccentDark then theme.AccentDark = cfg.AccentDark end
        self.Theme  = theme
        self.Accent = theme.Accent

        -- ---------- geometry ----------
        local W, H = 322, 332           -- v2.5: slightly larger base for better breathing room
        if typeof(cfg.Size) == "Vector2" then W, H = cfg.Size.X, cfg.Size.Y
        elseif typeof(cfg.Size) == "UDim2" then W, H = cfg.Size.X.Offset, cfg.Size.Y.Offset end
        local S = cfg.Scale or 1.42

        self.BaseW, self.BaseH, self.S = W, H, S
        self.Config    = cfg
        self.Tabs      = {}
        self.TabOrder  = {}
        self.Flags     = SWIFT.Flags
        self._accentFns= {}
        self._themeFns = {}
        self._conns    = {}
        self._persist  = {}                -- flag -> component api, for save/load
        self.HeaderImageName = cfg.HeaderImage
        --  What ResetConfig() restores. Captured from the ORIGINAL call, before the saved
        --  config was merged in, so "reset" means "how the script author shipped it".
        self._defaults = {
                Theme = (type(origCfg.Theme) == "string" and origCfg.Theme) or "Midnight",
                Accent = origCfg.Accent, Scale = origCfg.Scale or 1.42,
                HeaderImage = origCfg.HeaderImage, ToggleKey = origCfg.ToggleKey,
                Position = origCfg.Position,
        }
        self.Font       = cfg.Font       or Enum.Font.Gotham
        self.FontMedium = cfg.FontMedium or Enum.Font.GothamMedium
        self.FontBold   = cfg.FontBold   or Enum.Font.GothamBold
        self.FontBlack  = cfg.FontBlack  or Enum.Font.GothamBlack

        -- ---------- screen gui ----------
        local screen = inst("ScreenGui", {
                Name = cfg.Name or ("SWIFT_" .. tostring(math.random(100000, 999999))),
                ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = cfg.DisplayOrder or 999,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        pcall(function() screen.Parent = guiParent() end)
        if not screen.Parent then screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        self.ScreenGui = screen

        -- ---------- shell (unscaled: keeps drag maths in real pixels) ----------
        --  Size stays in BASE units forever; the UIScale below does all the scaling.
        local shell = inst("CanvasGroup", {
                Name = "shell", BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.fromOffset(W, H),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = cfg.Position or UDim2.fromScale(0.5, 0.5),
                ClipsDescendants = true, GroupTransparency = 0, ZIndex = 5,
        }, screen)
        -- IMGUI: tight, subtle shell shadow
        local shadow = inst("ImageLabel", {
                Name = "shellShadow", BackgroundTransparency = 1, ZIndex = 4,
                Image = "rbxassetid://1316045217",
                ImageColor3 = Color3.fromRGB(0, 0, 0),
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(10, 10, 118, 118),
                Size = UDim2.new(1, 10, 1, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Visible = false,
        }, screen)
        self.ShellShadow = shadow
        --  THE one and only scale carrier. A UIScale scales the object it sits in plus
        --  every descendant, so the shell, its background and all controls are a single
        --  unit. Nothing else may ever encode size.
        local shellScale = inst("UIScale", { Scale = S }, shell)
        local CR = cfg.CornerRadius or 5                 -- v2.5: rounder shell (was 3)
        inst("UICorner", { CornerRadius = UDim.new(0, CR) }, shell)
        local shellStroke = inst("UIStroke", { Color = theme.Border, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, shell)
        --  Plain container, NO UIScale of its own — it simply inherits the shell's.
        local scaler = inst("Frame", { Name = "scaler", BackgroundTransparency = 1, BorderSizePixel = 0,
                ZIndex = 1, Size = UDim2.fromScale(1, 1) }, shell)
        local shellBg = inst("Frame", { Name = "bg", BackgroundColor3 = theme.Background,
                BorderSizePixel = 0, ZIndex = -1, Size = UDim2.fromScale(1, 1) }, scaler)
        inst("UICorner", { CornerRadius = UDim.new(0, CR) }, shellBg)

        self.Shell, self.ShellBg, self.Scaler, self.ShellScale = shell, shellBg, scaler, shellScale

        --  ---------------------------------------------------------------------------
        --  SCALE OWNERSHIP  —  ONE property, one writer.
        --  self.S     = the scale the user asked for  (authoritative)
        --  self._bias = transient cosmetic multiplier (drag lift, hide shrink)
        --  The ONLY thing that encodes size is ShellScale.Scale = S * bias, applied by
        --  _render() and re-asserted every Heartbeat. Shell.Size is a constant in base
        --  units and is never written, so there is no second value to fall out of sync.
        --  ---------------------------------------------------------------------------
        self._bias = 1
        self:_render()
        table.insert(self._conns, RunService.Heartbeat:Connect(function()
                self:_render()
        end))
        self:_onTheme(function(t)
                shellBg.BackgroundColor3 = t.Background
                shellStroke.Color = t.Border
        end)

        --============================================================================================
        -- HEADER
        --============================================================================================
        local headerH = cfg.HeaderHeight or 32                 -- v2.5: slightly taller header (was 29)
        local header = inst("Frame", { Name = "header", Size = UDim2.new(1, 0, 0, headerH),
                BackgroundTransparency = 1, ZIndex = 4, ClipsDescendants = true }, scaler)
        local headerStroke = inst("UIStroke", { Color = theme.HeaderBorder, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, header)
        self.Header = header
        self:_onTheme(function(t) headerStroke.Color = t.HeaderBorder end)

        ------------------------------------------------------------------------------------
        --  HEADER ARTWORK  —  the mockup's `.shell:before`
        --      background: linear-gradient(130deg,#7775,#1111), url('thumb.jpg') center/cover;
        --      opacity:.23; filter:grayscale(1)
        --  A real military-FPS image, greyed and faded left→right so the tabs stay readable.
        ------------------------------------------------------------------------------------
        if cfg.HeaderImage ~= false then
                local img = resolveHeaderImage(cfg.HeaderImage)
                if img ~= "" then
                        local artW = cfg.HeaderImageWidth       -- nil = span the whole bar
                        local art = inst("ImageLabel", {
                                Name = "headerArt", BackgroundTransparency = 1, ZIndex = 1, Active = false,
                                Size = artW and UDim2.fromOffset(artW, headerH) or UDim2.new(1, 0, 0, headerH),
                                Position = UDim2.fromOffset(0, 0),
                                Image = img, ScaleType = Enum.ScaleType.Crop,     -- center / cover
                                ImageColor3 = cfg.HeaderImageTint or Color3.fromRGB(150, 150, 158),
                                ImageTransparency = 1,                            -- fades in when loaded
                        }, header)
                        -- ONE UIGradient: carries both the 130deg darkening and the fade-out
                        local artGrad = inst("UIGradient", {
                                Name = "fade", Rotation = 8,
                                Color = ColorSequence.new({
                                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(170, 170, 178)),
                                        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(105, 105, 115)),
                                        ColorSequenceKeypoint.new(1,    Color3.fromRGB( 45,  45,  54)),
                                }),
                                Transparency = NumberSequence.new({
                                        NumberSequenceKeypoint.new(0,    0),
                                        NumberSequenceKeypoint.new(0.32, 0.16),
                                        NumberSequenceKeypoint.new(0.62, 0.42),
                                        NumberSequenceKeypoint.new(1,    cfg.HeaderImageFade or 0.58),
                                }),
                        }, art)
                        self.HeaderArt, self.HeaderArtGradient = art, artGrad

                        local target = cfg.HeaderImageTransparency or 0.72   -- CSS opacity:.23
                        task.spawn(function()
                                local t0 = os.clock()
                                while not art.IsLoaded and os.clock() - t0 < 5 do task.wait(0.1) end
                                if art.Parent then
                                        TweenService:Create(art, TweenInfo.new(0.5), { ImageTransparency = target }):Play()
                                end
                        end)
                end
        end

        ------------------------------------------------------------------------------------
        --  LOGO   (SubTitle defaults to nil — the "BETA" tag is gone unless you ask for it)
        ------------------------------------------------------------------------------------
        do
                local logo = inst("Frame", { Name = "logo", BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 11, 0.5, 0),     -- v2.5: 9→11px inset
                        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), ZIndex = 4 }, header)
                inst("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center }, logo)  -- v2.5: 2→3px gap

                if cfg.LogoIcon then
                        local li = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12),  -- v2.5: 10→12px
                                Image = resolveIcon(cfg.LogoIcon), ImageColor3 = theme.Accent,
                                ScaleType = Enum.ScaleType.Fit, LayoutOrder = 0 }, logo)
                        self:_onAccent(function(c) li.ImageColor3 = c end)
                end
                local title = inst("TextLabel", { BackgroundTransparency = 1, Font = self.FontBlack,
                        Text = cfg.Title or "SWIFT", TextColor3 = theme.Text, TextSize = cfg.TitleSize or 11,  -- v2.5: 9→11pt
                        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 11), LayoutOrder = 1 }, logo)
                self.TitleLabel = title
                self:_onTheme(function(t) title.TextColor3 = t.Text end)

                -- Only rendered when SubTitle is explicitly provided.
                if cfg.SubTitle and cfg.SubTitle ~= "" then
                        local sub = inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font,
                                Text = cfg.SubTitle, TextColor3 = theme.Muted, TextSize = 5,
                                AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 11), LayoutOrder = 2 }, logo)
                        self.SubTitleLabel = sub
                        self:_onTheme(function(t) sub.TextColor3 = t.Muted end)
                end
        end

        ------------------------------------------------------------------------------------
        --  NAV
        ------------------------------------------------------------------------------------
        local nav = inst("Frame", { Name = "nav", BackgroundTransparency = 1, ZIndex = 4,
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0),       -- v2.5: 9→11px inset
                AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, headerH) }, header)
        inst("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),    -- v2.5: 7→8px gap
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, nav)
        self.Nav = nav

        ------------------------------------------------------------------------------------
        --  PAGE HEAD  +  CONTENT
        ------------------------------------------------------------------------------------
        --  PAGE HEAD is OFF by default.
        --  It carried two labels (tab title + section), and every card can carry a title of its
        --  own, so a 2-column grid rendered FOUR headings stacked at the top of the window —
        --  "UI | Interface" sitting directly on top of "Appearance | Keybinds". The nav bar
        --  already spells out the active tab, so the page head was the redundant pair.
        --  Opt back in with ShowPageTitle = true (the mockup look); when you do, the first row
        --  of cards drops its titles so you still never get four.
        local pageHeadH = cfg.ShowPageTitle == true and 19 or 0
        self.ShowPageTitle = pageHeadH > 0
        if pageHeadH > 0 then
                local ph = inst("Frame", { Name = "pageHead", Size = UDim2.new(1, 0, 0, pageHeadH),
                        Position = UDim2.fromOffset(0, headerH), BackgroundTransparency = 1, ZIndex = 3 }, scaler)
                self.PageTitle = inst("TextLabel", { BackgroundTransparency = 1, Font = self.FontMedium,
                        Text = "", TextColor3 = theme.SubText, TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(15, 0),
                        Size = UDim2.new(0.5, -15, 1, 0) }, ph)
                self.SectionTitle = inst("TextLabel", { BackgroundTransparency = 1, Font = self.FontMedium,
                        Text = "", TextColor3 = theme.SubText, TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0.5, 8, 0, 0),
                        Size = UDim2.new(0.5, -15, 1, 0) }, ph)
                self:_onTheme(function(t)
                        self.PageTitle.TextColor3 = t.SubText; self.SectionTitle.TextColor3 = t.SubText
                end)
        end

        local content = inst("Frame", { Name = "content", BackgroundTransparency = 1, ZIndex = 2,
                Position = UDim2.fromOffset(0, headerH + pageHeadH),
                Size = UDim2.new(1, 0, 1, -(headerH + pageHeadH)) }, scaler)
        -- v2.5: slightly more generous padding for a cleaner frame
        local PAD_X = cfg.PaddingX or 14
        local PAD_T = cfg.PaddingTop or 5
        local PAD_B = cfg.PaddingBottom or 7
        inst("UIPadding", { PaddingTop = UDim.new(0, PAD_T), PaddingBottom = UDim.new(0, PAD_B),
                PaddingLeft = UDim.new(0, PAD_X), PaddingRight = UDim.new(0, PAD_X) }, content)

        local cols = cfg.Columns or 2
        local rows = cfg.Rows or 2
        local gapX, gapY = cfg.GapX or 12, cfg.GapY or 8      -- v2.5: tighter columns, more vertical air
        local innerW = W - PAD_X * 2
        local innerH = H - headerH - pageHeadH - PAD_T - PAD_B
        local cellW  = (innerW - gapX * (cols - 1)) / cols
        local cellH  = (innerH - gapY * (rows - 1)) / rows
        inst("UIGridLayout", {
                CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(gapX, gapY),
                FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder,
        }, content)
        self.Content, self.CellW, self.CellH = content, cellW, cellH

        --============================================================================================
        -- DRAG   (shell is unscaled, so mouse delta maps 1:1 onto Position offset)
        --============================================================================================
        if cfg.Draggable ~= false then
                local dragging, dragInput, dragStart, startPos
                local endConn
                table.insert(self._conns, header.InputBegan:Connect(function(input)
                        if (input.UserInputType == Enum.UserInputType.MouseButton1
                                        or input.UserInputType == Enum.UserInputType.Touch)
                                        and not pointIn(nav, input.Position.X, input.Position.Y) then
                                dragging, dragStart, startPos = true, input.Position, shell.Position
                                self:CloseOverlays()
                                -- NOTE: read self.S live, never the `S` upvalue captured at creation —
                                -- SetScale() can have changed it since, and using the stale value would
                                -- snap the window back to its original scale when the drag ends.
                                self:_animateBias(1.012, 0.12)
                                -- one connection at a time: Roblox recycles InputObjects, so leaving these
                                -- attached makes every later click re-fire this handler.
                                if endConn then endConn:Disconnect() end
                                endConn = input.Changed:Connect(function()
                                        if input.UserInputState == Enum.UserInputState.End then
                                                dragging = false
                                                if endConn then endConn:Disconnect(); endConn = nil end
                                                self:_animateBias(1, 0.18)
                                                self:_scheduleSave()      -- remember where the user parked it
                                        end
                                end)
                        end
                end))
                table.insert(self._conns, header.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement
                                        or input.UserInputType == Enum.UserInputType.Touch then
                                dragInput = input
                        end
                end))
                table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
                        if dragging and input == dragInput then
                                local d = input.Position - dragStart
                                shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
                        end
                end))
        end

        --============================================================================================
        -- TOGGLE KEY
        --============================================================================================
        self.Hidden = false
        self.ToggleKey = cfg.ToggleKey or Enum.KeyCode.F1
        table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end                       -- never fire while typing in a TextBox
                --  A keybind row is capturing input right now: the very next key belongs to IT.
                --  Without this, rebinding the toggle key also fires the toggle, so the menu
                --  vanished the instant you pressed the new key.
                if self._listening then return end
                local k = self.ToggleKey
                if k == nil then return end
                if typeof(k) == "EnumItem" and k.EnumType == Enum.UserInputType then
                        if input.UserInputType == k then self:Toggle() end
                elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == k then
                        self:Toggle()
                end
        end))

        --============================================================================================
        -- SHARED INPUT (sliders / palette dragging, hotkey capture)
        --============================================================================================
        self._activeDrag = nil
        table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
                if self._activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                                or input.UserInputType == Enum.UserInputType.Touch) then
                        self._activeDrag(input.Position.X, input.Position.Y)
                end
        end))
        table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch then
                        self._activeDrag = nil
                end
        end))
        self._listening = nil
        table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gp)
                if self._listening and not gp then
                        local n = keyName(input)
                        if n == false then self._listening.cancel(); self._listening = nil
                        elseif n then self._listening.apply(n, input); self._listening = nil end
                end
        end))

        --============================================================================================
        -- BUILT-IN SETTINGS TAB
        --   Hard-coded and always present. Built here, before the host script gets the window
        --   back, so it exists no matter what the caller does. It pins itself to the far right
        --   of the nav and never steals focus from the script's own first tab.
        --============================================================================================
        if cfg.SettingsTab ~= false then
                self:_buildSettingsTab(cfg)
        end

        -- intro animation (@keyframes show)
        if cfg.Animate ~= false then
                shell.GroupTransparency = 1
                TweenService:Create(shell, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
                        { GroupTransparency = 0 }):Play()
                -- v2.5: fade the shadow in alongside the shell
                if self.ShellShadow then
                        self.ShellShadow.Visible = true
                        self.ShellShadow.ImageTransparency = 1
                        TweenService:Create(self.ShellShadow, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
                                { ImageTransparency = 0.5 }):Play()
                end
                self._bias = 0.944
                self:_render()
                self:_animateBias(1, 0.6)
        else
                if self.ShellShadow then
                        self.ShellShadow.Visible = true
                        self.ShellShadow.ImageTransparency = 0.5
                end
        end

        table.insert(SWIFT.Windows, self)
        return self
end

--================================================================================================
-- WINDOW METHODS
--================================================================================================
function Window:_onAccent(fn) table.insert(self._accentFns, fn); fn(self.Accent); return fn end
function Window:_onTheme(fn)  table.insert(self._themeFns, fn);  return fn end

function Window:SetAccent(color)
        self.Accent = color
        self.Theme.Accent = color
        for _, fn in ipairs(self._accentFns) do pcall(fn, color) end
        self:_scheduleSave()
        return self
end

function Window:SetTheme(nameOrTable)
        local t
        if typeof(nameOrTable) == "table" then t = derive(self.Theme, nameOrTable)
        elseif THEMES[nameOrTable] then
                t = derive(THEMES[nameOrTable], {})
                self.ThemeName = nameOrTable
        else return self end
        self.Theme = t
        for _, fn in ipairs(self._themeFns) do pcall(fn, t) end
        self:SetAccent(t.Accent)
        self:_scheduleSave()
        return self
end

function Window:SetTitle(txt) if self.TitleLabel then self.TitleLabel.Text = txt end return self end

function Window:SetHeaderImage(v)
        local img = resolveHeaderImage(v)
        self.HeaderImageName = v
        if self.HeaderArt then
                self.HeaderArt.Image = img
                self.HeaderArt.ImageTransparency = img == "" and 1 or (self.Config.HeaderImageTransparency or 0.72)
        end
        self:_scheduleSave()
        return self
end

--  Derives every scale-dependent property from (self.S, self._bias).
--  Idempotent and cheap: it only writes when a value is actually wrong, so it is
--  safe to call every frame. This is the ONLY place the scale is written.
--  Writes the single scale value. Shell.Size is never touched — it is a constant.
function Window:_render()
        local sc = self.ShellScale
        if not (sc and sc.Parent) then return end
        local eff = (self.S or 1) * (self._bias or 1)
        if math.abs(sc.Scale - eff) > 0.0005 then
                sc.Scale = eff
        end
        -- v2.5: keep the drop shadow glued to the shell's position + scale
        local sh = self.ShellShadow
        if sh and sh.Parent then
                local p = self.Shell.Position
                if sh.Position ~= p then sh.Position = p end
                if math.abs((sh:FindFirstChild("UIScale") and sh.UIScale.Scale or 1) - eff) > 0.0005 then
                        if not sh:FindFirstChild("UIScale") then
                                inst("UIScale", { Scale = eff }, sh)
                        else
                                sh.UIScale.Scale = eff
                        end
                end
        end
end

--  Live-resize the whole window. Safe to call continuously (e.g. every frame from
--  a slider drag) — it just updates a number; _render() does the rest.
function Window:SetScale(s)
        s = tonumber(s)
        if not s or s ~= s or s == math.huge or s == -math.huge then
                return self                                   -- reject nil / NaN / inf
        end
        self.S = math.clamp(s, 0.2, 6)
        -- A cosmetic animation may be mid-flight; cancelling it must also RESET the bias,
        -- otherwise the window keeps a stranded partial multiplier (e.g. 1.0106) forever
        -- and lands slightly off the size the user picked.
        self._scaleAnim = nil
        self._bias = 1
        if self._biasConn then self._biasConn:Disconnect(); self._biasConn = nil end
        self:_render()
        self:_scheduleSave()
        return self
end

--  Animate the cosmetic bias by stepping a plain number on Heartbeat. Deliberately
--  NOT a Tween on the UIScale: a tween owns the property until it finishes, which is
--  how a stale animation could previously slam the scale back to an old value.
function Window:_animateBias(target, duration)
        local from = self._bias or 1
        if duration and duration > 0 and math.abs(target - from) > 1e-6 then
                local anim = { from = from, to = target, t = 0, dur = duration }
                self._scaleAnim = anim
                if not self._biasConn then
                        self._biasConn = RunService.Heartbeat:Connect(function(dt)
                                local a = self._scaleAnim
                                if not a then
                                        self._biasConn:Disconnect(); self._biasConn = nil
                                        return
                                end
                                a.t = a.t + (dt or 1 / 60)
                                local k = math.clamp(a.t / a.dur, 0, 1)
                                k = 1 - (1 - k) ^ 3                       -- ease out
                                self._bias = a.from + (a.to - a.from) * k
                                if k >= 1 then
                                        self._bias = a.to
                                        self._scaleAnim = nil
                                        if self._biasConn then self._biasConn:Disconnect(); self._biasConn = nil end
                                end
                                self:_render()
                        end)
                        table.insert(self._conns, self._biasConn)
                end
        else
                self._scaleAnim = nil
                self._bias = target
                self:_render()
        end
end

function Window:GetScale() return self.S end

--  DIAGNOSTIC. If the window ever appears the wrong size, call
--      Window:DebugScale()
--  It reports the authoritative numbers vs. what is actually on the instances, and
--  starts logging any external write that tries to fight the library.
function Window:DebugScale()
        local eff = (self.S or 1) * (self._bias or 1)
        print(("[SWIFT] S=%.4f bias=%.4f -> expected UIScale %.4f (%.1f x %.1f px)")
                :format(self.S or -1, self._bias or -1, eff, self.BaseW * eff, self.BaseH * eff))
        print(("[SWIFT] actual  UIScale=%.4f  rendered=%.1f x %.1f  animating=%s")
                :format(self.ShellScale.Scale, self.Shell.AbsoluteSize.X, self.Shell.AbsoluteSize.Y,
                        tostring(self._scaleAnim ~= nil)))
        print(("[SWIFT] Shell.Size (must stay %d x %d): %d x %d")
                :format(self.BaseW, self.BaseH, self.Shell.Size.X.Offset, self.Shell.Size.Y.Offset))
        if not self._scaleWatch then
                self._scaleWatch = self.ShellScale:GetPropertyChangedSignal("Scale"):Connect(function()
                        local want = (self.S or 1) * (self._bias or 1)
                        if math.abs(self.ShellScale.Scale - want) > 0.0005 then
                                warn(("[SWIFT] external write: UIScale set to %.4f (library wants %.4f)")
                                        :format(self.ShellScale.Scale, want))
                                warn(debug.traceback("[SWIFT] written from:", 2))
                        end
                end)
                table.insert(self._conns, self._scaleWatch)
                print("[SWIFT] now logging external writes to the scale.")
        end
        return self
end

--  Show / hide. Toggle() flips, Toggle(true) hides, Toggle(false) shows.
--  A CanvasGroup at GroupTransparency = 1 is invisible but its buttons still eat clicks,
--  so the shell is also made Visible = false once the fade finishes (and visible again
--  immediately on the way in, before the fade starts).
function Window:Toggle(state)
        if state == nil then state = not self.Hidden end
        self.Hidden = state
        if state then self:CloseOverlays() end
        self._fadeToken = (self._fadeToken or 0) + 1
        local token = self._fadeToken
        if not state then
                self.Shell.Visible = true
                if self.ShellShadow then self.ShellShadow.Visible = true end
        end
        TweenService:Create(self.Shell, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { GroupTransparency = state and 1 or 0 }):Play()
        -- v2.5: fade the shadow in/out with the shell
        if self.ShellShadow then
                TweenService:Create(self.ShellShadow, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { ImageTransparency = state and 1 or 0.5 }):Play()
        end
        self:_animateBias(state and 0.94 or 1, 0.22)
        self.Shell.Active = not state
        if state then
                task.delay(0.23, function()
                        --  Only hide if no later Toggle superseded this one.
                        if self._fadeToken == token and self.Hidden and self.Shell and self.Shell.Parent then
                                self.Shell.Visible = false
                                if self.ShellShadow then self.ShellShadow.Visible = false end
                        end
                end)
        end
        return self
end

function Window:Show() return self:Toggle(false) end
function Window:Hide() return self:Toggle(true) end
function Window:IsVisible() return not self.Hidden end

function Window:Destroy()
        if self.SaveEnabled and self.AutoSave then pcall(function() self:SaveConfig() end) end
        for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
        self:CloseOverlays()
        if self.ScreenGui then self.ScreenGui:Destroy() end
        for i, w in ipairs(SWIFT.Windows) do if w == self then table.remove(SWIFT.Windows, i) break end end
end

--================================================================================================
-- TOGGLE
--   Hotkey only, by design: there is no floating on-screen button. The bind is the bind.
--   `SetToggleButton` is kept as an accepted no-op so older scripts don't error.
--================================================================================================
function Window:SetToggleButton() return self end

--  Rebind the hotkey. Accepts Enum.KeyCode, Enum.UserInputType.MouseButtonN, or a
--  pretty name string ("F1", "RIGHTSHIFT", "MOUSE 3"). nil / "NONE" unbinds.
function Window:SetToggleKey(k)
        local resolved = keyFromName(k)
        --  The hotkey is the ONLY way back to a hidden menu, so an unrecognised name must not
        --  silently unbind it and strand the user. Keep the previous key instead.
        if resolved == nil and k ~= nil and tostring(k):upper() ~= "NONE" then
                return self
        end
        self.ToggleKey = resolved
        self:_scheduleSave()
        return self
end

function Window:GetToggleKeyName() return prettyKey(self.ToggleKey) end

--================================================================================================
-- CONFIG SAVE / LOAD
--   The built-in UI settings always persist. Any other control persists too if it was
--   declared with  Save = true  (or if it lives on the built-in Settings tab, which sets
--   Save = true for you) — that is how user-added rows in the settings menu are kept.
--================================================================================================
function Window:_serialise()
        local p = self.Shell and self.Shell.Position or UDim2.fromScale(0.5, 0.5)
        local data = {
                _version    = SWIFT.Version,
                Theme       = self.ThemeName,
                Accent      = self.Accent,
                Scale       = self.S,
                HeaderImage = self.HeaderImageName,
                ToggleKey   = prettyKey(self.ToggleKey),
                AutoSave    = self.AutoSave,
                Position    = { XS = p.X.Scale, XO = p.X.Offset, YS = p.Y.Scale, YO = p.Y.Offset },
                Flags       = {},
        }
        for flag, api in pairs(self._persist or {}) do
                local ok, v = pcall(function() return api:Get() end)
                if ok then data.Flags[flag] = v end
        end
        return data
end

--  Immediate write. Returns (ok, "file"|"memory"|error).
function Window:SaveConfig()
        if not self.SaveEnabled then return false, "saving disabled" end
        self._saveQueued = false
        return saveJSON(self.ConfigName, self:_serialise())
end

--  Coalesces a burst of writes (e.g. every frame of a scale-slider drag) into one file write
--  half a second after the last change. Without this a drag would hammer the filesystem.
function Window:_scheduleSave()
        if not (self.SaveEnabled and self.AutoSave) then return end
        self._saveStamp = os.clock()
        if self._saveQueued then return end
        self._saveQueued = true
        task.spawn(function()
                while self._saveQueued do
                        task.wait(0.15)
                        if not self._saveQueued then return end
                        if os.clock() - (self._saveStamp or 0) >= 0.5 then
                                self._saveQueued = false
                                pcall(function() self:SaveConfig() end)
                                return
                        end
                end
        end)
end

--  Re-apply a saved config to a LIVE window (the constructor handles the boot-time path).
function Window:LoadConfig(data)
        data = data or loadJSON(self.ConfigName)
        if type(data) ~= "table" then return false end
        local wasAuto = self.AutoSave
        self.AutoSave = false                       -- don't write while restoring
        if type(data.Theme) == "string" and THEMES[data.Theme] then self:SetTheme(data.Theme) end
        if typeof(data.Accent) == "Color3" then self:SetAccent(data.Accent) end
        if tonumber(data.Scale) then self:SetScale(tonumber(data.Scale)) end
        if data.HeaderImage ~= nil then self:SetHeaderImage(data.HeaderImage) end
        if data.ToggleKey ~= nil then self:SetToggleKey(data.ToggleKey) end
        if type(data.Position) == "table" and self.Shell then
                self.Shell.Position = UDim2.new(data.Position.XS or 0.5, data.Position.XO or 0,
                                                data.Position.YS or 0.5, data.Position.YO or 0)
        end
        for flag, v in pairs(data.Flags or {}) do
                local api = (self._persist or {})[flag]
                if api and api.Set then pcall(function() api:Set(v) end) end
        end
        self.AutoSave = wasAuto
        if self.SettingsRefresh then pcall(self.SettingsRefresh) end
        return true
end

--  Wipe the file and put the UI back to how CreateWindow was originally called.
function Window:ResetConfig()
        deleteJSON(self.ConfigName)
        local d = self._defaults or {}
        local wasAuto = self.AutoSave
        self.AutoSave = false
        self:SetTheme(d.Theme or "Midnight")
        if d.Accent then self:SetAccent(d.Accent) end
        self:SetScale(d.Scale or 1.42)
        self:SetHeaderImage(d.HeaderImage)
        self:SetToggleKey(d.ToggleKey or Enum.KeyCode.F1)
        if self.Shell then self.Shell.Position = d.Position or UDim2.fromScale(0.5, 0.5) end
        self.AutoSave = wasAuto
        if self.SettingsRefresh then pcall(self.SettingsRefresh) end
        self:_scheduleSave()
        return self
end

--  Register any control for persistence by hand:  Window:Persist("myFlag", api)
function Window:Persist(flag, api)
        if flag and api and api.Get and api.Set then self._persist[flag] = api end
        return self
end

--================================================================================================
-- OVERLAYS  (dropdown / multi-select / colour picker)
--   • dropdown + multi  → click-away backdrop
--   • picker            → NO backdrop; closes on "Done" or on hiding the window
--================================================================================================
function Window:CloseOverlays()
        if self._backdrop then self._backdrop:Destroy(); self._backdrop = nil end
        if self.ScreenGui then
                for _, c in ipairs(self.ScreenGui:GetChildren()) do
                        if c.Name == "swift_overlay" or c.Name == "swift_overlay_shadow" then c:Destroy() end
                end
        end
        if self._onOverlayClosed then
                local fn = self._onOverlayClosed; self._onOverlayClosed = nil; pcall(fn)
        end
end

function Window:_backdropFor()
        self:CloseOverlays()
        -- No visible backdrop at all — just a transparent click-catcher
        self._backdrop = inst("TextButton", { Name = "swift_backdrop", Text = "",
                BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 7 }, self.ScreenGui)
        self._backdrop.Activated:Connect(function() self:CloseOverlays() end)
        return self._backdrop
end

-- shared panel: placement (flips above when it would overflow) + open animation
function Window:_menuPanel(button, rowCount, onClosed)
        local S, T = self.S, self.Theme
        local vp = getViewport()
        local ROW_H, PAD = 17, 4                  -- IMGUI: compact 17px rows, 4px padding
        local w = math.max(70 * S, button.AbsoluteSize.X)   -- IMGUI: 70px min width
        local h = rowCount * ROW_H + PAD * 2

        local d = inst("Frame", { Name = "swift_overlay", BackgroundColor3 = T.DropdownBg, ZIndex = 9,
                Size = UDim2.fromOffset(w, h), BorderSizePixel = 0, ClipsDescendants = true }, self.ScreenGui)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, d)
        inst("UIStroke", { Color = T.DropdownBorder, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, d)
        local list = inst("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, d)
        inst("UIPadding", { PaddingTop = UDim.new(0, PAD), PaddingBottom = UDim.new(0, PAD),
                PaddingLeft = UDim.new(0, PAD), PaddingRight = UDim.new(0, PAD) }, list)
        inst("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)

        local br, bs = button.AbsolutePosition, button.AbsoluteSize
        local gap  = 4 * S
        local left = math.clamp(br.X + bs.X - w, 8, math.max(8, vp.X - w - 8))
        local below = br.Y + bs.Y + gap
        local flip = (below + h > vp.Y - 8)
        local top  = flip and math.max(8, br.Y - h - gap) or below
        d.Position = UDim2.fromOffset(left, top)

        -- Shadow created AFTER position is known
        local shadow = inst("ImageLabel", { Name = "swift_overlay_shadow", BackgroundTransparency = 1, ZIndex = 8,
                Image = "rbxassetid://1316045217", ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(10, 10, 118, 118),
                ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.6,
                Size = UDim2.fromOffset(w + 8, h + 8), AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromOffset(left - 4, top - 4) }, self.ScreenGui)

        d.Size = UDim2.fromOffset(w, 0)
        TweenService:Create(d, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { Size = UDim2.fromOffset(w, h) }):Play()
        if flip then
                d.Position = UDim2.fromOffset(left, br.Y - gap)
                shadow.Position = UDim2.fromOffset(left - 4, br.Y - gap - 4)
                TweenService:Create(d, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Position = UDim2.fromOffset(left, top) }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        { Position = UDim2.fromOffset(left - 4, top - 4) }):Play()
        end
        self._onOverlayClosed = onClosed
        return d, list, ROW_H
end

--  A menu row.
--    selected == nil    -> the row has no selection state (plain list)
--    selected == false  -> selectable, currently off
--    selected == true   -> selectable, currently on
--  Selection is shown by a LEFT ACCENT BAR plus accent-coloured text — there is no tick
--  icon. Hover brightens the text to near-white, so a row that is both selected and
--  hovered reads white with the bar still lit.
--  Returns (item, label, handle); handle:Set(bool) flips the row's selected look.
function Window:_menuItem(list, i, text, rowH, selected, onClick)
        local T = self.Theme
        local item = inst("TextButton", { Text = "", BackgroundColor3 = T.MenuHover,
                BackgroundTransparency = 1, AutoButtonColor = false, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, rowH), LayoutOrder = i }, list)
        inst("UICorner", { CornerRadius = UDim.new(0, 2) }, item)            -- IMGUI: 2px radius

        local barH = math.max(6, rowH - 6)
        local bar = inst("Frame", { Name = "bar", BackgroundColor3 = self.Accent, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(2, selected and barH or 0),
                BackgroundTransparency = selected and 0 or 1, Visible = selected ~= nil }, item)
        inst("UICorner", { CornerRadius = UDim.new(0, 1) }, bar)

        local label = inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font, Text = text,
                TextColor3 = selected and self.Accent or T.MenuText, TextSize = 7,           -- IMGUI: 7pt
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -14, 1, 0) }, item)

        local isOn, hovering = selected == true, false
        local function paint(fast)
                local ti = TweenInfo.new(fast and 0.08 or 0.1)
                local col = hovering and T.MenuTextHover or (isOn and self.Accent or T.MenuText)
                TweenService:Create(label, ti, { TextColor3 = col }):Play()
                TweenService:Create(item, ti,
                        { BackgroundTransparency = hovering and 0.92 or 1 }):Play()
                if selected ~= nil then
                        bar.BackgroundColor3 = self.Accent
                        TweenService:Create(bar, TweenInfo.new(fast and 0.08 or 0.12, Enum.EasingStyle.Quad,
                                Enum.EasingDirection.Out), {
                                        Size = UDim2.fromOffset(2, isOn and barH or 0),
                                        BackgroundTransparency = isOn and 0 or 1 }):Play()
                end
        end

        item.MouseEnter:Connect(function() hovering = true;  paint(true)  end)
        item.MouseLeave:Connect(function() hovering = false; paint(false) end)

        local handle = {}
        function handle:Set(v) isOn = v and true or false; paint(true) end
        function handle:Get() return isOn end

        item.Activated:Connect(function() onClick(handle, label) end)
        label.TextTransparency = 1
        TweenService:Create(label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                0, false, i * 0.012), { TextTransparency = 0 }):Play()
        return item, label, handle
end

function Window:OpenDropdown(button, options, current, onSelect, onClosed)
        self:_backdropFor()
        local d, list, rowH = self:_menuPanel(button, #options, onClosed)
        for i, opt in ipairs(options) do
                self:_menuItem(list, i, tostring(opt), rowH,
                        (current ~= nil) and (opt == current) or nil, function()
                                onSelect(opt)
                                self:CloseOverlays()
                        end)
        end
        return d
end

function Window:OpenMulti(button, options, state, onChange, onClosed)
        self:_backdropFor()
        local T = self.Theme
        local d, list, rowH = self:_menuPanel(button, #options + 1, onClosed)
        local handles = {}
        for i, opt in ipairs(options) do
                local _, _, handle = self:_menuItem(list, i, tostring(opt), rowH, state[opt] == true,
                        function(h)
                                state[opt] = not state[opt]
                                h:Set(state[opt])
                                onChange()
                        end)
                handles[opt] = handle
        end
        local footer = inst("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, rowH),
                LayoutOrder = #options + 1 }, list)
        inst("Frame", { BackgroundColor3 = T.DropdownBorder, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1) }, footer)
        local function mini(text, iconName, x, fn)
                local b = inst("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
                        Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(x, 0) }, footer)
                local ic = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(7, 7),
                        Image = resolveIcon(iconName), ImageColor3 = T.Muted, ScaleType = Enum.ScaleType.Fit,
                        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0) }, b)
                local lb = inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font, Text = text,
                        TextColor3 = T.Muted, TextSize = 6, TextXAlignment = Enum.TextXAlignment.Left,
                        Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -14, 1, 0) }, b)
                b.MouseEnter:Connect(function()
                        TweenService:Create(lb, TweenInfo.new(0.1), { TextColor3 = self.Accent }):Play()
                        TweenService:Create(ic, TweenInfo.new(0.1), { ImageColor3 = self.Accent }):Play()
                end)
                b.MouseLeave:Connect(function()
                        TweenService:Create(lb, TweenInfo.new(0.1), { TextColor3 = T.Muted }):Play()
                        TweenService:Create(ic, TweenInfo.new(0.1), { ImageColor3 = T.Muted }):Play()
                end)
                b.Activated:Connect(fn)
        end
        local function setAll(v)
                for _, opt in ipairs(options) do
                        state[opt] = v
                        if handles[opt] then handles[opt]:Set(v) end
                end
                onChange()
        end
        mini("All",  "lucide-check-square", 0,   function() setAll(true)  end)
        mini("None", "lucide-square",       0.5, function() setAll(false) end)
        return d
end

--  HSV colour picker (no backdrop — "Done" or window hide closes it)
function Window:OpenPicker(anchor, initial, onChange)
        self:CloseOverlays()
        local S, T = self.S, self.Theme
        local vp = getViewport()
        local PW, PH = 142 * S, 113 * S

        local picker = inst("Frame", { Name = "swift_overlay", BackgroundColor3 = WHITE, ZIndex = 10,
                Size = UDim2.fromOffset(PW, PH), BorderSizePixel = 0 }, self.ScreenGui)
        inst("UIGradient", { Color = ColorSequence.new(T.PickerA, T.PickerB), Rotation = 145 }, picker)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, picker)
        inst("UIStroke", { Color = T.PickerBorder, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, picker)
        inst("UIPadding", { PaddingTop = UDim.new(0, 7 * S), PaddingBottom = UDim.new(0, 7 * S),
                PaddingLeft = UDim.new(0, 7 * S), PaddingRight = UDim.new(0, 7 * S) }, picker)
        inst("UIListLayout", { Padding = UDim.new(0, 6 * S), SortOrder = Enum.SortOrder.LayoutOrder }, picker)

        local br, bs = anchor.AbsolutePosition, anchor.AbsoluteSize
        local gap = 7 * S
        local left = math.max(8, math.min(vp.X - PW - 8, br.X + bs.X / 2 - PW / 2))
        local below = br.Y + bs.Y + gap
        local py = (below + PH > vp.Y - 8) and math.max(8, br.Y - PH - gap) or below
        picker.Position = UDim2.fromOffset(left, py)

        local ps = inst("UIScale", { Scale = 1.15 }, picker)
        TweenService:Create(ps, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Scale = 1 }):Play()

        local h, s, v = Color3.toHSV(initial or self.Accent)

        -- SV palette
        local palette = inst("Frame", { Size = UDim2.new(1, 0, 0, 67 * S), BorderSizePixel = 0,
                BackgroundColor3 = WHITE, LayoutOrder = 1 }, picker)
        inst("UICorner", { CornerRadius = UDim.new(0, 4) }, palette)
        local satLayer = inst("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE,
                BorderSizePixel = 0 }, palette)
        inst("UICorner", { CornerRadius = UDim.new(0, 4) }, satLayer)
        local satGrad = inst("UIGradient", { Color = ColorSequence.new(WHITE, hsvToColor(h, 1, 1)) }, satLayer)
        local valLayer = inst("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE,
                BorderSizePixel = 0 }, palette)
        inst("UICorner", { CornerRadius = UDim.new(0, 4) }, valLayer)
        inst("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0, 0, 0)),
                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0) }) }, valLayer)
        local cursor = inst("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(7 * S, 7 * S), BorderSizePixel = 0,
                Position = UDim2.fromScale(s, 1 - v) }, palette)
        inst("UICorner", { CornerRadius = UDim.new(0.5, 0) }, cursor)
        inst("UIStroke", { Color = WHITE, Thickness = 1 }, cursor)

        -- hue bar
        local hueBar = inst("Frame", { Size = UDim2.new(1, 0, 0, 4 * S), BackgroundTransparency = 1,
                LayoutOrder = 2 }, picker)
        local hueTrack = inst("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE,
                BorderSizePixel = 0 }, hueBar)
        inst("UICorner", { CornerRadius = UDim.new(0, 2) }, hueTrack)
        inst("UIGradient", { Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)) }) }, hueTrack)
        local hueThumb = inst("Frame", { BackgroundColor3 = Color3.fromRGB(216, 216, 220),
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7 * S, 7 * S),
                Position = UDim2.fromScale(h, 0.5), BorderSizePixel = 0 }, hueBar)
        inst("UICorner", { CornerRadius = UDim.new(0.5, 0) }, hueThumb)

        -- footer
        local footer = inst("Frame", { Size = UDim2.new(1, 0, 0, 16 * S), BackgroundTransparency = 1,
                LayoutOrder = 3 }, picker)
        inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(7 * S, 7 * S),
                Image = resolveIcon("lucide-pipette"), ImageColor3 = Color3.fromRGB(150, 150, 160),
                ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0) }, footer)
        local hex = inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font,
                Text = toHex(initial or self.Accent), TextColor3 = Color3.fromRGB(180, 180, 189),
                TextSize = 7, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 9 * S, 0.5, 0), Size = UDim2.new(0.6, 0, 1, 0) }, footer)
        local done = inst("TextButton", { Text = "", BackgroundColor3 = Color3.fromRGB(68, 68, 78),
                AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(40 * S, 14 * S) }, footer)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, done)
        inst("UIStroke", { Color = Color3.fromRGB(85, 85, 96), Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, done)
        inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(7 * S, 7 * S),
                Image = resolveIcon("lucide-check"), ImageColor3 = Color3.fromRGB(221, 221, 221),
                ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 4, 0.5, 0) }, done)
        inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font, Text = "Done",
                TextColor3 = Color3.fromRGB(221, 221, 221), TextSize = 7,
                TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(5 + 7 * S, 0),
                Size = UDim2.new(1, -(8 + 7 * S), 1, 0) }, done)
        done.Activated:Connect(function() self:CloseOverlays() end)

        local function emit()
                local col = hsvToColor(h, s, v)
                hex.Text = toHex(col)
                if onChange then onChange(col) end
        end
        local function palXY(x, y)
                local ap, as = palette.AbsolutePosition, palette.AbsoluteSize
                return math.clamp((x - ap.X) / math.max(as.X, 1), 0, 1),
                       math.clamp((y - ap.Y) / math.max(as.Y, 1), 0, 1)
        end
        local function applyPal(nx, ny)
                s, v = nx, 1 - ny
                cursor.Position = UDim2.fromScale(nx, ny)
                emit()
        end
        palette.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch then
                        applyPal(palXY(input.Position.X, input.Position.Y))
                        self._activeDrag = function(mx, my) applyPal(palXY(mx, my)) end
                end
        end)
        hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch then
                        local function setHue(x)
                                local ap, as = hueBar.AbsolutePosition.X, hueBar.AbsoluteSize.X
                                h = math.clamp((x - ap) / math.max(as, 1), 0, 1)
                                hueThumb.Position = UDim2.fromScale(h, 0.5)
                                satGrad.Color = ColorSequence.new(WHITE, hsvToColor(h, 1, 1))
                                emit()
                        end
                        setHue(input.Position.X)
                        self._activeDrag = function(mx) setHue(mx) end
                end
        end)
        return picker
end

--================================================================================================
-- NOTIFICATIONS
--================================================================================================
function Window:Notify(cfg)
        cfg = cfg or {}
        local T, S = self.Theme, self.S
        if not self._notifRoot then
                self._notifRoot = inst("Frame", { Name = "swift_notifs", BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12),
                        Size = UDim2.fromOffset(190 * S, 400), ZIndex = 20 }, self.ScreenGui)
                inst("UIListLayout", { Padding = UDim.new(0, 6),
                        VerticalAlignment = Enum.VerticalAlignment.Bottom,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        SortOrder = Enum.SortOrder.LayoutOrder }, self._notifRoot)
        end

        local card = inst("CanvasGroup", { BackgroundColor3 = T.Background, BorderSizePixel = 0,
                Size = UDim2.fromOffset(200 * S, 38 * S), GroupTransparency = 1, ZIndex = 20 }, self._notifRoot)  -- v2.5: 190→200w, 34→38h
        inst("UICorner", { CornerRadius = UDim.new(0, 5) }, card)            -- v2.5: 3→5 radius
        inst("UIStroke", { Color = T.Border, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
        inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(12 * S, 12 * S),  -- v2.5: 10→12px icon
                Image = resolveIcon(cfg.Icon or "lucide-info"), ImageColor3 = self.Accent,
                ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(8 * S, 7 * S) }, card)
        inst("TextLabel", { BackgroundTransparency = 1, Font = self.FontBold,
                Text = cfg.Title or "Notification", TextColor3 = T.Text, TextSize = 9 * S,   -- v2.5: 8→9pt
                TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(24 * S, 6 * S),
                Size = UDim2.new(1, -30 * S, 0, 10 * S) }, card)
        inst("TextLabel", { BackgroundTransparency = 1, Font = self.Font, Text = cfg.Content or "",
                TextColor3 = T.Label, TextSize = 8 * S, TextXAlignment = Enum.TextXAlignment.Left,  -- v2.5: 7→8pt
                TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(24 * S, 18 * S),
                Size = UDim2.new(1, -30 * S, 0, 10 * S) }, card)
        local bar = inst("Frame", { BackgroundColor3 = self.Accent, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1) }, card)

        TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { GroupTransparency = 0 }):Play()
        local dur = cfg.Duration or 3
        TweenService:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear),
                { Size = UDim2.new(0, 0, 0, 1) }):Play()
        task.delay(dur, function()
                if card.Parent then
                        TweenService:Create(card, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
                        task.wait(0.32)
                        if card.Parent then card:Destroy() end
                end
        end)
        return card
end

--================================================================================================
-- TAB
--================================================================================================
local Tab  = {}; Tab.__index  = Tab
local Card = {}; Card.__index = Card

--  Window:AddTab{ Name="Aim", Icon="lucide-crosshair", Title=?, Section=?, Default=? }
function Window:AddTab(cfg)
        cfg = cfg or {}
        local T = self.Theme
        local name = cfg.Name or ("Tab" .. (#self.TabOrder + 1))

        --  Name collision. Two cases matter:
        --    1. A host script adds its own "Settings" tab. Rather than render two identical
        --       nav icons, hand back the built-in one — its cards then land next to the base
        --       rows, which is exactly the intent of "people can add stuff in that menu".
        --    2. Any other duplicate name would silently clobber self.Tabs[name] and orphan the
        --       first tab's nav button, so return the existing tab instead.
        if self.Tabs[name] and not cfg._settings then
                local existing = self.Tabs[name]
                if cfg.Section and cfg.Section ~= "" then existing:SetSection(cfg.Section) end
                if not existing.IsSettings then self._userTabSeen = true end
                if cfg.Default then self:SelectTab(name) end
                return existing
        end

        local self_ = self
        local tab = setmetatable({
                Window = self, Name = name, Cards = {},
                Title = cfg.Title or name, Section = cfg.Section or "",
        }, Tab)

        --  The built-in Settings tab is pinned to the far right (LayoutOrder 9999) so that host
        --  scripts can keep calling AddTab afterwards without it drifting into the middle.
        tab.IsSettings = cfg._settings == true
        local btn = inst("TextButton", { Name = "nav_" .. name, BackgroundTransparency = 1,
                AutoButtonColor = false, Text = "", AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, self.Header.AbsoluteSize.Y > 0 and 29 or 29),
                LayoutOrder = tab.IsSettings and 9999 or (#self.TabOrder + 1) }, self.Nav)
        inst("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
                VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, btn)

        local holder = inst("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(11, 11),  -- v2.5: 9→11px nav icons
                LayoutOrder = 1 }, btn)
        local img = inst("ImageLabel", { Name = "icon", BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1), Image = resolveIcon(cfg.Icon or "lucide-circle"),
                ImageColor3 = T.NavInactive, ScaleType = Enum.ScaleType.Fit }, holder)
        local iconScale  = inst("UIScale", { Scale = 1 }, holder)
        local hoverScale = inst("UIScale", { Scale = 1 }, holder)

        local span = inst("TextLabel", { BackgroundTransparency = 1, Font = self.FontMedium,
                Text = name, TextColor3 = T.NavActive, TextSize = 9,             -- v2.5: 8→9pt nav label
                AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 9),
                Visible = false, LayoutOrder = 2 }, btn)

        tab.Button, tab.Icon, tab.Span, tab.IconScale = btn, img, span, iconScale

        btn.MouseEnter:Connect(function()
                if self_.ActiveTab ~= tab then
                        TweenService:Create(img, TweenInfo.new(0.16),
                                { ImageColor3 = Color3.fromRGB(238, 238, 238) }):Play()
                        TweenService:Create(hoverScale, TweenInfo.new(0.16, Enum.EasingStyle.Back,
                                Enum.EasingDirection.Out), { Scale = 1.15 }):Play()
                end
        end)
        btn.MouseLeave:Connect(function()
                if self_.ActiveTab ~= tab then
                        TweenService:Create(img, TweenInfo.new(0.18),
                                { ImageColor3 = self_.Theme.NavInactive }):Play()
                end
                TweenService:Create(hoverScale, TweenInfo.new(0.18), { Scale = 1 }):Play()
        end)
        btn.Activated:Connect(function() self_:SelectTab(name) end)

        self:_onAccent(function(c) if self_.ActiveTab == tab then img.ImageColor3 = c end end)
        self:_onTheme(function(t)
                span.TextColor3 = t.NavActive
                if self_.ActiveTab ~= tab then img.ImageColor3 = t.NavInactive end
        end)

        -- each tab owns a container of cards, shown/hidden on switch
        tab.Container = inst("Frame", { Name = "tab_" .. name, BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1), Visible = false })

        self.Tabs[name] = tab
        table.insert(self.TabOrder, tab)
        --  Never let the built-in Settings tab steal focus at boot: it is created before the
        --  host script's own tabs exist, so it would otherwise always be the "first" one.
        local firstReal = not tab.IsSettings
                and (self.ActiveTab == nil or (self.ActiveTab.IsSettings and not self._userTabSeen))
        if firstReal then self._userTabSeen = true end
        if cfg.Default or firstReal or #self.TabOrder == 1 then
                self:SelectTab(name)
        end
        return tab
end

function Window:SelectTab(name)
        local tab = self.Tabs[name]
        if not tab or self.ActiveTab == tab then return self end
        self:CloseOverlays()
        self.ActiveTab = tab

        for _, t in ipairs(self.TabOrder) do
                local active = (t == tab)
                TweenService:Create(t.Icon, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { ImageColor3 = active and self.Accent or self.Theme.NavInactive }):Play()
                if active then
                        t.Span.Visible = true
                        t.Span.TextTransparency = 1
                        TweenService:Create(t.Span, TweenInfo.new(0.26, Enum.EasingStyle.Sine,
                                Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()   -- @keyframes tabText
                        t.IconScale.Scale = 0.7
                        TweenService:Create(t.IconScale, TweenInfo.new(0.26, Enum.EasingStyle.Back,
                                Enum.EasingDirection.Out), { Scale = 1 }):Play()              -- @keyframes tabIcon
                else
                        t.Span.Visible = false
                        t.IconScale.Scale = 1
                end
        end

        -- page headings cross-fade
        local function swap(lbl, text, base)
                if not lbl or lbl.Text == text then return end
                TweenService:Create(lbl, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
                task.delay(0.1, function()
                        if not lbl.Parent then return end
                        lbl.Text = text
                        lbl.Position = UDim2.new(base.X.Scale, base.X.Offset - 5, base.Y.Scale, base.Y.Offset)
                        TweenService:Create(lbl, TweenInfo.new(0.24, Enum.EasingStyle.Quint,
                                Enum.EasingDirection.Out), { TextTransparency = 0, Position = base }):Play()
                end)
        end
        swap(self.PageTitle,   tab.Title,   UDim2.fromOffset(15, 0))
        swap(self.SectionTitle, tab.Section, UDim2.new(0.5, 8, 0, 0))

        -- swap card containers and replay the rise animation
        for _, t in ipairs(self.TabOrder) do
                if t.Container.Parent then t.Container.Parent = nil end
        end
        for _, c in ipairs(self.Content:GetChildren()) do
                if c:IsA("CanvasGroup") then c.Parent = nil end
        end
        for i, card in ipairs(tab.Cards) do
                card.Frame.Parent = self.Content
                if self.Config.Animate ~= false then
                        card.Frame.GroupTransparency = 1                              -- @keyframes rise
                        card.Scale.Scale = 0.96
                        local ti = TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out,
                                0, false, (i - 1) * 0.04)
                        TweenService:Create(card.Frame, ti, { GroupTransparency = 0 }):Play()
                        TweenService:Create(card.Scale, ti, { Scale = 1 }):Play()
                end
                for _, fn in ipairs(card._mountFns) do task.spawn(fn) end
        end
        return self
end

function Tab:Select() self.Window:SelectTab(self.Name); return self end
function Tab:SetSection(t) self.Section = t
        if self.Window.ActiveTab == self and self.Window.SectionTitle then
                self.Window.SectionTitle.Text = t end
        return self end

--================================================================================================
-- CARD
--================================================================================================
--  Tab:AddCard{ Title="Aimbot", Tag="MAIN MODULE", ShowTitle=true/false }
function Tab:AddCard(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local index = #self.Cards + 1
        --  Title visibility, so headings never stack:
        --    page head ON  -> the top row of cards stays title-less (the mockup's look), because
        --                     the page head is already labelling that row.
        --    page head OFF -> EVERY card shows its own title; it is the only heading on screen.
        local showHeader = cfg.ShowTitle
        if showHeader == nil then
                if W.ShowPageTitle then showHeader = (index > (W.Config.Columns or 2))
                else showHeader = true end
        end

        local frame = inst("CanvasGroup", { Name = "card_" .. (cfg.Title or index),
                BackgroundTransparency = 1, ClipsDescendants = false, LayoutOrder = index })
        local scale = inst("UIScale", { Scale = 1 }, frame)

        local titleLbl
        if showHeader and cfg.Title then
                titleLbl = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontBold,   -- v2.5: Medium→Bold for crisper titles
                        Text = cfg.Title, TextColor3 = T.SubText, TextSize = 11,                 -- v2.5: 10→11pt
                        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20) }, frame)  -- v2.5: 19→20px
                W:_onTheme(function(t) titleLbl.TextColor3 = t.SubText end)
        end

        local scroll = inst("ScrollingFrame", { BackgroundTransparency = 1, ScrollBarThickness = 0,
                BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
                Size = titleLbl and UDim2.new(1, 0, 1, -20) or UDim2.fromScale(1, 1),
                Position = titleLbl and UDim2.fromOffset(0, 20) or UDim2.fromOffset(0, 0) }, frame)
        inst("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)  -- v2.5: 3→4px row gap
        inst("UIPadding", { PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 18) }, scroll)

        -- CSS mask-image edge fades (colour tracks the shell background)
        local masks = {}
        local function mask(top)
                local m = inst("Frame", { BackgroundColor3 = T.Background, BorderSizePixel = 0, ZIndex = 6,
                        Size = UDim2.new(1, 0, 0, 12) }, frame)
                inst("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, top and 0 or 1),
                        NumberSequenceKeypoint.new(1, top and 1 or 0) }) }, m)
                if top then m.Position = UDim2.fromOffset(0, titleLbl and 19 or 0)
                else m.AnchorPoint, m.Position = Vector2.yAxis, UDim2.fromScale(0, 1) end
                masks[#masks + 1] = m
        end
        mask(true); mask(false)
        W:_onTheme(function(t) for _, m in ipairs(masks) do m.BackgroundColor3 = t.Background end end)

        local card = setmetatable({
                Window = W, Tab = self, Frame = frame, Scale = scale, Scroll = scroll,
                TitleLabel = titleLbl, _mountFns = {}, _order = 0,
        }, Card)
        table.insert(self.Cards, card)
        if W.ActiveTab == self then
                frame.Parent = W.Content
                for _, fn in ipairs(card._mountFns) do task.spawn(fn) end
        end
        return card
end

function Card:_next() self._order = self._order + 1; return self._order end

--  base row  (.row)
function Card:_row(height)
        local W, T = self.Window, self.Window.Theme
        local f = inst("Frame", { BackgroundColor3 = T.Row, Size = UDim2.new(1, 0, 0, height),
                LayoutOrder = self:_next() }, self.Scroll)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, f)       -- IMGUI: tight 3px radius
        f.MouseEnter:Connect(function()
                TweenService:Create(f, TweenInfo.new(0.1), { BackgroundColor3 = W.Theme.RowHover }):Play()
        end)
        f.MouseLeave:Connect(function()
                TweenService:Create(f, TweenInfo.new(0.12), { BackgroundColor3 = W.Theme.Row }):Play()
        end)
        W:_onTheme(function(t) f.BackgroundColor3 = t.Row end)
        return f
end

function Card:_label(parent, text, rightGap)
        local W, T = self.Window, self.Window.Theme
        local l = inst("TextLabel", { BackgroundTransparency = 1, Font = W.Font, Text = text,
                TextColor3 = T.Label, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -(rightGap or 25), 1, 0) }, parent)  -- v2.5: 7→8pt, 5→7px inset
        W:_onTheme(function(t) l.TextColor3 = t.Label end)
        return l
end

--  pill button used by select / multi / keybind
function Card:_pill(parent, width)
        local W, T = self.Window, self.Window.Theme
        local btn = inst("TextButton", { Text = "", BackgroundColor3 = T.Control, AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0),
                Size = UDim2.fromOffset(width, 15), ClipsDescendants = true }, parent)   -- IMGUI: 15px tall
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, btn)                       -- IMGUI: 3px radius
        local stroke = inst("UIStroke", { Color = T.ControlBorder, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
        btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = W.Theme.ControlHover }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.12), { Color = W.Theme.ControlBorderHover }):Play()
        end)
        btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = W.Theme.Control }):Play()
                TweenService:Create(stroke, TweenInfo.new(0.12), { Color = W.Theme.ControlBorder }):Play()
        end)
        btn.MouseButton1Down:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.06), { BackgroundColor3 = W.Theme.ControlPress }):Play()
        end)
        btn.MouseButton1Up:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = W.Theme.ControlHover }):Play()
        end)
        W:_onTheme(function(t) btn.BackgroundColor3 = t.Control; stroke.Color = t.ControlBorder end)
        return btn, stroke
end

function Card:_caret(btn)
        local W, T = self.Window, self.Window.Theme
        local c = inst("ImageLabel", { Name = "caret", BackgroundTransparency = 1,
                Size = UDim2.fromOffset(7, 7), Image = resolveIcon("lucide-chevron-down"),
                ImageColor3 = T.Caret, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -3, 0.5, 0) }, btn)
        W:_onTheme(function(t) c.ImageColor3 = t.Caret end)
        return c, function(open)
                TweenService:Create(c, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Rotation = open and 180 or 0 }):Play()
        end
end

--  flag registration
function Card:_flag(cfg, get)
        if cfg.Flag then SWIFT.Flags[cfg.Flag] = get() end
        return function(v) if cfg.Flag then SWIFT.Flags[cfg.Flag] = v end end
end

--================================================================================================
-- COMPONENT · TOGGLE
--   Card:AddToggle{ Name=, Default=false, Flag=, Callback=function(v) end }
--================================================================================================
function Card:AddToggle(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(24)                  -- IMGUI: compact 24px row
        local state = cfg.Default == true

        -- Checkbox with original gradient
        local boxSize = 14
        local box = inst("Frame", {
                BackgroundColor3 = WHITE,  -- WHITE base: UIGradient multiplies with this
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(boxSize, boxSize),
                BorderSizePixel = 0,
        }, r)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, box)
        local grad = inst("UIGradient", { Rotation = 135,
                Color = state and ColorSequence.new(T.AccentDark, W.Accent)
                              or ColorSequence.new(T.ToggleOff, T.ToggleOff) }, box)
        local check = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 8),
                Image = resolveIcon("lucide-check"), ImageColor3 = WHITE, ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                ImageTransparency = state and 0 or 1, ZIndex = 3 }, box)
        local cScale = inst("UIScale", { Scale = state and 1 or 0.6 }, check)
        self:_label(r, cfg.Name or "Toggle", 26)

        local setFlag = self:_flag(cfg, function() return state end)
        local function paint()
                grad.Color = state and ColorSequence.new(W.Theme.AccentDark, W.Accent)
                                   or ColorSequence.new(W.Theme.ToggleOff, W.Theme.ToggleOff)
        end
        W:_onAccent(paint)
        W:_onTheme(paint)

        local api = {}
        function api:Set(v, silent)
                state = v and true or false
                paint(); setFlag(state)
                TweenService:Create(check, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { ImageTransparency = state and 0 or 1 }):Play()
                TweenService:Create(cScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out), { Scale = state and 1 or 0.6 }):Play()
                if not silent and cfg.Callback then task.spawn(cfg.Callback, state) end
                return api
        end
        function api:Get() return state end
        api.Row = r

        -- IMGUI: no bounce animation on click, just clean state toggle
        inst("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
                Size = UDim2.fromScale(1, 1) }, r).Activated:Connect(function()
                        api:Set(not state)
                end)
        if cfg.Default and cfg.Callback then task.spawn(cfg.Callback, state) end
        return api
end

--================================================================================================
-- COMPONENT · SLIDER
--   Card:AddSlider{ Name=, Min=0, Max=100, Default=, Decimals=0, Suffix="", Flag=, Callback= }
--================================================================================================
function Card:AddSlider(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local minV  = cfg.Min or 0
        local maxV  = cfg.Max or 100
        local dp    = cfg.Decimals or 0
        local unit  = cfg.Suffix or cfg.Unit or ""
        local value = math.clamp(cfg.Default or minV, minV, maxV)

        local r = self:_row(36)                  -- IMGUI: 36px slider row
        local nameLbl = inst("TextLabel", { BackgroundTransparency = 1, Font = W.Font,
                Text = cfg.Name or "Slider", TextColor3 = T.RangeLabel, TextSize = 8,
                TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(7, 4),
                Size = UDim2.new(1, -54, 0, 9) }, r)
        local out = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontMedium,
                Text = fmtNumber(minV, dp) .. unit, TextColor3 = T.RangeValue, TextSize = 7,
                TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(48, 9) }, r)
        -- IMGUI: track positioned for compact layout
        local track = inst("Frame", { BackgroundColor3 = T.TrackEmpty, Position = UDim2.fromOffset(7, 20),
                Size = UDim2.new(1, -14, 0, 3) }, r)
        inst("UICorner", { CornerRadius = UDim.new(0, 2) }, track)
        local fill = inst("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1) }, track)
        inst("UICorner", { CornerRadius = UDim.new(0, 2) }, fill)
        local fillGrad = inst("UIGradient", {
                Color = ColorSequence.new(T.AccentDark, W.Accent) }, fill)
        -- Circular thumb
        local thumb = inst("Frame", { BackgroundColor3 = T.Thumb, AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(8, 8) }, track)
        inst("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumb)
        local thumbScale = inst("UIScale", { Scale = 1 }, thumb)

        W:_onAccent(function(c) fillGrad.Color = ColorSequence.new(W.Theme.AccentDark, c) end)
        W:_onTheme(function(t)
                nameLbl.TextColor3 = t.RangeLabel; out.TextColor3 = t.RangeValue
                track.BackgroundColor3 = t.TrackEmpty; thumb.BackgroundColor3 = t.Thumb
                fillGrad.Color = ColorSequence.new(t.AccentDark, W.Accent)
        end)

        local setFlag = self:_flag(cfg, function() return value end)
        local mounting = true
        local moveInfo = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local function apply(v, animate, info, silent)
                value = math.clamp(v, minV, maxV)
                if dp <= 0 then value = math.floor(value + 0.5) else value = round(value, dp) end
                local p = (maxV > minV) and (value - minV) / (maxV - minV) or 0
                if animate then
                        info = info or moveInfo
                        TweenService:Create(fill,  info, { Size     = UDim2.fromScale(p, 1) }):Play()
                        TweenService:Create(thumb, info, { Position = UDim2.fromScale(p, 0.5) }):Play()
                else
                        fill.Size      = UDim2.fromScale(p, 1)
                        thumb.Position = UDim2.fromScale(p, 0.5)
                end
                out.Text = fmtNumber(value, dp) .. unit
                setFlag(value)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, value) end
        end

        local hit = inst("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, 16, 3, 0) }, track)
        local hovering, grabbing = false, false
        local function refreshThumb()
                local big = (hovering or grabbing)
                -- IMGUI: subtle scale, no glow ring
                TweenService:Create(thumbScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out), { Scale = big and 1.25 or 1 }):Play()
        end
        hit.MouseEnter:Connect(function() hovering = true;  refreshThumb() end)
        hit.MouseLeave:Connect(function() hovering = false; refreshThumb() end)

        -- Geometry is LATCHED on press. If this slider's callback resizes the window
        -- (e.g. "Interface Scale"), the track itself moves underneath the cursor —
        -- re-reading AbsolutePosition every frame would make the slider chase a moving
        -- target and jitter. Sampling once keeps the drag a stable 1:1 mapping.
        local gripX, gripW
        local function fromX(x, animate)
                local ap = gripX or track.AbsolutePosition.X
                local as = gripW or track.AbsoluteSize.X
                local p = math.clamp((x - ap) / math.max(as, 1), 0, 1)
                apply(minV + p * (maxV - minV), animate)
        end
        hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch then
                        mounting = false
                        grabbing = true; refreshThumb()
                        gripX, gripW = track.AbsolutePosition.X, track.AbsoluteSize.X
                        fromX(input.Position.X, true)                     -- click-to-jump glides
                        W._activeDrag = function(x) fromX(x, false) end   -- 1:1 while dragging
                end
        end)
        local endConn = UserInputService.InputEnded:Connect(function(input)
                if grabbing and (input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch) then
                        grabbing = false; refreshThumb()
                        gripX, gripW = nil, nil        -- next press re-samples the (possibly moved) track
                        if W._activeDrag then W._activeDrag = nil end
                end
        end)
        r.Destroying:Connect(function() mounting = false; endConn:Disconnect() end)

        -- mount sweep + counting readout, replayed on every tab entry
        local function mount()
                mounting = true
                fill.Size = UDim2.fromScale(0, 1); thumb.Position = UDim2.fromScale(0, 0.5)
                local DUR = 0.45
                apply(value, true, TweenInfo.new(DUR, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), true)
                local target, t0 = value, os.clock()
                while mounting and r.Parent do
                        local a = (os.clock() - t0) / DUR
                        if a >= 1 then break end
                        out.Text = fmtNumber(minV + (target - minV) * (1 - (1 - a) ^ 5), dp) .. unit
                        task.wait()
                end
                if r.Parent then out.Text = fmtNumber(value, dp) .. unit end
                mounting = false
        end
        table.insert(self._mountFns, mount)
        if W.Config.Animate == false then apply(value, false, nil, true) else task.spawn(mount) end

        local api = { Row = r }
        function api:Set(v, silent) mounting = false; apply(v, true, nil, silent); return api end
        function api:Get() return value end
        if cfg.Callback and cfg.Default then task.spawn(cfg.Callback, value) end
        return api
end

--================================================================================================
-- COMPONENT · DROPDOWN   (single select)
--   Card:AddDropdown{ Name=, Options={...}, Default=, Flag=, Callback= }
--   Options may be a table OR a function returning one (evaluated each open → live lists).
--================================================================================================
function Card:AddDropdown(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(23)                  -- IMGUI: compact 23px dropdown row

        local function opts()
                local o = cfg.Options
                if type(o) == "function" then o = o() end
                local out = {}
                for _, v in ipairs(o or {}) do out[#out + 1] = tostring(v) end
                if #out == 0 then out = { "None" } end
                return out
        end

        local current = cfg.Default
        if current == nil or current == "" then current = opts()[1] end

        local btn = self:_pill(r, cfg.Width or 62)       -- IMGUI: 62px
        local txt = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontMedium,
                TextColor3 = T.ControlText, TextSize = 7, Text = tostring(current),
                Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(3, 0),
                TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd }, btn)
        local _, spin = self:_caret(btn)
        self:_label(r, cfg.Name or "Dropdown", 74)       -- IMGUI: 74px right gap
        W:_onTheme(function(t) txt.TextColor3 = t.ControlText end)

        local setFlag = self:_flag(cfg, function() return current end)
        local api = { Row = r }
        function api:Set(v, silent)
                current = v
                TweenService:Create(txt, TweenInfo.new(0.08), { TextTransparency = 1 }):Play()
                task.delay(0.08, function()
                        if not txt.Parent then return end
                        txt.Text = tostring(v)
                        TweenService:Create(txt, TweenInfo.new(0.14), { TextTransparency = 0 }):Play()
                end)
                setFlag(v)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, v) end
                return api
        end
        function api:Get() return current end
        function api:Refresh(newOpts) if newOpts then cfg.Options = newOpts end return api end

        btn.Activated:Connect(function()
                spin(true)
                W:OpenDropdown(btn, opts(), current, function(v) api:Set(v) end, function() spin(false) end)
        end)
        if cfg.Default and cfg.Callback then task.spawn(cfg.Callback, current) end
        return api
end

--================================================================================================
-- COMPONENT · MULTI DROPDOWN
--   Anything NOT ticked is false. Value is a { [option]=bool } map covering every option.
--   Card:AddMultiDropdown{ Name=, Options={...}, Default={"A","B"}, Flag=, Callback= }
--================================================================================================
function Card:AddMultiDropdown(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(25)                  -- IMGUI: compact 25px multi row

        local options = {}
        do
                local o = cfg.Options
                if type(o) == "function" then o = o() end
                for _, v in ipairs(o or {}) do options[#options + 1] = tostring(v) end
        end

        -- EVERY option starts false; only the defaults flip on
        local state = {}
        for _, o in ipairs(options) do state[o] = false end
        for _, o in ipairs(cfg.Default or {}) do
                if state[tostring(o)] ~= nil then state[tostring(o)] = true end
        end

        local btn = self:_pill(r, cfg.Width or 62)       -- IMGUI: 62px
        local txt = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontMedium,
                TextColor3 = T.ControlText, TextSize = 7, Text = "",
                Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(3, 0),
                TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd }, btn)
        local _, spin = self:_caret(btn)
        self:_label(r, cfg.Name or "Multi", 74)          -- IMGUI: 74px right gap

        local setFlag = self:_flag(cfg, function() return state end)
        local function selected()
                local on = {}
                for _, o in ipairs(options) do if state[o] then on[#on + 1] = o end end
                return on
        end
        local function refresh(silent)
                local on = selected()
                local s
                if     #on == 0            then s = "None"
                elseif #on == 1            then s = on[1]
                elseif #on == #options     then s = "All"
                else                            s = on[1] .. " +" .. (#on - 1) end
                txt.Text = s
                txt.TextColor3 = (#on == 0) and W.Theme.Muted or W.Theme.ControlText
                setFlag(state)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, state, on) end
        end
        refresh(true)

        local api = { Row = r }
        function api:Get() return state end
        function api:GetSelected() return selected() end
        --  Accepts EITHER a list of names {"A","B"} OR the map shape this returns from :Get()
        --  ({A=true,B=false}) so a saved config round-trips without the caller converting.
        function api:Set(list, silent)
                for _, o in ipairs(options) do state[o] = false end
                if type(list) == "table" then
                        if #list > 0 then
                                for _, o in ipairs(list) do
                                        if state[tostring(o)] ~= nil then state[tostring(o)] = true end
                                end
                        else
                                for k, v in pairs(list) do
                                        if state[tostring(k)] ~= nil then state[tostring(k)] = (v == true) end
                                end
                        end
                end
                refresh(silent); return api
        end
        btn.Activated:Connect(function()
                spin(true)
                W:OpenMulti(btn, options, state, function() refresh() end, function() spin(false) end)
        end)
        return api
end

--================================================================================================
-- COMPONENT · INPUT   (text or number)
--   Card:AddInput{ Name=, Type="text"|"number", Default=, Placeholder=, Suffix=,
--                  Min=, Max=, Flag=, Callback= }
--================================================================================================
function Card:AddInput(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local isNum = (cfg.Type == "number" or cfg.Numeric == true)
        local minV, maxV = cfg.Min or 0, cfg.Max or 100
        local unit = cfg.Suffix or ""
        local r = self:_row(25)                  -- IMGUI: compact 25px input row

        local holder = inst("Frame", { BackgroundColor3 = T.Control, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(cfg.Width or 62, 15),
                ClipsDescendants = true }, r)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, holder)            -- IMGUI: 3px radius
        local stroke = inst("UIStroke", { Color = T.ControlBorder, Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, holder)
        local underline = inst("Frame", { BackgroundColor3 = W.Accent, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(0, 0, 0, 1) }, holder)
        W:_onAccent(function(c) underline.BackgroundColor3 = c end)

        local typeIcon = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 8),  -- v2.5: 7→8px
                Image = resolveIcon(isNum and "lucide-hash" or "lucide-text-cursor-input"),
                ImageColor3 = T.Muted, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 4, 0.5, 0) }, holder)

        local box = inst("TextBox", { BackgroundTransparency = 1, Font = W.Font, TextSize = 8,    -- v2.5: 7→8pt
                TextColor3 = T.ControlText, Text = tostring(cfg.Default or ""),
                PlaceholderText = tostring(cfg.Placeholder or (isNum and "0" or "")),
                PlaceholderColor3 = T.Muted, ClearTextOnFocus = false,
                TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -18, 1, 0),
                Position = UDim2.fromOffset(13, 0),
                TextXAlignment = isNum and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left }, holder)
        if unit ~= "" then
                inst("TextLabel", { BackgroundTransparency = 1, Font = W.Font, Text = unit,
                        TextColor3 = T.Muted, TextSize = 6, AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(12, 10),
                        TextXAlignment = Enum.TextXAlignment.Right }, holder)
                box.Size = UDim2.new(1, -28, 1, 0)
        end
        self:_label(r, cfg.Name or "Input", 75)
        W:_onTheme(function(t)
                holder.BackgroundColor3 = t.Control; stroke.Color = t.ControlBorder
                box.TextColor3 = t.ControlText; typeIcon.ImageColor3 = t.Muted
        end)

        local value = isNum and math.clamp(tonumber(cfg.Default) or minV, minV, maxV)
                             or tostring(cfg.Default or "")
        local setFlag = self:_flag(cfg, function() return value end)

        local function commit(raw, silent)
                if isNum then
                        local n = tonumber((tostring(raw):gsub("[^%-%d%.]", "")))
                        if n then
                                value = math.clamp(n, minV, maxV)
                                if (cfg.Decimals or 0) <= 0 then value = math.floor(value + 0.5) end
                        else
                                local base = holder.Position          -- reject: shake
                                for i, dx in ipairs({ -3, 3, -2, 2, 0 }) do
                                        task.delay(i * 0.04, function()
                                                if holder.Parent then holder.Position = base + UDim2.fromOffset(dx, 0) end
                                        end)
                                end
                        end
                        box.Text = fmtNumber(value, cfg.Decimals or 0)
                else
                        value = tostring(raw)
                        box.Text = value
                end
                setFlag(value)
                TweenService:Create(stroke, TweenInfo.new(0.1), { Color = W.Accent }):Play()
                task.delay(0.18, function()
                        if stroke.Parent then
                                TweenService:Create(stroke, TweenInfo.new(0.25),
                                        { Color = W.Theme.ControlBorder }):Play()
                        end
                end)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, value) end
        end

        box.Focused:Connect(function()
                TweenService:Create(typeIcon, TweenInfo.new(0.12), { ImageColor3 = W.Accent }):Play()
                TweenService:Create(holder, TweenInfo.new(0.12), { BackgroundColor3 = W.Theme.ControlHover }):Play()
                TweenService:Create(underline, TweenInfo.new(0.18, Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out), { Size = UDim2.new(1, -6, 0, 1) }):Play()
        end)
        box.FocusLost:Connect(function()
                TweenService:Create(typeIcon, TweenInfo.new(0.15), { ImageColor3 = W.Theme.Muted }):Play()
                TweenService:Create(holder, TweenInfo.new(0.15), { BackgroundColor3 = W.Theme.Control }):Play()
                TweenService:Create(underline, TweenInfo.new(0.15), { Size = UDim2.new(0, 0, 0, 1) }):Play()
                commit(box.Text)
        end)

        if isNum then
                local function step(d)
                        value = math.clamp(value + d, minV, maxV)
                        box.Text = fmtNumber(value, cfg.Decimals or 0)
                        setFlag(value)
                        if cfg.Callback then task.spawn(cfg.Callback, value) end
                        TweenService:Create(box, TweenInfo.new(0.06), { TextColor3 = W.Accent }):Play()
                        task.delay(0.1, function()
                                if box.Parent then
                                        TweenService:Create(box, TweenInfo.new(0.2),
                                                { TextColor3 = W.Theme.ControlText }):Play()
                                end
                        end)
                end
                local hovering = false
                holder.MouseEnter:Connect(function() hovering = true end)
                holder.MouseLeave:Connect(function() hovering = false end)
                holder.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseWheel then
                                step(input.Position.Z > 0 and 1 or -1)
                        end
                end)
                local arrow = UserInputService.InputBegan:Connect(function(input, gp)
                        if not hovering or gp then return end
                        if     input.KeyCode == Enum.KeyCode.Up   then step(1)
                        elseif input.KeyCode == Enum.KeyCode.Down then step(-1) end
                end)
                r.Destroying:Connect(function() arrow:Disconnect() end)
        end

        local api = { Row = r, Box = box }
        function api:Set(v, silent) commit(v, silent); return api end
        function api:Get() return value end
        return api
end

--================================================================================================
-- COMPONENT · KEYBIND
--   Card:AddKeybind{ Name=, Default="F1"|Enum.KeyCode, Flag=, Callback=fn(keyName, input) }
--================================================================================================
function Card:AddKeybind(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(27)                  -- v2.5: 25→27px
        local current = cfg.Default
        if typeof(current) == "EnumItem" then current = PRETTY_KEYS[current.Name] or current.Name:upper() end
        current = tostring(current or "NONE")

        local btn, stroke = self:_pill(r, cfg.Width or 44)    -- v2.5: 40→44px
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.Size = UDim2.fromOffset(0, 16)                    -- v2.5: 14→16h
        btn.Font, btn.TextSize, btn.TextColor3 = W.FontMedium, 7, Color3.fromRGB(196, 196, 206)  -- v2.5: 6→7pt, medium weight
        btn.Text = current
        inst("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, btn)
        self:_label(r, cfg.Name or "Keybind", 58)            -- v2.5: 55→58 right gap

        local setFlag = self:_flag(cfg, function() return current end)
        local api = { Row = r }
        function api:Get() return current end
        function api:Set(v, silent)
                current = tostring(v); btn.Text = current; setFlag(current)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, current) end
                return api
        end

        btn.Activated:Connect(function()
                if W._listening then W._listening.cancel(); W._listening = nil end
                local previous = current
                btn.Text = ""
                local waitIcon = inst("ImageLabel", { BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(8, 8), Image = resolveIcon("lucide-keyboard"),
                        ImageColor3 = W.Accent, ScaleType = Enum.ScaleType.Fit,
                        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, btn)
                stroke.Color = W.Accent
                local alive = true
                task.spawn(function()      -- breathe while listening
                        while alive and waitIcon.Parent do
                                TweenService:Create(waitIcon, TweenInfo.new(0.45, Enum.EasingStyle.Sine),
                                        { ImageTransparency = 0.6 }):Play()
                                task.wait(0.45)
                                if not alive then break end
                                TweenService:Create(waitIcon, TweenInfo.new(0.45, Enum.EasingStyle.Sine),
                                        { ImageTransparency = 0 }):Play()
                                task.wait(0.45)
                        end
                end)
                local function restore(name)
                        alive = false
                        if waitIcon then waitIcon:Destroy() end
                        btn.Text = name
                        stroke.Color = W.Theme.ControlBorder
                        btn.TextColor3 = Color3.fromRGB(196, 196, 206)      -- v2.5: match new default
                end
                W._listening = {
                        apply = function(name, input)
                                current = name; restore(name); setFlag(name)
                                TweenService:Create(stroke, TweenInfo.new(0.08), { Color = W.Accent }):Play()
                                task.delay(0.2, function()
                                        if stroke.Parent then
                                                TweenService:Create(stroke, TweenInfo.new(0.3),
                                                        { Color = W.Theme.ControlBorder }):Play()
                                        end
                                end)
                                if cfg.Callback then task.spawn(cfg.Callback, name, input) end
                        end,
                        cancel = function() restore(previous) end,     -- ESC keeps the old binding
                }
        end)
        return api
end

--================================================================================================
-- COMPONENT · COLOURPICKER
--   Card:AddColorpicker{ Name=, Default=Color3, Toggle=false, ToggleDefault=, Flag=, Callback= }
--   Toggle=true renders the mockup's "color-toggle" row (a checkbox + a swatch).
--================================================================================================
function Card:AddColorpicker(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(27)                  -- v2.5: 25→27px
        local color = cfg.Default or W.Accent
        local withToggle = cfg.Toggle == true
        local state = cfg.ToggleDefault == true

        local check, cScale, grad, box
        if withToggle then
                box = inst("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(14, 14),  -- v2.5: 12→14px
                        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0) }, r)  -- v2.5: -24→-28
                inst("UICorner", { CornerRadius = UDim.new(0, 3) }, box)            -- v2.5: 2→3 radius
                grad = inst("UIGradient", { Rotation = 135,
                        Color = state and ColorSequence.new(T.AccentDark, W.Accent)
                                      or ColorSequence.new(T.ToggleOff, T.ToggleOff) }, box)
                check = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(11, 11),  -- v2.5: 10→11px
                        Image = resolveIcon("lucide-check"), ImageColor3 = WHITE,
                        ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5), ImageTransparency = state and 0 or 1 }, box)
                cScale = inst("UIScale", { Scale = state and 1 or 0.55 }, check)
        end

        -- v2.5: larger, rounder colour swatch for a more tactile feel
        local dot = inst("Frame", { BackgroundColor3 = color, Size = UDim2.fromOffset(22, 12),  -- v2.5: 14×9 → 22×12
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0) }, r)
        inst("UICorner", { CornerRadius = UDim.new(0, 3) }, dot)                    -- v2.5: 2→3 radius
        local dScale = inst("UIScale", { Scale = 1 }, dot)
        local ring = inst("UIStroke", { Color = WHITE, Thickness = 0, Transparency = 0.4 }, dot)
        self:_label(r, cfg.Name or "Colour", withToggle and 52 or 34)              -- v2.5: wider gaps for bigger swatch

        local setFlag = self:_flag(cfg, function() return color end)
        local hit = inst("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
                Size = UDim2.fromScale(1, 1) }, dot)
        hit.MouseEnter:Connect(function()
                TweenService:Create(dScale, TweenInfo.new(0.14, Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out), { Scale = 1.18 }):Play()
                TweenService:Create(ring, TweenInfo.new(0.14), { Thickness = 1 }):Play()
        end)
        hit.MouseLeave:Connect(function()
                TweenService:Create(dScale, TweenInfo.new(0.16), { Scale = 1 }):Play()
                TweenService:Create(ring, TweenInfo.new(0.16), { Thickness = 0 }):Play()
        end)

        local api = { Row = r }
        function api:Set(c, silent)
                color = c; dot.BackgroundColor3 = c; setFlag(c)
                if not silent and cfg.Callback then task.spawn(cfg.Callback, c, state) end
                return api
        end
        function api:Get() return color end
        function api:GetToggle() return state end

        hit.Activated:Connect(function()
                dScale.Scale = 0.9
                TweenService:Create(dScale, TweenInfo.new(0.2, Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out), { Scale = 1.18 }):Play()
                W:OpenPicker(dot, color, function(c) api:Set(c) end)
        end)

        if withToggle then
                local function paint()
                        grad.Color = state and ColorSequence.new(W.Theme.AccentDark, W.Accent)
                                           or ColorSequence.new(W.Theme.ToggleOff, W.Theme.ToggleOff)
                end
                W:_onAccent(paint); W:_onTheme(paint)
                local bScale = inst("UIScale", { Scale = 1 }, box)
                inst("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
                        Size = UDim2.fromScale(1, 1) }, box).Activated:Connect(function()
                                state = not state
                                paint()
                                TweenService:Create(check, TweenInfo.new(0.14),
                                        { ImageTransparency = state and 0 or 1 }):Play()
                                TweenService:Create(cScale, TweenInfo.new(0.14, Enum.EasingStyle.Back,
                                        Enum.EasingDirection.Out), { Scale = state and 1 or 0.65 }):Play()
                                bScale.Scale = 0.82
                                TweenService:Create(bScale, TweenInfo.new(0.22, Enum.EasingStyle.Back,
                                        Enum.EasingDirection.Out), { Scale = 1 }):Play()
                                if cfg.Callback then task.spawn(cfg.Callback, color, state) end
                        end)
                function api:SetToggle(v)
                        state = v and true or false; paint()
                        check.ImageTransparency = state and 0 or 1
                        cScale.Scale = state and 1 or 0.65
                        return api
                end
        end
        return api
end

--================================================================================================
-- COMPONENT · BUTTON / LABEL / PARAGRAPH / DIVIDER
--================================================================================================
function Card:AddButton(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(27)                  -- v2.5: 25→27px
        local btn = self:_pill(r, cfg.Width or 56)    -- v2.5: 52→56px
        local lbl = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontMedium,   -- v2.5: medium weight
                Text = cfg.ButtonText or "Run", TextColor3 = T.ControlText, TextSize = 8,    -- v2.5: 7→8pt
                Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center }, btn)
        if cfg.Icon then
                local ic = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(8, 8),  -- v2.5: 7→8px
                        Image = resolveIcon(cfg.Icon), ImageColor3 = T.ControlText,
                        ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 5, 0.5, 0) }, btn)
                lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(1, -16, 1, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                W:_onTheme(function(t) ic.ImageColor3 = t.ControlText end)
        end
        self:_label(r, cfg.Name or "Button", 68)       -- v2.5: 65→68 right gap
        W:_onTheme(function(t) lbl.TextColor3 = t.ControlText end)
        btn.Activated:Connect(function()
                local s = inst("UIScale", { Scale = 0.9 }, btn)
                TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out), { Scale = 1 }):Play()
                task.delay(0.25, function() if s.Parent then s:Destroy() end end)
                if cfg.Callback then task.spawn(cfg.Callback) end
        end)
        return { Row = r, Button = btn }
end

function Card:AddLabel(cfg)
        cfg = type(cfg) == "string" and { Text = cfg } or (cfg or {})
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(cfg.Height or 22)            -- v2.5: 20→22px
        local x = 7                                         -- v2.5: 5→7px
        if cfg.Icon then
                local ic = inst("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(9, 9),  -- v2.5: 8→9px
                        Image = resolveIcon(cfg.Icon), ImageColor3 = W.Accent, ScaleType = Enum.ScaleType.Fit,
                        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0) }, r)
                W:_onAccent(function(c) ic.ImageColor3 = c end)
                x = 18
        end
        local lbl = inst("TextLabel", { BackgroundTransparency = 1, Font = W.Font,
                Text = cfg.Text or "", TextColor3 = T.Label, TextSize = 8,               -- v2.5: 7→8pt
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -(x + 5), 1, 0) }, r)
        W:_onTheme(function(t) lbl.TextColor3 = t.Label end)
        local api = { Row = r }
        function api:Set(t) lbl.Text = t; return api end
        return api
end

function Card:AddParagraph(cfg)
        cfg = cfg or {}
        local W, T = self.Window, self.Window.Theme
        local r = self:_row(cfg.Height or 42)            -- v2.5: 40→42px
        inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontBold, Text = cfg.Title or "",
                TextColor3 = T.SubText, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left,  -- v2.5: 7→8pt
                Position = UDim2.fromOffset(7, 4), Size = UDim2.new(1, -12, 0, 10) }, r)
        local body = inst("TextLabel", { BackgroundTransparency = 1, Font = W.Font,
                Text = cfg.Content or "", TextColor3 = T.Label, TextSize = 7,              -- v2.5: 6→7pt
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true, Position = UDim2.fromOffset(7, 15),
                Size = UDim2.new(1, -12, 1, -18) }, r)
        W:_onTheme(function(t) body.TextColor3 = t.Label end)
        return { Row = r }
end

--  .divider
function Card:AddDivider(text)
        local W, T = self.Window, self.Window.Theme
        local f = inst("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
                LayoutOrder = self:_next() }, self.Scroll)
        if text then
                local lbl = inst("TextLabel", { BackgroundTransparency = 1, Font = W.FontBold,    -- v2.5: Medium→Bold
                        Text = text, TextColor3 = Color3.fromRGB(212, 212, 218), TextSize = 9,    -- v2.5: 8→9pt
                        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom,
                        Size = UDim2.new(1, 0, 1, -4) }, f)
        end
        local line = inst("Frame", { BackgroundColor3 = T.Divider, BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1) }, f)
        W:_onTheme(function(t) line.BackgroundColor3 = t.Divider end)
        return { Row = f }
end

--================================================================================================
-- PERSISTENCE WRAPPER
--   Wraps every value-carrying Card:Add* so that a control is remembered when it declares
--   Save = true, or when it sits on a card that opted the whole card in (_autoSave), which
--   is what the built-in Settings tab does. Wrapping here — once, generically — beats
--   editing eleven component constructors and can't drift out of sync with them.
--================================================================================================
for _, mName in ipairs({ "AddToggle", "AddSlider", "AddDropdown", "AddMultiDropdown",
                         "AddInput", "AddKeybind", "AddColorpicker" }) do
        local original = Card[mName]
        Card[mName] = function(self, cfg, ...)
                local W = self.Window
                local wants = false
                if type(cfg) == "table" and cfg.Flag then
                        wants = cfg.Save
                        if wants == nil then wants = self._autoSave end
                        wants = wants and true or false
                end

                --  Hook the CALLBACK rather than api:Set. Sliders commit from their drag handler,
                --  multi-selects from the overlay, keybinds from the input listener and text boxes
                --  from FocusLost — none of those go through api:Set, but every one of them fires
                --  the callback. Wrapping here catches all change paths with one hook, and silent
                --  restores (which deliberately skip the callback) correctly do NOT queue a write.
                if wants then
                        local userCb = cfg.Callback
                        cfg.Callback = function(...)
                                W:_scheduleSave()
                                if userCb then return userCb(...) end
                        end
                end

                local api = original(self, cfg, ...)

                if wants and api and api.Get and api.Set then
                        W:Persist(cfg.Flag, api)
                        --  Apply the stored value now the control exists. Silent, so restoring never
                        --  re-fires the host script's callback chain during construction.
                        --  The callback DOES fire, on purpose: restoring "ESP = true" has to actually
                        --  switch ESP on, not just tick the box. Pass SilentLoad = true to suppress it.
                        local saved = W.SavedConfig
                        local v = saved and saved.Flags and saved.Flags[cfg.Flag]
                        if v ~= nil then pcall(function() api:Set(v, cfg.SilentLoad == true) end) end
                end
                return api
        end
end

-- aliases so common naming conventions all work
Card.AddSection   = Card.AddDivider
Card.AddTextbox   = Card.AddInput
Card.AddColorPicker = Card.AddColorpicker
Card.AddMulti     = Card.AddMultiDropdown
Card.AddSliderInt = Card.AddSlider

--================================================================================================
-- BUILT-IN SETTINGS TAB
--   Always present. Created lazily but automatically the moment CreateWindow finishes, so
--   every script that loads SWIFT gets it for free with no code. Host scripts can add their
--   own rows to it — the base rows can never be removed.
--
--     Window.Settings                -> the Tab
--     Window:SettingsCard{Title=...} -> a NEW card on that tab, auto-persisting
--     Window.SettingsCards.Menu / .Window / .Config -> the built-in cards, add rows to them
--================================================================================================
local THEME_ORDER = { "Midnight", "Obsidian", "Crimson", "Emerald", "Amethyst", "Ocean",
                      "Sandstorm", "Monochrome" }

function Window:_buildSettingsTab(cfg)
        cfg = cfg or self.Config or {}
        if self.Settings then return self.Settings end

        --  Components fire their Callback once at construction when they have a Default.
        --  For these rows that is actively harmful: the Theme dropdown would call SetTheme(),
        --  which re-derives the palette and would overwrite an accent we just restored from
        --  disk. So the built-in rows no-op until the whole tab is built.
        self._settingsBooting = true

        local tab = self:AddTab({
                Name = cfg.SettingsTabName or "Settings",
                Icon = cfg.SettingsTabIcon or "lucide-settings",
                Section = "Interface", _settings = true,
        })
        self.Settings = tab
        self.SettingsCards = {}

        local function live(fn)
                return function(...)
                        if self._settingsBooting then return end
                        return fn(...)
                end
        end

        --  Cards created here are opted into persistence wholesale.
        local function card(t)
                local c = tab:AddCard(t)
                c._autoSave = true
                return c
        end

        ----------------------------------------------------------------------------------------
        -- CARD 1 · MENU  (appearance)
        ----------------------------------------------------------------------------------------
        local menu = card({ Title = "Menu", Tag = "APPEARANCE", ShowTitle = true })
        self.SettingsCards.Menu = menu

        local themeNames = {}
        for _, n in ipairs(THEME_ORDER) do if THEMES[n] then themeNames[#themeNames + 1] = n end end
        for n in pairs(THEMES) do
                local found = false
                for _, e in ipairs(themeNames) do if e == n then found = true break end end
                if not found then themeNames[#themeNames + 1] = n end
        end

        local themeDd = menu:AddDropdown({
                Name = "Theme", Options = themeNames, Default = self.ThemeName or "Midnight",
                Save = false,           -- stored under the top-level "Theme" key, not as a flag
                Callback = live(function(v) self:SetTheme(v) end),
        })
        local accentCp = menu:AddColorpicker({
                Name = "Accent", Default = self.Accent, Save = false,
                Callback = live(function(c) self:SetAccent(c) end),
        })
        local scaleSl = menu:AddSlider({
                Name = "UI Scale", Min = 50, Max = 250, Default = math.floor((self.S or 1.42) * 100 + 0.5),
                Suffix = "%", Save = false,
                Callback = live(function(v) self:SetScale(v / 100) end),
        })
        local headerNames = { "fps", "fps2", "fps3", "fps4", "fps5", "warzone", "combat",
                              "pficon", "gameicon", "avatar", "none" }
        local hdrDd = menu:AddDropdown({
                Name = "Header Image", Options = headerNames,
                Default = (type(self.HeaderImageName) == "string" and self.HeaderImageName) or "fps",
                Save = false,
                Callback = live(function(v) self:SetHeaderImage(v) end),
        })

        ----------------------------------------------------------------------------------------
        -- CARD 2 · WINDOW  (toggle key + launcher button)
        ----------------------------------------------------------------------------------------
        local win = card({ Title = "Window", Tag = "CONTROLS", ShowTitle = true })
        self.SettingsCards.Window = win

        local keyKb = win:AddKeybind({
                Name = "Toggle Menu", Default = prettyKey(self.ToggleKey), Save = false,
                Callback = live(function(name) self:SetToggleKey(name) end),
        })
        --  There is no on-screen button to bring the menu back, so hiding it from in here has
        --  to tell you which key reopens it — otherwise the menu is simply gone.
        win:AddButton({
                Name = "Hide Menu", ButtonText = "Hide", Icon = "lucide-eye-off",
                Callback = function()
                        local k = self:GetToggleKeyName()
                        self:Toggle(true)
                        if k ~= "NONE" then
                                self:Notify({ Title = "Menu hidden", Content = "Press " .. k .. " to reopen",
                                        Icon = "lucide-keyboard", Duration = 3 })
                        end
                end,
        })
        win:AddButton({
                Name = "Recentre Window", ButtonText = "Centre", Icon = "lucide-move",
                Callback = function()
                        self.Shell.Position = UDim2.fromScale(0.5, 0.5)
                        self:_scheduleSave()
                end,
        })

        ----------------------------------------------------------------------------------------
        -- CARD 3 · CONFIG  (save / load / reset)
        ----------------------------------------------------------------------------------------
        local conf = card({ Title = "Config", Tag = "SAVED", ShowTitle = true })
        self.SettingsCards.Config = conf

        conf:AddToggle({
                Name = "Auto Save", Default = self.AutoSave, Save = false,
                Callback = live(function(v)
                        self.AutoSave = v and true or false
                        if v then self:SaveConfig() end
                end),
        })
        conf:AddButton({
                Name = "Save Now", ButtonText = "Save", Icon = "lucide-save",
                Callback = function()
                        local ok, where = self:SaveConfig()
                        self:Notify({ Title = "UI Settings",
                                Content = ok and (where == "file" and "Written to " .. cfgPath(self.ConfigName)
                                                                   or "Saved for this session")
                                              or "Save failed",
                                Icon = ok and "lucide-check-circle" or "lucide-alert-triangle", Duration = 3 })
                end,
        })
        conf:AddButton({
                Name = "Reload", ButtonText = "Load", Icon = "lucide-download",
                Callback = function()
                        local ok = self:LoadConfig()
                        self:Notify({ Title = "UI Settings",
                                Content = ok and "Config reloaded" or "Nothing saved yet",
                                Icon = ok and "lucide-check-circle" or "lucide-info", Duration = 3 })
                end,
        })
        conf:AddButton({
                Name = "Reset Defaults", ButtonText = "Reset", Icon = "lucide-rotate-ccw",
                Callback = function()
                        self:ResetConfig()
                        self:Notify({ Title = "UI Settings", Content = "Restored to defaults",
                                Icon = "lucide-rotate-ccw", Duration = 3 })
                end,
        })
        conf:AddLabel({
                Text = FS.Available and ("File: " .. cfgPath(self.ConfigName))
                                     or "No filesystem - session only",
                Icon = FS.Available and "lucide-hard-drive" or "lucide-alert-triangle",
        })

        --  Pull the built-in rows back in line after LoadConfig/ResetConfig moved the window
        --  underneath them. Silent so re-displaying a value never re-fires its callback.
        self.SettingsRefresh = function()
                themeDd:Set(self.ThemeName or "Midnight", true)
                accentCp:Set(self.Accent, true)
                scaleSl:Set(math.floor((self.S or 1.42) * 100 + 0.5), true)
                hdrDd:Set((type(self.HeaderImageName) == "string" and self.HeaderImageName) or "fps", true)
                keyKb:Set(prettyKey(self.ToggleKey), true)
        end

        self._settingsBooting = false
        return tab
end

--  Add your own card to the always-present settings tab. Rows on it persist by default.
function Window:SettingsCard(cfg)
        if not self.Settings then self:_buildSettingsTab() end
        local c = self.Settings:AddCard(cfg or { Title = "Custom", ShowTitle = true })
        c._autoSave = true
        return c
end

return SWIFT
