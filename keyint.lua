local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/haha-wt/Keyint-Ltd-Sti/main/gui.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/haha-wt/Keyint-Ltd-Sti/main/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/haha-wt/Keyint-Ltd-Sti/main/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local GameSystems = workspace:WaitForChild("Game Systems")

local VehicleWorkspaces = {
    "Gunship Workspace",
    "Plane Workspace",
    "Tank Workspace",
    "Boat Workspace",
    "Drone Workspace",
    "Helicopter Workspace"
}

_G.espRange = 1500
_G.EspPlayers = false
_G.EspVehicle = false
_G.AimbotLoaded = false

local Window = Fluent:CreateWindow({
    Title = "Keint Hub",
    SubTitle = "War Tycoon | by lrx",
    TabWidth = 140,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Gun & Aimbot", Icon = "crosshair" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Ayarlar", Icon = "settings" })
}

local AimbotToggle = Tabs.Combat:AddToggle("AimbotToggle", {
    Title = "Aimbot Aç / Kapat",
    Description = "Aimbot'u tamamen açar veya kapatır",
    Default = true
})

AimbotToggle:OnChanged(function(Value)
    if not _G.AimbotLoaded then
        if Value then
            _G.AimbotLoaded = true
            loadstring(game:HttpGet("https://raw.githubusercontent.com/haha-wt/Keyint-Ltd-Sti/main/aim.lua"))()
            Fluent:Notify({
                Title = "Keint Hub",
                Content = "Aimbot yüklendi!",
                Duration = 5,
                SubTitle = "Aimbot"
            })
        end
        return
    end

    if getgenv().Aimbot and getgenv().Aimbot.Functions and getgenv().Aimbot.Functions.SetEnabled then
        getgenv().Aimbot.Functions:SetEnabled(Value)
    end
end)

_G.AimbotStateChanged = function(state)
    if AimbotToggle then
        AimbotToggle:SetValue(state)
    end
end

local TriggerKeyLabel = Tabs.Combat:AddParagraph({
    Title = "Aimbot Nişan Tuşu: MouseButton2",
    Content = "Aşağıdaki butonla değiştirebilirsin."
})

Tabs.Combat:AddButton({
    Title = "Aimbot Nişan Tuşunu Ata",
    Description = "Bir sonraki basacağın tuş aimbot nişan tuşu olur",
    Callback = function()
        Fluent:Notify({
            Title = "Keint Hub",
            Content = "Şimdi bir tuşa bas...",
            Duration = 4,
            SubTitle = "Tuş Atama"
        })

        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

            local keyName = input.KeyCode.Name

            if getgenv().Aimbot and getgenv().Aimbot.Functions and getgenv().Aimbot.Functions.SetTriggerKey then
                getgenv().Aimbot.Functions:SetTriggerKey(keyName)
            else
                _G.AimbotPendingTriggerKey = keyName
            end

            connection:Disconnect()

            if TriggerKeyLabel and TriggerKeyLabel.SetTitle then
                TriggerKeyLabel:SetTitle("Aimbot Nişan Tuşu: " .. keyName)
            end

            Fluent:Notify({
                Title = "Keint Hub",
                Content = "Aimbot nişan tuşu: " .. keyName,
                Duration = 5,
                SubTitle = "Tuş Atandı"
            })
        end)
    end
})

local ToggleModeToggle = Tabs.Combat:AddToggle("AimbotToggleMode", {
    Title = "Aimbot Toggle Modu",
    Description = "Açıksa tuşa bir kere basınca nişan alır, kapalıysa basılı tutunca",
    Default = false
})

ToggleModeToggle:OnChanged(function(Value)
    if getgenv().Aimbot and getgenv().Aimbot.Functions and getgenv().Aimbot.Functions.SetToggle then
        getgenv().Aimbot.Functions:SetToggle(Value)
    else
        _G.AimbotPendingToggle = Value
    end
end)

local EspPlayersToggle = Tabs.ESP:AddToggle("EspPlayers", {
    Title = "Oyuncu ESP",
    Description = "Oyuncuları duvar arkasından gösterir",
    Default = false
})

EspPlayersToggle:OnChanged(function(Value)
    _G.EspPlayers = Value
end)

local EspVehicleToggle = Tabs.ESP:AddToggle("EspVehicle", {
    Title = "Araç ESP",
    Description = "Araçları duvar arkasından gösterir",
    Default = false
})

EspVehicleToggle:OnChanged(function(Value)
    _G.EspVehicle = Value
end)

local EspRangeSlider = Tabs.ESP:AddSlider("EspRange", {
    Title = "ESP Mesafesi",
    Description = "ESP'nin görüneceği maksimum mesafe",
    Default = 1500,
    Min = 200,
    Max = 2500,
    Rounding = 0,
    Callback = function(Value)
        _G.espRange = Value
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("KeintHub")
SaveManager:SetFolder("KeintHub/WarTycoon")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local function createHighlight()
    local highlight = Instance.new("Highlight")
    highlight.Name = "XRay"
    highlight.OutlineColor = Color3.new(0, 0, 0)
    return highlight
end

local function createBillboard()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NamePlayer"
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1500
    billboard.Size = UDim2.new(0, 300, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 1.8, 0)

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Non Team"
    textLabel.BackgroundTransparency = 1
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Size = UDim2.new(0, 300, 0, 50)
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 15
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextStrokeTransparency = 0
    textLabel.Parent = billboard

    return billboard, textLabel
end

local function updatePlayerESP(player)
    if not player.Character or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    if player == LocalPlayer then return end

    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local distance = (player.Character.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
    local nameTag = head:FindFirstChild("NamePlayer")
    local xray = player.Character:FindFirstChild("XRay")

    if nameTag then
        nameTag.MaxDistance = _G.espRange
    end

    if distance > _G.espRange then
        if xray then xray:Destroy() end
        if nameTag then nameTag:Destroy() end
        return
    end

    if _G.EspPlayers then
        if not xray then
            local newHighlight = createHighlight()
            newHighlight.FillColor = player.TeamColor.Color
            newHighlight.OutlineColor = player.TeamColor.Color
            newHighlight.Parent = player.Character
        end
        if not nameTag then
            local bb, label = createBillboard()
            bb.Adornee = head
            label.Text = tostring(player.Team)
            label.TextColor3 = player.TeamColor.Color
            bb.Parent = head
        end
    else
        if xray then xray:Destroy() end
        if nameTag then nameTag:Destroy() end
    end
end

local function updateVehicleESP(vehicle)
    if vehicle:GetAttribute("Owner") == LocalPlayer.Name then
        if vehicle:FindFirstChild("XRay") then
            vehicle.XRay:Destroy()
        end
    elseif not vehicle:FindFirstChild("XRay") and _G.EspVehicle then
        local xray = createHighlight()
        xray.FillColor = Color3.new(0, 0, 1)
        xray.OutlineColor = Color3.new(0, 0, 1)
        xray.Parent = vehicle
    elseif vehicle:FindFirstChild("XRay") and not _G.EspVehicle then
        vehicle.XRay:Destroy()
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updatePlayerESP(player)
        end
    end

    for _, folderName in ipairs(VehicleWorkspaces) do
        local workspaceFolder = GameSystems:FindFirstChild(folderName)
        if workspaceFolder then
            for _, model in ipairs(workspaceFolder:GetChildren()) do
                if model:IsA("Model") then
                    updateVehicleESP(model)
                end
            end
        end
    end
end)

Fluent:Notify({
    Title = "Keint Hub",
    Content = "Script başarıyla yüklendi! Sağ Shift ile aç/kapat.",
    Duration = 6,
    SubTitle = "Yüklendi"
})