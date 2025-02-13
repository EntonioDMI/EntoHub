-- ESP Module
local ESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local DrawingNew = Drawing.new
local V2New = Vector2.new
local V3New = Vector3.new
local WTVP = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild

-- ESP Objects Container
local ESPObjects = {}

-- Settings
local Settings = {
    Enabled = false,
    Boxes = false,
    Health = false,
    Tracers = false,
    Distance = false,
    Chams = false,
    Names = false,
    DisplayNames = false,
    Tools = false,
    TeamCheck = true,
    TextColor = Color3.new(1, 1, 1),
    TextTransparency = 0,
    TextOffset = 0,
    ChamsOutlineColor = Color3.new(1, 0, 0),
    ChamsFillColor = Color3.new(1, 0, 0),
    ChamsTransparency = 0.5
}

-- Utility Functions
local function IsAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    return character and humanoid and humanoid.Health > 0
end

local function IsTeammate(player)
    if not Settings.TeamCheck then return false end
    if player.Team and LocalPlayer.Team then
        return player.Team == LocalPlayer.Team
    end
    return false
end

local function GetPlayerTool(player)
    local character = player.Character
    if not character then return "None" end
    
    local tool = character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
end

local function CreateDrawing(type, properties)
    local drawing = DrawingNew(type)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

-- ESP Object Class
local ESPObject = {}
ESPObject.__index = ESPObject

function ESPObject.new(player)
    local self = setmetatable({
        Player = player,
        Drawings = {
            Box = CreateDrawing("Square", {
                Thickness = 1,
                Filled = false,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            BoxOutline = CreateDrawing("Square", {
                Thickness = 3,
                Filled = false,
                Transparency = 1,
                Color = Color3.new(0, 0, 0),
                Visible = false
            }),
            HealthBar = CreateDrawing("Square", {
                Thickness = 1,
                Filled = true,
                Transparency = 1,
                Color = Color3.new(0, 1, 0),
                Visible = false
            }),
            HealthBarOutline = CreateDrawing("Square", {
                Thickness = 1,
                Filled = false,
                Transparency = 1,
                Color = Color3.new(0, 0, 0),
                Visible = false
            }),
            Tracer = CreateDrawing("Line", {
                Thickness = 1,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            Name = CreateDrawing("Text", {
                Size = 13,
                Center = true,
                Outline = true,
                Transparency = 1,
                Visible = false
            }),
            Distance = CreateDrawing("Text", {
                Size = 13,
                Center = true,
                Outline = true,
                Transparency = 1,
                Visible = false
            }),
            Tool = CreateDrawing("Text", {
                Size = 13,
                Center = true,
                Outline = true,
                Transparency = 1,
                Visible = false
            })
        },
        Chams = Instance.new("Highlight")
    }, ESPObject)
    
    self.Chams.Parent = CoreGui
    
    return self
end

function ESPObject:Update()
    if not Settings.Enabled then
        self:Hide()
        return
    end
    
    local player = self.Player
    if not player or not IsAlive(player) or player == LocalPlayer then
        self:Hide()
        return
    end
    
    if Settings.TeamCheck and IsTeammate(player) then
        self:Hide()
        return
    end
    
    local character = player.Character
    if not character then
        self:Hide()
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not humanoidRootPart or not humanoid or not head then
        self:Hide()
        return
    end
    
    local rootPos = humanoidRootPart.Position
    local headPos = head.Position
    
    local rootPoint, rootVisible = WTVP(Camera, rootPos)
    local headPoint, headVisible = WTVP(Camera, headPos)
    
    if not rootVisible and not headVisible then
        self:Hide()
        return
    end
    
    local screenRootPos = V2New(rootPoint.X, rootPoint.Y)
    local screenHeadPos = V2New(headPoint.X, headPoint.Y)
    
    local boxHeight = math.abs(screenRootPos.Y - screenHeadPos.Y)
    local boxWidth = boxHeight * 0.6
    
    -- Update Box
    if Settings.Boxes then
        self.Drawings.BoxOutline.Size = V2New(boxWidth, boxHeight)
        self.Drawings.BoxOutline.Position = V2New(screenHeadPos.X - boxWidth / 2, screenHeadPos.Y)
        self.Drawings.BoxOutline.Visible = true
        
        self.Drawings.Box.Size = V2New(boxWidth, boxHeight)
        self.Drawings.Box.Position = V2New(screenHeadPos.X - boxWidth / 2, screenHeadPos.Y)
        self.Drawings.Box.Visible = true
    else
        self.Drawings.Box.Visible = false
        self.Drawings.BoxOutline.Visible = false
    end
    
    -- Update Health Bar
    if Settings.Health then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health / maxHealth
        
        self.Drawings.HealthBarOutline.Size = V2New(4, boxHeight)
        self.Drawings.HealthBarOutline.Position = V2New(screenHeadPos.X - boxWidth / 2 - 6, screenHeadPos.Y)
        self.Drawings.HealthBarOutline.Visible = true
        
        self.Drawings.HealthBar.Size = V2New(2, boxHeight * healthPercent)
        self.Drawings.HealthBar.Position = V2New(screenHeadPos.X - boxWidth / 2 - 5, screenHeadPos.Y + boxHeight * (1 - healthPercent))
        self.Drawings.HealthBar.Color = Color3.fromHSV(healthPercent / 3, 1, 1)
        self.Drawings.HealthBar.Visible = true
    else
        self.Drawings.HealthBar.Visible = false
        self.Drawings.HealthBarOutline.Visible = false
    end
    
    -- Update Tracer
    if Settings.Tracers then
        self.Drawings.Tracer.From = V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        self.Drawings.Tracer.To = screenRootPos
        self.Drawings.Tracer.Visible = true
    else
        self.Drawings.Tracer.Visible = false
    end
    
    -- Update Name
    if Settings.Names or Settings.DisplayNames then
        local text = Settings.DisplayNames and player.DisplayName or player.Name
        self.Drawings.Name.Text = text
        self.Drawings.Name.Position = V2New(screenHeadPos.X, screenHeadPos.Y - 25 + Settings.TextOffset)
        self.Drawings.Name.Color = Settings.TextColor
        self.Drawings.Name.Transparency = 1 - Settings.TextTransparency
        self.Drawings.Name.Visible = true
    else
        self.Drawings.Name.Visible = false
    end
    
    -- Update Distance
    if Settings.Distance then
        local distance = math.floor((Camera.CFrame.Position - rootPos).Magnitude)
        self.Drawings.Distance.Text = tostring(distance) .. " studs"
        self.Drawings.Distance.Position = V2New(screenRootPos.X, screenRootPos.Y + 5 + Settings.TextOffset)
        self.Drawings.Distance.Color = Settings.TextColor
        self.Drawings.Distance.Transparency = 1 - Settings.TextTransparency
        self.Drawings.Distance.Visible = true
    else
        self.Drawings.Distance.Visible = false
    end
    
    -- Update Tool
    if Settings.Tools then
        local tool = GetPlayerTool(player)
        self.Drawings.Tool.Text = tool
        self.Drawings.Tool.Position = V2New(screenRootPos.X, screenRootPos.Y + 20 + Settings.TextOffset)
        self.Drawings.Tool.Color = Settings.TextColor
        self.Drawings.Tool.Transparency = 1 - Settings.TextTransparency
        self.Drawings.Tool.Visible = true
    else
        self.Drawings.Tool.Visible = false
    end
    
    -- Update Chams
    if Settings.Chams then
        self.Chams.Adornee = character
        self.Chams.FillColor = Settings.ChamsFillColor
        self.Chams.OutlineColor = Settings.ChamsOutlineColor
        self.Chams.FillTransparency = Settings.ChamsTransparency
        self.Chams.OutlineTransparency = Settings.ChamsTransparency
        self.Chams.Enabled = true
    else
        self.Chams.Enabled = false
    end
end

function ESPObject:Hide()
    for _, drawing in pairs(self.Drawings) do
        drawing.Visible = false
    end
    self.Chams.Enabled = false
end

function ESPObject:Destroy()
    for _, drawing in pairs(self.Drawings) do
        drawing:Remove()
    end
    self.Chams:Destroy()
end

-- Main ESP Functions
function ESP:Init()
    Players.PlayerAdded:Connect(function(player)
        ESPObjects[player] = ESPObject.new(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        local object = ESPObjects[player]
        if object then
            object:Destroy()
            ESPObjects[player] = nil
        end
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESPObjects[player] = ESPObject.new(player)
        end
    end
    
    RunService.RenderStepped:Connect(function()
        for _, object in pairs(ESPObjects) do
            object:Update()
        end
    end)
end

function ESP:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        Settings[key] = value
    end
end

ESP:Init()

return ESP
