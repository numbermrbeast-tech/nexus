--[[
╔══════════════════════════════════════════════════════════════════╗
║  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗    ██╗   ██╗██████╗║
║  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██║   ██║╚════██╗
║  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║ █████╔╝
║  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ╚██╗ ██╔╝ ╚═══██╗
║  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║     ╚████╔╝ ██████╔╝
║  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝      ╚═══╝  ╚═════╝
║  Da Hood Script  |  Silent Aim + Aimbot + ESP + Config System    ║
║  Version 3.0     |  Advanced Prediction + Auto-Pred + Smooth     ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════════════════════════════
--  CONSTANTS
-- ══════════════════════════════════════════════════════════════════
local NEXUS = {
    Name        = "NexusV3",
    Version     = "3.0.0",
    Author      = "Nexus",
    GameId      = 2788229376,   -- Da Hood
    GameName    = "Da Hood",
    FolderName  = "NexusV3",
    ConfigExt   = ".json",
    AutoUpdateUrl = "",         -- Set your raw URL here for live updates
    ToggleKey   = Enum.KeyCode.RightControl,
    BulletSpeed = 300,          -- Da Hood approximate bullet stud/s
}

-- ══════════════════════════════════════════════════════════════════
--  GAME DETECTOR
-- ══════════════════════════════════════════════════════════════════
local GameDetector = {}

function GameDetector.IsCorrectGame()
    return game.PlaceId == NEXUS.GameId
end

function GameDetector.GetGameName()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end

function GameDetector.Assert()
    if not GameDetector.IsCorrectGame() then
        warn(string.format(
            "[NexusV3] Wrong game detected! Expected '%s' (PlaceId: %d). Got PlaceId: %d. Aborting.",
            NEXUS.GameName, NEXUS.GameId, game.PlaceId
        ))
        return false
    end
    return true
end

-- ══════════════════════════════════════════════════════════════════
--  DEBUG SYSTEM
-- ══════════════════════════════════════════════════════════════════
local Debug = {}
Debug.Enabled  = true
Debug.Verbose  = false
Debug.Logs     = {}
Debug.ErrorLog = {}
Debug.MaxLogs  = 500

local function timestamp()
    return string.format("[%02d:%02d:%02d]", os.date("*t").hour, os.date("*t").min, os.date("*t").sec)
end

function Debug.Log(tag, msg, verbose)
    if not Debug.Enabled then return end
    if verbose and not Debug.Verbose then return end
    local entry = string.format("%s [%s] %s", timestamp(), tag, tostring(msg))
    table.insert(Debug.Logs, entry)
    if #Debug.Logs > Debug.MaxLogs then table.remove(Debug.Logs, 1) end
    print(entry)
end

function Debug.Warn(tag, msg)
    local entry = string.format("%s [WARN][%s] %s", timestamp(), tag, tostring(msg))
    table.insert(Debug.Logs, entry)
    table.insert(Debug.ErrorLog, entry)
    warn(entry)
end

function Debug.Error(tag, msg)
    local entry = string.format("%s [ERROR][%s] %s", timestamp(), tag, tostring(msg))
    table.insert(Debug.Logs, entry)
    table.insert(Debug.ErrorLog, entry)
    warn(entry)
end

function Debug.Dump()
    print("═══════════ NexusV3 Debug Dump ═══════════")
    for _, v in ipairs(Debug.Logs) do print(v) end
    print("═══════════════════════════════════════════")
end

function Debug.DumpErrors()
    print("═══════════ NexusV3 Error Dump ═══════════")
    if #Debug.ErrorLog == 0 then
        print("  No errors logged.")
    else
        for _, v in ipairs(Debug.ErrorLog) do print(v) end
    end
    print("═══════════════════════════════════════════")
end

function Debug.Clear()
    Debug.Logs     = {}
    Debug.ErrorLog = {}
    print("[NexusV3] Debug logs cleared.")
end

-- ══════════════════════════════════════════════════════════════════
--  SAFE WRAPPERS
-- ══════════════════════════════════════════════════════════════════
local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then Debug.Error("Safe", tostring(err)) end
    return ok
end

local function SafeReturn(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        Debug.Error("SafeReturn", tostring(result))
        return nil
    end
    return result
end

local function SafeTween(obj, info, props)
    if not obj or not obj.Parent then return nil end
    local ok, t = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if ok and t then t:Play() return t end
    return nil
end

local function QT(obj, dur, props)
    return SafeTween(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad,        Enum.EasingDirection.Out), props)
end
local function ET(obj, dur, props)
    return SafeTween(obj, TweenInfo.new(dur, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props)
end
local function ST(obj, dur, props)
    return SafeTween(obj, TweenInfo.new(dur, Enum.EasingStyle.Back,        Enum.EasingDirection.Out), props)
end
local function LT(obj, dur, props)
    return SafeTween(obj, TweenInfo.new(dur, Enum.EasingStyle.Linear,      Enum.EasingDirection.InOut), props)
end

-- ══════════════════════════════════════════════════════════════════
--  UNC TEST SYSTEM
-- ══════════════════════════════════════════════════════════════════
local UNCTester = {}
UNCTester.Results = {}

local function testFunc(name, fn)
    local ok, err = pcall(fn)
    local status = ok and "PASS" or "FAIL"
    local entry = {name = name, status = status, err = err}
    table.insert(UNCTester.Results, entry)
    Debug.Log("UNC", string.format("%s  %s %s", status == "PASS" and "✓" or "✗", name, ok and "" or ("— "..tostring(err))))
    return ok
end

function UNCTester.RunAll()
    UNCTester.Results = {}
    Debug.Log("UNC", "Running UNC environment tests...")

    testFunc("readfile",    function() assert(type(readfile) == "function") end)
    testFunc("writefile",   function() assert(type(writefile) == "function") end)
    testFunc("makefolder",  function() assert(type(makefolder) == "function") end)
    testFunc("isfile",      function() assert(type(isfile) == "function") end)
    testFunc("isfolder",    function() assert(type(isfolder) == "function") end)
    testFunc("listfiles",   function() assert(type(listfiles) == "function") end)
    testFunc("delfile",     function() assert(type(delfile) == "function") end)

    testFunc("request / http",   function() assert(type(request) == "function" or type(http) == "table" or type(syn) == "table") end)
    testFunc("getgenv",          function() assert(type(getgenv) == "function") end)
    testFunc("getrenv",          function() assert(type(getrenv) == "function") end)
    testFunc("getfenv",          function() assert(type(getfenv) == "function") end)
    testFunc("getsenv",          function() assert(type(getsenv) == "function") end)
    testFunc("hookfunction",     function() assert(type(hookfunction) == "function") end)
    testFunc("newcclosure",      function() assert(type(newcclosure) == "function") end)
    testFunc("iscclosure",       function() assert(type(iscclosure) == "function") end)
    testFunc("islclosure",       function() assert(type(islclosure) == "function") end)
    testFunc("checkcaller",      function() assert(type(checkcaller) == "function") end)
    testFunc("clonefunction",    function() assert(type(clonefunction) == "function") end)
    testFunc("getinstances",     function() assert(type(getinstances) == "function") end)
    testFunc("getnilinstances",  function() assert(type(getnilinstances) == "function") end)
    testFunc("getscripts",       function() assert(type(getscripts) == "function") end)
    testFunc("getloadedmodules", function() assert(type(getloadedmodules) == "function") end)
    testFunc("getcallingscript", function() assert(type(getcallingscript) == "function") end)
    testFunc("getconnections",   function() assert(type(getconnections) == "function") end)
    testFunc("firesignal",       function() assert(type(firesignal) == "function") end)
    testFunc("fireclickdetector",function() assert(type(fireclickdetector) == "function") end)
    testFunc("fireproximityprompt", function() assert(type(fireproximityprompt) == "function") end)
    testFunc("getrawmetatable",  function() assert(type(getrawmetatable) == "function") end)
    testFunc("setrawmetatable",  function() assert(type(setrawmetatable) == "function") end)
    testFunc("setreadonly",      function() assert(type(setreadonly) == "function") end)
    testFunc("isreadonly",       function() assert(type(isreadonly) == "function") end)
    testFunc("identifyexecutor", function() assert(type(identifyexecutor) == "function" or type(syn) == "table") end)
    testFunc("Drawing",          function() assert(type(Drawing) == "table") end)
    testFunc("Drawing.new",      function() assert(type(Drawing.new) == "function") end)
    testFunc("cleardrawcache",   function() assert(type(cleardrawcache) == "function") end)

    local pass = 0
    local fail = 0
    for _, r in ipairs(UNCTester.Results) do
        if r.status == "PASS" then pass = pass + 1 else fail = fail + 1 end
    end

    Debug.Log("UNC", string.format("Done: %d/%d passed (%d failed)", pass, pass+fail, fail))
    return pass, fail, UNCTester.Results
end

function UNCTester.GetExecutorName()
    if type(identifyexecutor) == "function" then
        return identifyexecutor()
    elseif type(syn) == "table" then
        return "Synapse X"
    elseif type(KRNL_LOADED) ~= "nil" then
        return "Krnl"
    elseif type(RC_VERSION) ~= "nil" then
        return "RC7"
    else
        return "Unknown Executor"
    end
end

-- ══════════════════════════════════════════════════════════════════
--  FILE SYSTEM / CONFIG MANAGER
-- ══════════════════════════════════════════════════════════════════
local ConfigManager = {}
ConfigManager.FolderPath  = NEXUS.FolderName
ConfigManager.ConfigPath  = NEXUS.FolderName .. "/configs"
ConfigManager.LogPath     = NEXUS.FolderName .. "/logs"
ConfigManager.CurrentCfg  = "default"

local function FSAvailable()
    return type(writefile) == "function" and type(readfile) == "function"
        and type(makefolder) == "function" and type(isfolder) == "function"
end

function ConfigManager.Init()
    if not FSAvailable() then
        Debug.Warn("Config", "Filesystem functions unavailable — configs will not persist.")
        return false
    end
    Safe(function()
        if not isfolder(ConfigManager.FolderPath) then
            makefolder(ConfigManager.FolderPath)
            Debug.Log("Config", "Created folder: " .. ConfigManager.FolderPath)
        end
        if not isfolder(ConfigManager.ConfigPath) then
            makefolder(ConfigManager.ConfigPath)
            Debug.Log("Config", "Created folder: " .. ConfigManager.ConfigPath)
        end
        if not isfolder(ConfigManager.LogPath) then
            makefolder(ConfigManager.LogPath)
            Debug.Log("Config", "Created folder: " .. ConfigManager.LogPath)
        end
    end)
    return true
end

local function TableToJson(tbl, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    local result = "{\n"
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for i, k in ipairs(keys) do
        local v = tbl[k]
        local key = string.format('%s  "%s": ', spaces, tostring(k))
        local val
        if type(v) == "table" then
            val = TableToJson(v, indent + 1)
        elseif type(v) == "string" then
            val = string.format('"%s"', v:gsub('"', '\\"'))
        elseif type(v) == "number" then
            val = string.format("%g", v)
        elseif type(v) == "boolean" then
            val = v and "true" or "false"
        else
            val = string.format('"%s"', tostring(v))
        end
        result = result .. key .. val
        if i < #keys then result = result .. "," end
        result = result .. "\n"
    end
    return result .. spaces .. "}"
end

local function JsonToTable(str)
    -- Simple JSON parser for flat/nested bool+number+string
    local ok, result = pcall(function()
        local t = {}
        -- Parse string values
        for k, v in str:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
            t[k] = v
        end
        -- Parse bool values
        for k, v in str:gmatch('"([^"]+)"%s*:%s*(true|false)') do
            t[k] = (v == "true")
        end
        -- Parse number values (not already matched)
        for k, v in str:gmatch('"([^"]+)"%s*:%s*(%-?%d+%.?%d*)') do
            if t[k] == nil then
                t[k] = tonumber(v)
            end
        end
        return t
    end)
    if ok then return result else return {} end
end

function ConfigManager.Save(name, data)
    if not FSAvailable() then return false end
    name = name or ConfigManager.CurrentCfg
    local path = ConfigManager.ConfigPath .. "/" .. name .. NEXUS.ConfigExt
    local ok = Safe(function()
        local json = TableToJson(data)
        writefile(path, json)
        Debug.Log("Config", "Saved config: " .. name)
    end)
    return ok
end

function ConfigManager.Load(name)
    if not FSAvailable() then return nil end
    name = name or ConfigManager.CurrentCfg
    local path = ConfigManager.ConfigPath .. "/" .. name .. NEXUS.ConfigExt
    local data = SafeReturn(function()
        if not isfile(path) then
            Debug.Warn("Config", "Config not found: " .. name)
            return nil
        end
        local content = readfile(path)
        return JsonToTable(content)
    end)
    if data then Debug.Log("Config", "Loaded config: " .. name) end
    return data
end

function ConfigManager.Delete(name)
    if not FSAvailable() then return false end
    local path = ConfigManager.ConfigPath .. "/" .. name .. NEXUS.ConfigExt
    return Safe(function()
        if type(delfile) == "function" and isfile(path) then
            delfile(path)
            Debug.Log("Config", "Deleted config: " .. name)
        end
    end)
end

function ConfigManager.List()
    if not FSAvailable() then return {} end
    local configs = {}
    Safe(function()
        if type(listfiles) == "function" then
            local files = listfiles(ConfigManager.ConfigPath)
            for _, f in ipairs(files) do
                local name = f:match("([^/\\]+)" .. NEXUS.ConfigExt .. "$")
                if name then table.insert(configs, name) end
            end
        end
    end)
    return configs
end

function ConfigManager.WriteLog(content)
    if not FSAvailable() then return end
    Safe(function()
        local t = os.date("*t")
        local fname = string.format("%s/%04d-%02d-%02d_%02d-%02d.txt",
            ConfigManager.LogPath, t.year, t.month, t.day, t.hour, t.min)
        writefile(fname, content)
        Debug.Log("Config", "Log written: " .. fname)
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  AUTO UPDATER
-- ══════════════════════════════════════════════════════════════════
local AutoUpdater = {}
AutoUpdater.LatestVersion = NEXUS.Version
AutoUpdater.UpdateAvailable = false
AutoUpdater.Status = "idle"   -- idle / checking / uptodate / outdated / error

function AutoUpdater.ParseVersion(vstr)
    local major, minor, patch = vstr:match("(%d+)%.(%d+)%.(%d+)")
    if not major then
        major, minor = vstr:match("(%d+)%.(%d+)")
        patch = 0
    end
    return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
end

function AutoUpdater.IsNewer(v1, v2)
    local ma1, mi1, p1 = AutoUpdater.ParseVersion(v1)
    local ma2, mi2, p2 = AutoUpdater.ParseVersion(v2)
    if ma1 ~= ma2 then return ma1 > ma2 end
    if mi1 ~= mi2 then return mi1 > mi2 end
    return p1 > p2
end

function AutoUpdater.Check(callback)
    if NEXUS.AutoUpdateUrl == "" then
        AutoUpdater.Status = "uptodate"
        Debug.Log("Updater", "No update URL configured.")
        if callback then callback(false, NEXUS.Version, NEXUS.Version) end
        return
    end

    AutoUpdater.Status = "checking"
    Debug.Log("Updater", "Checking for updates...")

    task.spawn(function()
        local ok, result = pcall(function()
            local res
            if type(request) == "function" then
                res = request({Url = NEXUS.AutoUpdateUrl, Method = "GET"})
                return res and res.Body or nil
            elseif type(syn) == "table" and type(syn.request) == "function" then
                res = syn.request({Url = NEXUS.AutoUpdateUrl, Method = "GET"})
                return res and res.Body or nil
            end
            return nil
        end)

        if ok and result then
            local remoteVersion = result:match("version%s*=%s*[\"']?([%d%.]+)")
                                or result:match("([%d]+%.[%d]+%.[%d]+)")
            if remoteVersion then
                AutoUpdater.LatestVersion = remoteVersion
                if AutoUpdater.IsNewer(remoteVersion, NEXUS.Version) then
                    AutoUpdater.UpdateAvailable = true
                    AutoUpdater.Status = "outdated"
                    Debug.Log("Updater", "Update available: v" .. remoteVersion)
                    if callback then callback(true, NEXUS.Version, remoteVersion) end
                else
                    AutoUpdater.Status = "uptodate"
                    Debug.Log("Updater", "Up to date: v" .. NEXUS.Version)
                    if callback then callback(false, NEXUS.Version, NEXUS.Version) end
                end
            else
                AutoUpdater.Status = "error"
                Debug.Warn("Updater", "Could not parse remote version.")
                if callback then callback(false, NEXUS.Version, NEXUS.Version) end
            end
        else
            AutoUpdater.Status = "error"
            Debug.Warn("Updater", "Update check failed: " .. tostring(result))
            if callback then callback(false, NEXUS.Version, NEXUS.Version) end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════════
local Theme = {
    Bg          = Color3.fromRGB(11, 11, 16),
    Surface     = Color3.fromRGB(18, 18, 26),
    SurfaceAlt  = Color3.fromRGB(24, 24, 34),
    SurfaceHov  = Color3.fromRGB(30, 30, 44),
    Border      = Color3.fromRGB(40, 40, 60),
    BorderBright= Color3.fromRGB(60, 60, 90),
    Accent      = Color3.fromRGB(110, 55, 235),
    AccentBright= Color3.fromRGB(140, 90, 255),
    AccentDark  = Color3.fromRGB(75, 35, 165),
    AccentGlow  = Color3.fromRGB(90, 40, 210),
    Cyan        = Color3.fromRGB(40, 180, 255),
    Pink        = Color3.fromRGB(210, 55, 190),
    TextHi      = Color3.fromRGB(245, 245, 255),
    TextMid     = Color3.fromRGB(160, 160, 195),
    TextLow     = Color3.fromRGB(95, 95, 130),
    TextDim     = Color3.fromRGB(55, 55, 80),
    Green       = Color3.fromRGB(55, 220, 120),
    Red         = Color3.fromRGB(225, 55, 75),
    Yellow      = Color3.fromRGB(225, 185, 35),
    Orange      = Color3.fromRGB(225, 120, 35),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0, 0, 0),
}

-- ══════════════════════════════════════════════════════════════════
--  UI FACTORY
-- ══════════════════════════════════════════════════════════════════
local UI = {}

function UI.New(class, props, parent)
    local ok, inst = pcall(function()
        local i = Instance.new(class)
        for k, v in pairs(props or {}) do
            pcall(function() i[k] = v end)
        end
        if parent then i.Parent = parent end
        return i
    end)
    if not ok then Debug.Error("UI.New", "Failed "..class..": "..tostring(inst)) return nil end
    return inst
end

function UI.Corner(r, p)
    return UI.New("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end

function UI.Stroke(color, thick, trans, p)
    return UI.New("UIStroke", {
        Color        = color or Theme.Border,
        Thickness    = thick or 1,
        Transparency = trans or 0,
    }, p)
end

function UI.Pad(t, b, l, r, p)
    return UI.New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    }, p)
end

function UI.Grad(rot, colors, p)
    local kps = {}
    for i, c in ipairs(colors) do
        kps[i] = ColorSequenceKeypoint.new((i-1)/(#colors-1), c)
    end
    return UI.New("UIGradient", {
        Rotation = rot or 0,
        Color    = ColorSequence.new(kps),
    }, p)
end

function UI.List(padding, dir, align, p)
    return UI.New("UIListLayout", {
        Padding             = UDim.new(0, padding or 0),
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    }, p)
end

function UI.Frame(props, parent)
    return UI.New("Frame", props, parent)
end

function UI.TextLabel(props, parent)
    return UI.New("TextLabel", props, parent)
end

function UI.TextButton(props, parent)
    return UI.New("TextButton", props, parent)
end

function UI.TextBox(props, parent)
    return UI.New("TextBox", props, parent)
end

function UI.ScrollFrame(props, parent)
    return UI.New("ScrollingFrame", props, parent)
end

function UI.ImageLabel(props, parent)
    return UI.New("ImageLabel", props, parent)
end

function UI.Ripple(btn, color)
    Safe(function()
        local r = UI.Frame({
            AnchorPoint            = Vector2.new(0.5, 0.5),
            BackgroundColor3       = color or Theme.White,
            BackgroundTransparency = 0.78,
            Position               = UDim2.new(0.5, 0, 0.5, 0),
            Size                   = UDim2.new(0, 0, 0, 0),
            ZIndex                 = btn.ZIndex + 10,
            ClipsDescendants       = false,
        }, btn)
        UI.Corner(999, r)
        local ms = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.8
        QT(r, 0.55, {
            Size                   = UDim2.new(0, ms, 0, ms),
            BackgroundTransparency = 1,
        })
        task.delay(0.55, function()
            if r and r.Parent then r:Destroy() end
        end)
    end)
end

function UI.MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, mpos, fpos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mpos = input.Position
            fpos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mpos
            frame.Position = UDim2.new(
                fpos.X.Scale, fpos.X.Offset + delta.X,
                fpos.Y.Scale, fpos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  FOV CIRCLE DRAWING
-- ══════════════════════════════════════════════════════════════════
local FOVCircle = {}
FOVCircle.Circle  = nil
FOVCircle.Enabled = false
FOVCircle.Radius  = 100
FOVCircle.Color   = Color3.fromRGB(255, 255, 255)
FOVCircle.Thick   = 1.5

function FOVCircle.Create()
    if type(Drawing) ~= "table" then return end
    if FOVCircle.Circle then
        pcall(function() FOVCircle.Circle:Remove() end)
    end
    Safe(function()
        local c = Drawing.new("Circle")
        c.Visible   = FOVCircle.Enabled
        c.Position  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        c.Radius    = FOVCircle.Radius
        c.Color     = FOVCircle.Color
        c.Thickness = FOVCircle.Thick
        c.Filled    = false
        c.Transparency = 1
        FOVCircle.Circle = c
    end)
end

function FOVCircle.Update(radius, color, enabled)
    FOVCircle.Radius  = radius or FOVCircle.Radius
    FOVCircle.Color   = color  or FOVCircle.Color
    FOVCircle.Enabled = enabled ~= nil and enabled or FOVCircle.Enabled
    if FOVCircle.Circle then
        Safe(function()
            FOVCircle.Circle.Radius  = FOVCircle.Radius
            FOVCircle.Circle.Color   = FOVCircle.Color
            FOVCircle.Circle.Visible = FOVCircle.Enabled
        end)
    end
end

function FOVCircle.Destroy()
    if FOVCircle.Circle then
        Safe(function() FOVCircle.Circle:Remove() end)
        FOVCircle.Circle = nil
    end
end

-- Keep FOV circle centered
RunService.RenderStepped:Connect(function()
    if FOVCircle.Circle and FOVCircle.Circle.Visible then
        Safe(function()
            FOVCircle.Circle.Position = Vector2.new(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y / 2
            )
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  PREDICTION ENGINE
-- ══════════════════════════════════════════════════════════════════
local Prediction = {}
Prediction.Multiplier    = 1.0
Prediction.AutoEnabled   = false
Prediction.MinMultiplier = 0.5
Prediction.MaxMultiplier = 2.5
Prediction.HitHistory    = {}   -- {true/false, ...}
Prediction.HistorySize   = 20
Prediction.AdjustRate    = 0.08

function Prediction.GetVelocity(hrp)
    if not hrp then return Vector3.zero end
    local vel = SafeReturn(function() return hrp.Velocity end)
    return vel or Vector3.zero
end

function Prediction.Calculate(targetPos, targetVel, origin, bulletSpeed)
    bulletSpeed = bulletSpeed or NEXUS.BulletSpeed
    local dist      = (targetPos - origin).Magnitude
    local travelTime = dist / bulletSpeed
    -- Iterative refinement (2 passes)
    local predicted = targetPos + targetVel * travelTime * Prediction.Multiplier
    local dist2      = (predicted - origin).Magnitude
    local travelTime2 = dist2 / bulletSpeed
    predicted = targetPos + targetVel * travelTime2 * Prediction.Multiplier
    return predicted, travelTime2
end

function Prediction.RecordHit(wasHit)
    table.insert(Prediction.HitHistory, wasHit)
    if #Prediction.HitHistory > Prediction.HistorySize then
        table.remove(Prediction.HitHistory, 1)
    end
end

function Prediction.AutoAdjust()
    if not Prediction.AutoEnabled then return end
    if #Prediction.HitHistory < 5 then return end
    local hits = 0
    for _, v in ipairs(Prediction.HitHistory) do
        if v then hits = hits + 1 end
    end
    local ratio = hits / #Prediction.HitHistory
    -- Too many misses → increase prediction
    -- Too many hits → decrease slightly
    if ratio < 0.4 then
        Prediction.Multiplier = math.min(
            Prediction.Multiplier + Prediction.AdjustRate,
            Prediction.MaxMultiplier
        )
    elseif ratio > 0.75 then
        Prediction.Multiplier = math.max(
            Prediction.Multiplier - Prediction.AdjustRate * 0.5,
            Prediction.MinMultiplier
        )
    end
    Debug.Log("Prediction", string.format("AutoPred: %.2f (hit rate %.0f%%)", Prediction.Multiplier, ratio*100), true)
end

-- ══════════════════════════════════════════════════════════════════
--  PLAYER UTILITIES
-- ══════════════════════════════════════════════════════════════════
local PlayerUtil = {}

function PlayerUtil.GetCharacter(player)
    return player and player.Character
end

function PlayerUtil.GetHRP(player)
    local char = PlayerUtil.GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

function PlayerUtil.GetHumanoid(player)
    local char = PlayerUtil.GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

function PlayerUtil.IsAlive(player)
    local hum = PlayerUtil.GetHumanoid(player)
    return hum and hum.Health > 0
end

function PlayerUtil.GetPartPosition(player, partName)
    local char = PlayerUtil.GetCharacter(player)
    if not char then return nil end
    local part = char:FindFirstChild(partName)
    if part then return part.Position end
    -- Fall back to HRP
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position
end

function PlayerUtil.IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

function PlayerUtil.IsOnScreen(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return onScreen, Vector2.new(vp.X, vp.Y), vp.Z
end

function PlayerUtil.GetScreenPos(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

function PlayerUtil.DistanceToMouse(player, hitPart)
    local hrp = PlayerUtil.GetHRP(player)
    if not hrp then return math.huge end
    local targetPos = PlayerUtil.GetPartPosition(player, hitPart) or hrp.Position
    local screenPos, onScreen = PlayerUtil.GetScreenPos(targetPos)
    if not onScreen then return math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - center).Magnitude
end

-- ══════════════════════════════════════════════════════════════════
--  AIMBOT SYSTEM
-- ══════════════════════════════════════════════════════════════════
local Aimbot = {}

Aimbot.Enabled        = false
Aimbot.FOV            = 120
Aimbot.Smoothness     = 0.25      -- 0.05 = very smooth, 1.0 = instant
Aimbot.HitPart        = "Head"
Aimbot.TeamCheck      = true
Aimbot.VisCheck       = true
Aimbot.HoldKey        = Enum.UserInputType.MouseButton2
Aimbot.Target         = nil
Aimbot.Locked         = false
Aimbot.MaxDistance    = 500
Aimbot.Connections    = {}
Aimbot.StickyTarget   = false     -- keep target even if no longer closest
Aimbot.StickyTimeout  = 3.0       -- seconds before sticky expires
Aimbot._stickyTimer   = 0

function Aimbot.GetBestTarget()
    local best    = nil
    local bestDist = Aimbot.FOV + 1

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not PlayerUtil.IsAlive(player) then continue end
        if Aimbot.TeamCheck and PlayerUtil.IsTeammate(player) then continue end

        local hrp = PlayerUtil.GetHRP(player)
        if not hrp then continue end

        -- Distance check
        local localHRP = PlayerUtil.GetHRP(LocalPlayer)
        if localHRP then
            local worldDist = (hrp.Position - localHRP.Position).Magnitude
            if worldDist > Aimbot.MaxDistance then continue end
        end

        -- Visibility check
        if Aimbot.VisCheck then
            local origin = Camera.CFrame.Position
            local result = Workspace:Raycast(
                origin,
                (hrp.Position - origin),
                RaycastParams.new()
            )
            if result and result.Instance then
                local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
                local targetChar = player.Character
                if hitChar ~= targetChar then continue end
            end
        end

        local dist = PlayerUtil.DistanceToMouse(player, Aimbot.HitPart)
        if dist < bestDist then
            bestDist = dist
            best     = player
        end
    end

    return best
end

function Aimbot.LockOn(player)
    Aimbot.Target = player
    Aimbot.Locked = player ~= nil
    Aimbot._stickyTimer = 0
end

function Aimbot.Step(dt)
    if not Aimbot.Enabled then return end

    local holding = UserInputService:IsMouseButtonPressed(Aimbot.HoldKey)
        or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if not holding then
        if not Aimbot.StickyTarget then
            Aimbot.Target = nil
            Aimbot.Locked = false
        end
        return
    end

    -- Sticky timeout
    if Aimbot.StickyTarget and Aimbot.Locked then
        Aimbot._stickyTimer = Aimbot._stickyTimer + dt
        if Aimbot._stickyTimer >= Aimbot.StickyTimeout then
            Aimbot.Target = nil
            Aimbot.Locked = false
            Aimbot._stickyTimer = 0
        end
    end

    -- Re-acquire if no target
    if not Aimbot.Locked or not Aimbot.Target then
        local t = Aimbot.GetBestTarget()
        Aimbot.LockOn(t)
        if t then
            Debug.Log("Aimbot", "Locked onto: " .. t.Name, true)
        end
    end

    if not Aimbot.Target then return end

    -- Validate target still alive and in range
    if not PlayerUtil.IsAlive(Aimbot.Target) then
        Aimbot.LockOn(nil)
        return
    end

    local dist = PlayerUtil.DistanceToMouse(Aimbot.Target, Aimbot.HitPart)
    if dist > Aimbot.FOV * 1.5 and not Aimbot.StickyTarget then
        Aimbot.LockOn(nil)
        return
    end

    -- Get target position (with prediction)
    local hrp      = PlayerUtil.GetHRP(Aimbot.Target)
    if not hrp then Aimbot.LockOn(nil) return end

    local origin   = Camera.CFrame.Position
    local targetPos = PlayerUtil.GetPartPosition(Aimbot.Target, Aimbot.HitPart)
                   or hrp.Position
    local vel      = Prediction.GetVelocity(hrp)

    local predicted
    if Prediction.Multiplier > 0.01 then
        predicted = Prediction.Calculate(targetPos, vel, origin)
    else
        predicted = targetPos
    end

    -- Smooth aim: lerp camera toward target
    local currentCF  = Camera.CFrame
    local targetCF   = CFrame.lookAt(currentCF.Position, predicted)
    local smoothed   = currentCF:Lerp(targetCF, math.clamp(Aimbot.Smoothness, 0.01, 1.0))

    Safe(function()
        Camera.CFrame = smoothed
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  SILENT AIM SYSTEM
-- ══════════════════════════════════════════════════════════════════
local SilentAim = {}

SilentAim.Enabled       = false
SilentAim.HitPart       = "Head"
SilentAim.TeamCheck     = true
SilentAim.FOV           = 180
SilentAim.MaxDistance   = 500
SilentAim._hooked       = false
SilentAim._origNewIndex = nil
SilentAim._origIndex    = nil
SilentAim._connection   = nil

function SilentAim.GetTarget()
    local best     = nil
    local bestDist = SilentAim.FOV + 1

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not PlayerUtil.IsAlive(player) then continue end
        if SilentAim.TeamCheck and PlayerUtil.IsTeammate(player) then continue end

        local hrp = PlayerUtil.GetHRP(player)
        if not hrp then continue end

        local localHRP = PlayerUtil.GetHRP(LocalPlayer)
        if localHRP then
            local wd = (hrp.Position - localHRP.Position).Magnitude
            if wd > SilentAim.MaxDistance then continue end
        end

        local d = PlayerUtil.DistanceToMouse(player, SilentAim.HitPart)
        if d < bestDist then
            bestDist = d
            best     = player
        end
    end

    return best
end

-- Mouse metamethod hook for silent aim
function SilentAim.Hook()
    if SilentAim._hooked then return end
    if not (type(getrawmetatable) == "function") then
        Debug.Warn("SilentAim", "getrawmetatable not available — silent aim cannot hook mouse")
        return
    end

    Safe(function()
        local mt = getrawmetatable(Mouse)
        if not mt then
            Debug.Warn("SilentAim", "Could not get mouse metatable")
            return
        end

        local wasReadonly = isreadonly and isreadonly(mt)
        if wasReadonly and setreadonly then
            setreadonly(mt, false)
        end

        local origIndex = mt.__index
        mt.__index = newcclosure and newcclosure(function(self, key)
            if SilentAim.Enabled and (key == "Hit" or key == "Target") then
                local target = SilentAim.GetTarget()
                if target then
                    local partPos = PlayerUtil.GetPartPosition(target, SilentAim.HitPart)
                    local hrp     = PlayerUtil.GetHRP(target)
                    if partPos and hrp then
                        local vel = Prediction.GetVelocity(hrp)
                        local origin = Camera.CFrame.Position
                        local predicted = Prediction.Calculate(partPos, vel, origin)

                        if key == "Hit" then
                            return CFrame.new(predicted)
                        elseif key == "Target" then
                            local char = target.Character
                            if char then
                                return char:FindFirstChild(SilentAim.HitPart) or hrp
                            end
                        end
                    end
                end
            end
            if type(origIndex) == "function" then
                return origIndex(self, key)
            end
            return rawget(self, key)
        end) or function(self, key)
            if SilentAim.Enabled and (key == "Hit" or key == "Target") then
                local target = SilentAim.GetTarget()
                if target then
                    local partPos = PlayerUtil.GetPartPosition(target, SilentAim.HitPart)
                    local hrp     = PlayerUtil.GetHRP(target)
                    if partPos and hrp then
                        local vel = Prediction.GetVelocity(hrp)
                        local origin = Camera.CFrame.Position
                        local predicted = Prediction.Calculate(partPos, vel, origin)
                        if key == "Hit" then return CFrame.new(predicted) end
                        if key == "Target" then
                            local char = target.Character
                            return char and (char:FindFirstChild(SilentAim.HitPart) or hrp) or hrp
                        end
                    end
                end
            end
            if type(origIndex) == "function" then return origIndex(self, key) end
            return rawget(self, key)
        end

        SilentAim._origIndex = origIndex
        if wasReadonly and setreadonly then setreadonly(mt, true) end
        SilentAim._hooked = true
        Debug.Log("SilentAim", "Mouse hook installed successfully")
    end)
end

function SilentAim.Unhook()
    if not SilentAim._hooked then return end
    Safe(function()
        local mt = getrawmetatable(Mouse)
        if not mt then return end
        local wasReadonly = isreadonly and isreadonly(mt)
        if wasReadonly and setreadonly then setreadonly(mt, false) end
        if SilentAim._origIndex then
            mt.__index = SilentAim._origIndex
        end
        if wasReadonly and setreadonly then setreadonly(mt, true) end
        SilentAim._hooked = false
        Debug.Log("SilentAim", "Mouse hook removed")
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  ESP SYSTEM
-- ══════════════════════════════════════════════════════════════════
local ESP = {}
ESP.Enabled       = false
ESP.Boxes         = true
ESP.Names         = true
ESP.Distance      = true
ESP.Health        = true
ESP.Tracers       = false
ESP.TeamCheck     = false
ESP.MaxDistance   = 500
ESP.BoxColor      = Color3.fromRGB(255, 50, 50)
ESP.TeamColor     = Color3.fromRGB(50, 200, 100)
ESP.NameColor     = Color3.fromRGB(255, 255, 255)
ESP.DistColor     = Color3.fromRGB(200, 200, 200)
ESP.HealthColor   = Color3.fromRGB(50, 220, 100)
ESP.TracerColor   = Color3.fromRGB(255, 50, 50)
ESP.TextSize      = 14
ESP._drawings     = {}  -- [player.UserId] = {box, name, dist, health, tracer}
ESP._connection   = nil

local function DrawingAvailable()
    return type(Drawing) == "table" and type(Drawing.new) == "function"
end

local function NewDrawing(class, props)
    if not DrawingAvailable() then return nil end
    local d = SafeReturn(function()
        local obj = Drawing.new(class)
        for k, v in pairs(props or {}) do
            pcall(function() obj[k] = v end)
        end
        return obj
    end)
    return d
end

local function RemoveDrawing(d)
    if d then Safe(function() d:Remove() end) end
end

function ESP.CreateForPlayer(player)
    if player == LocalPlayer then return end
    if ESP._drawings[player.UserId] then return end

    local drawings = {}

    drawings.box = NewDrawing("Square", {
        Visible      = false,
        Filled       = false,
        Color        = ESP.BoxColor,
        Thickness    = 1.5,
        Transparency = 1,
    })

    drawings.name = NewDrawing("Text", {
        Visible      = false,
        Color        = ESP.NameColor,
        Size         = ESP.TextSize,
        Center       = true,
        Outline      = true,
        OutlineColor = Color3.fromRGB(0,0,0),
        Transparency = 1,
    })

    drawings.dist = NewDrawing("Text", {
        Visible      = false,
        Color        = ESP.DistColor,
        Size         = ESP.TextSize - 2,
        Center       = true,
        Outline      = true,
        OutlineColor = Color3.fromRGB(0,0,0),
        Transparency = 1,
    })

    drawings.health = NewDrawing("Square", {
        Visible      = false,
        Filled       = true,
        Color        = ESP.HealthColor,
        Transparency = 1,
    })

    drawings.healthBg = NewDrawing("Square", {
        Visible      = false,
        Filled       = true,
        Color        = Color3.fromRGB(30, 30, 30),
        Transparency = 1,
    })

    drawings.tracer = NewDrawing("Line", {
        Visible      = false,
        Color        = ESP.TracerColor,
        Thickness    = 1,
        Transparency = 1,
    })

    ESP._drawings[player.UserId] = drawings
end

function ESP.RemoveForPlayer(player)
    local d = ESP._drawings[player.UserId]
    if not d then return end
    for _, drawing in pairs(d) do
        RemoveDrawing(drawing)
    end
    ESP._drawings[player.UserId] = nil
end

function ESP.UpdatePlayer(player)
    local d = ESP._drawings[player.UserId]
    if not d then return end

    local show = ESP.Enabled
        and player ~= LocalPlayer
        and PlayerUtil.IsAlive(player)

    if not show then
        for _, drawing in pairs(d) do
            if drawing then Safe(function() drawing.Visible = false end) end
        end
        return
    end

    local char = player.Character
    if not char then return end

    local hrp   = char:FindFirstChild("HumanoidRootPart")
    local head  = char:FindFirstChild("Head")
    local hum   = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not head or not hum then return end

    local localHRP = PlayerUtil.GetHRP(LocalPlayer)
    if localHRP then
        local wd = (hrp.Position - localHRP.Position).Magnitude
        if wd > ESP.MaxDistance then
            for _, drawing in pairs(d) do
                if drawing then Safe(function() drawing.Visible = false end) end
            end
            return
        end
    end

    -- Team color
    local boxColor = (ESP.TeamCheck and PlayerUtil.IsTeammate(player)) and ESP.TeamColor or ESP.BoxColor

    -- Screen positions
    local topPos, topOnScreen   = PlayerUtil.GetScreenPos(head.Position  + Vector3.new(0, 0.7, 0))
    local botPos, botOnScreen   = PlayerUtil.GetScreenPos(hrp.Position   - Vector3.new(0, 2.8, 0))
    local hrpPos, hrpOnScreen   = PlayerUtil.GetScreenPos(hrp.Position)

    if not topOnScreen and not botOnScreen then
        for _, drawing in pairs(d) do
            if drawing then Safe(function() drawing.Visible = false end) end
        end
        return
    end

    local height = math.abs(topPos.Y - botPos.Y)
    local width  = height * 0.55

    -- BOX
    if d.box then
        Safe(function()
            d.box.Visible   = ESP.Boxes
            d.box.Color     = boxColor
            d.box.Size      = Vector2.new(width, height)
            d.box.Position  = Vector2.new(hrpPos.X - width/2, topPos.Y)
        end)
    end

    -- NAME
    if d.name then
        Safe(function()
            d.name.Visible   = ESP.Names
            d.name.Text      = player.Name
            d.name.Position  = Vector2.new(hrpPos.X, topPos.Y - 16)
        end)
    end

    -- DISTANCE
    if d.dist then
        Safe(function()
            local localHRP2 = PlayerUtil.GetHRP(LocalPlayer)
            local wd2 = localHRP2 and math.floor((hrp.Position - localHRP2.Position).Magnitude) or 0
            d.dist.Visible  = ESP.Distance
            d.dist.Text     = wd2 .. "m"
            d.dist.Position = Vector2.new(hrpPos.X, botPos.Y + 2)
        end)
    end

    -- HEALTH BAR
    if d.healthBg and d.health then
        Safe(function()
            local maxHp = hum.MaxHealth
            local hp    = hum.Health
            local ratio = maxHp > 0 and (hp / maxHp) or 0
            local barH  = height
            local barW  = 4
            local barX  = hrpPos.X - width/2 - barW - 2
            local barY  = topPos.Y

            local healthColor
            if ratio > 0.6 then
                healthColor = Color3.fromRGB(55, 220, 100)
            elseif ratio > 0.3 then
                healthColor = Color3.fromRGB(225, 185, 35)
            else
                healthColor = Color3.fromRGB(225, 55, 75)
            end

            d.healthBg.Visible  = ESP.Health
            d.healthBg.Size     = Vector2.new(barW, barH)
            d.healthBg.Position = Vector2.new(barX, barY)

            d.health.Visible  = ESP.Health
            d.health.Color    = healthColor
            d.health.Size     = Vector2.new(barW, barH * ratio)
            d.health.Position = Vector2.new(barX, barY + barH * (1 - ratio))
        end)
    end

    -- TRACER
    if d.tracer then
        Safe(function()
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.Visible = ESP.Tracers
            d.tracer.Color   = boxColor
            d.tracer.From    = screenCenter
            d.tracer.To      = hrpPos
        end)
    end
end

function ESP.Start()
    if not DrawingAvailable() then
        Debug.Warn("ESP", "Drawing API not available in this executor")
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP.CreateForPlayer(player)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        task.wait(1)
        ESP.CreateForPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        ESP.RemoveForPlayer(player)
    end)

    ESP._connection = RunService.RenderStepped:Connect(function()
        if not ESP.Enabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ESP.UpdatePlayer(player)
            end
        end
    end)

    Debug.Log("ESP", "ESP system started")
end

function ESP.Stop()
    if ESP._connection then
        ESP._connection:Disconnect()
        ESP._connection = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        ESP.RemoveForPlayer(player)
    end
    Debug.Log("ESP", "ESP system stopped")
end

-- ══════════════════════════════════════════════════════════════════
--  AIMBOT HEARTBEAT
-- ══════════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function(dt)
    Safe(function() Aimbot.Step(dt) end)
    Safe(function() Prediction.AutoAdjust() end)
end)

-- ══════════════════════════════════════════════════════════════════
--  ADVANCED LOADER  (Circle → Square morph)
-- ══════════════════════════════════════════════════════════════════
local Loader = {}

function Loader.Show(config)
    config = config or {}
    local libName     = config.Name       or "NexusV3"
    local version     = config.Version    or NEXUS.Version
    local gameName    = config.GameName   or NEXUS.GameName
    local loadTime    = config.Time       or 4.0
    local onFinish    = config.OnFinish   or function() end
    local updateInfo  = config.UpdateInfo or nil  -- nil, "checking", "uptodate", "outdated"

    -- Destroy old loader
    local oldGui = CoreGui:FindFirstChild("NexusV3_Loader")
    if oldGui then oldGui:Destroy() end

    local SG = UI.New("ScreenGui", {
        Name           = "NexusV3_Loader",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- TRANSPARENT root — no black background
    local Root = UI.Frame({
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex                 = 10,
    }, SG)

    -- Blur effect behind loader panel
    local BlurFrame = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 0, 0, 0),
        BackgroundColor3       = Color3.fromRGB(5, 5, 12),
        BackgroundTransparency = 0.25,
        ZIndex                 = 11,
    }, Root)
    UI.Corner(999, BlurFrame)  -- starts as circle

    -- Glow layer behind panel
    local GlowBg = UI.ImageLabel({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://5028857472",
        ImageColor3            = Theme.Accent,
        ImageTransparency      = 0.7,
        ZIndex                 = 10,
    }, Root)

    -- Outer ring (circle)
    local OuterRing = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 80, 0, 80),
        BackgroundTransparency = 1,
        ZIndex                 = 12,
    }, Root)
    UI.Corner(999, OuterRing)
    local outerStroke = UI.Stroke(Theme.Accent, 2.5, 0, OuterRing)

    -- Inner spinning ring
    local InnerRing = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 55, 0, 55),
        BackgroundTransparency = 1,
        ZIndex                 = 13,
    }, Root)
    UI.Corner(999, InnerRing)
    UI.Stroke(Theme.Cyan, 1.5, 0.4, InnerRing)

    -- Spinning arc (partial frame trick)
    local SpinArc = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 68, 0, 68),
        BackgroundTransparency = 1,
        ZIndex                 = 14,
    }, Root)
    UI.Corner(999, SpinArc)
    UI.Stroke(Theme.Pink, 2, 0, SpinArc)

    -- Center diamond
    local DiamondFrame = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 22, 0, 22),
        BackgroundColor3       = Theme.Accent,
        Rotation               = 45,
        ZIndex                 = 15,
    }, Root)
    UI.Corner(3, DiamondFrame)

    local DiamondInner = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 11, 0, 11),
        BackgroundColor3       = Color3.fromRGB(5, 5, 12),
        Rotation               = 45,
        ZIndex                 = 16,
    }, Root)
    UI.Corner(2, DiamondInner)

    -- Content (hidden at start, shown after morph)
    local ContentFrame = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 360, 0, 220),
        BackgroundTransparency = 1,
        ZIndex                 = 17,
        ClipsDescendants       = false,
    }, Root)

    -- Title
    local TitleText = UI.TextLabel({
        AnchorPoint            = Vector2.new(0.5, 0),
        Position               = UDim2.new(0.5, 0, 0, 12),
        Size                   = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text                   = libName,
        TextColor3             = Theme.TextHi,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 24,
        TextTransparency       = 1,
        ZIndex                 = 18,
    }, ContentFrame)

    -- Version + game badge
    local BadgeRow = UI.Frame({
        AnchorPoint            = Vector2.new(0.5, 0),
        Position               = UDim2.new(0.5, 0, 0, 48),
        Size                   = UDim2.new(0, 240, 0, 22),
        BackgroundTransparency = 1,
        ZIndex                 = 18,
    }, ContentFrame)

    local VersionBadge = UI.Frame({
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(0, 64, 0, 20),
        BackgroundColor3 = Theme.AccentDark,
        ZIndex           = 19,
    }, BadgeRow)
    UI.Corner(10, VersionBadge)
    UI.TextLabel({
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "v" .. version,
        TextColor3             = Theme.AccentBright,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 11,
        TextTransparency       = 1,
        ZIndex                 = 20,
    }, VersionBadge)

    local GameBadge = UI.Frame({
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 70, 0.5, 0),
        Size             = UDim2.new(0, 90, 0, 20),
        BackgroundColor3 = Color3.fromRGB(20, 40, 20),
        ZIndex           = 19,
    }, BadgeRow)
    UI.Corner(10, GameBadge)
    local GameBadgeLbl = UI.TextLabel({
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "● " .. gameName,
        TextColor3             = Theme.Green,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 11,
        TextTransparency       = 1,
        ZIndex                 = 20,
    }, GameBadge)

    -- Update badge
    local UpdateBadge = UI.Frame({
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 166, 0.5, 0),
        Size             = UDim2.new(0, 74, 0, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 15),
        ZIndex           = 19,
    }, BadgeRow)
    UI.Corner(10, UpdateBadge)
    local UpdateBadgeLbl = UI.TextLabel({
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "⟳ Checking",
        TextColor3             = Theme.Yellow,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 11,
        TextTransparency       = 1,
        ZIndex                 = 20,
    }, UpdateBadge)

    -- Separator
    local Sep = UI.Frame({
        AnchorPoint      = Vector2.new(0.5, 0),
        Position         = UDim2.new(0.5, 0, 0, 78),
        Size             = UDim2.new(0, 300, 0, 1),
        BackgroundColor3 = Theme.Border,
        ZIndex           = 18,
    }, ContentFrame)
    UI.Grad(0, {Theme.Black, Theme.Accent, Theme.Cyan, Theme.Accent, Theme.Black}, Sep)

    -- Status label
    local StatusText = UI.TextLabel({
        AnchorPoint            = Vector2.new(0.5, 0),
        Position               = UDim2.new(0.5, 0, 0, 88),
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text                   = "Initializing...",
        TextColor3             = Theme.TextLow,
        Font                   = Enum.Font.Gotham,
        TextSize               = 12,
        TextTransparency       = 1,
        ZIndex                 = 18,
    }, ContentFrame)

    -- Progress bar background
    local ProgBg = UI.Frame({
        AnchorPoint      = Vector2.new(0.5, 0),
        Position         = UDim2.new(0.5, 0, 0, 114),
        Size             = UDim2.new(0, 300, 0, 5),
        BackgroundColor3 = Theme.SurfaceAlt,
        ZIndex           = 18,
    }, ContentFrame)
    UI.Corner(999, ProgBg)
    UI.Stroke(Theme.Border, 1, 0, ProgBg)

    local ProgFill = UI.Frame({
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex           = 19,
    }, ProgBg)
    UI.Corner(999, ProgFill)
    UI.Grad(0, {Theme.Cyan, Theme.Accent, Theme.Pink}, ProgFill)

    -- Glowing tip on progress
    local ProgTip = UI.Frame({
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(1, 0, 0.5, 0),
        Size             = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Theme.White,
        BackgroundTransparency = 0.2,
        ZIndex           = 20,
    }, ProgFill)
    UI.Corner(999, ProgTip)

    -- Percent text
    local PctText = UI.TextLabel({
        AnchorPoint            = Vector2.new(0.5, 0),
        Position               = UDim2.new(0.5, 0, 0, 124),
        Size                   = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text                   = "0%",
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 11,
        TextTransparency       = 1,
        ZIndex                 = 18,
    }, ContentFrame)

    -- Load steps list
    local StepsList = UI.Frame({
        AnchorPoint      = Vector2.new(0.5, 0),
        Position         = UDim2.new(0.5, 0, 0, 148),
        Size             = UDim2.new(0, 300, 0, 60),
        BackgroundTransparency = 1,
        ZIndex           = 18,
        ClipsDescendants = true,
    }, ContentFrame)
    UI.List(3, nil, Enum.HorizontalAlignment.Left, StepsList)

    local loadStepsData = {
        {text = "Game verification",   time = 0.05},
        {text = "Loading debug system",time = 0.12},
        {text = "Filesystem init",     time = 0.20},
        {text = "Checking for updates",time = 0.30},
        {text = "Aimbot engine",       time = 0.42},
        {text = "Silent aim hooks",    time = 0.55},
        {text = "ESP renderer",        time = 0.65},
        {text = "Prediction engine",   time = 0.75},
        {text = "Config system",       time = 0.82},
        {text = "Building interface",  time = 0.91},
        {text = "Ready!",              time = 1.00},
    }

    local stepLabels = {}
    for _, s in ipairs(loadStepsData) do
        local lbl = UI.TextLabel({
            Size                   = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text                   = "○  " .. s.text,
            TextColor3             = Theme.TextDim,
            Font                   = Enum.Font.Gotham,
            TextSize               = 11,
            TextTransparency       = 0,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 19,
        }, StepsList)
        table.insert(stepLabels, {lbl = lbl, data = s})
    end

    -- Corner accent lines on the morphed panel
    local cornerPieces = {}
    local cDefs = {
        {ap = Vector2.new(0,0), pos = UDim2.new(0, 8, 0, 8), rot = 0},
        {ap = Vector2.new(1,0), pos = UDim2.new(1, -8, 0, 8), rot = 90},
        {ap = Vector2.new(0,1), pos = UDim2.new(0, 8, 1, -8), rot = 270},
        {ap = Vector2.new(1,1), pos = UDim2.new(1, -8, 1, -8), rot = 180},
    }
    for _, cd in ipairs(cDefs) do
        local cf = UI.Frame({
            AnchorPoint            = cd.ap,
            Position               = cd.pos,
            Size                   = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Rotation               = cd.rot,
            ZIndex                 = 18,
            Visible                = false,
        }, BlurFrame)
        UI.Frame({Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Cyan, ZIndex=19}, cf)
        UI.Frame({Size=UDim2.new(0,1,1,0), BackgroundColor3=Theme.Cyan, ZIndex=19}, cf)
        table.insert(cornerPieces, cf)
    end

    -- ─── ANIMATION SEQUENCE ─────────────────────────────
    local spinAngle = 0
    local spinConn  = nil

    spinConn = RunService.Heartbeat:Connect(function(dt)
        spinAngle = spinAngle + dt * 200
        Safe(function()
            SpinArc.Rotation  = spinAngle
            InnerRing.Rotation = -spinAngle * 0.6
            if DiamondFrame and DiamondFrame.Parent then
                DiamondFrame.Rotation = 45 + spinAngle * 0.3
            end
            if DiamondInner and DiamondInner.Parent then
                DiamondInner.Rotation = 45 - spinAngle * 0.5
            end
        end)
    end)

    -- PHASE 1: Circle grows in (0 → 0.4s)
    task.delay(0.1, function()
        ET(OuterRing, 0.5, {Size = UDim2.new(0, 90, 0, 90)})
        ET(InnerRing, 0.5, {Size = UDim2.new(0, 65, 0, 65)})
        ET(SpinArc,   0.5, {Size = UDim2.new(0, 78, 0, 78)})
        ET(BlurFrame, 0.5, {Size = UDim2.new(0, 90, 0, 90)})
        ET(GlowBg,    0.5, {Size = UDim2.new(0, 180, 0, 180)})
    end)

    -- PHASE 2: Hold spin for a moment (0.6s)
    -- PHASE 3: Morph circle → square (0.6 → 1.2s)
    task.delay(0.7, function()
        -- Outer ring expands to panel size
        ET(BlurFrame, 0.55, {
            Size             = UDim2.new(0, 380, 0, 240),
            BackgroundTransparency = 0.08,
        })
        ET(GlowBg, 0.55, {Size = UDim2.new(0, 480, 0, 320)})

        -- Corner radius morphs from circle to square
        local cornerUI = BlurFrame:FindFirstChildOfClass("UICorner")
        if cornerUI then
            ET(cornerUI, 0.55, {CornerRadius = UDim.new(0, 10)})
        end

        -- Outer ring transforms to border
        ET(OuterRing, 0.45, {
            Size                   = UDim2.new(0, 380, 0, 240),
            BackgroundTransparency = 1,
        })
        local outerCorner = OuterRing:FindFirstChildOfClass("UICorner")
        if outerCorner then ET(outerCorner, 0.45, {CornerRadius = UDim.new(0, 10)}) end
        if outerStroke then ET(outerStroke, 0.45, {Color = Theme.Border, Transparency = 0}) end

        ET(InnerRing, 0.3, {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 0, 0, 0),
        })
        ET(SpinArc, 0.3, {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 0, 0, 0),
        })
    end)

    -- PHASE 4: Content fades in (1.2s)
    task.delay(1.25, function()
        if spinConn then spinConn:Disconnect() spinConn = nil end

        -- Diamond fades out
        ET(DiamondFrame, 0.2, {BackgroundTransparency = 1})
        ET(DiamondInner, 0.2, {BackgroundTransparency = 1})

        -- Accent line appears at top of panel
        local accentBar = UI.Frame({
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 0),
            Size             = UDim2.new(0, 0, 0, 2),
            BackgroundColor3 = Theme.Accent,
            ZIndex           = 20,
        }, BlurFrame)
        UI.Corner(999, accentBar)
        UI.Grad(0, {Theme.Cyan, Theme.Accent, Theme.Pink, Theme.Accent, Theme.Cyan}, accentBar)
        ET(accentBar, 0.4, {Size = UDim2.new(1, 0, 0, 2)})

        -- Show corner pieces
        for _, cf in ipairs(cornerPieces) do
            cf.Visible = true
            ET(cf, 0.3, {})
        end

        -- Title fades in
        task.delay(0.1, function()
            ET(TitleText,  0.4, {TextTransparency = 0})
        end)
        task.delay(0.2, function()
            -- Badges fade in
            for _, child in ipairs(BadgeRow:GetChildren()) do
                if child:IsA("Frame") then
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("TextLabel") then
                            ET(sub, 0.3, {TextTransparency = 0})
                        end
                    end
                end
            end
        end)
        task.delay(0.3, function()
            ET(StatusText, 0.3, {TextTransparency = 0})
            ET(PctText,    0.3, {TextTransparency = 0})
        end)
    end)

    -- PHASE 5: Progress steps (1.5s → loadTime)
    local progStartTime = 1.5
    local progDuration  = loadTime - progStartTime

    for i, stepEntry in ipairs(stepLabels) do
        local stepDelay = progStartTime + stepEntry.data.time * progDuration
        local pct       = stepEntry.data.time

        task.delay(stepDelay, function()
            Safe(function()
                -- Update step labels
                for j, se in ipairs(stepLabels) do
                    if j < i then
                        se.lbl.Text      = "✓  " .. se.data.text
                        se.lbl.TextColor3 = Theme.Green
                    elseif j == i then
                        se.lbl.Text      = "►  " .. se.data.text
                        se.lbl.TextColor3 = Theme.Accent
                    end
                end

                -- Progress bar
                QT(ProgFill, 0.4, {Size = UDim2.new(pct, 0, 1, 0)})
                if StatusText and StatusText.Parent then
                    StatusText.Text = stepEntry.data.text .. "..."
                end
                if PctText and PctText.Parent then
                    PctText.Text = math.floor(pct * 100) .. "%"
                end
            end)
        end)
    end

    -- Update detector feedback in badge
    task.delay(progStartTime + 0.30 * progDuration + 0.1, function()
        Safe(function()
            if updateInfo == "outdated" then
                UpdateBadgeLbl.Text      = "↑ Update!"
                UpdateBadgeLbl.TextColor3 = Theme.Yellow
                UpdateBadge.BackgroundColor3 = Color3.fromRGB(35, 30, 10)
            elseif updateInfo == "uptodate" or updateInfo == "error" then
                UpdateBadgeLbl.Text      = "✓ Latest"
                UpdateBadgeLbl.TextColor3 = Theme.Green
                UpdateBadge.BackgroundColor3 = Color3.fromRGB(10, 30, 15)
            end
        end)
    end)

    -- PHASE 6: Outro
    task.delay(loadTime, function()
        Safe(function()
            if PctText and PctText.Parent then PctText.Text = "100%" end
            QT(ProgFill, 0.25, {Size = UDim2.new(1, 0, 1, 0)})
        end)
    end)

    task.delay(loadTime + 0.35, function()
        Safe(function()
            ET(BlurFrame, 0.4, {
                Size                   = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
            })
            ET(GlowBg,    0.4, {Size = UDim2.new(0, 0, 0, 0)})
            ET(OuterRing, 0.35, {Size = UDim2.new(0, 0, 0, 0)})
            ET(TitleText,  0.3, {TextTransparency = 1})
            ET(StatusText, 0.3, {TextTransparency = 1})
        end)
    end)

    task.delay(loadTime + 0.85, function()
        Safe(function()
            if SG and SG.Parent then SG:Destroy() end
            onFinish()
        end)
    end)

    -- Public API
    local loaderAPI = {}
    function loaderAPI:SetStatus(txt)
        Safe(function()
            if StatusText and StatusText.Parent then StatusText.Text = txt end
        end)
    end
    function loaderAPI:SetProgress(pct)
        pct = math.clamp(pct, 0, 1)
        Safe(function()
            QT(ProgFill, 0.3, {Size = UDim2.new(pct, 0, 1, 0)})
            if PctText and PctText.Parent then PctText.Text = math.floor(pct*100).."%"  end
        end)
    end
    function loaderAPI:SetUpdateStatus(status)
        Safe(function()
            if status == "outdated" then
                UpdateBadgeLbl.Text       = "↑ Update!"
                UpdateBadgeLbl.TextColor3 = Theme.Yellow
            elseif status == "uptodate" then
                UpdateBadgeLbl.Text       = "✓ Latest"
                UpdateBadgeLbl.TextColor3 = Theme.Green
            else
                UpdateBadgeLbl.Text       = "⟳ Checking"
                UpdateBadgeLbl.TextColor3 = Theme.Yellow
            end
        end)
    end
    function loaderAPI:Destroy()
        Safe(function()
            if spinConn then spinConn:Disconnect() end
            if SG and SG.Parent then SG:Destroy() end
        end)
    end

    Debug.Log("Loader", "Loader started")
    return loaderAPI
end

-- ══════════════════════════════════════════════════════════════════
--  WINDOW BUILDER
-- ══════════════════════════════════════════════════════════════════
local WindowBuilder = {}

function WindowBuilder.New(config)
    config = config or {}
    local wName   = config.Name      or "NexusV3"
    local wSize   = config.Size      or Vector2.new(620, 460)
    local wPos    = config.Position  or UDim2.new(0.5, -wSize.X/2, 0.5, -wSize.Y/2)
    local togKey  = config.ToggleKey or NEXUS.ToggleKey

    -- Destroy old
    local old = CoreGui:FindFirstChild("NexusV3_UI")
    if old then old:Destroy() end

    local W = {}
    W.Tabs        = {}
    W.ActiveTab   = nil
    W.Visible     = true
    W.Connections = {}
    W.Flags       = {}   -- global flag registry (for config save/load)

    local SG = UI.New("ScreenGui", {
        Name           = "NexusV3_UI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- Main frame
    local Main = UI.Frame({
        Position         = wPos,
        Size             = UDim2.new(0, wSize.X, 0, wSize.Y),
        BackgroundColor3 = Theme.Bg,
        ZIndex           = 2,
        ClipsDescendants = false,
    }, SG)
    UI.Corner(10, Main)
    UI.Stroke(Theme.Border, 1, 0, Main)

    -- Drop shadow
    local Shadow = UI.ImageLabel({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 6),
        Size                   = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://5028857472",
        ImageColor3            = Color3.fromRGB(0, 0, 0),
        ImageTransparency      = 0.65,
        ZIndex                 = 1,
    }, Main)

    -- Accent glow at top
    local TopGlow = UI.Frame({
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        ZIndex           = 5,
    }, Main)
    UI.Grad(0, {Theme.Cyan, Theme.Accent, Theme.Pink, Theme.Accent, Theme.Cyan}, TopGlow)

    -- ─── TITLE BAR ──────────────────────────────────
    local TitleBar = UI.Frame({
        Size             = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Surface,
        ZIndex           = 3,
    }, Main)
    UI.Grad(90, {Theme.SurfaceAlt, Theme.Surface}, TitleBar)

    local AccentUnderline = UI.Frame({
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Accent,
        ZIndex           = 4,
    }, TitleBar)
    UI.Grad(0, {Theme.Cyan, Theme.Accent, Theme.Pink}, AccentUnderline)

    -- Diamond icon
    local TitleDiamond = UI.Frame({
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 14, 0.5, 0),
        Size             = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = Theme.Accent,
        Rotation         = 45,
        ZIndex           = 4,
    }, TitleBar)
    UI.Corner(2, TitleDiamond)
    UI.Frame({
        AnchorPoint      = Vector2.new(0.5,0.5),
        Position         = UDim2.new(0.5,0,0.5,0),
        Size             = UDim2.new(0.5,0,0.5,0),
        BackgroundColor3 = Theme.Surface,
        Rotation         = 45,
        ZIndex           = 5,
    }, TitleDiamond)

    UI.TextLabel({
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 38, 0.5, 0),
        Size                   = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text                   = wName,
        TextColor3             = Theme.TextHi,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 15,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 4,
    }, TitleBar)

    -- Version label
    UI.TextLabel({
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 155, 0.5, 0),
        Size                   = UDim2.new(0, 60, 0, 16),
        BackgroundTransparency = 1,
        Text                   = "v" .. NEXUS.Version,
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 4,
    }, TitleBar)

    -- FPS indicator
    local FPSLabel = UI.TextLabel({
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 80, 0, 18),
        BackgroundTransparency = 1,
        Text                   = "0 FPS",
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        ZIndex                 = 4,
    }, TitleBar)

    -- FPS updater
    local fpsTimer = 0
    local fpsFrames = 0
    local fpsConn = RunService.Heartbeat:Connect(function(dt)
        fpsTimer  = fpsTimer + dt
        fpsFrames = fpsFrames + 1
        if fpsTimer >= 0.5 then
            local fps = math.floor(fpsFrames / fpsTimer)
            if FPSLabel and FPSLabel.Parent then
                FPSLabel.Text = fps .. " FPS"
                if fps >= 50 then
                    FPSLabel.TextColor3 = Theme.Green
                elseif fps >= 30 then
                    FPSLabel.TextColor3 = Theme.Yellow
                else
                    FPSLabel.TextColor3 = Theme.Red
                end
            end
            fpsTimer  = 0
            fpsFrames = 0
        end
    end)
    table.insert(W.Connections, fpsConn)

    -- Close button
    local CloseBtn = UI.TextButton({
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -10, 0.5, 0),
        Size                   = UDim2.new(0, 22, 0, 22),
        BackgroundColor3       = Theme.Red,
        BackgroundTransparency = 0.25,
        Text                   = "×",
        TextColor3             = Theme.White,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
        ZIndex                 = 5,
        AutoButtonColor        = false,
    }, TitleBar)
    UI.Corner(6, CloseBtn)

    local MinBtn = UI.TextButton({
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -38, 0.5, 0),
        Size                   = UDim2.new(0, 22, 0, 22),
        BackgroundColor3       = Theme.Yellow,
        BackgroundTransparency = 0.25,
        Text                   = "–",
        TextColor3             = Theme.White,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
        ZIndex                 = 5,
        AutoButtonColor        = false,
    }, TitleBar)
    UI.Corner(6, MinBtn)

    CloseBtn.MouseEnter:Connect(function() QT(CloseBtn, 0.12, {BackgroundTransparency = 0}) end)
    CloseBtn.MouseLeave:Connect(function() QT(CloseBtn, 0.12, {BackgroundTransparency = 0.25}) end)
    MinBtn.MouseEnter:Connect(function() QT(MinBtn, 0.12, {BackgroundTransparency = 0}) end)
    MinBtn.MouseLeave:Connect(function() QT(MinBtn, 0.12, {BackgroundTransparency = 0.25}) end)

    local minimized = false
    local fullSz    = UDim2.new(0, wSize.X, 0, wSize.Y)

    CloseBtn.MouseButton1Click:Connect(function() W:Toggle() end)
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        ET(Main, 0.35, {Size = minimized and UDim2.new(0, wSize.X, 0, 44) or fullSz})
    end)

    UI.MakeDraggable(Main, TitleBar)

    -- ─── BODY ───────────────────────────────────────
    local Body = UI.Frame({
        Position               = UDim2.new(0, 0, 0, 44),
        Size                   = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        ZIndex                 = 3,
        ClipsDescendants       = true,
    }, Main)

    -- Sidebar
    local Sidebar = UI.Frame({
        Size             = UDim2.new(0, 148, 1, 0),
        BackgroundColor3 = Theme.Surface,
        ZIndex           = 3,
    }, Body)
    UI.Grad(0, {Theme.Surface, Theme.Bg}, Sidebar)

    UI.Frame({
        AnchorPoint      = Vector2.new(1,0),
        Position         = UDim2.new(1,0,0,0),
        Size             = UDim2.new(0,1,1,0),
        BackgroundColor3 = Theme.Border,
        ZIndex           = 4,
    }, Sidebar)

    -- Tab search bar
    local SearchBg = UI.Frame({
        Position         = UDim2.new(0, 8, 0, 8),
        Size             = UDim2.new(1, -16, 0, 28),
        BackgroundColor3 = Theme.Bg,
        ZIndex           = 4,
    }, Sidebar)
    UI.Corner(7, SearchBg)
    UI.Stroke(Theme.Border, 1, 0, SearchBg)

    UI.TextLabel({
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 8, 0.5, 0),
        Size                   = UDim2.new(1, -8, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "🔍 Search",
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
    }, SearchBg)

    local TabScroll = UI.ScrollFrame({
        Position               = UDim2.new(0, 0, 0, 44),
        Size                   = UDim2.new(1, 0, 1, -44),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = Theme.Accent,
        CanvasSize             = UDim2.new(0,0,0,0),
        ZIndex                 = 4,
        BorderSizePixel        = 0,
    }, Sidebar)

    local TabLayout = UI.List(3, nil, Enum.HorizontalAlignment.Center, TabScroll)
    UI.Pad(4, 4, 6, 6, TabScroll)

    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize = UDim2.new(0,0,0, TabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- Content area
    local ContentArea = UI.Frame({
        Position               = UDim2.new(0, 148, 0, 0),
        Size                   = UDim2.new(1, -148, 1, 0),
        BackgroundTransparency = 1,
        ZIndex                 = 3,
    }, Body)

    -- Status bar at bottom
    local StatusBar = UI.Frame({
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 148, 1, 0),
        Size             = UDim2.new(1, -148, 0, 20),
        BackgroundColor3 = Theme.Surface,
        ZIndex           = 4,
    }, Body)

    UI.TextLabel({
        AnchorPoint            = Vector2.new(0, 0.5),
        Position               = UDim2.new(0, 8, 0.5, 0),
        Size                   = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "● " .. NEXUS.GameName .. "  |  NexusV3 " .. NEXUS.Version,
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
    }, StatusBar)

    local TargetStatusLbl = UI.TextLabel({
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -8, 0.5, 0),
        Size                   = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "No target",
        TextColor3             = Theme.TextDim,
        Font                   = Enum.Font.Gotham,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Right,
        ZIndex                 = 5,
    }, StatusBar)

    -- Update target status
    RunService.Heartbeat:Connect(function()
        Safe(function()
            if TargetStatusLbl and TargetStatusLbl.Parent then
                if Aimbot.Target and PlayerUtil.IsAlive(Aimbot.Target) then
                    TargetStatusLbl.Text       = "🎯 " .. Aimbot.Target.Name
                    TargetStatusLbl.TextColor3 = Theme.Red
                elseif SilentAim.Enabled then
                    local t = SilentAim.GetTarget()
                    if t then
                        TargetStatusLbl.Text       = "👁 " .. t.Name
                        TargetStatusLbl.TextColor3 = Theme.Orange
                    else
                        TargetStatusLbl.Text       = "No target"
                        TargetStatusLbl.TextColor3 = Theme.TextDim
                    end
                else
                    TargetStatusLbl.Text       = "No target"
                    TargetStatusLbl.TextColor3 = Theme.TextDim
                end
            end
        end)
    end)

    -- Show/Hide animation
    local function DoShow()
        Main.Visible = true
        Main.BackgroundTransparency = 1
        Main.Position = UDim2.new(wPos.X.Scale, wPos.X.Offset, wPos.Y.Scale, wPos.Y.Offset - 18)
        ET(Main, 0.38, {BackgroundTransparency = 0, Position = wPos})
    end

    local function DoHide()
        local t = ET(Main, 0.28, {
            BackgroundTransparency = 1,
            Position = UDim2.new(wPos.X.Scale, wPos.X.Offset, wPos.Y.Scale, wPos.Y.Offset + 14),
        })
        if t then
            t.Completed:Connect(function()
                if Main and Main.Parent then Main.Visible = false end
            end)
        end
    end

    function W:Toggle()
        W.Visible = not W.Visible
        if W.Visible then DoShow() else DoHide() end
    end

    local togConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == togKey then W:Toggle() end
    end)
    table.insert(W.Connections, togConn)

    -- ─── NOTIFICATION SYSTEM ────────────────────────
    local NotifHolder = UI.Frame({
        AnchorPoint            = Vector2.new(1, 1),
        Position               = UDim2.new(1, -14, 1, -14),
        Size                   = UDim2.new(0, 290, 1, -80),
        BackgroundTransparency = 1,
        ZIndex                 = 100,
    }, SG)

    UI.New("UIListLayout", {
        Padding           = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder         = Enum.SortOrder.LayoutOrder,
    }, NotifHolder)

    function W:Notify(cfg)
        cfg = cfg or {}
        local nTitle  = cfg.Title or "NexusV3"
        local nDesc   = cfg.Desc  or ""
        local nType   = cfg.Type  or "info"
        local nTime   = cfg.Time  or 3.5

        local typeMap = {
            info    = {c = Theme.Accent,  ic = "ℹ"},
            success = {c = Theme.Green,   ic = "✓"},
            danger  = {c = Theme.Red,     ic = "✕"},
            warning = {c = Theme.Yellow,  ic = "⚠"},
        }
        local tm = typeMap[nType] or typeMap.info

        Safe(function()
            local Notif = UI.Frame({
                Size                   = UDim2.new(1, 0, 0, 0),
                BackgroundColor3       = Theme.SurfaceAlt,
                BackgroundTransparency = 0.05,
                ClipsDescendants       = true,
                ZIndex                 = 101,
            }, NotifHolder)
            UI.Corner(8, Notif)
            UI.Stroke(tm.c, 1, 0.4, Notif)

            UI.Frame({
                Size             = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = tm.c,
                ZIndex           = 102,
            }, Notif)

            UI.TextLabel({
                Position               = UDim2.new(0, 14, 0, 7),
                Size                   = UDim2.new(1, -22, 0, 18),
                BackgroundTransparency = 1,
                Text                   = tm.ic .. "  " .. nTitle,
                TextColor3             = Theme.TextHi,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 103,
            }, Notif)

            if nDesc ~= "" then
                UI.TextLabel({
                    Position               = UDim2.new(0, 14, 0, 27),
                    Size                   = UDim2.new(1, -22, 0, 30),
                    BackgroundTransparency = 1,
                    Text                   = nDesc,
                    TextColor3             = Theme.TextMid,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    TextWrapped            = true,
                    ZIndex                 = 103,
                }, Notif)
            end

            local progH = UI.Frame({
                Position         = UDim2.new(0, 0, 1, -2),
                Size             = UDim2.new(1, 0, 0, 2),
                BackgroundColor3 = tm.c,
                ZIndex           = 102,
            }, Notif)
            UI.Corner(999, progH)

            ST(Notif, 0.38, {Size = UDim2.new(1, 0, 0, nDesc ~= "" and 66 or 42)})

            task.delay(0.1, function()
                LT(progH, nTime - 0.1, {Size = UDim2.new(0, 0, 0, 2)})
            end)
            task.delay(nTime, function()
                local t = ET(Notif, 0.32, {
                    Size                   = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                })
                if t then
                    t.Completed:Connect(function()
                        if Notif and Notif.Parent then Notif:Destroy() end
                    end)
                end
            end)
        end)
    end

    -- ─── CONFIG SAVE / LOAD ─────────────────────────
    function W:SaveConfig(name)
        local data = {}
        for flagName, flagRef in pairs(W.Flags) do
            local ok, val = pcall(function() return flagRef:Get() end)
            if ok then data[flagName] = val end
        end
        local saved = ConfigManager.Save(name or ConfigManager.CurrentCfg, data)
        if saved then
            W:Notify({Title="Config Saved", Desc='Saved as "'..(name or ConfigManager.CurrentCfg)..'"', Type="success"})
        else
            W:Notify({Title="Save Failed", Desc="Filesystem not available.", Type="danger"})
        end
    end

    function W:LoadConfig(name)
        local data = ConfigManager.Load(name or ConfigManager.CurrentCfg)
        if not data then
            W:Notify({Title="Load Failed", Desc='Config "'..(name or "default")..'" not found.', Type="danger"})
            return
        end
        for flagName, val in pairs(data) do
            local flagRef = W.Flags[flagName]
            if flagRef then
                pcall(function() flagRef:Set(val) end)
            end
        end
        W:Notify({Title="Config Loaded", Desc='Loaded "'..(name or ConfigManager.CurrentCfg)..'"', Type="success"})
    end

    -- ─── TAB BUILDER ────────────────────────────────
    function W:AddTab(cfg)
        cfg = cfg or {}
        local tName = cfg.Name or ("Tab " .. #W.Tabs + 1)
        local tIcon = cfg.Icon or ""

        local Tab   = {}
        Tab.Name    = tName
        Tab.Flags   = {}

        -- Tab button
        local TBtn = UI.TextButton({
            Size                   = UDim2.new(1, 0, 0, 36),
            BackgroundColor3       = Theme.Bg,
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 5,
            AutoButtonColor        = false,
        }, TabScroll)
        UI.Corner(8, TBtn)

        local TInd = UI.Frame({
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, 2, 0, 0),
            BackgroundColor3 = Theme.Accent,
            ZIndex           = 6,
        }, TBtn)
        UI.Corner(999, TInd)

        UI.TextLabel({
            AnchorPoint            = Vector2.new(0, 0.5),
            Position               = UDim2.new(0, 14, 0.5, 0),
            Size                   = UDim2.new(1, -14, 1, 0),
            BackgroundTransparency = 1,
            Text                   = (tIcon ~= "" and tIcon .. "  " or "") .. tName,
            TextColor3             = Theme.TextLow,
            Font                   = Enum.Font.GothamMedium,
            TextSize               = 13,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 6,
        }, TBtn)

        -- Content scroll
        local TContent = UI.ScrollFrame({
            Size                   = UDim2.new(1, 0, 1, -20),
            BackgroundTransparency = 1,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.Accent,
            CanvasSize             = UDim2.new(0,0,0,0),
            Visible                = false,
            ZIndex                 = 4,
            BorderSizePixel        = 0,
        }, ContentArea)
        UI.Pad(8, 8, 10, 10, TContent)

        local TLayout = UI.List(5, nil, nil, TContent)

        TLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TContent.CanvasSize = UDim2.new(0,0,0, TLayout.AbsoluteContentSize.Y + 16)
        end)

        Tab._btn     = TBtn
        Tab._ind     = TInd
        Tab._content = TContent

        local function Select()
            Safe(function()
                if W.ActiveTab then
                    W.ActiveTab._content.Visible = false
                    QT(W.ActiveTab._btn, 0.18, {BackgroundTransparency = 1})
                    local al = W.ActiveTab._btn:FindFirstChildOfClass("TextLabel")
                    if al then QT(al, 0.18, {TextColor3 = Theme.TextLow}) end
                    QT(W.ActiveTab._ind, 0.18, {Size = UDim2.new(0, 2, 0, 0)})
                end
                W.ActiveTab = Tab
                TContent.Visible = true
                QT(TBtn, 0.18, {BackgroundTransparency = 0.88})
                local tl = TBtn:FindFirstChildOfClass("TextLabel")
                if tl then QT(tl, 0.18, {TextColor3 = Theme.Accent}) end
                QT(TInd, 0.18, {Size = UDim2.new(0, 3, 0.65, 0)})
            end)
        end

        TBtn.MouseButton1Click:Connect(Select)
        TBtn.MouseEnter:Connect(function()
            if W.ActiveTab ~= Tab then
                QT(TBtn, 0.12, {BackgroundTransparency = 0.94})
                local tl = TBtn:FindFirstChildOfClass("TextLabel")
                if tl then QT(tl, 0.12, {TextColor3 = Theme.TextMid}) end
            end
        end)
        TBtn.MouseLeave:Connect(function()
            if W.ActiveTab ~= Tab then
                QT(TBtn, 0.12, {BackgroundTransparency = 1})
                local tl = TBtn:FindFirstChildOfClass("TextLabel")
                if tl then QT(tl, 0.12, {TextColor3 = Theme.TextLow}) end
            end
        end)

        table.insert(W.Tabs, Tab)
        if #W.Tabs == 1 then Select() end

        -- ── SECTION ────────────────────────────────
        function Tab:Section(name)
            local sf = UI.Frame({
                Size                   = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                ZIndex                 = 5,
            }, TContent)
            local sl = UI.Frame({
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.Border,
                ZIndex           = 5,
            }, sf)
            UI.Grad(0, {Theme.Accent, Theme.Border, Theme.Black}, sl)
            UI.TextLabel({
                AnchorPoint            = Vector2.new(0, 0.5),
                Position               = UDim2.new(0, 0, 0.5, 0),
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = string.upper(name or ""),
                TextColor3             = Theme.TextLow,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 10,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 6,
            }, sf)
        end

        -- ── LABEL ──────────────────────────────────
        function Tab:Label(text, color)
            local lbl = UI.TextLabel({
                Size                   = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text                   = text or "",
                TextColor3             = color or Theme.TextMid,
                Font                   = Enum.Font.Gotham,
                TextSize               = 12,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 5,
            }, TContent)
            UI.Pad(0, 0, 2, 0, lbl)
            local el = {}
            function el:Set(t) if lbl and lbl.Parent then lbl.Text = t end end
            function el:SetColor(c) if lbl and lbl.Parent then lbl.TextColor3 = c end end
            return el
        end

        -- ── BUTTON ─────────────────────────────────
        function Tab:Button(cfg2)
            cfg2 = cfg2 or {}
            local bName    = cfg2.Name     or "Button"
            local bDesc    = cfg2.Desc     or ""
            local callback = cfg2.Callback or function() end

            local h = bDesc ~= "" and 42 or 32

            local Btn = UI.TextButton({
                Size             = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = Theme.SurfaceAlt,
                Text             = "",
                ZIndex           = 5,
                AutoButtonColor  = false,
                ClipsDescendants = true,
            }, TContent)
            UI.Corner(7, Btn)
            UI.Stroke(Theme.Border, 1, 0, Btn)

            UI.TextLabel({
                AnchorPoint            = Vector2.new(0, bDesc ~= "" and 0.25 or 0.5),
                Position               = UDim2.new(0, 12, bDesc ~= "" and 0.25 or 0.5, 0),
                Size                   = UDim2.new(1, -24, 0, 16),
                BackgroundTransparency = 1,
                Text                   = bName,
                TextColor3             = Theme.TextHi,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 6,
            }, Btn)

            if bDesc ~= "" then
                UI.TextLabel({
                    AnchorPoint            = Vector2.new(0, 0.75),
                    Position               = UDim2.new(0, 12, 0.75, 0),
                    Size                   = UDim2.new(1, -24, 0, 14),
                    BackgroundTransparency = 1,
                    Text                   = bDesc,
                    TextColor3             = Theme.TextLow,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, Btn)
            end

            -- Arrow indicator
            UI.TextLabel({
                AnchorPoint            = Vector2.new(1, 0.5),
                Position               = UDim2.new(1, -12, 0.5, 0),
                Size                   = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                Text                   = "›",
                TextColor3             = Theme.TextDim,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 16,
                ZIndex                 = 6,
            }, Btn)

            Btn.MouseEnter:Connect(function()
                QT(Btn, 0.12, {BackgroundColor3 = Theme.SurfaceHov})
                UI.Stroke(Theme.AccentDark, 1, 0, Btn)
            end)
            Btn.MouseLeave:Connect(function()
                QT(Btn, 0.12, {BackgroundColor3 = Theme.SurfaceAlt})
                local s = Btn:FindFirstChildOfClass("UIStroke")
                if s then QT(s, 0.12, {Color = Theme.Border}) end
            end)
            Btn.MouseButton1Down:Connect(function()
                QT(Btn, 0.06, {BackgroundColor3 = Theme.AccentGlow})
            end)
            Btn.MouseButton1Click:Connect(function()
                UI.Ripple(Btn, Theme.Accent)
                QT(Btn, 0.1, {BackgroundColor3 = Theme.SurfaceAlt})
                Safe(callback)
            end)

            local el = {}
            function el:SetName(n)
                local l = Btn:FindFirstChildOfClass("TextLabel")
                if l then l.Text = n end
            end
            return el
        end

        -- ── TOGGLE ─────────────────────────────────
        function Tab:Toggle(cfg2)
            cfg2 = cfg2 or {}
            local tgName   = cfg2.Name     or "Toggle"
            local tgDesc   = cfg2.Desc     or ""
            local tgDef    = cfg2.Default  ~= nil and cfg2.Default or false
            local tgKey    = cfg2.Keybind
            local tgFlag   = cfg2.Flag
            local callback = cfg2.Callback or function() end

            local state = tgDef
            local h     = tgDesc ~= "" and 42 or 34

            local Row = UI.Frame({
                Size             = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = Theme.SurfaceAlt,
                ZIndex           = 5,
            }, TContent)
            UI.Corner(7, Row)
            UI.Stroke(Theme.Border, 1, 0, Row)

            UI.TextLabel({
                AnchorPoint            = Vector2.new(0, tgDesc ~= "" and 0.28 or 0.5),
                Position               = UDim2.new(0, 12, tgDesc ~= "" and 0.28 or 0.5, 0),
                Size                   = UDim2.new(0.72, 0, 0, 16),
                BackgroundTransparency = 1,
                Text                   = tgName,
                TextColor3             = Theme.TextMid,
                Font                   = Enum.Font.Gotham,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 6,
            }, Row)

            if tgDesc ~= "" then
                UI.TextLabel({
                    AnchorPoint            = Vector2.new(0, 0.72),
                    Position               = UDim2.new(0, 12, 0.72, 0),
                    Size                   = UDim2.new(0.72, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text                   = tgDesc,
                    TextColor3             = Theme.TextDim,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, Row)
            end

            if tgKey then
                local ks = tostring(tgKey):gsub("Enum%.KeyCode%.", "")
                local kbFrame = UI.Frame({
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -52, 0.5, 0),
                    Size             = UDim2.new(0, 42, 0, 18),
                    BackgroundColor3 = Theme.Bg,
                    ZIndex           = 6,
                }, Row)
                UI.Corner(4, kbFrame)
                UI.Stroke(Theme.Border, 1, 0, kbFrame)
                UI.TextLabel({
                    Size                   = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text                   = ks,
                    TextColor3             = Theme.TextLow,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 10,
                    ZIndex                 = 7,
                }, kbFrame)
            end

            local Track = UI.Frame({
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                Size             = UDim2.new(0, 40, 0, 21),
                BackgroundColor3 = Theme.Bg,
                ZIndex           = 6,
            }, Row)
            UI.Corner(999, Track)
            UI.Stroke(Theme.Border, 1, 0, Track)

            local Knob = UI.Frame({
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, 3, 0.5, 0),
                Size             = UDim2.new(0, 15, 0, 15),
                BackgroundColor3 = Theme.TextLow,
                ZIndex           = 7,
            }, Track)
            UI.Corner(999, Knob)

            local function SetState(val)
                state = val
                Safe(function()
                    if state then
                        QT(Track, 0.18, {BackgroundColor3 = Theme.Accent})
                        QT(Knob,  0.18, {
                            Position         = UDim2.new(1, -18, 0.5, 0),
                            BackgroundColor3 = Theme.White,
                        })
                        local nl = Row:FindFirstChildOfClass("TextLabel")
                        if nl then QT(nl, 0.18, {TextColor3 = Theme.TextHi}) end
                    else
                        QT(Track, 0.18, {BackgroundColor3 = Theme.Bg})
                        QT(Knob,  0.18, {
                            Position         = UDim2.new(0, 3, 0.5, 0),
                            BackgroundColor3 = Theme.TextLow,
                        })
                        local nl = Row:FindFirstChildOfClass("TextLabel")
                        if nl then QT(nl, 0.18, {TextColor3 = Theme.TextMid}) end
                    end
                end)
                Safe(function() callback(state) end)
            end

            SetState(tgDef)

            local CA = UI.TextButton({
                Size                   = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 9,
            }, Row)
            CA.MouseButton1Click:Connect(function() SetState(not state) end)

            Row.MouseEnter:Connect(function() QT(Row, 0.12, {BackgroundColor3 = Theme.SurfaceHov}) end)
            Row.MouseLeave:Connect(function() QT(Row, 0.12, {BackgroundColor3 = Theme.SurfaceAlt}) end)

            if tgKey then
                local kc = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.KeyCode == tgKey then SetState(not state) end
                end)
                table.insert(W.Connections, kc)
            end

            local el = {}
            function el:Set(v) SetState(v) end
            function el:Get() return state end

            if tgFlag then
                W.Flags[tgFlag] = el
                Tab.Flags[tgFlag] = el
            end

            return el
        end

        -- ── SLIDER ─────────────────────────────────
        function Tab:Slider(cfg2)
            cfg2 = cfg2 or {}
            local sName    = cfg2.Name      or "Slider"
            local sMin     = cfg2.Min       or 0
            local sMax     = cfg2.Max       or 100
            local sDef     = cfg2.Default   or sMin
            local sPrec    = cfg2.Precision or 0
            local sSuf     = cfg2.Suffix    or ""
            local sFlag    = cfg2.Flag
            local callback = cfg2.Callback  or function() end

            local value = math.clamp(sDef, sMin, sMax)

            local Container = UI.Frame({
                Size             = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = Theme.SurfaceAlt,
                ZIndex           = 5,
            }, TContent)
            UI.Corner(7, Container)
            UI.Stroke(Theme.Border, 1, 0, Container)
            UI.Pad(8, 8, 12, 12, Container)

            local TopRow = UI.Frame({
                Size                   = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                ZIndex                 = 6,
            }, Container)

            UI.TextLabel({
                AnchorPoint            = Vector2.new(0, 0.5),
                Position               = UDim2.new(0, 0, 0.5, 0),
                Size                   = UDim2.new(0.7, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = sName,
                TextColor3             = Theme.TextMid,
                Font                   = Enum.Font.Gotham,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 7,
            }, TopRow)

            local ValLbl = UI.TextLabel({
                AnchorPoint            = Vector2.new(1, 0.5),
                Position               = UDim2.new(1, 0, 0.5, 0),
                Size                   = UDim2.new(0.3, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = tostring(value) .. sSuf,
                TextColor3             = Theme.Accent,
                Font                   = Enum.Font.GothamMedium,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Right,
                ZIndex                 = 7,
            }, TopRow)

            local TBg = UI.Frame({
                Position         = UDim2.new(0, 0, 1, -17),
                Size             = UDim2.new(1, 0, 0, 6),
                BackgroundColor3 = Theme.Bg,
                ZIndex           = 6,
            }, Container)
            UI.Corner(999, TBg)

            local TFill = UI.Frame({
                Size             = UDim2.new((value-sMin)/(sMax-sMin), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                ZIndex           = 7,
            }, TBg)
            UI.Corner(999, TFill)
            UI.Grad(0, {Theme.Cyan, Theme.Accent, Theme.Pink}, TFill)

            local Thumb = UI.Frame({
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new((value-sMin)/(sMax-sMin), 0, 0.5, 0),
                Size             = UDim2.new(0, 16, 0, 16),
                BackgroundColor3 = Theme.White,
                ZIndex           = 8,
            }, TBg)
            UI.Corner(999, Thumb)
            UI.Stroke(Theme.Accent, 2, 0, Thumb)

            local draggingS = false

            local function UpdateSlider(ix)
                Safe(function()
                    local rel = math.clamp((ix - TBg.AbsolutePosition.X) / TBg.AbsoluteSize.X, 0, 1)
                    local raw = sMin + (sMax - sMin) * rel
                    if sPrec == 0 then
                        value = math.floor(raw + 0.5)
                    else
                        value = math.floor(raw * (10^sPrec) + 0.5) / (10^sPrec)
                    end
                    TFill.Size    = UDim2.new(rel, 0, 1, 0)
                    Thumb.Position = UDim2.new(rel, 0, 0.5, 0)
                    if ValLbl and ValLbl.Parent then ValLbl.Text = tostring(value) .. sSuf end
                    Safe(function() callback(value) end)
                end)
            end

            TBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingS = true
                    UpdateSlider(input.Position.X)
                end
            end)
            Thumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingS = true
                end
            end)

            local sc1 = UserInputService.InputChanged:Connect(function(input)
                if draggingS and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input.Position.X)
                end
            end)
            local sc2 = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingS = false
                end
            end)
            table.insert(W.Connections, sc1)
            table.insert(W.Connections, sc2)

            Container.MouseEnter:Connect(function() QT(Container, 0.12, {BackgroundColor3 = Theme.SurfaceHov}) end)
            Container.MouseLeave:Connect(function() QT(Container, 0.12, {BackgroundColor3 = Theme.SurfaceAlt}) end)

            local el = {}
            function el:Set(v)
                v = math.clamp(v, sMin, sMax)
                value = v
                local p = (v - sMin)/(sMax - sMin)
                QT(TFill,  0.18, {Size = UDim2.new(p, 0, 1, 0)})
                QT(Thumb,  0.18, {Position = UDim2.new(p, 0, 0.5, 0)})
                if ValLbl and ValLbl.Parent then ValLbl.Text = tostring(v) .. sSuf end
            end
            function el:Get() return value end
            if sFlag then W.Flags[sFlag] = el Tab.Flags[sFlag] = el end
            return el
        end

        -- ── TEXTBOX ────────────────────────────────
        function Tab:Textbox(cfg2)
            cfg2 = cfg2 or {}
            local tbName   = cfg2.Name        or "Textbox"
            local tbPlace  = cfg2.Placeholder or "..."
            local tbDef    = cfg2.Default     or ""
            local tbSize   = cfg2.Size        or "small"
            local tbFlag   = cfg2.Flag
            local callback = cfg2.Callback    or function() end

            local heights = {small = 32, medium = 52, large = 82}
            local h = heights[tbSize] or 32

            local Wrap = UI.Frame({Size=UDim2.new(1,0,0,h+24), BackgroundTransparency=1, ZIndex=5}, TContent)

            UI.TextLabel({
                Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
                Text=tbName, TextColor3=Theme.TextMid, Font=Enum.Font.Gotham,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            }, Wrap)

            local IBg = UI.Frame({
                Position=UDim2.new(0,0,0,20), Size=UDim2.new(1,0,0,h),
                BackgroundColor3=Theme.Bg, ZIndex=6,
            }, Wrap)
            UI.Corner(7, IBg)
            local iStroke = UI.Stroke(Theme.Border, 1, 0, IBg)
            UI.Pad(4,4,8,8,IBg)

            local IField = UI.TextBox({
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                Text=tbDef, PlaceholderText=tbPlace,
                PlaceholderColor3=Theme.TextDim, TextColor3=Theme.TextHi,
                Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextYAlignment=Enum.TextYAlignment.Top,
                ClearTextOnFocus=false, MultiLine=(tbSize=="large"),
                ZIndex=7,
            }, IBg)

            IField.Focused:Connect(function()
                ET(IBg, 0.18, {BackgroundColor3 = Color3.fromRGB(14, 12, 24)})
                if iStroke then QT(iStroke, 0.18, {Color = Theme.Accent}) end
            end)
            IField.FocusLost:Connect(function(entered)
                ET(IBg, 0.18, {BackgroundColor3 = Theme.Bg})
                if iStroke then QT(iStroke, 0.18, {Color = Theme.Border}) end
                if entered then Safe(function() callback(IField.Text) end) end
            end)

            local el = {}
            function el:Set(v) if IField and IField.Parent then IField.Text = v end end
            function el:Get() return IField and IField.Text or "" end
            if tbFlag then W.Flags[tbFlag] = el Tab.Flags[tbFlag] = el end
            return el
        end

        -- ── DROPDOWN ───────────────────────────────
        function Tab:Dropdown(cfg2)
            cfg2 = cfg2 or {}
            local dName    = cfg2.Name     or "Dropdown"
            local dOpts    = cfg2.Options  or {}
            local dDef     = cfg2.Default  or (dOpts[1] or "")
            local dFlag    = cfg2.Flag
            local callback = cfg2.Callback or function() end

            local selected = dDef
            local ddOpen   = false

            local Wrap = UI.Frame({
                Size=UDim2.new(1,0,0,36), BackgroundTransparency=1,
                ZIndex=5, ClipsDescendants=false,
            }, TContent)

            local Hdr = UI.TextButton({
                Size=UDim2.new(1,0,0,36), BackgroundColor3=Theme.SurfaceAlt,
                Text="", ZIndex=5, AutoButtonColor=false,
            }, Wrap)
            UI.Corner(7, Hdr)
            UI.Stroke(Theme.Border, 1, 0, Hdr)

            UI.TextLabel({
                AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,12,0.5,0),
                Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1,
                Text=dName, TextColor3=Theme.TextMid,
                Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            }, Hdr)

            local SelLbl = UI.TextLabel({
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-30,0.5,0),
                Size=UDim2.new(0.42,0,1,0), BackgroundTransparency=1,
                Text=selected, TextColor3=Theme.Accent,
                Font=Enum.Font.GothamMedium, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=6,
            }, Hdr)

            local Arrow = UI.TextLabel({
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.new(0,16,0,16), BackgroundTransparency=1,
                Text="▾", TextColor3=Theme.TextLow,
                Font=Enum.Font.GothamBold, TextSize=14, ZIndex=6,
            }, Hdr)

            local DDPanel = UI.Frame({
                Position=UDim2.new(0,0,1,4), Size=UDim2.new(1,0,0,0),
                BackgroundColor3=Theme.Surface,
                ClipsDescendants=true, Visible=false, ZIndex=30,
            }, Wrap)
            UI.Corner(7, DDPanel)
            UI.Stroke(Theme.Accent, 1, 0.5, DDPanel)

            local DDScroll = UI.ScrollFrame({
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                ScrollBarThickness=2, ScrollBarImageColor3=Theme.Accent,
                CanvasSize=UDim2.new(0,0,0,0), ZIndex=31, BorderSizePixel=0,
            }, DDPanel)
            local DDLayout = UI.List(2, nil, nil, DDScroll)
            UI.Pad(4,4,6,6, DDScroll)

            DDLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local h = math.min(DDLayout.AbsoluteContentSize.Y + 8, 170)
                DDPanel.Size = UDim2.new(1,0,0,h)
                DDScroll.CanvasSize = UDim2.new(0,0,0, DDLayout.AbsoluteContentSize.Y+8)
            end)

            for _, opt in ipairs(dOpts) do
                local optVal = opt
                local OBtn = UI.TextButton({
                    Size=UDim2.new(1,0,0,28), BackgroundColor3=Theme.Surface,
                    BackgroundTransparency=1,
                    Text=optVal, TextColor3=optVal==selected and Theme.Accent or Theme.TextMid,
                    Font=Enum.Font.Gotham, TextSize=13, ZIndex=32, AutoButtonColor=false,
                }, DDScroll)
                UI.Corner(5, OBtn)
                OBtn.MouseEnter:Connect(function() QT(OBtn,0.1,{BackgroundTransparency=0.82,TextColor3=Theme.TextHi}) end)
                OBtn.MouseLeave:Connect(function()
                    QT(OBtn,0.1,{BackgroundTransparency=1,TextColor3=(OBtn.Text==selected and Theme.Accent or Theme.TextMid)})
                end)
                OBtn.MouseButton1Click:Connect(function()
                    selected = optVal
                    if SelLbl and SelLbl.Parent then SelLbl.Text = optVal end
                    for _, c in ipairs(DDScroll:GetChildren()) do
                        if c:IsA("TextButton") then
                            c.TextColor3 = (c.Text == selected) and Theme.Accent or Theme.TextMid
                        end
                    end
                    ddOpen = false
                    ET(Arrow, 0.18, {Rotation=0})
                    ET(DDPanel, 0.18, {Size=UDim2.new(1,0,0,0)})
                    task.delay(0.18, function() if DDPanel and DDPanel.Parent then DDPanel.Visible=false end end)
                    Safe(function() callback(optVal) end)
                end)
            end

            Hdr.MouseButton1Click:Connect(function()
                ddOpen = not ddOpen
                if ddOpen then
                    DDPanel.Visible = true
                    ET(Arrow, 0.18, {Rotation=180})
                    ET(DDPanel, 0.22, {Size=UDim2.new(1,0,0, math.min(#dOpts*30+8, 170))})
                else
                    ET(Arrow, 0.18, {Rotation=0})
                    ET(DDPanel, 0.18, {Size=UDim2.new(1,0,0,0)})
                    task.delay(0.18, function() if DDPanel and DDPanel.Parent then DDPanel.Visible=false end end)
                end
            end)
            Hdr.MouseEnter:Connect(function() QT(Hdr,0.12,{BackgroundColor3=Theme.SurfaceHov}) end)
            Hdr.MouseLeave:Connect(function() QT(Hdr,0.12,{BackgroundColor3=Theme.SurfaceAlt}) end)

            local el = {}
            function el:Set(v) selected=v if SelLbl and SelLbl.Parent then SelLbl.Text=v end end
            function el:Get() return selected end
            if dFlag then W.Flags[dFlag]=el Tab.Flags[dFlag]=el end
            return el
        end

        -- ── KEYBIND ────────────────────────────────
        function Tab:Keybind(cfg2)
            cfg2 = cfg2 or {}
            local kName    = cfg2.Name     or "Keybind"
            local kDef     = cfg2.Default  or Enum.KeyCode.Unknown
            local kFlag    = cfg2.Flag
            local callback = cfg2.Callback or function() end

            local bound    = kDef
            local listening= false

            local Row = UI.Frame({
                Size=UDim2.new(1,0,0,34), BackgroundColor3=Theme.SurfaceAlt, ZIndex=5,
            }, TContent)
            UI.Corner(7, Row)
            UI.Stroke(Theme.Border, 1, 0, Row)

            UI.TextLabel({
                AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,12,0.5,0),
                Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1,
                Text=kName, TextColor3=Theme.TextMid,
                Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            }, Row)

            local KDisp = UI.TextButton({
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.new(0,95,0,24), BackgroundColor3=Theme.Bg,
                Text=tostring(bound):gsub("Enum%.KeyCode%.",""),
                TextColor3=Theme.Accent, Font=Enum.Font.GothamMedium,
                TextSize=12, ZIndex=6,
            }, Row)
            UI.Corner(5, KDisp)
            UI.Stroke(Theme.Border, 1, 0, KDisp)

            KDisp.MouseButton1Click:Connect(function()
                listening = true
                KDisp.Text = "[ ... ]"
                KDisp.TextColor3 = Theme.Yellow
                QT(KDisp, 0.1, {BackgroundColor3=Color3.fromRGB(28,22,10)})
            end)

            local kbc = UserInputService.InputBegan:Connect(function(input, gp)
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    bound = input.KeyCode
                    local n = tostring(bound):gsub("Enum%.KeyCode%.","")
                    KDisp.Text = n
                    QT(KDisp, 0.18, {TextColor3=Theme.Accent, BackgroundColor3=Theme.Bg})
                    Safe(function() callback(bound) end)
                end
            end)
            table.insert(W.Connections, kbc)

            Row.MouseEnter:Connect(function() QT(Row,0.12,{BackgroundColor3=Theme.SurfaceHov}) end)
            Row.MouseLeave:Connect(function() QT(Row,0.12,{BackgroundColor3=Theme.SurfaceAlt}) end)

            local el = {}
            function el:Get() return bound end
            function el:Set(k)
                bound = k
                if KDisp and KDisp.Parent then KDisp.Text=tostring(k):gsub("Enum%.KeyCode%.","") end
            end
            if kFlag then W.Flags[kFlag]=el Tab.Flags[kFlag]=el end
            return el
        end

        -- ── COLOR DISPLAY ──────────────────────────
        function Tab:ColorIndicator(cfg2)
            cfg2 = cfg2 or {}
            local cName = cfg2.Name  or "Color"
            local cDef  = cfg2.Color or Theme.Accent

            local Row = UI.Frame({
                Size=UDim2.new(1,0,0,34), BackgroundColor3=Theme.SurfaceAlt, ZIndex=5,
            }, TContent)
            UI.Corner(7, Row)
            UI.Stroke(Theme.Border, 1, 0, Row)

            UI.TextLabel({
                AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,12,0.5,0),
                Size=UDim2.new(0.7,0,1,0), BackgroundTransparency=1,
                Text=cName, TextColor3=Theme.TextMid,
                Font=Enum.Font.Gotham, TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            }, Row)

            local Swatch = UI.Frame({
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-12,0.5,0),
                Size=UDim2.new(0,50,0,20), BackgroundColor3=cDef, ZIndex=6,
            }, Row)
            UI.Corner(5, Swatch)
            UI.Stroke(Theme.Border, 1, 0, Swatch)

            local el = {}
            function el:Set(c)
                cDef = c
                if Swatch and Swatch.Parent then Swatch.BackgroundColor3 = c end
            end
            function el:Get() return cDef end
            return el
        end

        -- ── INFO ROW ──────────────────────────────
        function Tab:InfoRow(left, right, rightColor)
            local Row = UI.Frame({
                Size=UDim2.new(1,0,0,26), BackgroundColor3=Theme.SurfaceAlt, ZIndex=5,
            }, TContent)
            UI.Corner(6, Row)
            UI.Stroke(Theme.Border, 1, 0.5, Row)

            UI.TextLabel({
                AnchorPoint=Vector2.new(0,0.5), Position=UDim2.new(0,10,0.5,0),
                Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1,
                Text=left or "", TextColor3=Theme.TextLow,
                Font=Enum.Font.Gotham, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            }, Row)

            local RLbl = UI.TextLabel({
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0),
                Size=UDim2.new(0.44,0,1,0), BackgroundTransparency=1,
                Text=right or "", TextColor3=rightColor or Theme.TextMid,
                Font=Enum.Font.GothamMedium, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=6,
            }, Row)

            local el = {}
            function el:SetRight(v, c)
                if RLbl and RLbl.Parent then
                    RLbl.Text = tostring(v)
                    if c then RLbl.TextColor3 = c end
                end
            end
            return el
        end

        -- ── DIVIDER ────────────────────────────────
        function Tab:Divider()
            local d = UI.Frame({
                Size=UDim2.new(1,0,0,1), BackgroundColor3=Theme.Border,
                ZIndex=5,
            }, TContent)
            UI.Grad(0, {Theme.Black, Theme.Border, Theme.Black}, d)
        end

        return Tab
    end

    -- ─── DESTROY ────────────────────────────────────
    function W:Destroy()
        Safe(function()
            for _, c in ipairs(W.Connections) do c:Disconnect() end
            W.Connections = {}
            if SG and SG.Parent then SG:Destroy() end
        end)
        Debug.Log("Window", "Destroyed")
    end

    -- Initial show
    Main.BackgroundTransparency = 1
    task.defer(function() Safe(DoShow) end)

    Debug.Log("Window", "'" .. wName .. "' created")
    return W
end

-- ══════════════════════════════════════════════════════════════════
--  LAUNCHER  — Game check → Init → Loader → Build GUI → Run
-- ══════════════════════════════════════════════════════════════════

-- ── GAME GATE ─────────────────────────────────────
if not GameDetector.Assert() then
    -- Show rejected notification via a tiny screen gui
    local rejSG = UI.New("ScreenGui", {
        Name="NexusV3_Rejected", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
    }, CoreGui)
    local rejF = UI.Frame({
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(0,340,0,120),
        BackgroundColor3=Theme.Bg, ZIndex=10,
    }, rejSG)
    UI.Corner(10, rejF)
    UI.Stroke(Theme.Red, 2, 0, rejF)
    UI.TextLabel({
        AnchorPoint=Vector2.new(0.5,0.3), Position=UDim2.new(0.5,0,0.3,0),
        Size=UDim2.new(1,0,0,30), BackgroundTransparency=1,
        Text="⚠  Wrong Game",
        TextColor3=Theme.Red, Font=Enum.Font.GothamBold, TextSize=18, ZIndex=11,
    }, rejF)
    UI.TextLabel({
        AnchorPoint=Vector2.new(0.5,0.65), Position=UDim2.new(0.5,0,0.65,0),
        Size=UDim2.new(1,-20,0,36), BackgroundTransparency=1,
        Text="NexusV3 only runs in " .. NEXUS.GameName .. ".\nPlaceId: " .. tostring(NEXUS.GameId),
        TextColor3=Theme.TextMid, Font=Enum.Font.Gotham, TextSize=12,
        TextWrapped=true, ZIndex=11,
    }, rejF)
    task.delay(5, function()
        if rejSG and rejSG.Parent then rejSG:Destroy() end
    end)
    return  -- abort execution
end

-- ── INIT SYSTEMS ──────────────────────────────────
Debug.Log("Init", "NexusV3 starting — game verified: " .. NEXUS.GameName)
Debug.Log("Init", "Executor: " .. UNCTester.GetExecutorName())
ConfigManager.Init()
FOVCircle.Create()
ESP.Start()

-- ── AUTO UPDATE CHECK ─────────────────────────────
local updateStatus = "checking"
local loaderRef    = nil   -- filled after loader starts

AutoUpdater.Check(function(hasUpdate, current, latest)
    if hasUpdate then
        updateStatus = "outdated"
        Debug.Warn("Updater", "Outdated! Latest: v" .. latest)
    else
        updateStatus = "uptodate"
    end
    if loaderRef then
        loaderRef:SetUpdateStatus(updateStatus)
    end
end)

-- ── LOADER ────────────────────────────────────────
loaderRef = Loader.Show({
    Name       = NEXUS.Name,
    Version    = NEXUS.Version,
    GameName   = NEXUS.GameName,
    Time       = 4.2,
    UpdateInfo = updateStatus,

    OnFinish   = function()

        -- ── BUILD MAIN WINDOW ─────────────────────
        local W = WindowBuilder.New({
            Name      = NEXUS.Name,
            Size      = Vector2.new(640, 480),
            ToggleKey = NEXUS.ToggleKey,
        })

        -- ══════════════════════════════════════════
        --  TAB: AIMBOT
        -- ══════════════════════════════════════════
        local tabAimbot = W:AddTab({Name = "Aimbot", Icon = "🎯"})

        tabAimbot:Section("Main Settings")

        local togAimbot = tabAimbot:Toggle({
            Name     = "Enable Aimbot",
            Desc     = "Hold RMB to lock onto nearest player",
            Default  = false,
            Flag     = "AimbotEnabled",
            Callback = function(v)
                Aimbot.Enabled = v
                W:Notify({Title="Aimbot", Desc=v and "Enabled" or "Disabled", Type=v and "success" or "danger"})
            end,
        })

        local togSilent = tabAimbot:Toggle({
            Name     = "Silent Aim",
            Desc     = "Redirect bullets without moving camera",
            Default  = false,
            Flag     = "SilentAimEnabled",
            Callback = function(v)
                SilentAim.Enabled = v
                if v then
                    SilentAim.Hook()
                    W:Notify({Title="Silent Aim", Desc="Enabled — bullets redirected", Type="success"})
                else
                    SilentAim.Unhook()
                    W:Notify({Title="Silent Aim", Desc="Disabled", Type="danger"})
                end
            end,
        })

        tabAimbot:Section("Aim Settings")

        local slFOV = tabAimbot:Slider({
            Name     = "FOV Radius",
            Min      = 20, Max = 500, Default = Aimbot.FOV,
            Suffix   = " px", Flag = "AimbotFOV",
            Callback = function(v)
                Aimbot.FOV      = v
                SilentAim.FOV   = v
                FOVCircle.Update(v)
            end,
        })

        local slSmooth = tabAimbot:Slider({
            Name      = "Smoothness",
            Min       = 1, Max = 100, Default = math.floor(Aimbot.Smoothness * 100),
            Suffix    = "%", Flag = "AimbotSmooth",
            Callback  = function(v)
                Aimbot.Smoothness = v / 100
            end,
        })

        local slPred = tabAimbot:Slider({
            Name     = "Prediction",
            Min      = 0, Max = 300, Default = math.floor(Prediction.Multiplier * 100),
            Suffix   = "%", Flag = "PredMultiplier",
            Callback = function(v)
                Prediction.Multiplier = v / 100
            end,
        })

        local togAutoPred = tabAimbot:Toggle({
            Name     = "Auto Prediction",
            Desc     = "Automatically adjusts pred based on hit rate",
            Default  = false,
            Flag     = "AutoPred",
            Callback = function(v)
                Prediction.AutoEnabled = v
                W:Notify({Title="Auto Pred", Desc=v and "On — hit/miss tracked" or "Off", Type=v and "success" or "info"})
            end,
        })

        local ddHitPart = tabAimbot:Dropdown({
            Name     = "Hit Part",
            Options  = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Left Arm", "Right Arm"},
            Default  = "Head",
            Flag     = "HitPart",
            Callback = function(v)
                Aimbot.HitPart    = v
                SilentAim.HitPart = v
            end,
        })

        local slMaxDist = tabAimbot:Slider({
            Name    = "Max Distance",
            Min     = 50, Max = 2000, Default = Aimbot.MaxDistance,
            Suffix  = " st", Flag = "AimbotMaxDist",
            Callback = function(v)
                Aimbot.MaxDistance    = v
                SilentAim.MaxDistance = v
                ESP.MaxDistance       = v
            end,
        })

        tabAimbot:Section("Checks")

        local togTeamCheck = tabAimbot:Toggle({
            Name     = "Team Check",
            Desc     = "Skip teammates",
            Default  = true,
            Flag     = "TeamCheck",
            Callback = function(v)
                Aimbot.TeamCheck    = v
                SilentAim.TeamCheck = v
            end,
        })

        local togVisCheck = tabAimbot:Toggle({
            Name     = "Visibility Check",
            Desc     = "Only aim at visible players",
            Default  = true,
            Flag     = "VisCheck",
            Callback = function(v) Aimbot.VisCheck = v end,
        })

        local togSticky = tabAimbot:Toggle({
            Name     = "Sticky Target",
            Desc     = "Keep lock even when off-FOV",
            Default  = false,
            Flag     = "StickyTarget",
            Callback = function(v) Aimbot.StickyTarget = v end,
        })

        tabAimbot:Section("FOV Circle")

        local togFOVCircle = tabAimbot:Toggle({
            Name     = "Show FOV Circle",
            Default  = false,
            Flag     = "ShowFOV",
            Callback = function(v) FOVCircle.Update(nil, nil, v) end,
        })

        tabAimbot:ColorIndicator({
            Name  = "FOV Color",
            Color = FOVCircle.Color,
        })

        -- ══════════════════════════════════════════
        --  TAB: ESP
        -- ══════════════════════════════════════════
        local tabESP = W:AddTab({Name = "ESP", Icon = "👁"})

        tabESP:Section("ESP Options")

        tabESP:Toggle({
            Name="Enable ESP", Default=false, Flag="ESPEnabled",
            Callback=function(v)
                ESP.Enabled = v
                W:Notify({Title="ESP", Desc=v and "Enabled" or "Disabled", Type=v and "success" or "danger"})
            end,
        })

        tabESP:Toggle({Name="Boxes",    Default=true,  Flag="ESPBoxes",    Callback=function(v) ESP.Boxes=v end})
        tabESP:Toggle({Name="Names",    Default=true,  Flag="ESPNames",    Callback=function(v) ESP.Names=v end})
        tabESP:Toggle({Name="Distance", Default=true,  Flag="ESPDistance", Callback=function(v) ESP.Distance=v end})
        tabESP:Toggle({Name="Health Bars", Default=true, Flag="ESPHealth", Callback=function(v) ESP.Health=v end})
        tabESP:Toggle({Name="Tracers",  Default=false, Flag="ESPTracers",  Callback=function(v) ESP.Tracers=v end})
        tabESP:Toggle({Name="Team Check (skip teammates)", Default=false, Flag="ESPTeamCheck", Callback=function(v) ESP.TeamCheck=v end})

        tabESP:Section("Appearance")

        tabESP:Slider({
            Name="Max Distance", Min=50, Max=2000, Default=500,
            Suffix=" st", Flag="ESPMaxDist",
            Callback=function(v) ESP.MaxDistance=v end,
        })
        tabESP:Slider({
            Name="Text Size", Min=8, Max=20, Default=14,
            Flag="ESPTextSize",
            Callback=function(v) ESP.TextSize=v end,
        })

        tabESP:ColorIndicator({Name="Box Color",    Color=ESP.BoxColor})
        tabESP:ColorIndicator({Name="Name Color",   Color=ESP.NameColor})
        tabESP:ColorIndicator({Name="Health Color", Color=ESP.HealthColor})
        tabESP:ColorIndicator({Name="Tracer Color", Color=ESP.TracerColor})

        -- ══════════════════════════════════════════
        --  TAB: SETTINGS / CONFIG
        -- ══════════════════════════════════════════
        local tabSettings = W:AddTab({Name = "Settings", Icon = "⚙"})

        tabSettings:Section("Script Settings")

        tabSettings:Keybind({
            Name    = "Toggle GUI",
            Default = NEXUS.ToggleKey,
            Flag    = "ToggleKey",
            Callback = function(k)
                NEXUS.ToggleKey = k
                W:Notify({Title="Keybind Set", Desc="Toggle: "..tostring(k):gsub("Enum%.KeyCode%.",""), Type="info"})
            end,
        })

        tabSettings:Section("Config Manager")

        local cfgNameBox = tabSettings:Textbox({
            Name = "Config Name",
            Placeholder = "e.g. default, rage, legit",
            Default = "default",
            Flag = "ConfigName",
        })

        tabSettings:Button({
            Name = "Save Config",
            Desc = "Saves all current settings to file",
            Callback = function()
                local name = cfgNameBox:Get()
                if name == "" then name = "default" end
                ConfigManager.CurrentCfg = name
                W:SaveConfig(name)
            end,
        })

        tabSettings:Button({
            Name = "Load Config",
            Desc = "Loads settings from saved file",
            Callback = function()
                local name = cfgNameBox:Get()
                if name == "" then name = "default" end
                W:LoadConfig(name)
            end,
        })

        tabSettings:Button({
            Name = "Delete Config",
            Desc = "Permanently deletes the config file",
            Callback = function()
                local name = cfgNameBox:Get()
                if name == "" then
                    W:Notify({Title="Error", Desc="Enter a config name first.", Type="warning"})
                    return
                end
                ConfigManager.Delete(name)
                W:Notify({Title="Deleted", Desc='"'..name..'" config deleted.', Type="danger"})
            end,
        })

        tabSettings:Button({
            Name = "List Configs",
            Desc = "Print saved configs to console",
            Callback = function()
                local cfgs = ConfigManager.List()
                if #cfgs == 0 then
                    W:Notify({Title="Configs", Desc="No configs saved yet.", Type="info"})
                else
                    print("[NexusV3] Saved configs:")
                    for i, c in ipairs(cfgs) do print("  "..i..". "..c) end
                    W:Notify({Title="Configs", Desc=#cfgs.." config(s) found. Check console.", Type="info"})
                end
            end,
        })

        tabSettings:Section("Display")

        tabSettings:Toggle({
            Name="Show Notifications", Default=true, Flag="ShowNotifs",
        })

        tabSettings:Slider({
            Name="Notification Duration", Min=1, Max=10, Default=4,
            Suffix="s", Flag="NotifDuration",
        })

        tabSettings:Section("Updater")

        local updateRow = tabSettings:InfoRow(
            "Update Status",
            AutoUpdater.Status == "outdated" and "⚠ Outdated" or "✓ Latest",
            AutoUpdater.Status == "outdated" and Theme.Yellow or Theme.Green
        )

        tabSettings:InfoRow("Current Version", NEXUS.Version, Theme.Cyan)
        tabSettings:InfoRow("Latest Version",  AutoUpdater.LatestVersion, Theme.TextMid)

        tabSettings:Button({
            Name = "Re-check for Updates",
            Callback = function()
                W:Notify({Title="Updater", Desc="Checking for updates...", Type="info"})
                AutoUpdater.Check(function(has, cur, lat)
                    updateRow:SetRight(
                        has and "⚠ v"..lat.." available!" or "✓ Up to date",
                        has and Theme.Yellow or Theme.Green
                    )
                    W:Notify({
                        Title = has and "Update Available!" or "Up to Date",
                        Desc  = has and "v"..lat.." available. Current: v"..cur or "You are on the latest version.",
                        Type  = has and "warning" or "success",
                        Time  = 5,
                    })
                end)
            end,
        })

        -- ══════════════════════════════════════════
        --  TAB: DEBUG / UNC
        -- ══════════════════════════════════════════
        local tabDebug = W:AddTab({Name = "Debug", Icon = "🛠"})

        tabDebug:Section("Environment Info")

        tabDebug:InfoRow("Executor",     UNCTester.GetExecutorName(), Theme.Accent)
        tabDebug:InfoRow("Game",         game.Name, Theme.TextMid)
        tabDebug:InfoRow("Place ID",     tostring(game.PlaceId), Theme.TextMid)
        tabDebug:InfoRow("Server Time",  tostring(math.floor(workspace.DistributedGameTime)), Theme.TextMid)

        tabDebug:Section("UNC Tests")

        local passRow = tabDebug:InfoRow("UNC Result", "Not run", Theme.TextDim)

        tabDebug:Button({
            Name = "Run UNC Tests",
            Desc = "Tests executor environment functions",
            Callback = function()
                local pass, fail = UNCTester.RunAll()
                passRow:SetRight(
                    pass.."/".. (pass+fail) .." passed",
                    fail == 0 and Theme.Green or Theme.Yellow
                )
                W:Notify({
                    Title = "UNC Tests Complete",
                    Desc  = pass.." passed, "..fail.." failed. Check console.",
                    Type  = fail == 0 and "success" or "warning",
                    Time  = 5,
                })
            end,
        })

        tabDebug:Button({
            Name = "Dump Debug Logs",
            Desc = "Print all logs to console",
            Callback = function()
                Debug.Dump()
                W:Notify({Title="Logs Dumped", Desc=tostring(#Debug.Logs).." entries in console.", Type="info"})
            end,
        })

        tabDebug:Button({
            Name = "Dump Error Logs",
            Desc = "Print only errors/warnings",
            Callback = function()
                Debug.DumpErrors()
                W:Notify({Title="Errors Dumped", Desc=tostring(#Debug.ErrorLog).." errors in console.", Type="warning"})
            end,
        })

        tabDebug:Button({
            Name = "Write Log to File",
            Desc = "Save debug log to NexusV3/logs/",
            Callback = function()
                local content = table.concat(Debug.Logs, "\n")
                ConfigManager.WriteLog(content)
                W:Notify({Title="Log Saved", Desc="Written to "..ConfigManager.LogPath, Type="success"})
            end,
        })

        tabDebug:Button({
            Name = "Clear Logs",
            Callback = function()
                Debug.Clear()
                W:Notify({Title="Logs Cleared", Type="info"})
            end,
        })

        tabDebug:Section("Test Executor")

        tabDebug:Button({
            Name = "Test: writefile",
            Desc = "Write then read a test file",
            Callback = function()
                if not FSAvailable() then
                    W:Notify({Title="Test Failed", Desc="writefile unavailable", Type="danger"}) return
                end
                local ok = Safe(function()
                    writefile(NEXUS.FolderName.."/test.txt", "NexusV3 test file!")
                    local r = readfile(NEXUS.FolderName.."/test.txt")
                    assert(r == "NexusV3 test file!", "Read mismatch")
                    if type(delfile) == "function" then
                        delfile(NEXUS.FolderName.."/test.txt")
                    end
                end)
                W:Notify({
                    Title = ok and "writefile ✓" or "writefile ✗",
                    Desc  = ok and "File written/read/deleted successfully" or "Test failed — check console",
                    Type  = ok and "success" or "danger",
                })
            end,
        })

        tabDebug:Button({
            Name = "Test: getrawmetatable",
            Desc = "Check if metamethod hooking works",
            Callback = function()
                local ok = Safe(function()
                    local mt = getrawmetatable(game)
                    assert(type(mt) == "table", "not a table")
                end)
                W:Notify({
                    Title = ok and "getrawmetatable ✓" or "getrawmetatable ✗",
                    Type  = ok and "success" or "danger",
                })
            end,
        })

        tabDebug:Button({
            Name = "Test: Drawing API",
            Desc = "Create and remove a test drawing",
            Callback = function()
                if not DrawingAvailable() then
                    W:Notify({Title="Drawing ✗", Desc="Drawing API unavailable", Type="danger"}) return
                end
                local ok = Safe(function()
                    local d = Drawing.new("Text")
                    d.Text     = "NexusV3 Drawing Test"
                    d.Position = Vector2.new(100, 100)
                    d.Color    = Theme.Accent
                    d.Size     = 18
                    d.Visible  = true
                    task.delay(2, function() pcall(function() d:Remove() end) end)
                end)
                W:Notify({
                    Title = ok and "Drawing ✓" or "Drawing ✗",
                    Desc  = ok and "Text drawn for 2 seconds" or "Failed",
                    Type  = ok and "success" or "danger",
                })
            end,
        })

        tabDebug:Button({
            Name = "Test: Notification Types",
            Callback = function()
                task.spawn(function()
                    W:Notify({Title="Info",    Desc="Info notification",    Type="info",    Time=2.5})
                    task.wait(0.5)
                    W:Notify({Title="Success", Desc="Success notification", Type="success", Time=2.5})
                    task.wait(0.5)
                    W:Notify({Title="Warning", Desc="Warning notification", Type="warning", Time=2.5})
                    task.wait(0.5)
                    W:Notify({Title="Danger",  Desc="Danger notification",  Type="danger",  Time=2.5})
                end)
            end,
        })

        tabDebug:Section("Live Stats")

        -- Live stats updater
        local statPred   = tabDebug:InfoRow("Prediction Mult", "1.00",    Theme.TextMid)
        local statTarget = tabDebug:InfoRow("Current Target",  "None",    Theme.TextMid)
        local statFOV    = tabDebug:InfoRow("FOV px",          tostring(Aimbot.FOV), Theme.TextMid)
        local statHook   = tabDebug:InfoRow("SA Hook Active",  "No",      Theme.TextMid)
        local statPlayers= tabDebug:InfoRow("Players Nearby",  "0",       Theme.TextMid)

        RunService.Heartbeat:Connect(function()
            Safe(function()
                statPred:SetRight(string.format("%.2f", Prediction.Multiplier),
                    Prediction.AutoEnabled and Theme.Cyan or Theme.TextMid)
                statTarget:SetRight(
                    Aimbot.Target and Aimbot.Target.Name or "None",
                    Aimbot.Target and Theme.Red or Theme.TextDim
                )
                statFOV:SetRight(tostring(Aimbot.FOV), Theme.TextMid)
                statHook:SetRight(SilentAim._hooked and "Yes" or "No",
                    SilentAim._hooked and Theme.Green or Theme.TextDim)

                local count = 0
                local localHRP = PlayerUtil.GetHRP(LocalPlayer)
                if localHRP then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and PlayerUtil.IsAlive(p) then
                            local hrp = PlayerUtil.GetHRP(p)
                            if hrp and (hrp.Position - localHRP.Position).Magnitude <= Aimbot.MaxDistance then
                                count = count + 1
                            end
                        end
                    end
                end
                statPlayers:SetRight(tostring(count), count > 0 and Theme.Orange or Theme.TextDim)
            end)
        end)

        -- ══════════════════════════════════════════
        --  TAB: INFO
        -- ══════════════════════════════════════════
        local tabInfo = W:AddTab({Name = "Info", Icon = "ℹ"})

        tabInfo:Section("Script Info")
        tabInfo:InfoRow("Name",     NEXUS.Name,    Theme.Accent)
        tabInfo:InfoRow("Version",  NEXUS.Version, Theme.Cyan)
        tabInfo:InfoRow("Author",   NEXUS.Author,  Theme.Pink)
        tabInfo:InfoRow("Game",     NEXUS.GameName, Theme.Green)
        tabInfo:InfoRow("PlaceId",  tostring(NEXUS.GameId), Theme.TextMid)
        tabInfo:InfoRow("Toggle",   tostring(NEXUS.ToggleKey):gsub("Enum%.KeyCode%.",""), Theme.TextMid)

        tabInfo:Divider()

        tabInfo:Section("Keybinds")
        tabInfo:InfoRow("Toggle GUI",    tostring(NEXUS.ToggleKey):gsub("Enum%.KeyCode%.",""), Theme.Accent)
        tabInfo:InfoRow("Hold Aimbot",   "RMB (Hold)", Theme.TextMid)
        tabInfo:InfoRow("Silent Aim",    "Passive (auto)", Theme.TextMid)

        tabInfo:Divider()

        tabInfo:Section("Folder Structure")
        tabInfo:Label(ConfigManager.FolderPath .. "/",         Theme.TextMid)
        tabInfo:Label("  ├── configs/  (.json files)",         Theme.TextLow)
        tabInfo:Label("  └── logs/     (.txt files)",          Theme.TextLow)

        tabInfo:Divider()

        tabInfo:Section("Credits & Notes")
        tabInfo:Label("NexusV3 — Made with NexusLib", Theme.TextMid)
        tabInfo:Label("Use responsibly. For Da Hood only.", Theme.TextLow)

        tabInfo:Button({
            Name = "Open Folder in Console",
            Callback = function()
                print("[NexusV3] Folder: " .. ConfigManager.FolderPath)
                print("[NexusV3] Configs: " .. ConfigManager.ConfigPath)
                print("[NexusV3] Logs: " .. ConfigManager.LogPath)
                local cfgs = ConfigManager.List()
                print("[NexusV3] Saved configs: " .. #cfgs)
                for i, c in ipairs(cfgs) do print("  " .. i .. ". " .. c) end
            end,
        })

        -- ── STARTUP NOTIFICATION ──────────────────
        task.delay(0.3, function()
            W:Notify({
                Title = "NexusV3 Loaded!",
                Desc  = "Game: " .. NEXUS.GameName .. " | v" .. NEXUS.Version
                     .. (AutoUpdater.UpdateAvailable and " | Update available!" or ""),
                Type  = AutoUpdater.UpdateAvailable and "warning" or "success",
                Time  = 5,
            })
        end)

        -- ── LOAD DEFAULT CONFIG IF EXISTS ────────
        task.delay(0.5, function()
            local defaultData = ConfigManager.Load("default")
            if defaultData then
                W:LoadConfig("default")
                Debug.Log("Init", "Auto-loaded default config")
            end
        end)

        Debug.Log("Init", "All tabs built. NexusV3 is ready.")
    end,  -- OnFinish end
})

Debug.Log("Init", "Loader running. Waiting for sequence to complete...")
