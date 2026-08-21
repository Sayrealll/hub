local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Window
local Window = Rayfield:CreateWindow({
    Name = "SAYREAL POGI",
    LoadingTitle = "ALL IN ONE GAME",
    LoadingSubtitle = "SAYREAL POGI",

    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "SAYREAL Hub"
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = true,

    KeySettings = {
        Title = "SAYREAL KEY SYSTEM",
        Subtitle = "Key System",
        Note = "Key In Discord Server",
        FileName = "kwkwkw",
        SaveKey = true,
        GrabKeyFromSite = true,
        Key = {
            "https://pastebin.com/raw/ntWcPGKV"
        }
    }
})


--==================================================
-- HOME TAB
--==================================================

local MainTab = Window:CreateTab("🏠 Home", nil)

MainTab:CreateSection("Main")


Rayfield:Notify({
    Title = "Successfully Executed! ✅",
    Content = "SAYREAL POGI loaded successfully.",
    Duration = 5,
    Image = 13047715178,
})


-- Auto Farm
local AutoFarm = false

MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",

    Callback = function(Value)
        AutoFarm = Value

        if AutoFarm then
            print("Auto Farm: ON")
        else
            print("Auto Farm: OFF")
        end
    end,
})


-- Auto Buy UI
local AutoBuyCarrot = false

MainTab:CreateToggle({
    Name = "Auto Buy Carrot",
    CurrentValue = false,
    Flag = "AutoBuyCarrot",

    Callback = function(Value)
        AutoBuyCarrot = Value

        if AutoBuyCarrot then
            print("Auto Buy Carrot: ON")
        else
            print("Auto Buy Carrot: OFF")
        end
    end,
})


MainTab:CreateDivider()

MainTab:CreateSection("Area")


MainTab:CreateDropdown({
    Name = "Select Area",

    Options = {
        "Starter World",
        "Pirate Island",
        "Pineapple Paradise"
    },

    CurrentOption = {
        "Starter World"
    },

    MultipleOptions = false,
    Flag = "SelectedArea",

    Callback = function(Option)
        print("Selected Area:", Option)
    end,
})


--==================================================
-- PLAYER TAB
--==================================================

local PlayerTab = Window:CreateTab("⚡ Player", nil)

PlayerTab:CreateSection("Movement")


-- Infinite Jump
local InfiniteJump = false

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",

    Callback = function(Value)
        InfiniteJump = Value
    end,
})


-- Infinite Jump connection
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then
        return
    end

    local Character = LocalPlayer.Character
    if not Character then
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)


-- WalkSpeed
PlayerTab:CreateSlider({
    Name = "Player Speed",

    Range = {
        1,
        350
    },

    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 16,
    Flag = "PlayerSpeed",

    Callback = function(Value)

        local Character = LocalPlayer.Character

        if not Character then
            return
        end

        local Humanoid =
            Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            Humanoid.WalkSpeed = Value
        end

    end,
})


-- JumpPower
PlayerTab:CreateSlider({
    Name = "Jump Power",

    Range = {
        1,
        350
    },

    Increment = 1,
    Suffix = " Power",
    CurrentValue = 50,
    Flag = "JumpPower",

    Callback = function(Value)

        local Character = LocalPlayer.Character

        if not Character then
            return
        end

        local Humanoid =
            Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            Humanoid.JumpPower = Value
        end

    end,
})


PlayerTab:CreateDivider()

PlayerTab:CreateSection("Custom Speed")


-- WalkSpeed input
PlayerTab:CreateInput({
    Name = "Custom WalkSpeed",

    PlaceholderText = "Enter 1-350",

    RemoveTextAfterFocusLost = true,

    Callback = function(Text)

        local Value = tonumber(Text)

        if not Value then
            return
        end

        Value = math.clamp(Value, 1, 350)

        local Character = LocalPlayer.Character

        if not Character then
            return
        end

        local Humanoid =
            Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then
            Humanoid.WalkSpeed = Value
        end

    end,
})


--==================================================
-- TELEPORT TAB
--==================================================

local TPTab = Window:CreateTab("🏝 Teleports", nil)

TPTab:CreateSection("Locations")


TPTab:CreateButton({
    Name = "Starter Island",

    Callback = function()
        print("Starter Island selected")

        -- Put your own game's legitimate teleport
        -- code here.
    end,
})


TPTab:CreateButton({
    Name = "Pirate Island",

    Callback = function()
        print("Pirate Island selected")

        -- Put your own game's legitimate teleport
        -- code here.
    end,
})


TPTab:CreateButton({
    Name = "Pineapple Paradise",

    Callback = function()
        print("Pineapple Paradise selected")

        -- Put your own game's legitimate teleport
        -- code here.
    end,
})


--==================================================
-- SETTINGS TAB
--==================================================

local SettingsTab = Window:CreateTab("⚙️ Settings", nil)

SettingsTab:CreateSection("Interface")


SettingsTab:CreateButton({
    Name = "Hide UI",

    Callback = function()
        Rayfield:SetVisibility(false)
    end,
})


SettingsTab:CreateButton({
    Name = "Destroy UI",

    Callback = function()
        Rayfield:Destroy()
    end,
})


--==================================================
-- CHARACTER RESPAWN SUPPORT
--==================================================

LocalPlayer.CharacterAdded:Connect(function(Character)

    task.wait(1)

    if not Character then
        return
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        print("Character loaded")
    end

end)

print("================================")
print(" SAYREAL POGI LOADED")
print("================================")
