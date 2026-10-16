--==================================================================
--  BLOX FRUITS HUB — MOBILE + QUEUE-ON-TELEPORT EDITION
--  Replace HUB_SCRIPT_URL below with the RAW URL of THIS script
--==================================================================
local HUB_SCRIPT_URL = "https://raw.githubusercontent.com/toprakt7777-dev/Idkbutstillcool/refs/heads/main/Bfscript.lua"
--==================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

if _G.BloxHubCleanup then pcall(_G.BloxHubCleanup) end

local Connections = {}
local function AddConnection(conn)
    if conn then table.insert(Connections, conn) end
    return conn
end

_G.BloxHubCleanup = function()
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then pcall(function() conn:Disconnect() end) end
    end
    table.clear(Connections)
end

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local Workspace          = game:GetService("Workspace")
local StatsService       = game:GetService("Stats")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")
local GuiService         = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ============================================================
-- PLATFORM DETECTION
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local IS_CONSOLE = UserInputService.GamepadEnabled and not UserInputService.TouchEnabled
local IS_PC = not IS_MOBILE and not IS_CONSOLE

-- Detect which mobile executor (affects some APIs)
local EXECUTOR_NAME = "Unknown"
pcall(function()
    if syn then EXECUTOR_NAME = "Synapse"
    elseif fluxus then EXECUTOR_NAME = "Fluxus"
    elseif krnl then EXECUTOR_NAME = "Krnl"
    elseif delta then EXECUTOR_NAME = "Delta"
    elseif arceus then EXECUTOR_NAME = "Arceus X"
    elseif hydrogen then EXECUTOR_NAME = "Hydrogen"
    elseif codex then EXECUTOR_NAME = "Codex"
    elseif Kavo then EXECUTOR_NAME = "Kavo"
    elseif VegaX then EXECUTOR_NAME = "VegaX"
    elseif Aztup then EXECUTOR_NAME = "Aztup"
    elseif is_sirhurt_closure then EXECUTOR_NAME = "SirHurt"
    end
end)

-- ============================================================
-- CHARACTER DATA
-- ============================================================
local CharacterData = { Character = nil, Humanoid = nil, RootPart = nil }
local LocalPlayerDeathCount = 0

local function UpdateCharacterReferences()
    local char = LocalPlayer.Character
    if char and char.Parent then
        CharacterData.Character = char
        CharacterData.Humanoid  = char:FindFirstChildOfClass("Humanoid")
        CharacterData.RootPart  = char:FindFirstChild("HumanoidRootPart")
    else
        CharacterData.Character = nil
        CharacterData.Humanoid  = nil
        CharacterData.RootPart  = nil
    end
end
UpdateCharacterReferences()

AddConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    CharacterData.Character = char
    CharacterData.Humanoid  = char:WaitForChild("Humanoid", 5)
    CharacterData.RootPart  = char:WaitForChild("HumanoidRootPart", 5)
    LocalPlayerDeathCount   = 0
    task.wait(0.2)
    UpdateCharacterReferences()
end))
AddConnection(LocalPlayer.CharacterRemoving:Connect(function()
    CharacterData.Character = nil
    CharacterData.Humanoid  = nil
    CharacterData.RootPart  = nil
end))

-- ============================================================
-- SETTINGS
-- ============================================================
local DefaultSettings = {
    PVPMode = false,
    FastAttack = true,
    SpamSoulGuitar = false,
    AutoClick = false,
    AutoEquip = true,
    EquipWeaponType = "Buddy Sword",
    BringMobs = true,
    SafeMode = false,
    WalkOnWater = false,
    Noclip = true,
    AutoRaceV4 = false,
    AutoFarmLevel = false, AutoFarmBoss = false, AutoFarmMaterial = false,
    FarmMastery = false, AutoRaid = false,
    AutoSeaEvents = false, AutoFactory = false, AutoPirateRaid = false,
    AimbotSkills = true,
    XMove100Hit = true,
    TargetPrediction = true,
    AimbotCamera = true,
    InstantLock = true,
    AimMethod = "Closest to LocalPlayer",
    TargetPriority = "LowestHP",
    TargetSelect = "",
    CameraSmoothness = 0.15,
    HitboxExpand = true,
    HitboxSize = 35,
    Crosshair = false, ShowFOV = false, FOVRadius = 180,
    Spectate = false,
    AutoStats = false, StatType = "Melee", StatPoints = 1,
    SelectedIslandTeleport = "",
    TweenSpeed = 350,
    EscapeHeight = 500,
    PlayerESP = true,
    BountyHunt = false,
    AutoPortalTP = true,
    PortalDistanceThreshold = 1500,
    AutoServerHopWhenEmpty = true,
    AvoidSafeZonePlayers = true,
    MaxTargetDistance = 10000,
    SavedTeam = "Pirates",
    AutoLoadConfig = true,
    ServerHopRegion = "Singapore",
    ServerHopMaxPlayers = 10,
    FilterMinServerBounty = true,
    MinServerBounty = 30000000,
    AutoDodge = true,
    DodgeRadius = 22,
    DodgeCooldown = 0.55,
    FastAttackBurstHP = 50,
    AttackRangeNormal = 120,
    AttackRangeBurst = 260,
    AttackRangeLowHP = 350,
    -- Mobile/queue specific
    AutoRejoinOnTeleport = true,
}

local Settings = {}
for k, v in pairs(DefaultSettings) do Settings[k] = v end

local ConfigFileName = "BloxHub_Config_V3.json"
local function SaveConfig()
    pcall(function()
        if writefile then writefile(ConfigFileName, HttpService:JSONEncode(Settings)) end
    end)
end
local function LoadConfig()
    pcall(function()
        if isfile and isfile(ConfigFileName) then
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do if Settings[k] ~= nil then Settings[k] = v end end
            end
        end
    end)
end
LoadConfig()

local UIControls = {}
local function UpdateStatusText(text)
    pcall(function()
        if UIControls and UIControls.HuntStatusParagraph then
            if UIControls.HuntStatusParagraph.SetContent then
                UIControls.HuntStatusParagraph:SetContent(text)
            elseif UIControls.HuntStatusParagraph.SetDesc then
                UIControls.HuntStatusParagraph:SetDesc(text)
            end
        end
    end)
end

local function GetTotalServerBounty()
    local totalBounty = 0
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            local bountyVal = 0
            local ls = p:FindFirstChild("leaderstats")
            if ls then
                local b = ls:FindFirstChild("Bounty / Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
                if b and b:IsA("ValueBase") then bountyVal = tonumber(b.Value) or 0 end
            end
            if bountyVal == 0 then
                local data = p:FindFirstChild("Data")
                if data then
                    local b = data:FindFirstChild("Bounty") or data:FindFirstChild("Honor")
                    if b and b:IsA("ValueBase") then bountyVal = tonumber(b.Value) or 0 end
                end
            end
            totalBounty = totalBounty + bountyVal
        end
    end)
    return totalBounty
end

local function ClearLoadingOverlays()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, n in ipairs({"ChooseTeam", "LoadingGui", "Fade", "BlackScreen"}) do
                local g = playerGui:FindFirstChild(n); if g then g:Destroy() end
            end
        end
        if Workspace.CurrentCamera then Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
    end)
end
ClearLoadingOverlays()

-- ============================================================
-- TEAM
-- ============================================================
local function JoinTeam(teamName)
    teamName = teamName or Settings.SavedTeam or "Pirates"
    pcall(function()
        ClearLoadingOverlays()
        local rf = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
        local cf = rf and rf:FindFirstChild("CommF_")
        if cf then cf:InvokeServer("SetTeam2", teamName) end
    end)
end
task.spawn(function() task.wait(0.3); JoinTeam(Settings.SavedTeam) end)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            ClearLoadingOverlays()
            if LocalPlayer.Team == nil or LocalPlayer.Team.Name == "Neutral" or not LocalPlayer.Character then
                JoinTeam(Settings.SavedTeam)
            end
        end)
    end
end)

-- ============================================================
-- TWEEN
-- ============================================================
local ActiveTween = nil
local LastTweenTarget = nil
local TweenBodyVel = nil

local function StopTween()
    if ActiveTween then pcall(function() ActiveTween:Cancel() end) ActiveTween = nil end
    if TweenBodyVel then pcall(function() TweenBodyVel:Destroy() end) TweenBodyVel = nil end
    LastTweenTarget = nil
end

-- ============================================================
-- INFINITE ESCAPE ASCENSION
-- ============================================================
local IsServerHopping = false
local LastServerHopTime = 0
local SERVER_HOP_COOLDOWN = 20
local IsEscaping = false
local EscapeBV = nil
local EscapeStopTime = 0

local function StartInfiniteEscape()
    if IsEscaping then return end
    IsEscaping = true
    EscapeStopTime = 0
    StopTween()
    local root = CharacterData.RootPart
    if root then
        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition") then
                pcall(function() obj:Destroy() end)
            end
        end
        if EscapeBV then pcall(function() EscapeBV:Destroy() end) end
        EscapeBV = Instance.new("BodyVelocity")
        EscapeBV.Name = "EscapeBV"
        EscapeBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        EscapeBV.Velocity = Vector3.new(0, 400, 0)
        EscapeBV.Parent = root
    end
end

local function StopInfiniteEscape()
    IsEscaping = false
    if EscapeBV then
        pcall(function() EscapeBV:Destroy() end)
        EscapeBV = nil
    end
end

task.spawn(function()
    while task.wait(0.03) do
        if IsEscaping then
            local root = CharacterData.RootPart
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

-- ============================================================
-- ============================================================
--          QUEUE ON TELEPORT  (MOBILE + PC, INFINITE CHAIN)
-- ============================================================
-- ============================================================
local function GetQueueOnTeleport()
    local candidates = {
        (getgenv and getgenv().queue_on_teleport),
        (getgenv and getgenv().queueonteleport),
        queue_on_teleport,
        queueonteleport,
        syn and syn.queue_on_teleport,
        syn and syn.queueonteleport,
        fluxus and fluxus.queue_on_teleport,
        fluxus and fluxus.queueonteleport,
        krnl and krnl.queue_on_teleport,
        delta and delta.queue_on_teleport,
        delta and delta.queueonteleport,
        arceus and arceus.queue_on_teleport,
        hydrogen and hydrogen.queue_on_teleport,
        codex and codex.queue_on_teleport,
        Kavo and Kavo.queue_on_teleport,
        VegaX and VegaX.queue_on_teleport,
    }
    for _, f in ipairs(candidates) do
        if type(f) == "function" then return f end
    end
    return nil
end

-- Builds the payload script that will run AFTER the teleport.
-- It re-loads THIS hub from HUB_SCRIPT_URL so the chain never stops.
local function BuildQueuePayload()
    return ([[
        -- === BloxHub Auto-Reloader Payload ===
        repeat task.wait() until game:IsLoaded()
        task.wait(0.6)

        -- Retry until we manage to load the hub
        local attempts, maxAttempts = 0, 6
        local url = "%s"

        while attempts < maxAttempts do
            attempts = attempts + 1
            local ok, err = pcall(function()
                local src = game:HttpGet(url .. "?t=" .. tostring(os.time()))
                local fn = loadstring(src) or loadstring(game:HttpGet(url))
                if fn then fn() end
            end)
            if ok then break end
            task.wait(1.5)
        end
    ]]):format(HUB_SCRIPT_URL)
end

local function QueueScriptOnTeleport()
    pcall(function()
        local qf = GetQueueOnTeleport()
        if not qf then
            warn(("[BloxHub] No queue_on_teleport function found on %s executor. Auto-rejoin disabled.")
                :format(EXECUTOR_NAME))
            return
        end
        -- Some executors need this flag for the queue to persist across multiple hops
        pcall(function()
            if getgenv then getgenv().queue_on_teleport_enabled = true end
        end)
        qf(BuildQueuePayload())
    end)
end

-- ============================================================
-- SERVER HOP (native __ServerBrowser, mobile-safe)
-- ============================================================
local function PrepareForTeleport()
    pcall(StopTween)
    pcall(SaveConfig)
    -- Queue reload of the FULL hub script (not just Fluent)
    if Settings.AutoRejoinOnTeleport ~= false then
        QueueScriptOnTeleport()
    end
    -- Force-kill any body movers
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                for _, obj in ipairs(part:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end
end

local function ServerHop(maxPlayers, region)
    if IsServerHopping then return end
    if (os.clock() - LastServerHopTime) < SERVER_HOP_COOLDOWN then return end
    IsServerHopping = true
    LastServerHopTime = os.clock()

    maxPlayers = maxPlayers or Settings.ServerHopMaxPlayers or 8
    region     = region     or Settings.ServerHopRegion     or "Singapore"

    PrepareForTeleport()
    ClearLoadingOverlays()
    pcall(StopTween)
    StopInfiniteEscape()

    task.spawn(function()
        local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
            or ReplicatedStorage:WaitForChild("__ServerBrowser", 10)

        if not serverBrowser then
            warn("[ServerHop] __ServerBrowser not found — aborting")
            IsServerHopping = false
            return
        end

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            or LocalPlayer:WaitForChild("PlayerGui", 5)

        local teleported = false

        for i = 1, 100 do
            pcall(function()
                local sb = playerGui and playerGui:FindFirstChild("ServerBrowser")
                local frame = sb and sb:FindFirstChild("Frame")
                local filters = frame and frame:FindFirstChild("Filters")
                local searchRegion = filters and filters:FindFirstChild("SearchRegion")
                if searchRegion and searchRegion:FindFirstChild("TextBox") then
                    searchRegion.TextBox.Text = region
                end
            end)

            local ok, response = pcall(function()
                return serverBrowser:InvokeServer(i)
            end)

            if ok and type(response) == "table" then
                local pool = {}
                for jobId, info in pairs(response) do
                    if type(info) == "table" and jobId ~= game.JobId then
                        local count = tonumber(info.Count) or 0
                        local maxCap = tonumber(info.MaxPlayers) or 12
                        local isPrivate = string.find(tostring(info.Private), "true", 1, true) ~= nil
                        if not isPrivate
                           and count > 0
                           and count <= maxPlayers
                           and count < maxCap then
                            table.insert(pool, { JobId = jobId, Count = count })
                        end
                    end
                end

                for s = #pool, 2, -1 do
                    local r = math.random(1, s)
                    pool[s], pool[r] = pool[r], pool[s]
                end

                for _, entry in ipairs(pool) do
                    local okTP = pcall(function()
                        serverBrowser:InvokeServer("teleport", entry.JobId)
                    end)
                    if okTP then
                        teleported = true
                        break
                    end
                end

                if teleported then
                    task.wait(8)
                    if IsServerHopping then IsServerHopping = false end
                    return
                end
            end

            task.wait(0.2)
        end

        if not teleported then
            warn("[ServerHop] No matching server found in browser")
            pcall(function()
                serverBrowser:InvokeServer("teleport")
            end)
        end

        task.wait(6)
        if IsServerHopping then IsServerHopping = false end
    end)
end

AddConnection(TeleportService.TeleportInitFailed:Connect(function()
    IsServerHopping = false
    ClearLoadingOverlays()
end))

-- ============================================================
-- PORTAL / WORLD
-- ============================================================
local PORTAL_DESTINATIONS = {
    ["Haunted Ship"]  = Vector3.new(937, 125, 32879),
    ["Dark Arena"]    = Vector3.new(3948, 13, -3479),
    ["Cafe"]          = Vector3.new(-382, 74, 356),
    ["Mansion"]       = Vector3.new(-494, 339, 593),
    ["Winter Castle"] = Vector3.new(5544.71, 60.13, -6359.08),
    ["Lab"]           = Vector3.new(-5541, 230, -5898),
    ["Graveyard"]     = Vector3.new(-5710, 126, -775),
    ["Colosseum"]     = Vector3.new(-1836, 46, 1642),
    ["Snow"]          = Vector3.new(1210, 429, -4663),
    ["Raid"]          = Vector3.new(-6495, 95, -4897),
    ["Lava"]          = Vector3.new(-5208, 184, -5505),
    ["Doghouse"]      = Vector3.new(-1984, 125, -82),
    ["Skull"]         = Vector3.new(-2956.24, 123.39, -9981.06),
    ["Docks 1"]       = Vector3.new(-923, 8, 1810),
    ["Docks 2"]       = Vector3.new(-13, 39, 2708),
    ["Docks 3"]       = Vector3.new(-1944, 9, -2594),
    ["Docks 4"]       = Vector3.new(-5798, 1, -5021),
    ["Remote"]        = Vector3.new(4766, 8, 2911)
}
local SelectedPortalDestination = "Cafe"

local Modules        = ReplicatedStorage:WaitForChild("Modules", 10)
local Net            = Modules and Modules:WaitForChild("Net", 10)
local RemotesFolder  = ReplicatedStorage:WaitForChild("Remotes", 10)
local CommF_         = RemotesFolder and RemotesFolder:FindFirstChild("CommF_")
local Register_Attack= Net and Net:FindFirstChild("RE/RegisterAttack")
local Register_Hit   = Net and Net:FindFirstChild("RE/RegisterHit")
local ComboEvent     = RemotesFolder and (RemotesFolder:FindFirstChild("Combo") or RemotesFolder:WaitForChild("Combo", 5))
local RequestGateway = RemotesFolder and RemotesFolder:FindFirstChild("RequestGateway")

if RequestGateway then
    RequestGateway.OnClientInvoke = function(_) return SelectedPortalDestination end
end

local function GetNetworkPing()
    local ping = 0.03
    pcall(function()
        local item = StatsService.Network.ServerStatsItem["Data Ping"]
        if item then ping = math.clamp(item:GetValue() / 1000, 0.01, 0.35) end
    end)
    return ping
end

local function GetLocalPlayerHealth()
    local char = CharacterData.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then return hum.Health, hum.MaxHealth end
    end
    return 0, 100
end

local function GetHealthRatio()
    local h, m = GetLocalPlayerHealth()
    if m <= 0 then return 1 end
    return h / m
end

local function ApplyAntiStun()
    local char = CharacterData.Character
    if not char then return end
    local hum, root = CharacterData.Humanoid, CharacterData.RootPart
    if hum then hum.PlatformStand = false hum.Sit = false end
    if root then
        pcall(function()
            root.AssemblyAngularVelocity = Vector3.zero
            if not IsEscaping then root.AssemblyLinearVelocity = Vector3.zero end
        end)
        for _, obj in ipairs(root:GetChildren()) do
            if ((obj:IsA("BodyVelocity") and obj.Name ~= "TweenBV" and obj.Name ~= "EscapeBV")
               or obj:IsA("BodyGyro") or obj:IsA("BodyPosition")) then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end

local PlaceId = game.PlaceId
local World1 = PlaceId == 2753915549 or PlaceId == 85211729168715
local World2 = PlaceId == 4442272183 or PlaceId == 79091703265657
local World3 = PlaceId == 7449423635 or PlaceId == 100117331123089

local HitValidator = { LastHitTime = 0, LastHitDamage = 0, TotalHitCount = 0, ReceivedHitTime = 0 }
local TargetKillCounts = {}

if ComboEvent and ComboEvent:IsA("RemoteEvent") then
    AddConnection(ComboEvent.OnClientEvent:Connect(function(...)
        local args = {...}
        local damage = args[1]
        if typeof(damage) == "number" and damage > 0 then
            HitValidator.LastHitTime = os.clock()
            HitValidator.LastHitDamage = damage
            HitValidator.TotalHitCount = HitValidator.TotalHitCount + 1
        end
    end))
end

local LastHealthObserved = 0
task.spawn(function()
    while task.wait(0.15) do
        local h = GetLocalPlayerHealth()
        if LastHealthObserved > 0 and h > 0 and h < LastHealthObserved - 3 then
            HitValidator.ReceivedHitTime = os.clock()
        end
        LastHealthObserved = h
    end
end)

function HitValidator:WasHitRecently(t) return (os.clock() - self.LastHitTime) <= (t or 1.5) end
function HitValidator:WasHitTakenRecently(t) return (os.clock() - self.ReceivedHitTime) <= (t or 1.5) end
function HitValidator:GetLastHitDamage() return self.LastHitDamage end

local function TrackPlayerKills(p)
    if p == LocalPlayer then return end
    AddConnection(p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            AddConnection(hum.Died:Connect(function()
                if HitValidator.LastHitTime > 0 and (os.clock() - HitValidator.LastHitTime) < 5 then
                    TargetKillCounts[p.UserId] = (TargetKillCounts[p.UserId] or 0) + 1
                end
            end))
        end
    end))
end
for _, p in ipairs(Players:GetPlayers()) do TrackPlayerKills(p) end
AddConnection(Players.PlayerAdded:Connect(TrackPlayerKills))

local function TrackLocalPlayerDeath(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        AddConnection(hum.Died:Connect(function()
            LocalPlayerDeathCount = LocalPlayerDeathCount + 1
            if LocalPlayerDeathCount >= 3 then
                task.spawn(function()
                    if not IsServerHopping and Settings.BountyHunt then
                        UpdateStatusText("Died 3 times! Initiating Server Hop...")
                        StartInfiniteEscape()
                        task.wait(1.2)
                        ServerHop()
                    end
                end)
            end
        end))
    end
end

AddConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2); UpdateCharacterReferences(); TrackLocalPlayerDeath(char)
end))
if LocalPlayer.Character then UpdateCharacterReferences(); TrackLocalPlayerDeath(LocalPlayer.Character) end

local IslandTeleports = {}
if World1 then
    IslandTeleports = {
        ["Starter Island"]=CFrame.new(979,16,1405), ["Jungle"]=CFrame.new(-1612,36,149),
        ["Pirate Village"]=CFrame.new(-1141,4,3831), ["Desert"]=CFrame.new(894,6,4390),
        ["Middle Town"]=CFrame.new(-690,15,1582), ["Frozen Village"]=CFrame.new(1285,7,-1325),
        ["Marine Fortress"]=CFrame.new(-5035,28,4325), ["Skypiea"]=CFrame.new(-4832,717,-2622),
        ["Prison"]=CFrame.new(4875,5,735), ["Colosseum"]=CFrame.new(-1428,7,301),
        ["Magma Village"]=CFrame.new(-5241,8,8404), ["Underwater City"]=CFrame.new(61163,11,1819),
        ["Fountain City"]=CFrame.new(5127,59,4105)
    }
elseif World2 then
    IslandTeleports = {
        ["Cafe / Rose Kingdom"]=CFrame.new(-382,73,297), ["Ushron / Factory"]=CFrame.new(432,116,-428),
        ["Green Zone"]=CFrame.new(-2385,73,-3022), ["Graveyard Island"]=CFrame.new(-5414,48,-725),
        ["Snow Mountain"]=CFrame.new(609,401,-5372), ["Cold Area"]=CFrame.new(-6026,15,-4971),
        ["Hot Area"]=CFrame.new(-5488,15,-5251), ["Cursed Ship"]=CFrame.new(923,125,32852),
        ["Ice Castle"]=CFrame.new(6148,294,-6741), ["Forgotten Island"]=CFrame.new(-3032,236,-10146)
    }
elseif World3 then
    IslandTeleports = {
        ["Port Town"]=CFrame.new(-290,7,5343), ["Hydra Island"]=CFrame.new(5228,604,345),
        ["Great Tree"]=CFrame.new(2280,25,-6722), ["Floating Turtle"]=CFrame.new(-13274,332,-7628),
        ["Castle on the Sea"]=CFrame.new(-5085,314,-3150), ["Haunted Castle"]=CFrame.new(-9515,142,5520),
        ["Chocolate Land"]=CFrame.new(130,24,-12110), ["Candy Island"]=CFrame.new(-2021,38,-12028),
        ["Tiki Outpost"]=CFrame.new(-16106,9,452)
    }
end

local CurrentTargetPos  = Vector3.zero
local CurrentTargetPart = nil
local CurrentTargetName = "None"
local CurrentTargetPlayer = nil
local HuntTargetPlayer  = nil
local HuntTargetStartTime = 0
local IsInEscapeMode    = false
local LastPortalTPTime  = 0
local IsPortalTeleporting = false
local SavedSettingsConfig = nil
local NoTargetStartTime = 0
local IsComboRunning    = false
local LastDodgeTime     = 0

local Fluent, Window
local isSyncingUI = false

local function DeepCopyTable(orig)
    local c = {}; for k, v in pairs(orig) do c[k] = v end; return c
end
local function GetCenterScreen()
    if not Camera then return Vector2.new(800, 600) end
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = CharacterData.Character
            if char and CommF_ then
                local buso = char:GetAttribute("BusoEnabled") or char:GetAttribute("HasBuso")
                    or (char:FindFirstChild("BusoEnabled") and char.BusoEnabled.Value == true)
                    or char:FindFirstChild("HasBuso")
                if not buso then CommF_:InvokeServer("Buso") end
            end
        end)
    end
end)

local function GetPredictedTargetPos(targetPart, projectileSpeed, gravity)
    if not targetPart or not targetPart.Parent then return Vector3.zero end
    local pos = targetPart.Position
    if Settings.TargetPrediction and CharacterData.RootPart then
        local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero
        if velocity.Magnitude < 900 then
            local dist = (CharacterData.RootPart.Position - pos).Magnitude
            local speed = projectileSpeed or 2600
            local ping = GetNetworkPing()
            local t = math.clamp((dist / speed) + ping, 0.008, 0.25)
            pos = pos + (velocity * t)
            if gravity and gravity > 0 then pos = pos + Vector3.new(0, 0.5 * gravity * (t ^ 2), 0) end
        end
    end
    return pos
end

-- ============================================================
-- SILENT AIM METATABLE HOOK (mobile-safe)
-- ============================================================
pcall(function()
    local getrawmetatable = getrawmetatable or function() return getmetatable(game) end
    local setreadonly = setreadonly or make_writeable or function() end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    local isHooking = false

    mt.__index = newcclosure(function(self, index)
        if not checkcaller() and not IsServerHopping and not IsEscaping and not isHooking
           and (Settings.AimbotSkills or Settings.XMove100Hit or Settings.SpamSoulGuitar) then
            if self == Mouse then
                isHooking = true
                local idx = type(index) == "string" and string.lower(index) or ""
                if idx == "hit" or idx == "cframe" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then
                        local predicted = GetPredictedTargetPos(CurrentTargetPart)
                        if predicted ~= Vector3.zero then isHooking = false return CFrame.new(predicted) end
                    end
                elseif idx == "target" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then isHooking = false return CurrentTargetPart end
                elseif idx == "unitray" then
                    if CurrentTargetPart and CurrentTargetPart.Parent then
                        local predicted = GetPredictedTargetPos(CurrentTargetPart)
                        if predicted ~= Vector3.zero and Camera then
                            local dir = (predicted - Camera.CFrame.Position).Unit
                            isHooking = false
                            return Ray.new(Camera.CFrame.Position, dir)
                        end
                    end
                end
                isHooking = false
            end
        end
        return oldIndex(self, index)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if not checkcaller() and not IsServerHopping and not IsEscaping and not isHooking
           and (Settings.AimbotSkills or Settings.XMove100Hit or Settings.SpamSoulGuitar) then
            if method == "Raycast" or method == "raycast" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local args = {...}
                    local origin = args[1]
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if typeof(origin) == "Vector3" and predicted ~= Vector3.zero then
                        local dirLen = typeof(args[2]) == "Vector3" and args[2].Magnitude or 1000
                        args[2] = (predicted - origin).Unit * dirLen
                        isHooking = false
                        return oldNamecall(self, unpack(args))
                    end
                    isHooking = false
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local args = {...}
                    local ray = args[1]
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if typeof(ray) == "Ray" and predicted ~= Vector3.zero then
                        args[1] = Ray.new(ray.Origin, (predicted - ray.Origin).Unit * ray.Direction.Magnitude)
                        isHooking = false
                        return oldNamecall(self, unpack(args))
                    end
                    isHooking = false
                end
            elseif method == "FireServer" or method == "InvokeServer" then
                if CurrentTargetPart and CurrentTargetPart.Parent then
                    isHooking = true
                    local predicted = GetPredictedTargetPos(CurrentTargetPart)
                    if predicted ~= Vector3.zero then
                        local args = {...}
                        local modified = false
                        for i = 1, #args do
                            local a = args[i]
                            if typeof(a) == "Vector3" then args[i] = predicted modified = true
                            elseif typeof(a) == "CFrame" then args[i] = CFrame.new(predicted) modified = true end
                        end
                        if modified then isHooking = false return oldNamecall(self, unpack(args)) end
                    end
                    isHooking = false
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ============================================================
-- SAFE ZONE / PVP / TEAM HELPERS
-- ============================================================
local function IsPlayerInSafeZone(player)
    if not player then return true end
    if player:GetAttribute("InSafeZone") == true or player:GetAttribute("SafeZone") == true then return true end
    local char = player.Character
    if char then
        if char:GetAttribute("InSafeZone") == true or char:GetAttribute("SafeZone") == true
           or char:FindFirstChild("SafeZone") or char:FindFirstChild("InSafeZone")
           or char:FindFirstChildOfClass("ForceField") then return true end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local sf = Workspace:FindFirstChild("SafeZones")
                or (Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("SafeZones"))
            if sf then
                for _, zone in ipairs(sf:GetChildren()) do
                    if zone:IsA("BasePart") then
                        local half = zone.Size / 2
                        local lp = zone.CFrame:PointToObjectSpace(hrp.Position)
                        if math.abs(lp.X) <= half.X and math.abs(lp.Y) <= half.Y and math.abs(lp.Z) <= half.Z then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function IsPlayerPvPDisabled(player)
    if not player then return true end
    if player:GetAttribute("PvpDisabled") == true or player:GetAttribute("PVPDisabled") == true then return true end
    local data = player:FindFirstChild("Data")
    if data then
        local v = data:FindFirstChild("PvpDisabled") or data:FindFirstChild("PVPDisabled")
        if v and v:IsA("ValueBase") and v.Value == true then return true end
    end
    local char = player.Character
    if char then
        if char:FindFirstChildOfClass("ForceField") then return true end
        local v = char:FindFirstChild("PvpDisabled") or char:FindFirstChild("PVPDisabled")
        if v and v:IsA("ValueBase") and v.Value == true then return true end
        if char:GetAttribute("PvpDisabled") == true or char:GetAttribute("PVPDisabled") == true then return true end
    end
    return false
end

local function GetPlayerLevel(player)
    player = player or LocalPlayer
    if not player then return 1 end
    local data = player:FindFirstChild("Data")
    if data then
        local v = data:FindFirstChild("Level")
        if v and v:IsA("ValueBase") then return tonumber(v.Value) or 1 end
    end
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local v = ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl")
        if v and v:IsA("ValueBase") then return tonumber(v.Value) or 1 end
    end
    return 1
end

local function GetPlayerTeam(player)
    if not player or not player.Team then return "Neutral" end
    return tostring(player.Team.Name)
end

-- ============================================================
-- EQUIP HELPERS + MOBILE SAFE KEYPRESS
-- ============================================================
local function EquipToolByName(toolName)
    local char = CharacterData.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char then return nil end
    local function Matches(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local name = string.lower(tool.Name)
        local query = string.lower(toolName)
        if name == query or string.find(name, query, 1, true) then return true end
        if (query == "soul guitar" or query == "skull guitar")
           and (name == "soul guitar" or name == "skull guitar") then return true end
        if query == "portal" and (string.find(name, "portal", 1, true) or string.find(name, "door", 1, true)) then return true end
        return false
    end
    for _, tool in ipairs(char:GetChildren()) do if Matches(tool) then return tool end end
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if Matches(tool) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(tool) task.wait() return char:FindFirstChild(tool.Name) or tool end
            end
        end
    end
    return nil
end

local function EquipToolByToolTip(toolType)
    if toolType == "Buddy Sword" or toolType == "Melee" then EquipToolByName("Buddy Sword") return end
    local char = CharacterData.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char or not backpack then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == toolType or tool.Name == toolType) then return end
    end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == toolType or tool.Name == toolType) then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(tool) end
            break
        end
    end
end

-- MOBILE-SAFE INPUT SENDER
local function SendKeyPress(keyCode)
    pcall(function()
        -- PC / Executor path
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
    -- Mobile extra: many Android executors need rawKeyEvent handled differently
    if IS_MOBILE then
        pcall(function()
            if keypress and type(keypress) == "function" then
                keypress(keyCode.Value)
            end
        end)
    end
end

local function SafeTweenTo(targetCFrame, speed)
    if IsServerHopping or IsEscaping then StopTween() return end
    local root, char = CharacterData.RootPart, CharacterData.Character
    if not root or not char then return end
    speed = speed or Settings.TweenSpeed or 350
    local distance = (root.Position - targetCFrame.Position).Magnitude
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    if distance <= 5 then
        StopTween()
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end
    if distance <= 45 then
        StopTween()
        local dir = (targetCFrame.Position - root.Position).Unit
        root.CFrame = CFrame.new(root.Position + (dir * math.min(distance, speed * 0.1)),
            targetCFrame.Position + targetCFrame.LookVector * 10)
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end
    if not TweenBodyVel or TweenBodyVel.Parent ~= root then
        if TweenBodyVel then pcall(function() TweenBodyVel:Destroy() end) end
        TweenBodyVel = Instance.new("BodyVelocity")
        TweenBodyVel.Name = "TweenBV"
        TweenBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        TweenBodyVel.Velocity = Vector3.zero
        TweenBodyVel.Parent = root
    end
    if LastTweenTarget and (LastTweenTarget.Position - targetCFrame.Position).Magnitude < 20
       and ActiveTween and ActiveTween.PlaybackState == Enum.PlaybackState.Playing then return end
    StopTween()
    LastTweenTarget = targetCFrame
    local duration = distance / math.max(speed, 50)
    ActiveTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    ActiveTween:Play()
end

local function PerformPortalTeleport(destinationName)
    if IsPortalTeleporting or IsServerHopping or IsEscaping or not destinationName then return end
    IsPortalTeleporting = true
    SelectedPortalDestination = destinationName
    local root = CharacterData.RootPart
    if root then
        StopTween()
        local barrier = Instance.new("Part")
        barrier.Name = "PortalTempBarrier"
        barrier.Size = Vector3.new(15, 1, 15)
        barrier.CFrame = root.CFrame - Vector3.new(0, 3.5, 0)
        barrier.Anchored = true
        barrier.Transparency = 1
        barrier.CanCollide = true
        barrier.Parent = Workspace
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        EquipToolByName("Portal")
        task.wait(0.1)
        SendKeyPress(Enum.KeyCode.C)
        task.wait(1.0)
        pcall(function() barrier:Destroy() end)
    end
    IsPortalTeleporting = false
end

local function FireSoulGuitarSpam()
    if not Settings.SpamSoulGuitar or IsServerHopping or IsEscaping then return end
    local char = CharacterData.Character
    if not char then return end
    local sgTool = EquipToolByName("Soul Guitar") or EquipToolByName("Skull Guitar")
    if not sgTool then return end
    local targetPos = Vector3.zero
    if CurrentTargetPart and CurrentTargetPart.Parent then
        local tPlayer = Players:GetPlayerFromCharacter(CurrentTargetPart.Parent)
        if tPlayer and (IsPlayerInSafeZone(tPlayer) or IsPlayerPvPDisabled(tPlayer)) then return end
        targetPos = GetPredictedTargetPos(CurrentTargetPart)
    elseif Mouse then
        pcall(function() targetPos = Mouse.Hit.Position end)
    end
    if targetPos == Vector3.zero then return end
    local toolRemote = sgTool:FindFirstChild("RemoteEvent") or sgTool:FindFirstChildOfClass("RemoteEvent")
    if toolRemote then pcall(function() toolRemote:FireServer(targetPos) end) end
    SendKeyPress(Enum.KeyCode.Z)
    SendKeyPress(Enum.KeyCode.X)
end

task.spawn(function()
    while task.wait(0.015) do
        if Settings.SpamSoulGuitar and not IsServerHopping and not IsEscaping then
            pcall(FireSoulGuitarSpam)
        end
    end
end)

local LastV4Attempt = 0
local function TriggerRaceV4()
    if not Settings.AutoRaceV4 or IsServerHopping or IsEscaping then return end
    if (tick() - LastV4Attempt) < 1.0 then return end
    LastV4Attempt = tick()
    pcall(function()
        local char = CharacterData.Character
        if not char then return end
        if not (char:FindFirstChild("RaceTrans") or char:FindFirstChild("RaceEnergy")) then return end
        SendKeyPress(Enum.KeyCode.Y)
    end)
end

local function ExecuteBuddySwordXSpam(targetPos)
    if IsServerHopping or IsEscaping then return end
    pcall(function()
        local buddyTool = EquipToolByName("Buddy Sword")
        if not buddyTool then return end
        if targetPos and targetPos ~= Vector3.zero then
            local toolRemote = buddyTool:FindFirstChild("RemoteEvent") or buddyTool:FindFirstChildOfClass("RemoteEvent")
            if toolRemote then pcall(function() toolRemote:FireServer(targetPos) end) end
        end
        SendKeyPress(Enum.KeyCode.X)
    end)
end

local function ExecuteSmartCombo(targetPart)
    if IsComboRunning or IsServerHopping or IsEscaping
       or not targetPart or not targetPart.Parent or IsInEscapeMode then return end
    IsComboRunning = true
    local function IsTargetValid()
        if not targetPart or not targetPart.Parent then return false end
        local parent = targetPart.Parent
        local hum = parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        if CharacterData.RootPart then
            local distance = (CharacterData.RootPart.Position - targetPart.Position).Magnitude
            if distance > 180 then return false end
        end
        local player = Players:GetPlayerFromCharacter(parent)
        if player and (IsPlayerInSafeZone(player) or IsPlayerPvPDisabled(player)) then return false end
        return true
    end

    local pool = {
        { Tool = "Godhuman",    Key = Enum.KeyCode.Z },
        { Tool = "Godhuman",    Key = Enum.KeyCode.X },
        { Tool = "Godhuman",    Key = Enum.KeyCode.C },
        { Tool = "Buddy Sword", Key = Enum.KeyCode.Z },
        { Tool = "Buddy Sword", Key = Enum.KeyCode.X },
        { Tool = "Soul Guitar", Key = Enum.KeyCode.Z },
        { Tool = "Soul Guitar", Key = Enum.KeyCode.X }
    }
    task.spawn(function()
        for _, step in ipairs(pool) do
            if not IsTargetValid() or IsInEscapeMode or IsServerHopping or IsEscaping then break end
            if EquipToolByName(step.Tool) then SendKeyPress(step.Key) task.wait(0.015) end
        end
        IsComboRunning = false
    end)
end

-- ============================================================
-- TARGETING
-- ============================================================
local function CanGetBounty(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return false end
    if (TargetKillCounts[targetPlayer.UserId] or 0) >= 3 then return false end
    if IsPlayerPvPDisabled(targetPlayer) then return false end
    if IsPlayerInSafeZone(targetPlayer) then return false end
    local targetChar = targetPlayer.Character
    local targetHrp  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if targetHrp and CharacterData.RootPart then
        local dist = (targetHrp.Position - CharacterData.RootPart.Position).Magnitude
        if dist > (Settings.MaxTargetDistance or 10000) then return false end
    end
    local myLevel = GetPlayerLevel(LocalPlayer)
    local targetLevel = GetPlayerLevel(targetPlayer)
    if myLevel > 10 and targetLevel > 10 then
        if myLevel >= 2550 then
            if targetLevel < math.floor(2550 * 0.75) then return false end
        else
            if targetLevel < math.floor(myLevel * 0.75) then return false end
        end
    end
    local myTeam = GetPlayerTeam(LocalPlayer)
    local targetTeam = GetPlayerTeam(targetPlayer)
    if string.find(string.lower(myTeam), "marine") and string.find(string.lower(targetTeam), "marine") then return false end
    return true
end

local function GetPlayerList()
    local list = {}
    for _, v in ipairs(Players:GetPlayers()) do if v ~= LocalPlayer then table.insert(list, v.Name) end end
    return list
end

local function ScoreTarget(p)
    local char = p.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    local dist = CharacterData.RootPart and (hrp.Position - CharacterData.RootPart.Position).Magnitude or math.huge
    if dist > (Settings.MaxTargetDistance or 10000) then return nil end
    local healthRatio = hum.Health / math.max(hum.MaxHealth, 1)
    return {
        Player = p,
        Distance = dist,
        HealthRatio = healthRatio,
        Health = hum.Health,
    }
end

local function GetBestBountyTarget()
    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if CanGetBounty(p) then
            local s = ScoreTarget(p)
            if s then table.insert(candidates, s) end
        end
    end
    if #candidates == 0 then return nil end
    local priority = Settings.TargetPriority or "LowestHP"
    table.sort(candidates, function(a, b)
        if priority == "LowestHP" then return a.HealthRatio < b.HealthRatio end
        if priority == "Closest" then return a.Distance < b.Distance end
        local aS = a.HealthRatio * 0.6 + (a.Distance / 5000) * 0.4
        local bS = b.HealthRatio * 0.6 + (b.Distance / 5000) * 0.4
        return aS < bS
    end)
    return candidates[1].Player
end
GetClosestBountyTarget = GetBestBountyTarget

local function GetClosestPlayerToLocalPlayer()
    local closestPlayer, shortestDistance = nil, math.huge
    if CharacterData.RootPart then
        local myPos = CharacterData.RootPart.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not IsPlayerInSafeZone(p) and not IsPlayerPvPDisabled(p)
               and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
               and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < shortestDistance and dist <= (Settings.MaxTargetDistance or 10000) then
                    shortestDistance = dist; closestPlayer = p
                end
            end
        end
    end
    return closestPlayer
end

local function GetClosestPlayerToCenterScreen()
    local closestPlayer, shortestDistance = nil, (Settings.ShowFOV and Settings.FOVRadius or math.huge)
    local center = GetCenterScreen()
    if not Camera then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not IsPlayerInSafeZone(p) and not IsPlayerPvPDisabled(p)
           and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
           and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local hrp = p.Character.HumanoidRootPart
            if CharacterData.RootPart and (hrp.Position - CharacterData.RootPart.Position).Magnitude <= (Settings.MaxTargetDistance or 10000) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestDistance then shortestDistance = dist; closestPlayer = p end
                end
            end
        end
    end
    return closestPlayer
end

-- ============================================================
-- FAST ATTACK (ADAPTIVE)
-- ============================================================
local FastAttack = {}
local FastAttack_enemies    = Workspace:FindFirstChild("Enemies") or Workspace
local FastAttack_characters = Workspace:FindFirstChild("Characters") or Workspace
local FastAttack_arms = {
    "RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm",
    "RightHand","LeftHand","RightFoot","LeftFoot","RightLeg","LeftLeg","Torso","Head"
}

local FastAttackState = { LastTickInterval = 0.03, LastRange = 120 }

function FastAttack:SuperFastAttack()
    if IsServerHopping or IsEscaping then return end
    local char = CharacterData.Character
    local root = CharacterData.RootPart
    local hum  = CharacterData.Humanoid
    if not char or not root or not hum or hum.Health <= 0 then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local healthRatio = hum.Health / math.max(hum.MaxHealth, 1)
    local range
    if healthRatio < 0.25 then
        range = Settings.AttackRangeLowHP or 350
    elseif healthRatio < 0.5 then
        range = Settings.AttackRangeBurst or 260
    else
        range = Settings.AttackRangeNormal or 120
    end
    FastAttackState.LastRange = range

    local hitData = {}
    local primaryPart
    local playerHits = {}

    for _, list in ipairs({ FastAttack_enemies, FastAttack_characters }) do
        if list then
            for _, e in ipairs(list:GetChildren()) do
                if e ~= char and not e:GetAttribute("IsBoat") then
                    local tp = Players:GetPlayerFromCharacter(e)
                    if tp and (IsPlayerInSafeZone(tp) or IsPlayerPvPDisabled(tp)) then
                        -- skip
                    else
                        local ehum = e:FindFirstChildOfClass("Humanoid")
                        local ebody = e:FindFirstChild("Head") or e.PrimaryPart
                        if ehum and ehum.Health > 0 and ebody
                           and (ebody.Position - root.Position).Magnitude <= range then
                            local part = e:FindFirstChild(FastAttack_arms[math.random(#FastAttack_arms)])
                                or e:FindFirstChild("UpperTorso") or e:FindFirstChild("Torso") or e.PrimaryPart
                            if part then
                                table.insert(hitData, { e, part })
                                primaryPart = part
                                if tp then table.insert(playerHits, tp) end
                            end
                        end
                    end
                end
            end
        end
    end

    if #hitData == 0 or not primaryPart then return end

    local lcr = tool:FindFirstChild("LeftClickRemote")
    if lcr then
        pcall(function() lcr:FireServer((primaryPart.Position - root.Position).Unit, 1) end)
    end

    if Register_Attack then pcall(function() Register_Attack:FireServer(0) end) end
    if Register_Hit then
        pcall(function() Register_Hit:FireServer(primaryPart, hitData) end)
        if healthRatio < 0.6 then
            for _ = 1, 2 do
                local extraHits = {}
                for _, h in ipairs(hitData) do
                    local alt = h[1]:FindFirstChild(FastAttack_arms[math.random(#FastAttack_arms)]) or h[2]
                    table.insert(extraHits, { h[1], alt })
                end
                pcall(function() Register_Hit:FireServer(extraHits[1] and extraHits[1][2] or primaryPart, extraHits) end)
            end
        end
    end
end

task.spawn(function()
    while true do
        local hr = GetHealthRatio()
        local interval
        if hr < 0.25 then
            interval = 0.006
        elseif hr < 0.5 then
            interval = 0.010
        else
            interval = 0.025
        end
        FastAttackState.LastTickInterval = interval
        task.wait(interval)
        if Settings.FastAttack and not IsServerHopping and not IsEscaping then
            pcall(function() FastAttack:SuperFastAttack() end)
        end
    end
end)

-- ============================================================
-- DODGER SYSTEM
-- ============================================================
local DodgeState = { LastDodge = 0, PatternIndex = 1 }
local DodgePatterns = {
    { Vector3.new(35, 12, 0) },
    { Vector3.new(-35, 12, 0) },
    { Vector3.new(0, 22, 35) },
    { Vector3.new(0, 22, -35) },
    { Vector3.new(28, 16, 28) },
    { Vector3.new(-28, 16, -28) },
}

local function PerformDodge()
    if not Settings.AutoDodge or IsEscaping or IsServerHopping then return end
    if (os.clock() - DodgeState.LastDodge) < (Settings.DodgeCooldown or 0.55) then return end
    local root = CharacterData.RootPart
    if not root or not Camera then return end

    DodgeState.LastDodge = os.clock()
    DodgeState.PatternIndex = (DodgeState.PatternIndex % #DodgePatterns) + 1
    local offset = DodgePatterns[DodgeState.PatternIndex][1]

    local camCF = Camera.CFrame
    local worldOffset = camCF:VectorToWorldSpace(offset)

    local threat = CurrentTargetPlayer
    if threat and threat.Character and threat.Character:FindFirstChild("HumanoidRootPart") then
        local threatPos = threat.Character.HumanoidRootPart.Position
        local toMe = (root.Position - threatPos)
        toMe = Vector3.new(toMe.X, 0, toMe.Z)
        if toMe.Magnitude > 0.1 then
            local side = Vector3.new(-toMe.Z, 0, toMe.X).Unit
            if DodgeState.PatternIndex % 2 == 0 then side = -side end
            worldOffset = side * 35 + Vector3.new(0, 12, 0)
        end
    end

    StopTween()
    root.AssemblyLinearVelocity = worldOffset * 6
    local newCF = root.CFrame + worldOffset
    root.CFrame = newCF
end

task.spawn(function()
    while task.wait(0.06) do
        if Settings.AutoDodge and not IsEscaping and not IsServerHopping and Settings.BountyHunt then
            if HitValidator:WasHitTakenRecently(0.4) then
                PerformDodge()
            else
                local root = CharacterData.RootPart
                if root then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and not IsPlayerInSafeZone(p) and not IsPlayerPvPDisabled(p)
                           and p.Character then
                            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health > 0 then
                                local dist = (hrp.Position - root.Position).Magnitude
                                if dist < (Settings.DodgeRadius or 22) then
                                    local theirVel = hrp.AssemblyLinearVelocity
                                    if theirVel.Magnitude > 5 then
                                        PerformDodge()
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- HITBOX EXTENDER
-- ============================================================
local HitboxState = { OriginalSizes = {}, LastTargetChar = nil }

local function RestoreHitbox(targetChar)
    if not targetChar or not HitboxState.OriginalSizes[targetChar] then return end
    for part, size in pairs(HitboxState.OriginalSizes[targetChar]) do
        if part and part.Parent then
            pcall(function()
                part.Size = size
                part.Transparency = HitboxState.OriginalSizes[targetChar][part.."_t"] or 0
            end)
        end
    end
    HitboxState.OriginalSizes[targetChar] = nil
end

local function ExpandHitbox(targetChar, size)
    if not targetChar then return end
    if HitboxState.LastTargetChar and HitboxState.LastTargetChar ~= targetChar then
        RestoreHitbox(HitboxState.LastTargetChar)
    end
    HitboxState.LastTargetChar = targetChar

    if not HitboxState.OriginalSizes[targetChar] then
        HitboxState.OriginalSizes[targetChar] = {}
        for _, part in ipairs(targetChar:GetChildren()) do
            if part:IsA("BasePart") then
                HitboxState.OriginalSizes[targetChar][part] = part.Size
            end
        end
    end

    local newSize = Vector3.new(size, size, size)
    for _, part in ipairs(targetChar:GetChildren()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Size = newSize
                part.Transparency = 0.7
                part.CanCollide = false
                part.Massless = true
                if part.Name == "Head" or part.Name == "Torso" or part.Name == "UpperTorso" then
                    part.BrickColor = BrickColor.new("Really red")
                    part.Material = Enum.Material.Neon
                end
            end)
        end
    end
end

-- ============================================================
-- STOP BOUNTY BUTTON (mobile-friendly bigger)
-- ============================================================
local StopBountyGui = nil

local function CreateStopBountyButton(onStopClicked)
    if StopBountyGui then pcall(function() StopBountyGui:Destroy() end) end
    StopBountyGui = Instance.new("ScreenGui")
    StopBountyGui.Name = "StopBountyHuntGUI"
    StopBountyGui.ResetOnSpawn = false
    pcall(function()
        if gethui then StopBountyGui.Parent = gethui()
        else StopBountyGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    local btnSize = IS_MOBILE and UDim2.new(0, 260, 0, 64) or UDim2.new(0, 220, 0, 50)
    local btn = Instance.new("TextButton")
    btn.Name = "StopButton"
    btn.Parent = StopBountyGui
    btn.Size = btnSize
    btn.Position = UDim2.new(0.5, -btnSize.X.Offset/2, 0.08, 0)
    btn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = IS_MOBILE and 22 or 18
    btn.Text = "🛑 STOP BOUNTY HUNT"
    btn.BorderSizePixel = 2

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        if onStopClicked then pcall(onStopClicked) end
    end)
    -- Mobile also fires TouchTap
    btn.TouchTap:Connect(function()
        if onStopClicked then pcall(onStopClicked) end
    end)
end

local function RemoveStopBountyButton()
    if StopBountyGui then pcall(function() StopBountyGui:Destroy() end) StopBountyGui = nil end
end

local BuildUI
local function SyncUIControls()
    isSyncingUI = true
    pcall(function()
        if UIControls.AimMethodDropdown then UIControls.AimMethodDropdown:SetValue(Settings.AimMethod) end
        if UIControls.TargetPriorityDropdown then UIControls.TargetPriorityDropdown:SetValue(Settings.TargetPriority) end
        if UIControls.TeamDropdown then UIControls.TeamDropdown:SetValue(Settings.SavedTeam) end
        if UIControls.AimbotSkillsTog then UIControls.AimbotSkillsTog:SetValue(Settings.AimbotSkills) end
        if UIControls.SpamSoulGuitarTog then UIControls.SpamSoulGuitarTog:SetValue(Settings.SpamSoulGuitar) end
        if UIControls.XMove100HitTog then UIControls.XMove100HitTog:SetValue(Settings.XMove100Hit) end
        if UIControls.TargetPredictionTog then UIControls.TargetPredictionTog:SetValue(Settings.TargetPrediction) end
        if UIControls.AimbotCameraTog then UIControls.AimbotCameraTog:SetValue(Settings.AimbotCamera) end
        if UIControls.InstantLockTog then UIControls.InstantLockTog:SetValue(Settings.InstantLock) end
        if UIControls.HitboxExpandTog then UIControls.HitboxExpandTog:SetValue(Settings.HitboxExpand) end
        if UIControls.HitboxSizeSlider then UIControls.HitboxSizeSlider:SetValue(Settings.HitboxSize) end
        if UIControls.PlayerESPTog then UIControls.PlayerESPTog:SetValue(Settings.PlayerESP) end
        if UIControls.FastAttackTog then UIControls.FastAttackTog:SetValue(Settings.FastAttack) end
        if UIControls.AutoRaceV4Tog then UIControls.AutoRaceV4Tog:SetValue(Settings.AutoRaceV4) end
        if UIControls.BountyHuntToggle then UIControls.BountyHuntToggle:SetValue(Settings.BountyHunt) end
        if UIControls.AutoPortalTPTog then UIControls.AutoPortalTPTog:SetValue(Settings.AutoPortalTP) end
        if UIControls.AutoServerHopWhenEmptyTog then UIControls.AutoServerHopWhenEmptyTog:SetValue(Settings.AutoServerHopWhenEmpty) end
        if UIControls.FilterMinServerBountyTog then UIControls.FilterMinServerBountyTog:SetValue(Settings.FilterMinServerBounty) end
        if UIControls.AutoDodgeTog then UIControls.AutoDodgeTog:SetValue(Settings.AutoDodge) end
    end)
    isSyncingUI = false
end

local function SetBountyHuntMode(enabled)
    if enabled then
        SavedSettingsConfig = DeepCopyTable(Settings)
        Settings.AimMethod = "Closest to LocalPlayer"
        Settings.TargetPriority = "LowestHP"
        Settings.AimbotSkills = true
        Settings.XMove100Hit = true
        Settings.AimbotCamera = true
        Settings.InstantLock = true
        Settings.HitboxExpand = true
        Settings.HitboxSize = 35
        Settings.PlayerESP = true
        Settings.FastAttack = true
        Settings.AutoRaceV4 = true
        Settings.AutoPortalTP = true
        Settings.AutoServerHopWhenEmpty = true
        Settings.AvoidSafeZonePlayers = true
        Settings.FilterMinServerBounty = true
        Settings.AutoDodge = true
        Settings.BountyHunt = true
        Settings.PVPMode = true

        LocalPlayerDeathCount = 0
        HuntTargetPlayer      = nil
        HuntTargetStartTime   = 0
        NoTargetStartTime     = 0
        IsInEscapeMode        = false
        StopInfiniteEscape()

        -- Queue reload so if we hop mid-hunt, script comes back
        QueueScriptOnTeleport()

        SyncUIControls()
        SaveConfig()
        CreateStopBountyButton(function() SetBountyHuntMode(false) end)
    else
        Settings.BountyHunt = false
        LocalPlayerDeathCount = 0
        HuntTargetPlayer      = nil
        IsInEscapeMode        = false
        IsPortalTeleporting   = false
        NoTargetStartTime     = 0
        StopInfiniteEscape()
        StopTween()
        RemoveStopBountyButton()
        if SavedSettingsConfig then
            for k, v in pairs(SavedSettingsConfig) do Settings[k] = v end
            SavedSettingsConfig = nil
        end
        SyncUIControls()
        SaveConfig()
    end
end

-- ============================================================
-- FLUENT UI  (mobile-adaptive size)
-- ============================================================
BuildUI = function(isPVPMode)
    StopTween()
    UIControls = {}
    pcall(function()
        if Window and Window.Destroy then Window:Destroy() end
        if Fluent and Fluent.Destroy then Fluent:Destroy() end
        Fluent = nil
    end)
    task.wait(0.1)

    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/huyyeuemhihi/Fluent/refs/heads/main/Fluentvip.lua"))()
    end)
    if not ok or not lib or type(lib) ~= "table" then
        ok, lib = pcall(function()
            return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
        end)
    end
    if not ok or not lib then return end

    Fluent = lib
    Settings.PVPMode = isPVPMode

    -- Mobile-adaptive window size
    local winSize = IS_MOBILE and UDim2.fromOffset(500, 380) or UDim2.fromOffset(640, 480)
    local tabWidth = IS_MOBILE and 130 or 160

    Window = Fluent:CreateWindow({
        Title = isPVPMode and "Blox Fruits Hub - PVP" or "Blox Fruits Hub",
        SubTitle = (IS_MOBILE and "Mobile Mode | " or "PC Mode | ") .. EXECUTOR_NAME,
        TabWidth = tabWidth,
        Size = winSize,
        Acrylic = false,
        Theme = "Dark",
        -- Only set MinimizeKey on PC (mobile has no LeftControl)
        MinimizeKey = IS_MOBILE and Enum.KeyCode.Unknown or Enum.KeyCode.LeftControl
    })

    -- Add mobile toggle floating button (Fluent already has one usually,
    -- but this ensures it works)
    if IS_MOBILE then
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local toggleGui = Instance.new("ScreenGui")
                toggleGui.Name = "BloxHubMobileToggle"
                toggleGui.ResetOnSpawn = false
                toggleGui.Parent = playerGui
                local tb = Instance.new("TextButton")
                tb.Size = UDim2.new(0, 80, 0, 80)
                tb.Position = UDim2.new(0, 10, 0.4, 0)
                tb.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
                tb.TextColor3 = Color3.fromRGB(255,255,255)
                tb.Font = Enum.Font.GothamBold
                tb.TextSize = 16
                tb.Text = "HUB"
                tb.Parent = toggleGui
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = tb
                tb.MouseButton1Click:Connect(function()
                    pcall(function()
                        if Window and Window.Toggle then Window:Toggle() end
                    end)
                end)
                tb.TouchTap:Connect(function()
                    pcall(function()
                        if Window and Window.Toggle then Window:Toggle() end
                    end)
                end)
            end
        end)
    end

    local Tabs = {}
    Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "swords" })
    if not isPVPMode then
        Tabs.MainFarm     = Window:AddTab({ Title = "Main Farm", Icon = "sword" })
        Tabs.MasteryRaids = Window:AddTab({ Title = "Mastery & Raids", Icon = "crown" })
        Tabs.SeaEvents    = Window:AddTab({ Title = "Sea & Events", Icon = "waves" })
        Tabs.Fruits       = Window:AddTab({ Title = "Fruits & Items", Icon = "apple" })
        Tabs.LocalPlayer  = Window:AddTab({ Title = "Stats & Team", Icon = "user" })
    end
    Tabs.PVP = Window:AddTab({ Title = "PVP & Aimbot", Icon = "crosshair" })
    if isPVPMode then Tabs.AutoHunt = Window:AddTab({ Title = "Auto Hunt", Icon = "target" }) end
    Tabs.Teleport = Window:AddTab({ Title = "Teleports", Icon = "map-pin" })
    Tabs.ESP      = Window:AddTab({ Title = "ESP & Visuals", Icon = "eye" })
    Tabs.Settings = Window:AddTab({ Title = "Config & Server", Icon = "settings" })

    -- COMBAT
    UIControls.PVPModeSwitchTog = Tabs.Combat:AddToggle("PVPModeSwitchTog", {
        Title = "⚡ Switch Between PVP / Standard Mode",
        Default = isPVPMode,
        Callback = function(v)
            if isSyncingUI then return end
            pcall(function()
                if v ~= Settings.PVPMode then
                    for k in pairs(Settings) do
                        if type(Settings[k]) == "boolean" and k ~= "PVPMode" then Settings[k] = false end
                    end
                    SetBountyHuntMode(false)
                    BuildUI(v)
                end
            end)
        end
    })

    UIControls.FastAttackTog = Tabs.Combat:AddToggle("FastAttackTog", {
        Title = "Enable Fast Attack (Adaptive)",
        Default = Settings.FastAttack,
        Callback = function(v) if isSyncingUI then return end Settings.FastAttack = v SaveConfig() end
    })

    UIControls.SpamSoulGuitarTog = Tabs.Combat:AddToggle("SpamSoulGuitarTog", {
        Title = "🔥 Spam Soul Guitar (Moves + M1 Aimbot)",
        Default = Settings.SpamSoulGuitar,
        Callback = function(v) if isSyncingUI then return end Settings.SpamSoulGuitar = v SaveConfig() end
    })

    Tabs.Combat:AddDropdown("WeaponTypeDropdown", {
        Title = "Select Weapon ToolTip",
        Values = { "Buddy Sword", "Melee", "Sword", "Blox Fruit", "Gun" },
        Default = Settings.EquipWeaponType,
        Callback = function(v) if isSyncingUI then return end Settings.EquipWeaponType = v SaveConfig() end
    })

    Tabs.Combat:AddToggle("WalkWaterTog", {
        Title = "Walk On Water", Default = Settings.WalkOnWater,
        Callback = function(v) if isSyncingUI then return end Settings.WalkOnWater = v SaveConfig() end
    })
    Tabs.Combat:AddToggle("NoclipTog", {
        Title = "Noclip Mode", Default = Settings.Noclip,
        Callback = function(v) if isSyncingUI then return end Settings.Noclip = v SaveConfig() end
    })
    UIControls.AutoRaceV4Tog = Tabs.Combat:AddToggle("AutoRaceV4Tog", {
        Title = "Auto Turn On Race V4", Default = Settings.AutoRaceV4,
        Callback = function(v) if isSyncingUI then return end Settings.AutoRaceV4 = v SaveConfig() end
    })

    -- PVP
    UIControls.AimMethodDropdown = Tabs.PVP:AddDropdown("AimMethodDropdown", {
        Title = "Select Aim Target Method",
        Values = { "Closest to Center Screen", "Closest to LocalPlayer", "Selected Player" },
        Default = Settings.AimMethod,
        Callback = function(v) if isSyncingUI then return end Settings.AimMethod = v SaveConfig() end
    })

    UIControls.TargetPriorityDropdown = Tabs.PVP:AddDropdown("TargetPriorityDropdown", {
        Title = "🎯 Target Priority (Bounty Hunt)",
        Values = { "LowestHP", "Closest", "Balanced" },
        Default = Settings.TargetPriority,
        Callback = function(v) if isSyncingUI then return end Settings.TargetPriority = v SaveConfig() end
    })

    UIControls.TargetDropdown = Tabs.PVP:AddDropdown("SelectTargetDropdown", {
        Title = "Select Target Player",
        Values = GetPlayerList(), Default = Settings.TargetSelect,
        Callback = function(v) if isSyncingUI then return end Settings.TargetSelect = v SaveConfig() end
    })

    UIControls.AimbotSkillsTog = Tabs.PVP:AddToggle("AimbotSkillsTog", {
        Title = "Skill Redirection Aimbot (100% Silent Aim)", Default = Settings.AimbotSkills,
        Callback = function(v) if isSyncingUI then return end Settings.AimbotSkills = v SaveConfig() end
    })
    UIControls.XMove100HitTog = Tabs.PVP:AddToggle("XMove100HitTog", {
        Title = "100% Buddy Sword X & Skill Auto-Lock", Default = Settings.XMove100Hit,
        Callback = function(v) if isSyncingUI then return end Settings.XMove100Hit = v SaveConfig() end
    })
    UIControls.TargetPredictionTog = Tabs.PVP:AddToggle("TargetPredictionTog", {
        Title = "Target Velocity Prediction", Default = Settings.TargetPrediction,
        Callback = function(v) if isSyncingUI then return end Settings.TargetPrediction = v SaveConfig() end
    })
    UIControls.AimbotCameraTog = Tabs.PVP:AddToggle("AimbotCameraTog", {
        Title = "Camera Lock On Target", Default = Settings.AimbotCamera,
        Callback = function(v) if isSyncingUI then return end Settings.AimbotCamera = v SaveConfig() end
    })
    UIControls.InstantLockTog = Tabs.PVP:AddToggle("InstantLockTog", {
        Title = "Instant Hard Lock (0 Delay)", Default = Settings.InstantLock,
        Callback = function(v) if isSyncingUI then return end Settings.InstantLock = v SaveConfig() end
    })

    UIControls.AutoDodgeTog = Tabs.PVP:AddToggle("AutoDodgeTog", {
        Title = "💨 Auto Dodger (Strafes When Attacked)",
        Default = Settings.AutoDodge,
        Callback = function(v) if isSyncingUI then return end Settings.AutoDodge = v SaveConfig() end
    })
    Tabs.PVP:AddSlider("DodgeRadiusSlider", {
        Title = "Dodge Trigger Radius (Studs)", Min = 10, Max = 50, Default = Settings.DodgeRadius, Rounding = 0,
        Callback = function(v) if isSyncingUI then return end Settings.DodgeRadius = v SaveConfig() end
    })

    UIControls.HitboxExpandTog = Tabs.PVP:AddToggle("HitboxExpandTog", {
        Title = "Expand Target Hitbox", Default = Settings.HitboxExpand,
        Callback = function(v) if isSyncingUI then return end Settings.HitboxExpand = v SaveConfig() end
    })
    UIControls.HitboxSizeSlider = Tabs.PVP:AddSlider("HitboxSizeSlider", {
        Title = "Hitbox Size Expansion", Min = 5, Max = 60, Default = Settings.HitboxSize, Rounding = 0,
        Callback = function(v) if isSyncingUI then return end Settings.HitboxSize = v SaveConfig() end
    })

    -- AUTO HUNT
    if isPVPMode and Tabs.AutoHunt then
        UIControls.HuntStatusParagraph = Tabs.AutoHunt:AddParagraph({
            Title = "Auto Bounty Hunt Status", Content = "Target: Searching..."
        })
        UIControls.BountyHuntToggle = Tabs.AutoHunt:AddToggle("BountyHuntTog", {
            Title = "Enable Auto Bounty Hunt", Default = Settings.BountyHunt,
            Callback = function(v) if isSyncingUI then return end SetBountyHuntMode(v) end
        })
        UIControls.FilterMinServerBountyTog = Tabs.AutoHunt:AddToggle("FilterMinServerBountyTog", {
            Title = "🏆 Server Browser 30M+ Bounty Filter", Default = Settings.FilterMinServerBounty,
            Callback = function(v) if isSyncingUI then return end Settings.FilterMinServerBounty = v SaveConfig() end
        })
        UIControls.AutoPortalTPTog = Tabs.AutoHunt:AddToggle("AutoPortalTPTog", {
            Title = "🌀 Portal Fast Teleport on Island Jump", Default = Settings.AutoPortalTP,
            Callback = function(v) if isSyncingUI then return end Settings.AutoPortalTP = v SaveConfig() end
        })
        UIControls.AutoServerHopWhenEmptyTog = Tabs.AutoHunt:AddToggle("AutoServerHopWhenEmptyTog", {
            Title = "🔀 Auto Server Hop When No Target Available", Default = Settings.AutoServerHopWhenEmpty,
            Callback = function(v) if isSyncingUI then return end Settings.AutoServerHopWhenEmpty = v SaveConfig() end
        })
        -- KEY: This is what keeps the script running after a hop
        Tabs.AutoHunt:AddToggle("AutoRejoinTog", {
            Title = "♻️ Auto-Reload Hub After Server Hop (Infinite Chain)",
            Default = Settings.AutoRejoinOnTeleport,
            Callback = function(v)
                if isSyncingUI then return end
                Settings.AutoRejoinOnTeleport = v
                SaveConfig()
                if v then QueueScriptOnTeleport() end
            end
        })
        Tabs.AutoHunt:AddSlider("PortalDistanceSlider", {
            Title = "Portal Teleport Trigger Distance (Studs)",
            Min = 500, Max = 4000, Default = Settings.PortalDistanceThreshold, Rounding = 0,
            Callback = function(v) if isSyncingUI then return end Settings.PortalDistanceThreshold = v SaveConfig() end
        })
        Tabs.AutoHunt:AddSlider("AttackRangeNormalSlider", {
            Title = "Attack Range (Normal HP)", Min = 80, Max = 400, Default = Settings.AttackRangeNormal, Rounding = 0,
            Callback = function(v) if isSyncingUI then return end Settings.AttackRangeNormal = v SaveConfig() end
        })
        Tabs.AutoHunt:AddSlider("AttackRangeBurstSlider", {
            Title = "Attack Range (HP < 50%)", Min = 100, Max = 500, Default = Settings.AttackRangeBurst, Rounding = 0,
            Callback = function(v) if isSyncingUI then return end Settings.AttackRangeBurst = v SaveConfig() end
        })
        Tabs.AutoHunt:AddSlider("AttackRangeLowHPSlider", {
            Title = "Attack Range (HP < 25%)", Min = 150, Max = 700, Default = Settings.AttackRangeLowHP, Rounding = 0,
            Callback = function(v) if isSyncingUI then return end Settings.AttackRangeLowHP = v SaveConfig() end
        })
    end

    -- TELEPORT
    local islandNames = {}
    for name in pairs(IslandTeleports) do table.insert(islandNames, name) end
    Tabs.Teleport:AddDropdown("IslandTeleportDropdown", {
        Title = "Select Target Island",
        Values = #islandNames > 0 and islandNames or { "No Teleports" },
        Default = islandNames[1] or "",
        Callback = function(v) if isSyncingUI then return end Settings.SelectedIslandTeleport = v SaveConfig() end
    })
    Tabs.Teleport:AddButton({
        Title = "Teleport to Selected Island",
        Callback = function()
            pcall(function()
                if Settings.SelectedIslandTeleport ~= "" and IslandTeleports[Settings.SelectedIslandTeleport] then
                    SafeTweenTo(IslandTeleports[Settings.SelectedIslandTeleport], Settings.TweenSpeed)
                end
            end)
        end
    })
    Tabs.Teleport:AddSlider("TweenSpeedSlider", {
        Title = "Tween Flight Speed", Min = 150, Max = 450, Default = Settings.TweenSpeed, Rounding = 0,
        Callback = function(v) if isSyncingUI then return end Settings.TweenSpeed = v SaveConfig() end
    })
    Tabs.Teleport:AddSlider("EscapeHeightSlider", {
        Title = "Sky Hover / Escape Height", Min = 100, Max = 1000, Default = Settings.EscapeHeight, Rounding = 0,
        Callback = function(v) if isSyncingUI then return end Settings.EscapeHeight = v SaveConfig() end
    })

    -- ESP
    UIControls.PlayerESPTog = Tabs.ESP:AddToggle("PlayerESPTog", {
        Title = "Player Text ESP", Default = Settings.PlayerESP,
        Callback = function(v) if isSyncingUI then return end Settings.PlayerESP = v SaveConfig() end
    })

    -- SETTINGS
    UIControls.TeamDropdown = Tabs.Settings:AddDropdown("SavedTeamDropdownConfig", {
        Title = "🚩 Auto-Join Team Selection", Values = { "Pirates", "Marines" },
        Default = Settings.SavedTeam or "Pirates",
        Callback = function(v) if isSyncingUI then return end Settings.SavedTeam = v SaveConfig() JoinTeam(v) end
    })
    Tabs.Settings:AddButton({
        Title = "💾 Save Current Configuration",
        Callback = function()
            SaveConfig()
            pcall(function()
                if Fluent and Fluent.Notify then
                    Fluent:Notify({ Title = "Config Saved", Content = "Settings successfully written.", Duration = 2 })
                end
            end)
        end
    })
    Tabs.Settings:AddButton({ Title = "🔀 Server Hop", Callback = function() ServerHop() end })
    Tabs.Settings:AddButton({
        Title = "♻️ Force Re-Queue Auto-Reloader",
        Callback = function()
            QueueScriptOnTeleport()
            pcall(function()
                if Fluent and Fluent.Notify then
                    Fluent:Notify({
                        Title = "Re-Queued",
                        Content = "Script will reload after next teleport/hop.",
                        Duration = 3
                    })
                end
            end)
        end
    })

    -- Auto-queue on UI build so it's always armed
    QueueScriptOnTeleport()
end

BuildUI(Settings.PVPMode or Settings.BountyHunt)
if Settings.BountyHunt then
    task.spawn(function() task.wait(0.3); SetBountyHuntMode(true) end)
end

-- ============================================================
-- RENDER STEPPED AIM / CAMERA / HITBOX
-- ============================================================
AddConnection(RunService.RenderStepped:Connect(function()
    if IsServerHopping then return end

    local targetPlayer = nil
    if Settings.BountyHunt and HuntTargetPlayer then
        targetPlayer = HuntTargetPlayer
    elseif Settings.AimMethod == "Closest to Center Screen" then
        targetPlayer = GetClosestPlayerToCenterScreen()
    elseif Settings.AimMethod == "Closest to LocalPlayer" then
        targetPlayer = GetClosestPlayerToLocalPlayer()
    elseif Settings.AimMethod == "Selected Player" and Settings.TargetSelect ~= "" then
        targetPlayer = Players:FindFirstChild(Settings.TargetSelect)
    end

    if targetPlayer and not IsPlayerInSafeZone(targetPlayer) and not IsPlayerPvPDisabled(targetPlayer)
       and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
       and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then

        local head = targetPlayer.Character:FindFirstChild("Head")
        local aimPart = head or targetPlayer.Character.HumanoidRootPart

        local dist = CharacterData.RootPart and (aimPart.Position - CharacterData.RootPart.Position).Magnitude or 0
        if dist <= (Settings.MaxTargetDistance or 10000) then
            CurrentTargetPart = aimPart
            CurrentTargetName = targetPlayer.Name
            CurrentTargetPlayer = targetPlayer
            CurrentTargetPos  = GetPredictedTargetPos(aimPart)
        else
            CurrentTargetPart = nil
            CurrentTargetName = "None"
            CurrentTargetPlayer = nil
            CurrentTargetPos  = Vector3.zero
        end
    else
        CurrentTargetPart = nil
        CurrentTargetName = "None"
        CurrentTargetPlayer = nil
        CurrentTargetPos  = Vector3.zero
    end

    if Settings.AimbotCamera and CurrentTargetPart and CurrentTargetPart.Parent and Camera then
        local predictedPos = CurrentTargetPos ~= Vector3.zero and CurrentTargetPos or CurrentTargetPart.Position
        local currentCamCF = Camera.CFrame
        local targetCamCF  = CFrame.new(currentCamCF.Position, predictedPos)
        if Settings.InstantLock then
            Camera.CFrame = targetCamCF
        else
            Camera.CFrame = currentCamCF:Lerp(targetCamCF, math.clamp(Settings.CameraSmoothness or 0.15, 0.01, 1))
        end
    end

    if Settings.HitboxExpand and CurrentTargetPart and CurrentTargetPart.Parent then
        local tChar = CurrentTargetPart.Parent
        local hr = GetHealthRatio()
        local sizeMult = hr < 0.25 and 1.5 or (hr < 0.5 and 1.25 or 1)
        ExpandHitbox(tChar, Settings.HitboxSize * sizeMult)
    end
end))

AddConnection(RunService.Stepped:Connect(function()
    if Settings.Noclip and not IsServerHopping and not IsEscaping then
        local char = CharacterData.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end))

-- ============================================================
-- 30M BOUNTY CHECKER
-- ============================================================
task.spawn(function()
    task.wait(15)
    while task.wait(5) do
        if Settings.BountyHunt and Settings.FilterMinServerBounty and not IsServerHopping and not IsEscaping then
            if not HitValidator:WasHitRecently(5.0) and not IsComboRunning then
                pcall(function()
                    local cur = GetTotalServerBounty()
                    if cur > 0 and cur < Settings.MinServerBounty then
                        UpdateStatusText(string.format("Server Bounty: %.1fM (<30M) -> Hopping...", cur / 1000000))
                        StartInfiniteEscape()
                        task.wait(1.5)
                        ServerHop()
                    end
                end)
            end
        end
    end
end)

-- ============================================================
-- AUTO BOUNTY HUNT LOOP
-- ============================================================
local LastEnablePvpTime = 0

task.spawn(function()
    while task.wait(0.1) do
        if Settings.BountyHunt and not IsServerHopping then
            pcall(function()
                if (os.clock() - LastEnablePvpTime) >= 1.0 then
                    LastEnablePvpTime = os.clock()
                    local rf = ReplicatedStorage:FindFirstChild("Remotes")
                    local cf = rf and rf:FindFirstChild("CommF_")
                    if cf then cf:InvokeServer("EnablePvp") end
                end

                local h, m = GetLocalPlayerHealth()
                local ratio = m > 0 and (h / m) or 1

                local danger = false
                if ratio < 0.35 then danger = true end
                if HitValidator:WasHitRecently(1.0) and HitValidator:GetLastHitDamage() > 1000 then danger = true end
                if ratio < 0.6 and HitValidator:WasHitTakenRecently(1.5) then danger = true end

                if danger then
                    if not IsEscaping then
                        StartInfiniteEscape()
                        UpdateStatusText("⚠️ ESCAPE MODE — Ascending infinitely...")
                    end
                    return
                end

                if IsEscaping and ratio > 0.9 and not HitValidator:WasHitTakenRecently(3.0) then
                    StopInfiniteEscape()
                end

                if HuntTargetPlayer then
                    local tChar = HuntTargetPlayer.Character
                    local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if tHrp and CharacterData.RootPart then
                        local curDist = (tHrp.Position - CharacterData.RootPart.Position).Magnitude
                        if curDist > (Settings.MaxTargetDistance or 10000) then HuntTargetPlayer = nil end
                    end
                end

                if not HuntTargetPlayer or not CanGetBounty(HuntTargetPlayer)
                   or (os.clock() - HuntTargetStartTime > 90) then
                    HuntTargetPlayer    = GetBestBountyTarget()
                    HuntTargetStartTime = os.clock()
                end

                if HuntTargetPlayer and CanGetBounty(HuntTargetPlayer) then
                    NoTargetStartTime = 0
                    local targetChar = HuntTargetPlayer.Character
                    local targetHrp  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum  = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

                    if targetHrp and targetHum and targetHum.Health > 0 then
                        local targetPos = targetHrp.Position
                        local dist = CharacterData.RootPart
                            and (targetPos - CharacterData.RootPart.Position).Magnitude or 0

                        local kills = TargetKillCounts[HuntTargetPlayer.UserId] or 0
                        local totalM = string.format("%.1fM", GetTotalServerBounty() / 1000000)
                        UpdateStatusText(string.format(
                            "Server: %s | Target: %s | HP: %d%% | Dist: %dm | Kills: %d/3",
                            totalM, HuntTargetPlayer.Name, math.floor((targetHum.Health / targetHum.MaxHealth) * 100),
                            math.floor(dist), kills))

                        if Settings.AutoPortalTP and dist > Settings.PortalDistanceThreshold
                           and (os.clock() - LastPortalTPTime > 12) then
                            local best, minD = "Cafe", math.huge
                            for pName, pPos in pairs(PORTAL_DESTINATIONS) do
                                local d = (pPos - targetPos).Magnitude
                                if d < minD then minD = d best = pName end
                            end
                            PerformPortalTeleport(best)
                            LastPortalTPTime = os.clock()
                            task.wait(1.2)
                        end

                        EquipToolByToolTip(Settings.EquipWeaponType)

                        local targetHpRatio = targetHum.Health / math.max(targetHum.MaxHealth, 1)
                        local standoff = (targetHpRatio < 0.3) and 8 or (targetHpRatio < 0.6) and 10 or 12
                        local myPos = CharacterData.RootPart and CharacterData.RootPart.Position or targetPos
                        local dir = (targetPos - myPos)
                        local hDir = Vector3.new(dir.X, 0, dir.Z)
                        if hDir.Magnitude > 0 then hDir = hDir.Unit else hDir = Vector3.new(0, 0, 1) end
                        local idealPos   = targetPos - (hDir * standoff) + Vector3.new(0, 6, 0)
                        local approachCF = CFrame.new(idealPos, targetPos)
                        SafeTweenTo(approachCF, Settings.TweenSpeed)

                        TriggerRaceV4()
                        ExecuteSmartCombo(targetHrp)
                        ExecuteBuddySwordXSpam(targetPos)
                        ApplyAntiStun()
                    else
                        NoTargetStartTime = os.clock()
                        UpdateStatusText("Target: " .. HuntTargetPlayer.Name .. " (Waiting respawn...)")
                    end
                else
                    if Settings.AutoServerHopWhenEmpty then
                        if HitValidator:WasHitRecently(3.0) or IsComboRunning then
                            NoTargetStartTime = os.clock()
                            return
                        end
                        if not IsServerHopping then
                            if NoTargetStartTime == 0 then NoTargetStartTime = os.clock() end
                            local elapsed = os.clock() - NoTargetStartTime
                            local waitTime = 15
                            local remaining = math.max(0, math.ceil(waitTime - elapsed))
                            UpdateStatusText("Target: Searching... (Hop in " .. remaining .. "s)")
                            if elapsed >= waitTime then
                                NoTargetStartTime = os.clock()
                                UpdateStatusText("Ascending + Hopping...")
                                StartInfiniteEscape()
                                task.wait(1.5)
                                ServerHop()
                            end
                        end
                    else
                        NoTargetStartTime = 0
                        UpdateStatusText("Target: Searching...")
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- QUEUE-ON-TELEPORT BOOTSTRAP (runs once on load)
-- ============================================================
task.spawn(function()
    task.wait(2)
    if Settings.AutoRejoinOnTeleport ~= false then
        QueueScriptOnTeleport()
        pcall(function()
            if Fluent and Fluent.Notify then
                Fluent:Notify({
                    Title = "Auto-Reload Armed",
                    Content = "Hub will reload itself after every server hop.",
                    Duration = 3
                })
            end
        end)
    end
end)
