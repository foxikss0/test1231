-- ═══════════════════════════════════════════════════════════════
-- femboycord  •  Obsidian Menu  +  RivalsUnlockAll  +  UI-ESP + World
-- Theme: Blackout/Pink   •   Keybind: RightShift
-- Auto-restart on teleport enabled
-- by 141/monolix
-- ═══════════════════════════════════════════════════════════════

local repo = 'https://raw.githubusercontent.com/deividcomsono/Obsidian/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- ═══════════════════════════════════════════════════════════════
-- АВТОПЕРЕЗАПУСК ПОСЛЕ ТЕЛЕПОРТА
-- ═══════════════════════════════════════════════════════════════
do
    local function getQueueOnTeleport()
        if type(queue_on_teleport) == "function" then return queue_on_teleport end
        if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
        if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
        if type(krnl) == "table" and type(krnl.queue_on_teleport) == "function" then return krnl.queue_on_teleport end
        if type(secure_call) == "function" then return nil end
        return nil
    end

    local queueFunc = getQueueOnTeleport()

    -- ⚠ ЗАМЕНИ ЭТУ ССЫЛКУ НА РЕАЛЬНЫЙ ПУТЬ/URL СВОЕГО СКРИПТА
    local scriptUrl = "ТВОЯ_ССЫЛКА_НА_СКРИПТ"

    if queueFunc and scriptUrl ~= "ТВОЯ_ССЫЛКА_НА_СКРИПТ" then
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        if LP then
            LP.OnTeleport:Connect(function(State)
                if State == Enum.TeleportState.Started then
                    local code = string.format(
                        'pcall(function() loadstring(game:HttpGet("%s"))() end)',
                        scriptUrl
                    )
                    local ok, err = pcall(queueFunc, code)
                    if ok then
                        print("[femboycord] Скрипт поставлен в очередь на перезапуск после телепорта.")
                    else
                        warn("[femboycord] queue_on_teleport ошибка:", err)
                    end
                end
            end)
            print("[femboycord] Автоперезапуск после телепорта активирован.")
        end
    elseif not queueFunc then
        warn("[femboycord] queue_on_teleport не найден — автоперезапуск недоступен на этом исполнителе.")
    else
        warn("[femboycord] scriptUrl не заменён — автоперезапуск отключён.")
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- UNLOCK ALL
-- ═══════════════════════════════════════════════════════════════
local SETTINGS = { configPath = "unlockall/config.json", replicateDelay = 0.20 }

local function safeRequire(parent, name, timeout)
    if not parent then return nil end
    local m = parent:WaitForChild(name, timeout or 10)
    if not m then return nil end
    local ok, r = pcall(require, m); if not ok then return nil end
    return r
end
local function safeWaitForChild(parent, name, timeout)
    if not parent then return nil end
    local ok, r = pcall(function() return parent:WaitForChild(name, timeout or 10) end)
    if ok then return r end
    return parent:FindFirstChild(name)
end

local PlayerScripts   = safeWaitForChild(LP, "PlayerScripts", 30)
local Controllers     = safeWaitForChild(PlayerScripts, "Controllers", 15)
local Modules         = safeWaitForChild(ReplicatedStorage, "Modules", 30)
local PlayerModules   = safeWaitForChild(PlayerScripts, "Modules", 15)

local EnumLibrary     = safeRequire(Modules, "EnumLibrary")
local CosmeticLibrary = safeRequire(Modules, "CosmeticLibrary")
local ItemLibrary     = safeRequire(Modules, "ItemLibrary")
local ReplicatedClass = safeRequire(Modules, "ReplicatedClass")
local PlayerData      = safeRequire(Controllers, "PlayerDataController")

if EnumLibrary and EnumLibrary.WaitForEnumBuilder then
    pcall(function() EnumLibrary:WaitForEnumBuilder() end)
end

local function safeEnum(n)
    if not ReplicatedClass then return nil end
    local ok, v = pcall(function() return ReplicatedClass:ToEnum(n) end)
    return ok and v or nil
end
local ENUM_NAME = safeEnum("Name")

local equippedByWeapon = {}
local favoritesByWeapon = {}
local inventoryOverlays = setmetatable({}, { __mode = "k" })
local lastProfilePlayer, constructingWeaponName = nil, nil
local pendingReplications = {}
local SUPPORTED_TYPES = { Skin=true, Charm=true, Wrap=true, Wrapping=true, Dance=true, Emote=true }

local function cloneTable(s)
    local c = {}; if s then for k,v in pairs(s) do c[k]=v end end; return c
end
local function isSupportedCosmetic(name, c)
    if type(c) ~= "table" then return false end
    if SUPPORTED_TYPES[c.Type] then return true end
    local n = string.lower(tostring(name))
    return n:find("charm",1,true) or n:find("wrap",1,true) or n:find("dance",1,true) or n:find("emote",1,true)
end
local function isWeaponCosmeticType(t) return t=="Skin" or t=="Charm" or t=="Wrap" or t=="Wrapping" end

local function cloneCosmetic(name, ft, opt)
    if not CosmeticLibrary then return nil end
    local b = CosmeticLibrary.Cosmetics[name]
    if not b or not isSupportedCosmetic(name, b) then return nil end
    local c = cloneTable(b); c.Name = name; c.Type = c.Type or ft; c.Seed = c.Seed or math.random(1,1e6)
    if EnumLibrary and EnumLibrary.ToEnum then
        local ok, e = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
        if ok and e then c.Enum = e; c.ObjectID = c.ObjectID or e end
    end
    opt = opt or {}
    if opt.inverted ~= nil then c.Inverted = opt.inverted end
    if opt.favoritesOnly ~= nil then c.OnlyUseFavorites = opt.favoritesOnly end
    return c
end

local function saveConfiguration()
    if type(writefile) ~= "function" then return end
    local se = {}
    for tn, set in pairs(equippedByWeapon) do
        se[tn] = {}
        for t, c in pairs(set) do
            if c and c.Name then se[tn][t] = {name=c.Name, seed=c.Seed, inverted=c.Inverted, favoritesOnly=c.OnlyUseFavorites} end
        end
    end
    pcall(function()
        if type(makefolder) == "function" then pcall(makefolder, "unlockall") end
        writefile(SETTINGS.configPath, HttpService:JSONEncode({equipped=se, favorites=favoritesByWeapon}))
    end)
end

local function loadConfiguration()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, ex = pcall(isfile, SETTINGS.configPath); if not ok or not ex then return end
    pcall(function()
        local s = HttpService:JSONDecode(readfile(SETTINGS.configPath))
        for tn, set in pairs(s.equipped or {}) do
            equippedByWeapon[tn] = {}
            for t, sc in pairs(set) do
                local c = cloneCosmetic(sc.name or sc.Name, t, {inverted=sc.inverted, favoritesOnly=sc.favoritesOnly})
                if c then c.Seed = sc.seed or sc.Seed or c.Seed; equippedByWeapon[tn][t] = c end
            end
        end
        favoritesByWeapon = s.favorites or {}
    end)
end

local function buildInvOverlay(ri)
    if type(ri) ~= "table" then return ri end
    local c = inventoryOverlays[ri]; if c then return c end
    local o = cloneTable(ri)
    if CosmeticLibrary then
        for n, cos in pairs(CosmeticLibrary.Cosmetics) do
            if isSupportedCosmetic(n, cos) then o[n] = o[n] or true end
        end
    end
    inventoryOverlays[ri] = o; return o
end
local function mergeFavorites(rf)
    local m = cloneTable(rf)
    for wn, set in pairs(favoritesByWeapon) do
        m[wn] = cloneTable(m[wn])
        for cn, en in pairs(set) do if en then m[wn][cn] = true end end
    end
    return m
end

local originalGet = PlayerData and PlayerData.Get
local originalGetWeaponData = PlayerData and PlayerData.GetWeaponData

if PlayerData then
    PlayerData.Get = function(self, key, ...)
        local v = originalGet(self, key, ...)
        if key == "CosmeticInventory" then return buildInvOverlay(v) end
        if key == "FavoritedCosmetics" then return mergeFavorites(v) end
        return v
    end
    PlayerData.GetWeaponData = function(self, wn, ...)
        local od = originalGetWeaponData(self, wn, ...); if not od then return nil end
        local m = cloneTable(od); m.Name = wn
        for t, c in pairs(equippedByWeapon[wn] or {}) do if isWeaponCosmeticType(t) then m[t] = c end end
        return m
    end
end

local function installOwnsCosmeticHooks()
    if not CosmeticLibrary then return end
    local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
    CosmeticLibrary.OwnsCosmetic = function(self, inv, name, wn, ...)
        if type(name) == "string" and name:find("MISSING_",1,true) then return originalOwnsCosmetic(self, inv, name, wn, ...) end
        local c = CosmeticLibrary.Cosmetics[name]
        if isSupportedCosmetic(name, c) then return true end
        return originalOwnsCosmetic(self, inv, name, wn, ...)
    end
    for _, mn in ipairs({"OwnsCosmeticNormally","OwnsCosmeticUniversally","OwnsCosmeticForWeapon"}) do
        if type(CosmeticLibrary[mn]) == "function" then
            local orig = CosmeticLibrary[mn]
            CosmeticLibrary[mn] = function(self, inv, name, wn, ...)
                local c = CosmeticLibrary.Cosmetics[name]
                if isSupportedCosmetic(name, c) then return true end
                return orig(self, inv, name, wn, ...)
            end
        end
    end
end

local function queueReplication(key)
    if pendingReplications[key] then return end
    pendingReplications[key] = true
    task.defer(function()
        pcall(function()
            if PlayerData and PlayerData.CurrentData and PlayerData.CurrentData.Replicate then
                PlayerData.CurrentData:Replicate(key)
            end
        end)
        task.wait(SETTINGS.replicateDelay)
        pendingReplications[key] = nil
        saveConfiguration()
    end)
end

local function setEquippedCosmetic(tn, ct, cn, opt)
    if not cn or cn == "" or cn == "None" then
        local s = equippedByWeapon[tn]
        if s then s[ct] = nil; if not next(s) then equippedByWeapon[tn] = nil end end
        return
    end
    local c = cloneCosmetic(cn, ct, {inverted=opt and opt.IsInverted, favoritesOnly=opt and opt.OnlyUseFavorites})
    if c then
        equippedByWeapon[tn] = equippedByWeapon[tn] or {}
        equippedByWeapon[tn][ct] = c
    end
end

local function isActuallyOwned(name)
    if not PlayerData or not originalGet then return false end
    local inv = originalGet(PlayerData, "CosmeticInventory")
    return type(inv) == "table" and rawget(inv, name) ~= nil
end

local function installRemoteHook()
    if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then return end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local dr = rem and rem:FindFirstChild("Data")
    local eqR = dr and dr:FindFirstChild("EquipCosmetic")
    local fvR = dr and dr:FindFirstChild("FavoriteCosmetic")
    if not eqR then return end
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if getnamecallmethod() ~= "FireServer" then return oldNC(self, ...) end
        local a = table.pack(...)
        if self == eqR then
            local tn, ct, cn, opt = a[1], a[2], a[3], a[4] or {}
            if not cn or cn == "" or cn == "None" then
                local s = equippedByWeapon[tn]
                if s and s[ct] then
                    s[ct] = nil
                    if not next(s) then equippedByWeapon[tn] = nil end
                    queueReplication(isWeaponCosmeticType(ct) and "WeaponInventory" or "CosmeticInventory")
                    return nil
                end
                return oldNC(self, ...)
            end
            local c = CosmeticLibrary and CosmeticLibrary.Cosmetics[cn]
            if isSupportedCosmetic(cn, c) and not isActuallyOwned(cn) then
                setEquippedCosmetic(tn, ct, cn, opt)
                queueReplication(isWeaponCosmeticType(ct) and "WeaponInventory" or "CosmeticInventory")
                return nil
            end
        elseif self == fvR then
            local tn, cn, en = a[1], a[2], a[3]
            local c = CosmeticLibrary and CosmeticLibrary.Cosmetics[cn]
            if isSupportedCosmetic(cn, c) and not isActuallyOwned(cn) then
                favoritesByWeapon[tn] = favoritesByWeapon[tn] or {}
                favoritesByWeapon[tn][cn] = en or nil
                queueReplication("FavoritedCosmetics")
                return nil
            end
        end
        return oldNC(self, ...)
    end))
end

local function installViewModelHooks()
    local modules = PlayerScripts and PlayerScripts:FindFirstChild("Modules")
    local classes = modules and modules:FindFirstChild("ClientReplicatedClasses")
    local fc = classes and classes:FindFirstChild("ClientFighter")
    local ciM = fc and fc:FindFirstChild("ClientItem")
    if not ciM then return end
    local okCI, ClientItem = pcall(require, ciM)
    if not okCI or type(ClientItem) ~= "table" then return end

    if type(ClientItem._CreateViewModel) == "function" then
        local orig = ClientItem._CreateViewModel
        ClientItem._CreateViewModel = function(self, vmR, ...)
            local wp = self.ClientFighter and self.ClientFighter.Player
            local wn = self.Name
            constructingWeaponName = wp == LP and wn or nil
            local sel = equippedByWeapon[wn]
            if wp == LP and sel and vmR then
                local dk = self:ToEnum("Data"); local data = vmR[dk] or vmR.Data
                if data then
                    for t, c in pairs(sel) do
                        if isWeaponCosmeticType(t) then
                            data[self:ToEnum(t)] = c
                            if t == "Skin" then
                                local nk = ENUM_NAME or self:ToEnum("Name")
                                if nk then data[nk] = c.Name end
                            end
                        end
                    end
                end
            end
            local r = orig(self, vmR, ...)
            constructingWeaponName = nil
            return r
        end
    end

    local vmM = ciM:FindFirstChild("ClientViewModel")
    if not vmM then return end
    local okVM, ClientViewModel = pcall(require, vmM)
    if not okVM or type(ClientViewModel) ~= "table" then return end

    for _, t in ipairs({"Skin","Charm","Wrap"}) do
        local gn = "Get" .. t
        if type(ClientViewModel[gn]) == "function" then
            local orig = ClientViewModel[gn]
            ClientViewModel[gn] = function(self, ...)
                local ci = self.ClientItem
                local wn = ci and ci.Name
                local wp = ci and ci.ClientFighter and ci.ClientFighter.Player
                local sel = wn and equippedByWeapon[wn]
                if wp == LP and sel and sel[t] then return sel[t] end
                return orig(self, ...)
            end
        end
    end

    local origNew = ClientViewModel.new
    ClientViewModel.new = function(rep, ci, ...)
        local wp = ci and ci.ClientFighter and ci.ClientFighter.Player
        local wn = constructingWeaponName or (ci and ci.Name)
        local sel = wn and equippedByWeapon[wn]
        if wp == LP and sel and rep then
            local dk = ReplicatedClass and ReplicatedClass:ToEnum("Data")
            local nk = ENUM_NAME or (ReplicatedClass and ReplicatedClass:ToEnum("Name"))
            rep[dk] = rep[dk] or {}
            for t, c in pairs(sel) do
                if isWeaponCosmeticType(t) then
                    rep[dk][ReplicatedClass:ToEnum(t)] = c
                    if t == "Skin" and nk then rep[dk][nk] = c.Name end
                end
            end
        end
        local r = origNew(rep, ci, ...)
        if wp == LP and sel and sel.Wrap and r and r._UpdateWrap then
            r:_UpdateWrap()
            task.delay(0.1, function()
                if r and not r._destroyed and r._UpdateWrap then r:_UpdateWrap() end
            end)
        end
        return r
    end
end

local function installViewModelImageHook()
    if not ItemLibrary then return end
    if type(ItemLibrary.GetViewModelImageFromWeaponData) ~= "function" then return end
    local orig = ItemLibrary.GetViewModelImageFromWeaponData
    ItemLibrary.GetViewModelImageFromWeaponData = function(self, wd, hr, ...)
        local wn = wd and wd.Name
        local sel = wn and equippedByWeapon[wn]
        if sel and sel.Skin and (wd.Skin == sel.Skin or lastProfilePlayer == LP) then
            local img = self.ViewModels[sel.Skin.Name]
            if img then return img[hr and "ImageHighResolution" or "Image"] or img.Image end
        end
        return orig(self, wd, hr, ...)
    end
end

local function installEmoteHook()
    pcall(function()
        local EC = safeRequire(Controllers, "EmoteController"); if not EC then return end
        local orig = EC.GetEmotes
        EC.GetEmotes = function(self, ...)
            local r = cloneTable(orig(self, ...))
            if CosmeticLibrary then
                for name, c in pairs(CosmeticLibrary.Cosmetics) do
                    if isSupportedCosmetic(name, c) and (c.Type == "Dance" or c.Type == "Emote") then
                        r[name] = r[name] or {Name=name, Type=c.Type, ObjectID=c.ObjectID, Enum=c.Enum}
                    end
                end
            end
            return r
        end
    end)
end

local function installProfileHook()
    pcall(function()
        if not PlayerModules then return end
        local P = PlayerModules:FindFirstChild("Pages")
        local VP = P and P:FindFirstChild("ViewProfile"); if not VP then return end
        local page = require(VP); if type(page.Fetch) ~= "function" then return end
        local orig = page.Fetch
        page.Fetch = function(self, tp, ...) lastProfilePlayer = tp; return orig(self, tp, ...) end
    end)
end

local UnlockAllInstalled = false
local function installUnlockAll()
    if UnlockAllInstalled then return true end
    if not CosmeticLibrary or not PlayerData then
        warn("[femboycord] Модули не загружены. UNLOCK ALL не может запуститься.")
        return false
    end
    pcall(installOwnsCosmeticHooks)
    pcall(installRemoteHook)
    pcall(installViewModelHooks)
    pcall(installViewModelImageHook)
    pcall(installEmoteHook)
    pcall(installProfileHook)
    pcall(loadConfiguration)
    UnlockAllInstalled = true
    print("[femboycord] UNLOCK ALL активирован")
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════════════════
local State = {
    Box = {
        Enabled = false, Style = "Outline",
        Color = Color3.fromRGB(255, 105, 180), Color2 = Color3.fromRGB(255, 180, 220),
        UseGradient = false, Thickness = 1, Transparency = 0, CornerLength = 3,
    },
    Name = {
        Enabled = false, Color = Color3.fromRGB(255, 255, 255), Size = 8,
        Outline = false, OutlineColor = Color3.fromRGB(0, 0, 0),
        Position = "Top", Offset = 0,
    },
    HPBar = {
        Enabled = false, Side = "Left", Style = "Solid",
        Color1 = Color3.fromRGB(80, 220, 120), Color2 = Color3.fromRGB(240, 80, 80),
        Thickness = 1, Gap = 0,
        BgColor = Color3.fromRGB(0, 0, 0), BgTransparency = 0,
        TextEnabled = false, TextMode = "Static", TextFormat = "Value",
        TextColor = Color3.fromRGB(255, 255, 255), TextSize = 8,
        TextOutline = false, TextOutlineColor = Color3.fromRGB(0, 0, 0),
        TextOffset = 0,
    },
}

local ESP = { Players = {} }

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "FemboycordESP"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.DisplayOrder = 1
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPGui.Parent = LP:WaitForChild("PlayerGui")

local function espDestroy(plr)
    local t = ESP.Players[plr]; if not t then return end
    if t.container then t.container:Destroy() end
    ESP.Players[plr] = nil
end

local function espCreate(plr)
    if plr == LP then return end
    espDestroy(plr)

    local container = Instance.new("Frame")
    container.Name = "ESP_" .. plr.Name
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.ZIndex = 1
    container.Parent = ESPGui

    local t = { container=container, boxLines={}, boxFill=nil, nameText=nil, hpBarBg=nil, hpBarFill=nil, hpText=nil }
    local S = State

    if S.Box.Enabled then
        if S.Box.Style == "Outline" or S.Box.Style == "Filled+Outline" then
            for i=1,4 do
                local l = Instance.new("Frame")
                l.BackgroundColor3 = S.Box.Color; l.BorderSizePixel = 0; l.ZIndex = 2; l.Parent = container
                table.insert(t.boxLines, l)
            end
        elseif S.Box.Style == "Corners" then
            for i=1,8 do
                local l = Instance.new("Frame")
                l.BackgroundColor3 = S.Box.Color; l.BorderSizePixel = 0; l.ZIndex = 2; l.Parent = container
                table.insert(t.boxLines, l)
            end
        end
        if S.Box.Style == "Filled" or S.Box.Style == "Filled+Outline" then
            local f = Instance.new("Frame")
            f.BackgroundColor3 = S.Box.Color
            f.BackgroundTransparency = S.Box.Transparency
            f.BorderSizePixel = 0; f.ZIndex = 1; f.Parent = container
            t.boxFill = f
        end
    end

    if S.Name.Enabled then
        local nm = Instance.new("TextLabel")
        nm.BackgroundTransparency = 1
        nm.TextColor3 = S.Name.Color
        nm.TextSize = S.Name.Size
        nm.Font = Enum.Font.GothamBold
        nm.TextStrokeTransparency = S.Name.Outline and 0 or 1
        nm.TextStrokeColor3 = S.Name.OutlineColor
        nm.Text = plr.Name
        nm.ZIndex = 4
        nm.Parent = container
        t.nameText = nm
    end

    if S.HPBar.Enabled then
        local bg = Instance.new("Frame")
        bg.BackgroundColor3 = S.HPBar.BgColor
        bg.BackgroundTransparency = S.HPBar.BgTransparency
        bg.BorderSizePixel = 0; bg.ZIndex = 2; bg.Parent = container
        t.hpBarBg = bg

        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = S.HPBar.Color1
        fill.BorderSizePixel = 0; fill.ZIndex = 3; fill.Parent = container
        t.hpBarFill = fill

        if S.HPBar.TextEnabled then
            local txt = Instance.new("TextLabel")
            txt.BackgroundTransparency = 1
            txt.TextColor3 = S.HPBar.TextColor
            txt.TextSize = S.HPBar.TextSize
            txt.Font = Enum.Font.GothamBold
            txt.TextStrokeTransparency = S.HPBar.TextOutline and 0 or 1
            txt.TextStrokeColor3 = S.HPBar.TextOutlineColor
            txt.Text = ""
            txt.ZIndex = 4
            txt.Parent = container
            t.hpText = txt
        end
    end

    ESP.Players[plr] = t
end

local function espRebuild()
    for plr in pairs(ESP.Players) do espDestroy(plr) end
    for _, plr in ipairs(Players:GetPlayers()) do
        espCreate(plr)
    end
end

local function getBounds(char, cam)
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end
    local ch = (hum.RigType == Enum.HumanoidRigType.R6) and 5 or 6
    local center = hrp.Position
    local tv, tOn = cam:WorldToViewportPoint(center + Vector3.new(0, ch/2 - 0.5, 0))
    local bv, bOn = cam:WorldToViewportPoint(center - Vector3.new(0, ch/2 - 0.5, 0))
    if not tOn and not bOn then return nil end
    local h = math.abs(bv.Y - tv.Y); if h < 5 then return nil end
    local w = h * 0.55
    local cx = (tv.X + bv.X) / 2
    return { x1=cx-w/2, y1=math.min(tv.Y,bv.Y), x2=cx+w/2, y2=math.max(tv.Y,bv.Y), w=w, h=h, cx=cx }
end

local function espUpdate()
    local cam = workspace.CurrentCamera; if not cam then return end
    local S = State

    for plr, t in pairs(ESP.Players) do
        pcall(function()
            local char = plr.Character
            if not plr.Parent or not char then t.container.Visible = false; return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then t.container.Visible = false; return end
            local b = getBounds(char, cam); if not b then t.container.Visible = false; return end
            t.container.Visible = true

            if S.Box.Enabled then
                local style = S.Box.Style
                if style == "Outline" or style == "Filled+Outline" then
                    if #t.boxLines >= 4 then
                        local th = S.Box.Thickness
                        t.boxLines[1].Position = UDim2.fromOffset(b.x1, b.y1); t.boxLines[1].Size = UDim2.fromOffset(b.w, th)
                        t.boxLines[2].Position = UDim2.fromOffset(b.x1, b.y2 - th); t.boxLines[2].Size = UDim2.fromOffset(b.w, th)
                        t.boxLines[3].Position = UDim2.fromOffset(b.x1, b.y1); t.boxLines[3].Size = UDim2.fromOffset(th, b.h)
                        t.boxLines[4].Position = UDim2.fromOffset(b.x2 - th, b.y1); t.boxLines[4].Size = UDim2.fromOffset(th, b.h)
                        for i=1,4 do t.boxLines[i].Visible = true; t.boxLines[i].BackgroundColor3 = S.Box.Color end
                    end
                elseif style == "Corners" then
                    if #t.boxLines >= 8 then
                        local L = S.Box.CornerLength
                        if L > b.w/3 then L = b.w/3 end; if L > b.h/3 then L = b.h/3 end
                        local th = S.Box.Thickness
                        t.boxLines[1].Position = UDim2.fromOffset(b.x1, b.y1); t.boxLines[1].Size = UDim2.fromOffset(L, th)
                        t.boxLines[2].Position = UDim2.fromOffset(b.x1, b.y1); t.boxLines[2].Size = UDim2.fromOffset(th, L)
                        t.boxLines[3].Position = UDim2.fromOffset(b.x2 - L, b.y1); t.boxLines[3].Size = UDim2.fromOffset(L, th)
                        t.boxLines[4].Position = UDim2.fromOffset(b.x2 - th, b.y1); t.boxLines[4].Size = UDim2.fromOffset(th, L)
                        t.boxLines[5].Position = UDim2.fromOffset(b.x1, b.y2 - th); t.boxLines[5].Size = UDim2.fromOffset(L, th)
                        t.boxLines[6].Position = UDim2.fromOffset(b.x1, b.y2 - L); t.boxLines[6].Size = UDim2.fromOffset(th, L)
                        t.boxLines[7].Position = UDim2.fromOffset(b.x2 - L, b.y2 - th); t.boxLines[7].Size = UDim2.fromOffset(L, th)
                        t.boxLines[8].Position = UDim2.fromOffset(b.x2 - th, b.y2 - L); t.boxLines[8].Size = UDim2.fromOffset(th, L)
                        for i=1,8 do t.boxLines[i].Visible = true; t.boxLines[i].BackgroundColor3 = S.Box.Color end
                    end
                end
                if (style == "Filled" or style == "Filled+Outline") and t.boxFill then
                    t.boxFill.Position = UDim2.fromOffset(b.x1, b.y1)
                    t.boxFill.Size = UDim2.fromOffset(b.w, b.h)
                    t.boxFill.BackgroundColor3 = S.Box.Color
                    local g = t.boxFill:FindFirstChildOfClass("UIGradient")
                    if S.Box.UseGradient then
                        if not g then g = Instance.new("UIGradient", t.boxFill); g.Rotation = 90 end
                        g.Color = ColorSequence.new(S.Box.Color, S.Box.Color2)
                    elseif g then g:Destroy() end
                    t.boxFill.Visible = true
                elseif t.boxFill then
                    t.boxFill.Visible = false
                end
            end

            if S.Name.Enabled and t.nameText then
                t.nameText.Text = plr.Name
                t.nameText.TextColor3 = S.Name.Color
                t.nameText.TextSize = S.Name.Size
                t.nameText.TextStrokeTransparency = S.Name.Outline and 0 or 1
                t.nameText.TextStrokeColor3 = S.Name.OutlineColor
                local lw = 200; local lh = S.Name.Size + 6
                if S.Name.Position == "Top" then
                    t.nameText.Position = UDim2.fromOffset(b.cx - lw/2, b.y1 - lh - S.Name.Offset)
                else
                    t.nameText.Position = UDim2.fromOffset(b.cx - lw/2, b.y2 + S.Name.Offset)
                end
                t.nameText.Size = UDim2.fromOffset(lw, lh)
                t.nameText.TextXAlignment = Enum.TextXAlignment.Center
                t.nameText.Visible = true
            elseif t.nameText then t.nameText.Visible = false end

            if S.HPBar.Enabled and t.hpBarBg then
                local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local side = S.HPBar.Side; local th = S.HPBar.Thickness; local gap = S.HPBar.Gap
                local barX, barY, barW, barH
                if side == "Left" then barX, barY, barW, barH = b.x1 - gap - th, b.y1, th, b.h
                elseif side == "Right" then barX, barY, barW, barH = b.x2 + gap, b.y1, th, b.h
                elseif side == "Top" then barX, barY, barW, barH = b.x1, b.y1 - gap - th, b.w, th
                else barX, barY, barW, barH = b.x1, b.y2 + gap, b.w, th end

                t.hpBarBg.Position = UDim2.fromOffset(barX, barY)
                t.hpBarBg.Size = UDim2.fromOffset(barW, barH)
                t.hpBarBg.Visible = true

                local isVert = (side == "Left" or side == "Right")
                if isVert then
                    local fh = barH * hpPct
                    t.hpBarFill.Position = UDim2.fromOffset(barX, barY + barH - fh)
                    t.hpBarFill.Size = UDim2.fromOffset(barW, fh)
                else
                    local fw = barW * hpPct
                    t.hpBarFill.Position = UDim2.fromOffset(barX, barY)
                    t.hpBarFill.Size = UDim2.fromOffset(fw, barH)
                end
                t.hpBarFill.Visible = true

                if S.HPBar.Style == "Gradient" then
                    local g = t.hpBarFill:FindFirstChildOfClass("UIGradient")
                    if not g then g = Instance.new("UIGradient", t.hpBarFill); g.Rotation = isVert and 90 or 0 end
                    g.Color = ColorSequence.new(S.HPBar.Color1, S.HPBar.Color2)
                else
                    local g = t.hpBarFill:FindFirstChildOfClass("UIGradient")
                    if g then g:Destroy() end
                    t.hpBarFill.BackgroundColor3 = S.HPBar.Color1
                end

                if S.HPBar.TextEnabled and t.hpText then
                    local text
                    if S.HPBar.TextFormat == "Percent" then
                        text = math.floor(hpPct * 100 + 0.5) .. "%"
                    else
                        text = math.floor(hum.Health + 0.5) .. " / " .. math.floor(hum.MaxHealth + 0.5)
                    end
                    t.hpText.Text = text
                    t.hpText.TextColor3 = S.HPBar.TextColor
                    t.hpText.TextSize = S.HPBar.TextSize
                    t.hpText.TextStrokeTransparency = S.HPBar.TextOutline and 0 or 1
                    t.hpText.TextStrokeColor3 = S.HPBar.TextOutlineColor
                    local off = S.HPBar.TextOffset; local lw = 100; local lh = S.HPBar.TextSize + 4
                    if isVert then
                        local fillTopY = barY + barH * (1 - hpPct)
                        local yPos = (S.HPBar.TextMode == "Magnet") and (fillTopY - lh/2) or (barY - lh/2)
                        if side == "Left" then
                            t.hpText.Position = UDim2.fromOffset(barX - lw - off, yPos)
                            t.hpText.TextXAlignment = Enum.TextXAlignment.Right
                        else
                            t.hpText.Position = UDim2.fromOffset(barX + barW + off, yPos)
                            t.hpText.TextXAlignment = Enum.TextXAlignment.Left
                        end
                        t.hpText.Size = UDim2.fromOffset(lw, lh)
                    else
                        local fillRightX = barX + barW * hpPct
                        local xPos = (S.HPBar.TextMode == "Magnet") and (fillRightX - lw/2) or (barX + barW/2 - lw/2)
                        local yPos
                        if side == "Top" then yPos = barY - lh - off else yPos = barY + barH + off end
                        t.hpText.Position = UDim2.fromOffset(xPos, yPos)
                        t.hpText.Size = UDim2.fromOffset(lw, lh)
                        t.hpText.TextXAlignment = Enum.TextXAlignment.Center
                    end
                    t.hpText.Visible = true
                elseif t.hpText then t.hpText.Visible = false end
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.5); espCreate(plr) end)
    if plr.Character then task.defer(function() task.wait(0.5); espCreate(plr) end) end
end)
Players.PlayerRemoving:Connect(espDestroy)
RunService.RenderStepped:Connect(function() pcall(espUpdate) end)

-- ═══════════════════════════════════════════════════════════════
-- WORLD ENGINE
-- ═══════════════════════════════════════════════════════════════
local World = { SavedProps = {}, WeatherEmitters = {} }

local function saveProp(inst, prop)
    if not inst or not prop then return end
    local key = tostring(inst) .. "_" .. prop
    for _, entry in ipairs(World.SavedProps) do
        if entry.Key == key then return end
    end
    local ok, val = pcall(function() return inst[prop] end)
    if ok then
        table.insert(World.SavedProps, { Key = key, Instance = inst, Property = prop, Value = val })
    end
end

local function restoreProp(inst, prop)
    for i = #World.SavedProps, 1, -1 do
        local e = World.SavedProps[i]
        if e.Instance == inst and e.Property == prop then
            pcall(function() inst[prop] = e.Value end)
            table.remove(World.SavedProps, i)
        end
    end
end

local function restoreAllProps()
    for _, entry in ipairs(World.SavedProps) do
        pcall(function() entry.Instance[entry.Property] = entry.Value end)
    end
    World.SavedProps = {}
end

function World.SetClockTime(t)
    saveProp(Lighting, "ClockTime")
    Lighting.ClockTime = math.clamp(t, 0, 24)
end
function World.RestoreClockTime() restoreProp(Lighting, "ClockTime") end

function World.SetBrightness(v)
    saveProp(Lighting, "Brightness")
    Lighting.Brightness = v
end
function World.RestoreBrightness() restoreProp(Lighting, "Brightness") end

function World.SetAmbient(c)
    saveProp(Lighting, "Ambient")
    Lighting.Ambient = c
end
function World.RestoreAmbient() restoreProp(Lighting, "Ambient") end

function World.SetOutdoorAmbient(c)
    saveProp(Lighting, "OutdoorAmbient")
    Lighting.OutdoorAmbient = c
end
function World.RestoreOutdoorAmbient() restoreProp(Lighting, "OutdoorAmbient") end

function World.GetAtmosphere()
    local a = Lighting:FindFirstChild("__fbc_atmo")
    if not a then a = Instance.new("Atmosphere", Lighting); a.Name = "__fbc_atmo" end
    return a
end
function World.SetAtmoDensity(v) World.GetAtmosphere().Density = v end
function World.SetAtmoHaze(v) World.GetAtmosphere().Haze = v end
function World.SetAtmoGlare(v) World.GetAtmosphere().Glare = v end
function World.SetAtmoColor(c)
    local a = World.GetAtmosphere(); a.Color = c; a.Decay = c
end
function World.RestoreAtmosphere()
    local a = Lighting:FindFirstChild("__fbc_atmo"); if a then a:Destroy() end
end

function World.SetFogEnabled(on)
    saveProp(Lighting, "FogEnd"); saveProp(Lighting, "FogStart")
    if on then Lighting.FogEnd = 500; Lighting.FogStart = 0
    else Lighting.FogEnd = 100000; Lighting.FogStart = 0 end
end
function World.SetFogEnd(v) saveProp(Lighting, "FogEnd"); Lighting.FogEnd = v end
function World.SetFogStart(v) saveProp(Lighting, "FogStart"); Lighting.FogStart = v end
function World.SetFogColor(c) saveProp(Lighting, "FogColor"); Lighting.FogColor = c end

local function ensureEffect(className, name)
    local e = Lighting:FindFirstChild(name)
    if not e or not e:IsA(className) then
        if e then e:Destroy() end
        e = Instance.new(className, Lighting); e.Name = name
    end
    return e
end

function World.SetBloom(on, intensity)
    if on then
        local b = ensureEffect("BloomEffect", "__fbc_bloom")
        b.Intensity = intensity or 1; b.Size = 24; b.Threshold = 1
    else
        local b = Lighting:FindFirstChild("__fbc_bloom"); if b then b:Destroy() end
    end
end
function World.SetBlur(on, size)
    if on then
        local b = ensureEffect("BlurEffect", "__fbc_blur"); b.Size = size or 8
    else
        local b = Lighting:FindFirstChild("__fbc_blur"); if b then b:Destroy() end
    end
end
function World.SetSunRays(on, intensity)
    if on then
        local s = ensureEffect("SunRaysEffect", "__fbc_sun")
        s.Intensity = intensity or 0.1; s.Spread = 1
    else
        local s = Lighting:FindFirstChild("__fbc_sun"); if s then s:Destroy() end
    end
end
function World.SetDOF(on, focus, far)
    if on then
        local d = ensureEffect("DepthOfFieldEffect", "__fbc_dof")
        d.FocusDistance = focus or 50; d.FarIntensity = far or 0.5; d.NearIntensity = 0
    else
        local d = Lighting:FindFirstChild("__fbc_dof"); if d then d:Destroy() end
    end
end
function World.SetColorCorrection(on, brightness, contrast, saturation, tintColor)
    if on then
        local c = ensureEffect("ColorCorrectionEffect", "__fbc_cc")
        c.Brightness = brightness or 0; c.Contrast = contrast or 0
        c.Saturation = saturation or 0; c.TintColor = tintColor or Color3.new(1, 1, 1)
    else
        local c = Lighting:FindFirstChild("__fbc_cc"); if c then c:Destroy() end
    end
end

local SKY_PRESETS = {
    Day = {
        SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288",
    },
    Night = {
        SkyboxBk = "rbxassetid://12064107", SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121", SkyboxLf = "rbxassetid://12063984",
        SkyboxRt = "rbxassetid://12064115", SkyboxUp = "rbxassetid://12064131",
    },
}

function World.SetSkybox(presetName)
    if not SKY_PRESETS[presetName] then return end
    local sky = Lighting:FindFirstChild("__fbc_sky")
    if not sky then sky = Instance.new("Sky", Lighting); sky.Name = "__fbc_sky" end
    for k, v in pairs(SKY_PRESETS[presetName]) do sky[k] = v end
end
function World.ClearSkybox()
    local sky = Lighting:FindFirstChild("__fbc_sky"); if sky then sky:Destroy() end
end
function World.SetSkyboxCustom(id, prop)
    if not id or id == "" then return end
    local sky = Lighting:FindFirstChild("__fbc_sky")
    if not sky then sky = Instance.new("Sky", Lighting); sky.Name = "__fbc_sky" end
    local full = "rbxassetid://" .. id
    if prop == "Bk" then sky.SkyboxBk = full
    elseif prop == "Dn" then sky.SkyboxDn = full
    elseif prop == "Ft" then sky.SkyboxFt = full
    elseif prop == "Lf" then sky.SkyboxLf = full
    elseif prop == "Rt" then sky.SkyboxRt = full
    elseif prop == "Up" then sky.SkyboxUp = full end
end

local function clearWeather()
    for _, e in ipairs(World.WeatherEmitters) do pcall(function() e:Destroy() end) end
    World.WeatherEmitters = {}
end

function World.SetRain(on, intensity)
    clearWeather()
    if not on then return end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local att = Instance.new("Attachment", hrp)
    local e = Instance.new("ParticleEmitter", att)
    e.Texture = "rbxassetid://241876428"
    e.Rate = (intensity or 200)
    e.Lifetime = NumberRange.new(0.6, 1)
    e.Speed = NumberRange.new(120, 150)
    e.SpreadAngle = Vector2.new(0, 0)
    e.Rotation = NumberRange.new(0)
    e.RotSpeed = NumberRange.new(0)
    e.Transparency = NumberSequence.new(0.4)
    e.Size = NumberSequence.new(0.15)
    e.LightEmission = 0.2
    e.Acceleration = Vector3.new(0, -250, 0)
    e.EmissionDirection = Enum.NormalId.Bottom
    e.VelocityInheritance = 0
    table.insert(World.WeatherEmitters, att)
    table.insert(World.WeatherEmitters, e)
end

function World.SetSnow(on, intensity)
    clearWeather()
    if not on then return end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local att = Instance.new("Attachment", hrp)
    local e = Instance.new("ParticleEmitter", att)
    e.Texture = "rbxassetid://241876428"
    e.Rate = (intensity or 80)
    e.Lifetime = NumberRange.new(3, 6)
    e.Speed = NumberRange.new(15, 25)
    e.SpreadAngle = Vector2.new(30, 30)
    e.Rotation = NumberRange.new(0)
    e.RotSpeed = NumberRange.new(-20, 20)
    e.Transparency = NumberSequence.new(0.2)
    e.Size = NumberSequence.new(0.4)
    e.LightEmission = 0.3
    e.Acceleration = Vector3.new(0, -30, 0)
    e.EmissionDirection = Enum.NormalId.Bottom
    e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    table.insert(World.WeatherEmitters, att)
    table.insert(World.WeatherEmitters, e)
end

function World.SetRemoveTextures(on)
    if on then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Material ~= Enum.Material.SmoothPlastic then
                saveProp(obj, "Material"); obj.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        restoreAllProps()
    end
end

function World.ResetAll()
    clearWeather()
    World.ClearSkybox()
    World.RestoreAtmosphere()
    for _, name in ipairs({"__fbc_bloom","__fbc_blur","__fbc_cc","__fbc_sun","__fbc_dof"}) do
        local e = Lighting:FindFirstChild(name); if e then e:Destroy() end
    end
    restoreAllProps()
end

-- ═══════════════════════════════════════════════════════════════
-- МЕНЮ
-- ═══════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = 'femboycord  •  by 141/monolix',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    ShowCustomCursor = true,
})

Library.ToggleKeybind = Enum.KeyCode.RightShift

-- ─── ТЕМА: Blackout + Pink ───
local PinkTheme = {
    ['FontColor']        = Color3.fromRGB(240, 240, 240),
    ['MainColor']        = Color3.fromRGB(18, 18, 18),
    ['AccentColor']      = Color3.fromRGB(255, 105, 180),
    ['BackgroundColor']  = Color3.fromRGB(10, 10, 10),
    ['OutlineColor']     = Color3.fromRGB(255, 105, 180),
    ['RiskColor']        = Color3.fromRGB(255, 60, 60),
}
pcall(function() ThemeManager:SetLibrary(Library) end)
pcall(function() ThemeManager:SetFolder('femboycord') end)
pcall(function() ThemeManager:SetTheme(PinkTheme) end)
pcall(function()
    Library.AccentColor     = PinkTheme.AccentColor
    Library.BackgroundColor = PinkTheme.BackgroundColor
    Library.MainColor       = PinkTheme.MainColor
    Library.FontColor       = PinkTheme.FontColor
    Library.OutlineColor    = PinkTheme.OutlineColor
    Library.RiskColor       = PinkTheme.RiskColor
end)

-- ─── ВКЛАДКИ С ИКОНКАМИ ───
local Tabs = {
    Combat = Window:AddTab('Combat', 'crosshair'),
    Render = Window:AddTab('Render', 'eye'),
    World  = Window:AddTab('World',  'globe'),
    Skin   = Window:AddTab('Skin',   'palette'),
    Misc   = Window:AddTab('Misc',   'settings'),
    Info   = Window:AddTab('Info',   'info'),
}

-- ─── COMBAT ───
local CLeft = Tabs.Combat:AddLeftGroupbox('AIM')
CLeft:AddToggle('SilentAim', { Text = 'Silent Aim', Default = false })
CLeft:AddToggle('AimAssist', { Text = 'Aim Assist', Default = false })
CLeft:AddToggle('TriggerBot', { Text = 'Trigger Bot', Default = false })
local CRight = Tabs.Combat:AddRightGroupbox('WEAPON')
CRight:AddToggle('NoRecoil', { Text = 'No Recoil', Default = false })
CRight:AddToggle('NoSpread', { Text = 'No Spread', Default = false })

-- ─── RENDER — BOX ───
local VLeft = Tabs.Render:AddLeftGroupbox('ESP — BOX')
VLeft:AddToggle('BoxEnabled', { Text = 'Enable Box', Default = false, Callback = function(v) State.Box.Enabled = v; espRebuild() end })
VLeft:AddDropdown('BoxStyle', { Text = 'Style', Values = {'Outline','Filled','Filled+Outline','Corners'}, Default = 1, Callback = function(v) State.Box.Style = v; espRebuild() end })
VLeft:AddLabel('Color'):AddColorPicker('BoxColor', { Default = State.Box.Color, Callback = function(c) State.Box.Color = c; espRebuild() end })
VLeft:AddToggle('BoxGradient', { Text = 'Gradient', Default = false, Callback = function(v) State.Box.UseGradient = v; espRebuild() end })
VLeft:AddLabel('Color 2'):AddColorPicker('BoxColor2', { Default = State.Box.Color2, Callback = function(c) State.Box.Color2 = c; espRebuild() end })
VLeft:AddSlider('BoxThickness', { Text = 'Thickness', Default = 1, Min = 1, Max = 5, Rounding = 0, Callback = function(v) State.Box.Thickness = v; espRebuild() end })
VLeft:AddSlider('BoxTransparency', { Text = 'Fill Transparency', Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) State.Box.Transparency = v; espRebuild() end })
VLeft:AddSlider('BoxCornerLength', { Text = 'Corner Length', Default = 3, Min = 3, Max = 30, Rounding = 0, Callback = function(v) State.Box.CornerLength = v; espRebuild() end })

-- ─── RENDER — NAME ───
local VRight = Tabs.Render:AddRightGroupbox('ESP — NAME')
VRight:AddToggle('NameEnabled', { Text = 'Show Name', Default = false, Callback = function(v) State.Name.Enabled = v; espRebuild() end })
VRight:AddDropdown('NamePosition', { Text = 'Position', Values = {'Top','Bottom'}, Default = 1, Callback = function(v) State.Name.Position = v; espRebuild() end })
VRight:AddLabel('Text Color'):AddColorPicker('NameColor', { Default = State.Name.Color, Callback = function(c) State.Name.Color = c; espRebuild() end })
VRight:AddSlider('NameSize', { Text = 'Text Size', Default = 8, Min = 8, Max = 24, Rounding = 0, Callback = function(v) State.Name.Size = v; espRebuild() end })
VRight:AddSlider('NameOffset', { Text = 'Offset', Default = 0, Min = 0, Max = 30, Rounding = 0, Callback = function(v) State.Name.Offset = v; espRebuild() end })
VRight:AddToggle('NameOutline', { Text = 'Outline', Default = false, Callback = function(v) State.Name.Outline = v; espRebuild() end })
VRight:AddLabel('Outline Color'):AddColorPicker('NameOutlineColor', { Default = State.Name.OutlineColor, Callback = function(c) State.Name.OutlineColor = c; espRebuild() end })

-- ─── RENDER — HP BAR / HP TEXT ───
local VTab = Tabs.Render:AddLeftTabbox()
local HpBar = VTab:AddTab('Health Bar')
HpBar:AddToggle('HPBarEnabled', { Text = 'Enable HP Bar', Default = false, Callback = function(v) State.HPBar.Enabled = v; espRebuild() end })
HpBar:AddDropdown('HPBarSide', { Text = 'Side', Values = {'Left','Right','Top','Bottom'}, Default = 1, Callback = function(v) State.HPBar.Side = v; espRebuild() end })
HpBar:AddDropdown('HPBarStyle', { Text = 'Style', Values = {'Solid','Gradient'}, Default = 1, Callback = function(v) State.HPBar.Style = v; espRebuild() end })
HpBar:AddLabel('Color 1'):AddColorPicker('HPBarColor1', { Default = State.HPBar.Color1, Callback = function(c) State.HPBar.Color1 = c; espRebuild() end })
HpBar:AddLabel('Color 2'):AddColorPicker('HPBarColor2', { Default = State.HPBar.Color2, Callback = function(c) State.HPBar.Color2 = c; espRebuild() end })
HpBar:AddLabel('Background'):AddColorPicker('HPBarBg', { Default = State.HPBar.BgColor, Callback = function(c) State.HPBar.BgColor = c; espRebuild() end })
HpBar:AddSlider('HPBarThickness', { Text = 'Bar Thickness', Default = 1, Min = 1, Max = 8, Rounding = 0, Callback = function(v) State.HPBar.Thickness = v; espRebuild() end })
HpBar:AddSlider('HPBarGap', { Text = 'Offset from box', Default = 0, Min = 0, Max = 12, Rounding = 0, Callback = function(v) State.HPBar.Gap = v; espRebuild() end })
HpBar:AddSlider('HPBarBgTrans', { Text = 'BG Transparency', Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) State.HPBar.BgTransparency = v; espRebuild() end })

local HpText = VTab:AddTab('Health Text')
HpText:AddToggle('HPTextEnabled', { Text = 'Show HP Text', Default = false, Callback = function(v) State.HPBar.TextEnabled = v; espRebuild() end })
HpText:AddDropdown('HPTextMode', { Text = 'Mode', Values = {'Static','Magnet'}, Default = 1, Callback = function(v) State.HPBar.TextMode = v; espRebuild() end })
HpText:AddDropdown('HPTextFormat', { Text = 'Format', Values = {'Value','Percent'}, Default = 1, Callback = function(v) State.HPBar.TextFormat = v; espRebuild() end })
HpText:AddLabel('Text Color'):AddColorPicker('HPTextColor', { Default = State.HPBar.TextColor, Callback = function(c) State.HPBar.TextColor = c; espRebuild() end })
HpText:AddSlider('HPTextSize', { Text = 'Text Size', Default = 8, Min = 8, Max = 24, Rounding = 0, Callback = function(v) State.HPBar.TextSize = v; espRebuild() end })
HpText:AddToggle('HPTextOutline', { Text = 'Outline', Default = false, Callback = function(v) State.HPBar.TextOutline = v; espRebuild() end })
HpText:AddLabel('Outline Color'):AddColorPicker('HPTextOutlineColor', { Default = State.HPBar.TextOutlineColor, Callback = function(c) State.HPBar.TextOutlineColor = c; espRebuild() end })
HpText:AddSlider('HPTextOffset', { Text = 'Text Offset', Default = 0, Min = 0, Max = 20, Rounding = 0, Callback = function(v) State.HPBar.TextOffset = v; espRebuild() end })

-- ─── WORLD — LIGHTING ───
local WLeft = Tabs.World:AddLeftGroupbox('LIGHTING')

WLeft:AddToggle('TimeToggle', { Text = 'Time of Day', Default = false, Callback = function(v)
    if v then
        local t = (Library.Options.ClockTime and Library.Options.ClockTime.Value) or 0
        World.SetClockTime(t)
    else
        World.RestoreClockTime()
    end
end })
WLeft:AddSlider('ClockTime', { Text = 'Time Value', Default = 0, Min = 0, Max = 24, Rounding = 0, Callback = function(v)
    if Library.Toggles.TimeToggle and Library.Toggles.TimeToggle.Value then
        World.SetClockTime(v)
    end
end })
WLeft:AddDivider()

WLeft:AddToggle('BrightnessToggle', { Text = 'Brightness', Default = false, Callback = function(v)
    if v then
        local b = (Library.Options.Brightness and Library.Options.Brightness.Value) or 0
        World.SetBrightness(b)
    else
        World.RestoreBrightness()
    end
end })
WLeft:AddSlider('Brightness', { Text = 'Brightness Value', Default = 0, Min = 0, Max = 10, Rounding = 1, Callback = function(v)
    if Library.Toggles.BrightnessToggle and Library.Toggles.BrightnessToggle.Value then
        World.SetBrightness(v)
    end
end })
WLeft:AddDivider()

WLeft:AddToggle('AmbientToggle', { Text = 'Ambient Color', Default = false, Callback = function(v)
    if v then
        local c = (Library.Options.AmbientColor and Library.Options.AmbientColor.Value) or Color3.fromRGB(128, 128, 128)
        World.SetAmbient(c)
    else
        World.RestoreAmbient()
    end
end })
WLeft:AddLabel('Ambient Color'):AddColorPicker('AmbientColor', { Default = Color3.fromRGB(128, 128, 128), Callback = function(c)
    if Library.Toggles.AmbientToggle and Library.Toggles.AmbientToggle.Value then
        World.SetAmbient(c)
    end
end })
WLeft:AddDivider()

WLeft:AddToggle('OutdoorAmbientToggle', { Text = 'Outdoor Ambient', Default = false, Callback = function(v)
    if v then
        local c = (Library.Options.OutdoorAmbientColor and Library.Options.OutdoorAmbientColor.Value) or Color3.fromRGB(128, 128, 128)
        World.SetOutdoorAmbient(c)
    else
        World.RestoreOutdoorAmbient()
    end
end })
WLeft:AddLabel('Outdoor Ambient'):AddColorPicker('OutdoorAmbientColor', { Default = Color3.fromRGB(128, 128, 128), Callback = function(c)
    if Library.Toggles.OutdoorAmbientToggle and Library.Toggles.OutdoorAmbientToggle.Value then
        World.SetOutdoorAmbient(c)
    end
end })

-- ─── WORLD — ATMOSPHERE / FOG ───
local WRight = Tabs.World:AddRightGroupbox('ATMOSPHERE / FOG')
WRight:AddSlider('AtmoDensity', { Text = 'Density', Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) World.SetAtmoDensity(v) end })
WRight:AddSlider('AtmoHaze', { Text = 'Haze', Default = 0, Min = 0, Max = 10, Rounding = 1, Callback = function(v) World.SetAtmoHaze(v) end })
WRight:AddSlider('AtmoGlare', { Text = 'Glare', Default = 0, Min = 0, Max = 10, Rounding = 1, Callback = function(v) World.SetAtmoGlare(v) end })
WRight:AddLabel('Atmosphere Color'):AddColorPicker('AtmoColor', { Default = Color3.fromRGB(199, 199, 199), Callback = function(c) World.SetAtmoColor(c) end })
WRight:AddDivider()
WRight:AddToggle('FogEnabled', { Text = 'Enable Fog', Default = false, Callback = function(v) World.SetFogEnabled(v) end })
WRight:AddSlider('FogEnd', { Text = 'Fog End', Default = 50, Min = 50, Max = 5000, Rounding = 0, Callback = function(v) World.SetFogEnd(v) end })
WRight:AddSlider('FogStart', { Text = 'Fog Start', Default = 0, Min = 0, Max = 500, Rounding = 0, Callback = function(v) World.SetFogStart(v) end })
WRight:AddLabel('Fog Color'):AddColorPicker('FogColor', { Default = Color3.fromRGB(192, 192, 192), Callback = function(c) World.SetFogColor(c) end })
WRight:AddDivider()
WRight:AddButton({ Text = '⟲  Reset World', Func = function()
    World.ResetAll()
    Library:Notify('World сброшен', 3)
end })

-- ─── WORLD — Tabbox ───
local WTab = Tabs.World:AddLeftTabbox()

local SkyTab = WTab:AddTab('Skybox')
SkyTab:AddDropdown('SkyPreset', { Text = 'Preset', Values = {'Day','Night'}, Default = 1, Callback = function(v) World.SetSkybox(v) end })
SkyTab:AddButton({ Text = 'Clear Skybox', Func = function() World.ClearSkybox() end })
SkyTab:AddDivider()
SkyTab:AddInput('SkyBk', { Text = 'Back ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Bk") end })
SkyTab:AddInput('SkyDn', { Text = 'Down ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Dn") end })
SkyTab:AddInput('SkyFt', { Text = 'Front ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Ft") end })
SkyTab:AddInput('SkyLf', { Text = 'Left ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Lf") end })
SkyTab:AddInput('SkyRt', { Text = 'Right ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Rt") end })
SkyTab:AddInput('SkyUp', { Text = 'Up ID', Default = '', Placeholder = 'ID без rbxassetid', Callback = function(v) World.SetSkyboxCustom(v, "Up") end })

local WeatherTab = WTab:AddTab('Weather')
WeatherTab:AddToggle('RainOn', { Text = 'Rain', Default = false, Callback = function(v)
    local intensity = (Library.Toggles.RainIntensity and Library.Toggles.RainIntensity.Value) or 20
    World.SetRain(v, intensity)
end })
WeatherTab:AddSlider('RainIntensity', { Text = 'Rain Intensity', Default = 20, Min = 20, Max = 2000, Rounding = 0, Callback = function(v)
    if Library.Toggles.RainOn and Library.Toggles.RainOn.Value then World.SetRain(true, v) end
end })
WeatherTab:AddDivider()
WeatherTab:AddToggle('SnowOn', { Text = 'Snow', Default = false, Callback = function(v)
    local intensity = (Library.Toggles.SnowIntensity and Library.Toggles.SnowIntensity.Value) or 10
    World.SetSnow(v, intensity)
end })
WeatherTab:AddSlider('SnowIntensity', { Text = 'Snow Intensity', Default = 10, Min = 10, Max = 500, Rounding = 0, Callback = function(v)
    if Library.Toggles.SnowOn and Library.Toggles.SnowOn.Value then World.SetSnow(true, v) end
end })

local TexTab = WTab:AddTab('Textures')
TexTab:AddToggle('RemoveTextures', { Text = 'Remove Wall Textures', Default = false, Callback = function(v) World.SetRemoveTextures(v) end })
TexTab:AddLabel('Убирает материал со стенок — делает их гладкими.')

local EffTab = Tabs.World:AddRightTabbox():AddTab('Effects')
EffTab:AddToggle('Bloom', { Text = 'Bloom', Default = false, Callback = function(v)
    local i = (Library.Toggles.BloomIntensity and Library.Toggles.BloomIntensity.Value) or 0
    World.SetBloom(v, i)
end })
EffTab:AddSlider('BloomIntensity', { Text = 'Bloom Intensity', Default = 0, Min = 0, Max = 5, Rounding = 1, Callback = function(v)
    if Library.Toggles.Bloom and Library.Toggles.Bloom.Value then World.SetBloom(true, v) end
end })
EffTab:AddToggle('Blur', { Text = 'Blur', Default = false, Callback = function(v)
    local s = (Library.Toggles.BlurSize and Library.Toggles.BlurSize.Value) or 1
    World.SetBlur(v, s)
end })
EffTab:AddSlider('BlurSize', { Text = 'Blur Size', Default = 1, Min = 1, Max = 40, Rounding = 0, Callback = function(v)
    if Library.Toggles.Blur and Library.Toggles.Blur.Value then World.SetBlur(true, v) end
end })
EffTab:AddToggle('SunRays', { Text = 'Sun Rays', Default = false, Callback = function(v) World.SetSunRays(v, 0.1) end })
EffTab:AddToggle('DOF', { Text = 'Depth of Field', Default = false, Callback = function(v) World.SetDOF(v, 50, 0.5) end })
EffTab:AddDivider()
EffTab:AddToggle('ColorCorrection', { Text = 'Color Correction', Default = false, Callback = function(v)
    local b = (Library.Toggles.CCBrightness and Library.Toggles.CCBrightness.Value) or 0
    local c = (Library.Toggles.CCContrast and Library.Toggles.CCContrast.Value) or 0
    local s = (Library.Toggles.CCSaturation and Library.Toggles.CCSaturation.Value) or 0
    local t = (Library.Options.CCTint and Library.Options.CCTint.Value) or Color3.new(1, 1, 1)
    World.SetColorCorrection(v, b, c, s, t)
end })
EffTab:AddSlider('CCBrightness', { Text = 'Brightness', Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = function(v)
    if Library.Toggles.ColorCorrection and Library.Toggles.ColorCorrection.Value then
        local c = (Library.Toggles.CCContrast and Library.Toggles.CCContrast.Value) or 0
        local s = (Library.Toggles.CCSaturation and Library.Toggles.CCSaturation.Value) or 0
        local t = (Library.Options.CCTint and Library.Options.CCTint.Value) or Color3.new(1, 1, 1)
        World.SetColorCorrection(true, v, c, s, t)
    end
end })
EffTab:AddSlider('CCContrast', { Text = 'Contrast', Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = function(v)
    if Library.Toggles.ColorCorrection and Library.Toggles.ColorCorrection.Value then
        local b = (Library.Toggles.CCBrightness and Library.Toggles.CCBrightness.Value) or 0
        local s = (Library.Toggles.CCSaturation and Library.Toggles.CCSaturation.Value) or 0
        local t = (Library.Options.CCTint and Library.Options.CCTint.Value) or Color3.new(1, 1, 1)
        World.SetColorCorrection(true, b, v, s, t)
    end
end })
EffTab:AddSlider('CCSaturation', { Text = 'Saturation', Default = 0, Min = -2, Max = 2, Rounding = 2, Callback = function(v)
    if Library.Toggles.ColorCorrection and Library.Toggles.ColorCorrection.Value then
        local b = (Library.Toggles.CCBrightness and Library.Toggles.CCBrightness.Value) or 0
        local c = (Library.Toggles.CCContrast and Library.Toggles.CCContrast.Value) or 0
        local t = (Library.Options.CCTint and Library.Options.CCTint.Value) or Color3.new(1, 1, 1)
        World.SetColorCorrection(true, b, c, v, t)
    end
end })
EffTab:AddLabel('Tint'):AddColorPicker('CCTint', { Default = Color3.new(1, 1, 1), Callback = function(c)
    if Library.Toggles.ColorCorrection and Library.Toggles.ColorCorrection.Value then
        local b = (Library.Toggles.CCBrightness and Library.Toggles.CCBrightness.Value) or 0
        local cn = (Library.Toggles.CCContrast and Library.Toggles.CCContrast.Value) or 0
        local s = (Library.Toggles.CCSaturation and Library.Toggles.CCSaturation.Value) or 0
        World.SetColorCorrection(true, b, cn, s, c)
    end
end })

-- ─── SKIN ───
local SLeft = Tabs.Skin:AddLeftGroupbox('UNLOCK ALL')
SLeft:AddButton({ Text = '⚡  UNLOCK ALL', Func = function()
    local ok = installUnlockAll()
    Library:Notify(ok and 'UNLOCK ALL активирован!' or 'Не удалось. Модули Rivals не найдены.', 4)
end })
SLeft:AddLabel('Активирует все Skin / Charm / Wrap клиентски.')

local SRight = Tabs.Skin:AddRightGroupbox('CONFIG')
SRight:AddButton({ Text = '💾  Save Config', Func = saveConfiguration })
SRight:AddButton({ Text = '📂  Load Config', Func = loadConfiguration })
SRight:AddButton({ Text = '🗑  Clear ALL Overrides', Func = function()
    for k in pairs(equippedByWeapon) do equippedByWeapon[k] = nil end
    queueReplication("WeaponInventory"); queueReplication("CosmeticInventory"); saveConfiguration()
    Library:Notify('Все overrides удалены', 3)
end })

local SRight2 = Tabs.Skin:AddRightGroupbox('QUICK EQUIP')
local function quick(w, t, n)
    return function()
        if not UnlockAllInstalled then installUnlockAll() end
        setEquippedCosmetic(w, t, n)
        queueReplication(isWeaponCosmeticType(t) and "WeaponInventory" or "CosmeticInventory")
        Library:Notify(w .. ' → ' .. n, 2)
    end
end
SRight2:AddButton({ Text = 'Katana → Saber', Func = quick("Katana", "Skin", "Saber") })
SRight2:AddButton({ Text = 'Assault Rifle → AK-47', Func = quick("Assault Rifle", "Skin", "AK-47") })
SRight2:AddButton({ Text = 'Sniper → Pixel Sniper', Func = quick("Sniper", "Skin", "Pixel Sniper") })
SRight2:AddButton({ Text = 'Knife → Karambit', Func = quick("Knife", "Skin", "Karambit") })

-- ─── MISC ───
local MLeft = Tabs.Misc:AddLeftGroupbox('MOVEMENT')
MLeft:AddToggle('WalkSpeedBoost', { Text = 'Walk Speed Boost', Default = false })
MLeft:AddToggle('JumpPowerBoost', { Text = 'Jump Power Boost', Default = false })
MLeft:AddToggle('InfiniteJump', { Text = 'Infinite Jump', Default = false })
local MRight = Tabs.Misc:AddRightGroupbox('SAFETY')
MRight:AddToggle('AntiAFK', { Text = 'Anti-AFK', Default = false })

-- ─── INFO ───
local ILeft = Tabs.Info:AddLeftGroupbox('⚠  ВНИМАНИЕ')
ILeft:AddLabel('Этот скрипт создан ИСКЛЮЧИТЕЛЬНО для тестирования античит-систем на ваших собственных серверах.')
ILeft:AddLabel('Использование на публичных серверах без разрешения владельца нарушает правила платформы.')
local IRight = Tabs.Info:AddRightGroupbox('TEAM')
IRight:AddLabel('•  Monika_8')
IRight:AddLabel('•  M8losigaret')
IRight:AddDivider()
IRight:AddLabel('femboycord  •  by 141 / monolix')

-- ═══════════════════════════════════════════════════════════════
-- АВТОПОДГРУЗКА
-- ═══════════════════════════════════════════════════════════════
pcall(function() SaveManager:SetLibrary(Library) end)
pcall(function() SaveManager:SetFolder('femboycord') end)
pcall(function() SaveManager:IgnoreThemeSettings() end)
pcall(function() SaveManager:BuildConfigSection(Tabs.Info) end)
pcall(function()
    if SaveManager.LoadAutoloadConfig then
        SaveManager:LoadAutoloadConfig()
    end
end)

pcall(function() ThemeManager:ApplyToTab(Tabs.Info) end)

task.spawn(function()
    if not UnlockAllInstalled then
        local ok = installUnlockAll()
        if not ok then
            task.wait(3)
            if not UnlockAllInstalled then installUnlockAll() end
        end
    end
end)

local function reapplyCharacterBound()
    task.wait(1.5)
    if Library.Toggles.RainOn and Library.Toggles.RainOn.Value then
        World.SetRain(true, Library.Toggles.RainIntensity.Value)
    end
    if Library.Toggles.SnowOn and Library.Toggles.SnowOn.Value then
        World.SetSnow(true, Library.Toggles.SnowIntensity.Value)
    end
    espRebuild()
    print("[femboycord] World/ESP переприменены после респавна")
end

if LP.Character then
    task.defer(reapplyCharacterBound)
end
LP.CharacterAdded:Connect(reapplyCharacterBound)

print("[femboycord] Loaded — Obsidian + Blackout/Pink + UnlockAll + ESP + World")
print("[femboycord] Menu toggle: RightShift  •  Auto-load + teleport-restart enabled")
