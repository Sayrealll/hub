-- Modernized, high-end standalone UI shell with dynamic rainfall particle effects, Platoboost Key System, and Anti-Drift integration.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local protectGui = syn and syn.protect_gui or function() end
local playerGui = (not pcall(function() return CoreGui:GetChildren() end) and player:WaitForChild("PlayerGui")) or CoreGui

local MAX_VALUE = 2500

--------------------------------------------------------------------------------
-- PLATOBOOST CONFIGURATION & API ENGINE
--------------------------------------------------------------------------------
local service = 30940;
local secret = "f65f541a-4b19-4e8b-9980-d765f42c7462";
local useNonce = true;

local notify;
local onMessage = function(message)
    if notify then
        notify("Key System", message, 4)
    else
        warn("[Key System]: " .. tostring(message))
    end
end;

repeat task.wait(1) until game:IsLoaded();

local requestSending = false;
local fSetClipboard, fRequest, fStringChar, fToString, fStringSub, fOsTime, fMathRandom, fMathFloor, fGetHwid = setclipboard or toclipboard, request or http_request or syn_request, string.char, tostring, string.sub, os.time, math.random, math.floor, gethwid or function() return game:GetService("Players").LocalPlayer.UserId end
local cachedLink, cachedTime = "", 0;

local lEncode = function(tbl)
    return HttpService:JSONEncode(tbl)
end

local lDecode = function(str)
    local s, r = pcall(function() return HttpService:JSONDecode(str) end)
    return s and r or {}
end

local lDigest = function(data)
    if syn and syn.crypt and syn.crypt.hash then
        return syn.crypt.hash(data)
    elseif crypt and crypt.hash then
        return crypt.hash(data, "sha256")
    end
    local hash = 0
    for i = 1, #data do
        hash = (hash * 31 + string.byte(data, i)) % 4294967296
    end
    return string.format("%08x", hash)
end

local host = "https://api.platoboost.com";
if fRequest then
    local hostResponse = fRequest({
        Url = host .. "/public/connectivity",
        Method = "GET"
    });
    if hostResponse and (hostResponse.StatusCode ~= 200 and hostResponse.StatusCode ~= 429) then
        host = "https://api.platoboost.net";
    end
end

function cacheLink()
    if cachedTime + (10*60) < fOsTime() then
        local response = fRequest({
            Url = host .. "/public/start",
            Method = "POST",
            Body = lEncode({
                service = service,
                identifier = lDigest(fGetHwid())
            }),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        });

        if response and response.StatusCode == 200 then
            local decoded = lDecode(response.Body);

            if decoded.success == true then
                cachedLink = decoded.data.url;
                cachedTime = fOsTime();
                return true, cachedLink;
            else
                onMessage(decoded.message);
                return false, decoded.message;
            end
        elseif response and response.StatusCode == 429 then
            local msg = "you are being rate limited, please wait 20 seconds and try again.";
            onMessage(msg);
            return false, msg;
        end

        local msg = "Failed to cache link.";
        onMessage(msg);
        return false, msg;
    else
        return true, cachedLink;
    end
end

if fRequest then cacheLink() end

local generateNonce = function()
    local str = ""
    for _ = 1, 16 do
        str = str .. fStringChar(fMathFloor(fMathRandom() * (122 - 97 + 1)) + 97)
    end
    return str
end

local copyLink = function()
    local success, link = cacheLink();
    if success and link ~= "" then
        fSetClipboard(link);
        onMessage("Key link copied to clipboard!");
    end
end

local redeemKey = function(key)
    local nonce = generateNonce();
    local endpoint = host .. "/public/redeem/" .. fToString(service);

    local body = {
        identifier = lDigest(fGetHwid()),
        key = key
    }

    if useNonce then
        body.nonce = nonce;
    end

    local response = fRequest({
        Url = endpoint,
        Method = "POST",
        Body = lEncode(body),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    });

    if response and response.StatusCode == 200 then
        local decoded = lDecode(response.Body);

        if decoded.success == true then
            if decoded.data.valid == true then
                if useNonce then
                    if decoded.data.hash == lDigest("true" .. "-" .. nonce .. "-" .. secret) then
                        return true;
                    else
                        onMessage("failed to verify integrity.");
                        return false;
                    end    
                else
                    return true;
                end
            else
                onMessage("key is invalid.");
                return false;
            end
        else
            if fStringSub(decoded.message or "", 1, 27) == "unique constraint violation" then
                onMessage("you already have an active key, please wait for it to expire before redeeming it.");
                return false;
            else
                onMessage(decoded.message);
                return false;
            end
        end
    elseif response and response.StatusCode == 429 then
        onMessage("you are being rate limited, please wait 20 seconds and try again.");
        return false;
    else
        onMessage("server returned an invalid status code, please try again later.");
        return false; 
    end
end

local verifyKey = function(key)
    if requestSending == true then
        onMessage("a request is already being sent, please slow down.");
        return false;
    else
        requestSending = true;
    end

    local nonce = generateNonce();
    local endpoint = host .. "/public/whitelist/" .. fToString(service) .. "?identifier=" .. lDigest(fGetHwid()) .. "&key=" .. key;

    if useNonce then
        endpoint = endpoint .. "&nonce=" .. nonce;
    end

    local response = fRequest({
        Url = endpoint,
        Method = "GET",
    });

    requestSending = false;

    if response and response.StatusCode == 200 then
        local decoded = lDecode(response.Body);

        if decoded.success == true then
            if decoded.data.valid == true then
                if useNonce then
                    if decoded.data.hash == lDigest("true" .. "-" .. nonce .. "-" .. secret) then
                        return true;
                    else
                        onMessage("failed to verify integrity.");
                        return false;
                    end
                else
                    return true;
                end
            else
                if fStringSub(key, 1, 4) == "KEY_" then
                    return redeemKey(key);
                else
                    onMessage("key is invalid.");
                    return false;
                end
            end
        else
            onMessage(decoded.message);
            return false;
        end
    elseif response and response.StatusCode == 429 then
        onMessage("you are being rate limited, please wait 20 seconds and try again.");
        return false;
    else
        onMessage("server returned an invalid status code, please try again later.");
        return false;
    end
end

local getFlag = function(name)
    local nonce = generateNonce();
    local endpoint = host .. "/public/flag/" .. fToString(service) .. "?name=" .. name;

    if useNonce then
        endpoint = endpoint .. "&nonce=" .. nonce;
    end

    local response = fRequest({
        Url = endpoint,
        Method = "GET",
    });

    if response and response.StatusCode == 200 then
        local decoded = lDecode(response.Body);

        if decoded.success == true then
            if useNonce then
                if decoded.data.hash == lDigest(fToString(decoded.data.value) .. "-" .. nonce .. "-" .. secret) then
                    return decoded.data.value;
                else
                    onMessage("failed to verify integrity.");
                    return nil;
                end
            else
                return decoded.data.value;
            end
        else
            onMessage(decoded.message);
            return nil;
        end
    else
        return nil;
    end
end

--------------------------------------------------------------------------------
-- STYLING & COLORS
--------------------------------------------------------------------------------
local colors = {
    background = Color3.fromRGB(8, 8, 12),
    panel = Color3.fromRGB(14, 14, 20),
    panelLight = Color3.fromRGB(20, 20, 28),
    accent = Color3.fromRGB(139, 92, 246),
    accentGlow = Color3.fromRGB(167, 139, 250),
    line = Color3.fromRGB(38, 38, 54),
    muted = Color3.fromRGB(115, 115, 138),
    white = Color3.fromRGB(245, 245, 250),
    black = Color3.fromRGB(4, 4, 6),
    rainBg = Color3.fromRGB(120, 140, 200),
    rainMid = Color3.fromRGB(165, 180, 252),
    rainFg = Color3.fromRGB(210, 225, 255),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {Color = color, Thickness = thickness, Transparency = transparency or 0}, parent)
end

local function addShadow(parent, transparency)
    return create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 50, 1, 50),
        ZIndex = parent.ZIndex - 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.35,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
    }, parent)
end

local screen = create("ScreenGui", {
    Name = "DreiiUltraUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

pcall(function() protectGui(screen) end)

--------------------------------------------------------------------------------
-- HIGH-PERFORMANCE ATMOSPHERIC RAIN ENGINE WITH SPLASH IMPACTS
--------------------------------------------------------------------------------
local rainContainer = create("Folder", {Name = "RainParticles"}, screen)
local rainDrops = {}
local maxRainDrops = 85
local windVelocityX = -0.08

local function createSplash(xScale, yScale)
    local splash = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(xScale, 0, yScale, 0),
        Size = UDim2.fromOffset(2, 2),
        BackgroundColor3 = colors.rainFg,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, rainContainer)
    corner(splash, 8)

    local targetSize = math.random(10, 22)
    TweenService:Create(splash, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(targetSize, math.floor(targetSize * 0.3)),
        BackgroundTransparency = 1
    }):Play()

    task.delay(0.26, function()
        if splash then splash:Destroy() end
    end)
end

for i = 1, maxRainDrops do
    local layer = math.random(1, 3)
    local dropColor, dropWidth, dropLengthMin, dropLengthMax, speedMult, transMin, transMax, zIndex

    if layer == 1 then
        dropColor = colors.rainBg
        dropWidth = 1
        dropLengthMin, dropLengthMax = 10, 20
        speedMult = 0.55
        transMin, transMax = 65, 85
        zIndex = 1
    elseif layer == 2 then
        dropColor = colors.rainMid
        dropWidth = 1.5
        dropLengthMin, dropLengthMax = 20, 35
        speedMult = 0.85
        transMin, transMax = 40, 65
        zIndex = 2
    else
        dropColor = colors.rainFg
        dropWidth = 2
        dropLengthMin, dropLengthMax = 35, 55
        speedMult = 1.25
        transMin, transMax = 20, 45
        zIndex = 3
    end

    local initialLength = math.random(dropLengthMin, dropLengthMax)
    local drop = create("Frame", {
        Size = UDim2.fromOffset(dropWidth, initialLength),
        BackgroundColor3 = dropColor,
        BackgroundTransparency = math.random(transMin, transMax) / 100,
        BorderSizePixel = 0,
        Position = UDim2.new(math.random() * 1.2 - 0.1, 0, math.random() * 1.2 - 0.1, 0),
        ZIndex = zIndex,
        Rotation = 6,
    }, rainContainer)
    corner(drop, 1)

    table.insert(rainDrops, {
        Object = drop,
        Speed = (math.random(600, 1100) / 100) * speedMult,
        Layer = layer,
        BaseLength = initialLength,
        SplashThreshold = math.random(88, 98) / 100,
    })
end

RunService.RenderStepped:Connect(function(dt)
    for _, dropData in ipairs(rainDrops) do
        local obj = dropData.Object
        local pos = obj.Position
        
        local newY = pos.Y.Scale + (dropData.Speed * dt * 0.35)
        local newX = pos.X.Scale + (windVelocityX * dt)

        if newY >= dropData.SplashThreshold and not dropData.HasSplashed then
            dropData.HasSplashed = true
            if dropData.Layer >= 2 then
                createSplash(pos.X.Scale, pos.Y.Scale)
            end
        end

        if newY > 1.05 or newX < -0.15 then
            dropData.Object.Position = UDim2.new(math.random() * 1.2 - 0.05, 0, -0.1, 0)
            dropData.HasSplashed = false
            dropData.SplashThreshold = math.random(88, 98) / 100
        else
            dropData.Object.Position = UDim2.new(newX, 0, newY, 0)
        end
    end
end)

--------------------------------------------------------------------------------
-- NOTIFICATION SYSTEM
--------------------------------------------------------------------------------
local notifications = create("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -24),
    Size = UDim2.fromOffset(340, 400),
    BackgroundTransparency = 1,
    ZIndex = 20,
}, screen)

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, notifications)

notify = function(title, message, duration)
    local toast = create("Frame", {
        Size = UDim2.fromOffset(320, 64),
        BackgroundColor3 = colors.panel,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, notifications)
    corner(toast, 10)
    stroke(toast, colors.line, 1, 0.4)
    addShadow(toast, 0.5)

    local bar = create("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.fromOffset(10, 8),
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    }, toast)
    corner(bar, 2)

    create("TextLabel", {
        Position = UDim2.fromOffset(26, 10),
        Size = UDim2.new(1, -36, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
    }, toast)

    create("TextLabel", {
        Position = UDim2.fromOffset(26, 30),
        Size = UDim2.new(1, -36, 0, 22),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = colors.muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
    }, toast)

    for _, obj in ipairs(toast:GetDescendants()) do
        if obj:IsA("TextLabel") then
            TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {TextTransparency = 0}):Play()
        elseif obj:IsA("Frame") then
            TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 0}):Play()
        end
    end
    TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency = 0}):Play()

    task.delay(duration or 3, function()
        if toast.Parent then
            for _, obj in ipairs(toast:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    TweenService:Create(obj, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {TextTransparency = 1}):Play()
                elseif obj:IsA("Frame") then
                    TweenService:Create(obj, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
                end
            end
            local fade = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {BackgroundTransparency = 1})
            fade:Play()
            fade.Completed:Wait()
            toast:Destroy()
        end
    end)
end

--------------------------------------------------------------------------------
-- ADAPTIVE PANEL FACTORY
--------------------------------------------------------------------------------
local function makePanel(title, subtitle, targetSize)
    local panel = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.88, 0.88),
        BackgroundColor3 = colors.panel,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ClipsDescendants = false,
    }, screen)

    corner(panel, 14)
    stroke(panel, colors.line, 1, 0.2)
    addShadow(panel, 1)

    create("UISizeConstraint", {
        MaxSize = Vector2.new(targetSize.X.Offset, targetSize.Y.Offset),
        MinSize = Vector2.new(280, 200),
    }, panel)

    create("UIAspectRatioConstraint", {
        AspectRatio = targetSize.X.Offset / targetSize.Y.Offset,
        AspectType = Enum.AspectType.FitWithinMaxSize,
        DominantAxis = Enum.DominantAxis.Width,
    }, panel)

    panel.Size = UDim2.fromScale(0.1, 0.1)
    TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromScale(0.88, 0.88),
        BackgroundTransparency = 0
    }):Play()

    local topGlow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
    }, panel)
    corner(topGlow, 2)

    create("TextLabel", {
        Position = UDim2.fromOffset(24, 20),
        Size = UDim2.new(1, -90, 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    create("TextLabel", {
        Position = UDim2.fromOffset(24, 46),
        Size = UDim2.new(1, -90, 0, 18),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = colors.muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)

    return panel
end

local keyPanel = makePanel("Dreii's Utility", "Enter your Platoboost key to continue", UDim2.fromOffset(380, 260))

local keyBox = create("TextBox", {
    Position = UDim2.fromOffset(24, 82),
    Size = UDim2.new(1, -48, 0, 42),
    BackgroundColor3 = colors.background,
    BorderSizePixel = 0,
    PlaceholderText = "Paste access key here...",
    PlaceholderColor3 = colors.muted,
    Text = "",
    TextColor3 = colors.white,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    ClearTextOnFocus = false,
}, keyPanel)
corner(keyBox, 8)
stroke(keyBox, colors.line, 1, 0.3)

local unlock = create("TextButton", {
    Position = UDim2.fromOffset(24, 136),
    Size = UDim2.new(1, -48, 0, 40),
    BackgroundColor3 = colors.accent,
    BorderSizePixel = 0,
    Text = "UNLOCK ACCESS",
    TextColor3 = colors.white,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    AutoButtonColor = false,
}, keyPanel)
corner(unlock, 8)

local getKeyBtn = create("TextButton", {
    Position = UDim2.fromOffset(24, 186),
    Size = UDim2.new(1, -48, 0, 36),
    BackgroundColor3 = colors.panelLight,
    BorderSizePixel = 0,
    Text = "GET KEY (COPY LINK)",
    TextColor3 = colors.white,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    AutoButtonColor = false,
}, keyPanel)
corner(getKeyBtn, 8)
stroke(getKeyBtn, colors.line, 1, 0.4)

unlock.MouseEnter:Connect(function()
    TweenService:Create(unlock, TweenInfo.new(0.2), {BackgroundColor3 = colors.accentGlow}):Play()
end)
unlock.MouseLeave:Connect(function()
    TweenService:Create(unlock, TweenInfo.new(0.2), {BackgroundColor3 = colors.accent}):Play()
end)

getKeyBtn.Activated:Connect(function()
    copyLink()
end)

local function draggable(frame, handle)
    local dragging, dragStart, startPosition
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

draggable(keyPanel, keyPanel)

--------------------------------------------------------------------------------
-- UTILITY CORE (WITH AUTO-STEAL EGGS ENGINE)
--------------------------------------------------------------------------------
getgenv().config = { minarea = 9 }

local utility = {
    Players = game:GetService("Players"),
    ReplicatedStorage = ReplicatedStorage,
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Target = nil,
    KillAuraEnabled = false,
    EggConn = nil,
    SpeedEnabled = false,
    WalkSpeed = 16,
    KnockbackEnabled = false,
    knockbackConnections = nil,
    AntiDriftEnabled = false,
    AutoStealEggEnabled = false,
    conns = {},
    areas = {
        "Forest",         -- 1
        "Lake",           -- 2
        "Desert",         -- 3
        "Jungle",         -- 4
        "Snow",           -- 5
        "Volcano",        -- 6
        "Abyss Ocean",    -- 7
        "Prehistoric",    -- 8
        "Cosmic",         -- 9
        "Cherry Blossom", -- 10
        "Titan Temple",   -- 11
    }
}

function utility:getBestEgg()
    local s, r = pcall(function(...)
        if not self.EggState then return nil end
        local egg = nil
        local biggestegg = 0
        for key, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx >= getgenv().config.minarea then
                if data.AssetScale > biggestegg then
                    biggestegg = data.AssetScale
                    egg = data
                end
            end
        end
        return egg
    end)
    if s and r then return r end
    return nil
end

function utility:GoTo(pos)
    pcall(function(...)
        local dist = math.huge
        local startTime = tick()
        repeat
            local dt = task.wait(0.01)
            if not self.LocalPlayer.Character or not self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then break end
            local start = self.LocalPlayer.Character.HumanoidRootPart.Position
            local targetPos = pos.BoundsCFrame and pos.BoundsCFrame.Position or Vector3.new(514, 71, -368)
            dist = (targetPos - start).Magnitude
            local half = start + (targetPos - start).Unit * dt * 350
            self.LocalPlayer.Character:MoveTo(half)
        until dist <= 5 or not self.AutoStealEggEnabled or (tick() - startTime > 10)
    end)
end

function utility:getproximitypromptforegg(egg)
    local s, r = pcall(function(...)
        local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
        local closetprompt = nil
        local closetdist = math.huge
        for key, prompt in next, CarryAreaEggs do
            local p = prompt.Parent
            if p then
                local dist = (egg.BoundsCFrame.Position - p.Position).Magnitude
                if dist < closetdist then
                    closetdist = dist
                    closetprompt = prompt
                end
            end
        end
        return closetprompt
    end)
    if s and r then return r end
    return nil
end

function utility:CreateSeed()
    local s, r = pcall(function(...)
        return ("%*:%*:%*"):format(self.LocalPlayer.UserId, 100, (math.floor(self.Workspace:GetServerTimeNow() * 1000)))
    end)
    if s and r then return r end
    return nil
end

function utility:CanUseTool()
    local s, r = pcall(function(...)
        local c = self.LocalPlayer.Character
        if not c then return false end
        local t = c:FindFirstChildOfClass("Tool")
        if not t or t:GetAttribute("ItemType") ~= "Gear" then return false end
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return false end
        if not self.ToolGameplayGuard then return true end
        local n = not self.ToolGameplayGuard.IsLocalInsideArena()
        if n then return false end
        if self.Workspace:GetAttribute("Event_MonsterEvent") then
            if h then
                local i = -268 < h.Position.Z
                if i then return true end
            end
            return false
        else
            return true
        end
    end)
    if s and r then return r end
    return false
end

function utility:attack(p)
    local s, r = pcall(function(...)
        if self["RE/BatSwing/Trigger"] then
            return self["RE/BatSwing/Trigger"]:FireServer(p, self:CreateSeed())
        end
    end)
    if s then return end
    return warn('failed: '..tostring(r))
end

function utility:GetClosetPlayer()
    local c = nil
    local cd = math.huge
    for _, p in next, self.Players:GetPlayers() do
        if p == self.LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local dist = self.LocalPlayer:DistanceFromCharacter(hrp.Position)
        if dist < cd and dist <= 16.5 then
            cd = dist
            c = p
        end
    end
    return c
end

function utility:bind(connection, callback)
    local s, r = pcall(function(...)
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return self.conns[conn]
    end)
    if s and r then return r end
    return warn('failed to bind connection error: '..tostring(r))
end

function utility:unbind(connection)
    local s, r = pcall(function(...)
        local conn = self.conns[connection]
        if conn then
            conn:Disconnect()
            self.conns[connection] = nil
            return true
        end
        return false
    end)
    if s and r then return true end
    return warn("failed to unbind")
end

utility.collectgarbage = function()
    local s, r = pcall(function(...) return getgc() end)
    if s and r then return r end
    return warn("failed to get garbage")
end

utility.safehook = function(f, c)
    local s, r = pcall(function(...) return hookfunction(f, newlclosure(c)) end)
    if s and r then return r end
    return warn("failed to hook function")
end

function utility:findfunction(nups, linedefined)
    local s, r = pcall(function(...)
        for _, f in next, self.collectgarbage() or {} do
            if typeof(f) == 'function' and islclosure(f) then
                local upvs = debug.getupvalues(f)
                local line = debug.info(f, "l")
                if upvs and #upvs == nups and line == linedefined then
                    if nups == 10 then
                        local t = debug.getupvalue(f, 3)
                        if typeof(t) == "table" and rawget(t, "Humanoid") then
                            return f
                        end
                    else
                        return f
                    end
                end
            end
        end
        return nil
    end)
    if s and r then return r end
    return nil
end

function utility:init()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return warn('failed to get localplayer') end

    pcall(function()
        self.Packages = self.ReplicatedStorage:WaitForChild("Packages", 3)
        if self.Packages then
            self.Networking = self.Packages:WaitForChild("Networking", 3)
            if self.Networking then
                self["RE/BatSwing/Trigger"] = self.Networking:WaitForChild("RE/BatSwing/Trigger", 3)
                self["RE/RigSync/Refresh"] = self.Networking:WaitForChild("RE/RigSync/Refresh", 3)
            end
        end
        self.Client = self.ReplicatedStorage:WaitForChild("Client", 3)
        if self.Client then
            local guard = self.Client:WaitForChild("ToolGameplayGuard", 3)
            if guard then
                self.ToolGameplayGuard = require(guard)
            end
            local eggStateModule = self.Client:WaitForChild("EggState", 3)
            if eggStateModule then
                self.EggState = require(eggStateModule)
            end
        end
    end)

    local isAttemptingToMove = false
    local movementKeys = {
        [Enum.KeyCode.W] = true,
        [Enum.KeyCode.A] = true,
        [Enum.KeyCode.S] = true,
        [Enum.KeyCode.D] = true,
        [Enum.KeyCode.Up] = true,
        [Enum.KeyCode.Down] = true,
        [Enum.KeyCode.Left] = true,
        [Enum.KeyCode.Right] = true,
    }

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if movementKeys[input.KeyCode] then
            isAttemptingToMove = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if movementKeys[input.KeyCode] then
            local stillMoving = false
            for keyCode, _ in pairs(movementKeys) do
                if UserInputService:IsKeyDown(keyCode) then
                    stillMoving = true
                    break
                end
            end
            local char = self.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not stillMoving and (not hum or hum.MoveDirection.Magnitude == 0) then
                isAttemptingToMove = false
            end
        end
    end)

    self.last = tick()
    self.conn = self.RunService.Heartbeat:Connect(function()
        local char = self.LocalPlayer.Character
        if not char then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if self.KillAuraEnabled then
            self.Target = self:GetClosetPlayer()
            if self.Target then
                if tick() - self.last >= 0.1 then
                    if self:CanUseTool() then
                        self:attack(self.Target)
                        self.last = tick()
                    end
                end
            end
        end

        if self.SpeedEnabled and hum then
            hum.WalkSpeed = self.WalkSpeed
        end

        if self.AntiDriftEnabled and rootPart and hum then
            if hum.MoveDirection.Magnitude > 0 then
                isAttemptingToMove = true
            else
                local keysPressed = false
                for keyCode, _ in pairs(movementKeys) do
                    if UserInputService:IsKeyDown(keyCode) then
                        keysPressed = true
                        break
                    end
                end
                if not keysPressed then
                    isAttemptingToMove = false
                end
            end

            if not isAttemptingToMove and hum.FloorMaterial ~= Enum.Material.Air then
                rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)

    -- Auto Steal Egg Worker Thread
    task.spawn(function()
        while true do
            if self.AutoStealEggEnabled then
                pcall(function()
                    local egg = self:getBestEgg()
                    if egg then
                        self:GoTo(egg)
                        task.wait(0.5)
                        local p = self:getproximitypromptforegg(egg)
                        if p and fireproximityprompt then
                            fireproximityprompt(p)
                        end
                        task.wait(0.1)
                        self:GoTo({["BoundsCFrame"] = CFrame.new(514, 71, -368)})
                    else
                        self:GoTo({["BoundsCFrame"] = CFrame.new(514, 71, -368)})
                    end
                end)
            end
            task.wait(1)
        end
    end)

    local function applyBypass(d)
        local e = d:FindFirstChildOfClass("Humanoid")
        if not e then return end
        local f = workspace.CurrentCamera
        local g = d:FindFirstChild("Animate")
        local h = e.WalkSpeed
        local i = e.JumpPower
        local j = e.JumpHeight
        local k = e.Health
        local l = e.MaxHealth

        if g and g:IsA("LocalScript") then g.Disabled = true end

        local m = e:FindFirstChildOfClass("Animator")
        if m then
            for _,n in next,m:GetPlayingAnimationTracks() do
                n:Stop(0)
            end
        end

        e.Archivable = true
        local o = e:Clone()
        for _,p in next,o:GetChildren() do
            if p:IsA("Animator") then p:Destroy() end
        end

        e.Name = "_OldHumanoid"
        o.Name = "Humanoid"
        o.Parent = d

        local q = Instance.new("Animator")
        q.Parent = o

        o.WalkSpeed = h
        o.JumpPower = i
        o.JumpHeight = j
        o.MaxHealth = l
        o.Health = math.min(k, l)

        if f then f.CameraSubject = o end
        e:Destroy()

        if g and g:IsA("LocalScript") then
            task.wait()
            g.Disabled = false
            task.defer(function()
                if g.Parent then
                    g.Disabled = true
                    task.wait()
                    g.Disabled = false
                end
            end)
        end

        task.defer(function()
            if o.Parent then
                o:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        return o
    end

    local function onCharAdded(s)
        s:WaitForChild("Humanoid")
        task.wait()
        applyBypass(s)
    end

    if self.LocalPlayer.Character then
        task.spawn(onCharAdded, self.LocalPlayer.Character)
    end

    self.LocalPlayer.CharacterAdded:Connect(function(s)
        task.spawn(onCharAdded, s)
    end)

    pcall(function()
        if getgc and hookfunction and islclosure then
            local func3 = self:findfunction(19, 3)
            if func3 then
                local v7 = debug.getupvalue(func3, 2)
                if v7 then
                    local hookedfunc3
                    hookedfunc3 = self.safehook(v7, function(p1, p2)
                        if p2 and typeof(p2) == "table" then
                            setmetatable(p2, {})
                        end
                        return hookedfunc3(p1, p2)
                    end)
                end
            end
        end
    end)

    return warn("Dreii's Utility Initialized Successfully")
end

--------------------------------------------------------------------------------
-- CONTROL CENTER / DASHBOARD UI
--------------------------------------------------------------------------------
local mainPanel, floatingToggle

local function showMain()
    keyPanel:Destroy()
    mainPanel = makePanel("Dreii's Utility", "Control Center / Active Status", UDim2.fromOffset(450, 480))
    draggable(mainPanel, mainPanel)

    floatingToggle = create("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 15, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = colors.panel,
        BorderSizePixel = 0,
        Text = "UI",
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Visible = false,
        AutoButtonColor = false,
    }, screen)
    corner(floatingToggle, 10)
    stroke(floatingToggle, colors.line, 1, 0.2)
    addShadow(floatingToggle, 0.4)
    draggable(floatingToggle, floatingToggle)

    floatingToggle.Activated:Connect(function()
        mainPanel.Visible = not mainPanel.Visible
        floatingToggle.Visible = not mainPanel.Visible
    end)

    local closeBtn = create("TextButton", {
        Position = UDim2.new(1, -38, 0, 18),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = colors.panelLight,
        BorderSizePixel = 0,
        Text = "✕",
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
    }, mainPanel)
    corner(closeBtn, 6)
    stroke(closeBtn, colors.line, 1, 0.4)

    closeBtn.Activated:Connect(function()
        screen:Destroy()
    end)

    local minBtn = create("TextButton", {
        Position = UDim2.new(1, -70, 0, 18),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = colors.panelLight,
        BorderSizePixel = 0,
        Text = "—",
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
    }, mainPanel)
    corner(minBtn, 6)
    stroke(minBtn, colors.line, 1, 0.4)

    minBtn.Activated:Connect(function()
        mainPanel.Visible = false
        floatingToggle.Visible = true
    end)

    local content = create("ScrollingFrame", {
        Position = UDim2.fromOffset(24, 82),
        Size = UDim2.new(1, -48, 1, -98),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.fromOffset(0, 520),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.line,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, mainPanel)

    create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local function toggle(title, description, callback)
        local button = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = colors.panelLight,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = 1,
        }, content)
        corner(button, 8)
        stroke(button, colors.line, 1, 0.5)

        create("TextLabel", {
            Position = UDim2.fromOffset(16, 10),
            Size = UDim2.new(1, -75, 0, 18),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = colors.white,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, button)

        create("TextLabel", {
            Position = UDim2.fromOffset(16, 30),
            Size = UDim2.new(1, -75, 0, 16),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = colors.muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, button)

        local indicator = create("Frame", {
            Position = UDim2.new(1, -54, 0.5, -11),
            Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = colors.background,
            BorderSizePixel = 0,
        }, button)
        corner(indicator, 11)
        stroke(indicator, colors.line, 1, 0.5)

        local knob = create("Frame", {
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = colors.muted,
            BorderSizePixel = 0,
        }, indicator)
        corner(knob, 8)

        local enabled = false
        button.Activated:Connect(function()
            enabled = not enabled
            TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundColor3 = enabled and colors.accent or colors.background}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = enabled and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = enabled and colors.white or colors.muted
            }):Play()
            callback(enabled)
            notify(title, enabled and "Feature Enabled" or "Feature Disabled", 2.5)
        end)
    end

    local function dropdown(title, options, callback)
        local container = create("Frame", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = colors.panelLight,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = 1,
        }, content)
        corner(container, 8)
        stroke(container, colors.line, 1, 0.5)

        create("TextLabel", {
            Position = UDim2.fromOffset(16, 8),
            Size = UDim2.new(1, -32, 0, 16),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = colors.muted,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, container)

        local dropBtn = create("TextButton", {
            Position = UDim2.fromOffset(16, 26),
            Size = UDim2.new(1, -32, 0, 22),
            BackgroundTransparency = 1,
            Text = options[getgenv().config.minarea] or options[1],
            TextColor3 = colors.white,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, container)

        local arrow = create("TextLabel", {
            Position = UDim2.new(1, -20, 0, 0),
            Size = UDim2.fromOffset(20, 22),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = colors.muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
        }, dropBtn)

        local list = create("Frame", {
            Position = UDim2.fromOffset(16, 56),
            Size = UDim2.new(1, -32, 0, #options * 26),
            BackgroundTransparency = 1,
        }, container)

        create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, list)

        local isOpen = false
        dropBtn.Activated:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and (56 + #options * 26 + 10) or 56
            TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
            arrow.Text = isOpen and "▲" or "▼"
        end)

        for idx, optionName in ipairs(options) do
            local item = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = colors.background,
                BorderSizePixel = 0,
                Text = "  " .. optionName,
                TextColor3 = colors.white,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = idx,
            }, list)
            corner(item, 4)

            item.Activated:Connect(function()
                dropBtn.Text = optionName
                isOpen = false
                TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 56)}):Play()
                arrow.Text = "▼"
                callback(idx, optionName)
            end)
        end
    end

    toggle("Auto-Steal-Best-Eggs", "Automatically teleports to & collects the best eggs", function(state)
        utility.AutoStealEggEnabled = state
    end)

    dropdown("MINIMUM EGG AREA", utility.areas, function(index, name)
        getgenv().config.minarea = index
        notify("Area Updated", "Set minimum egg area to: " .. name, 2.5)
    end)

    toggle("Kill-Aura", "Automatically swings bat at nearby players", function(state)
        utility.KillAuraEnabled = state
    end)

    toggle("Instant Egg Carry", "Removes hold duration for CarryAreaEgg", function(state)
        if state then
            utility.EggConn = utility:bind(utility.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
                if Player == utility.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
                    ProximityPrompt.HoldDuration = 0
                end
            end)
        else
            if utility.EggConn then
                utility:unbind(utility.EggConn)
                utility.EggConn = nil
            end
        end
    end)

    toggle("No Knockback", "Disables RE/RigSync/Refresh network sync", function(state)
        utility.KnockbackEnabled = state
        if state then
            if utility["RE/RigSync/Refresh"] and getconnections then
                local success, connections = pcall(function() return getconnections(utility["RE/RigSync/Refresh"].OnClientEvent) end)
                if success and connections then
                    utility.knockbackConnections = connections
                    for _, conn in next, connections do
                        conn:Disable()
                    end
                    notify("No Knockback", "Knockback connections disabled.", 2.5)
                end
            end
        else
            if utility.knockbackConnections then
                for _, conn in next, utility.knockbackConnections do
                    pcall(function() conn:Enable() end)
                end
                utility.knockbackConnections = nil
                notify("No Knockback", "Knockback connections re-enabled.", 2.5)
            end
        end
    end)

    toggle("WalkSpeed Bypass", "Enables custom walkspeed modification", function(state)
        utility.SpeedEnabled = state
    end)

    toggle("Anti-Drift", "Stops unwanted character sliding on stops", function(state)
        utility.AntiDriftEnabled = state
    end)

    local speedContainer = create("Frame", {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    }, content)

    create("TextLabel", {
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "WALKSPEED VALUE",
        TextColor3 = colors.white,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, speedContainer)

    local speedBox = create("TextBox", {
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = colors.panelLight,
        BorderSizePixel = 0,
        Text = "16",
        TextColor3 = colors.white,
        PlaceholderText = "16 - 2500",
        PlaceholderColor3 = colors.muted,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false,
    }, speedContainer)
    corner(speedBox, 8)
    stroke(speedBox, colors.line, 1, 0.5)

    speedBox.FocusLost:Connect(function()
        local num = tonumber(speedBox.Text)
        if num then
            num = math.clamp(math.floor(num + 0.5), 16, MAX_VALUE)
            speedBox.Text = tostring(num)
            utility.WalkSpeed = num
        else
            speedBox.Text = tostring(utility.WalkSpeed)
        end
    end)

    notify("Welcome", "Control center successfully loaded.", 4)
end

--------------------------------------------------------------------------------
-- ACCESS VALIDATION LISTENERS
--------------------------------------------------------------------------------
unlock.Activated:Connect(function()
    local enteredKey = keyBox.Text
    if enteredKey == "" then
        onMessage("Please enter a key before unlocking.")
        return
    end

    notify("Key System", "Verifying key with Platoboost...", 2)

    task.spawn(function()
        local isValid = verifyKey(enteredKey)
        if isValid then
            notify("Key System", "Access Granted! Loading interface...", 3)
            showMain()
            utility:init()
        end
    end)
end)

keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        unlock:Activate()
    end
end)
