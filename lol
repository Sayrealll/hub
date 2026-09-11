local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))

local WindUI

if RunService:IsStudio() then
    WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
else
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end
