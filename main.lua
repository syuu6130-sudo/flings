-- Advanced Fling & Fly Script with Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fling & Fly Script",
   LoadingTitle = "Advanced Movement System",
   LoadingSubtitle = "by Claude",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "FlingFlyConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- State Variables
local flingEnabled = false
local flyEnabled = false
local thirdPersonEnabled = false
local noClipEnabled = false

-- Settings
local flingPower = 500
local flingHeight = 50
local rotationSpeed = 20
local flySpeed = 50
local flySmooth = 0.5

-- Fly Variables
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Camera
local camera = Workspace.CurrentCamera
local defaultCameraDistance = player.CameraMaxZoomDistance

-- Helper Functions
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function getHumanoid(char)
    return char:FindFirstChildOfClass("Humanoid")
end

-- Fling Functions
local function enableFling()
    if not character then return end
    
    local root = getRoot(character)
    if not root then return end
    
    -- Remove collision
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
        end
    end
    
    -- Create spinning force
    if not root:FindFirstChild("FlingAttachment") then
        local attach = Instance.new("Attachment", root)
        attach.Name = "FlingAttachment"
        
        local spin = Instance.new("BodyAngularVelocity", root)
        spin.Name = "FlingSpinner"
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.AngularVelocity = Vector3.new(0, rotationSpeed, 0)
        spin.P = 3000
    end
    
    flingEnabled = true
    Rayfield:Notify({
        Title = "Fling Mode",
        Content = "Fling enabled! Collide with players to fling them.",
        Duration = 3,
        Image = 4483362458,
    })
end

local function disableFling()
    if not character then return end
    
    local root = getRoot(character)
    if root then
        if root:FindFirstChild("FlingSpinner") then
            root.FlingSpinner:Destroy()
        end
        if root:FindFirstChild("FlingAttachment") then
            root.FlingAttachment:Destroy()
        end
    end
    
    -- Restore collision
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = true
            v.Massless = false
        end
    end
    
    flingEnabled = false
end

local function flingTarget(targetChar)
    if not character or not targetChar then return end
    
    local root = getRoot(character)
    local targetRoot = getRoot(targetChar)
    
    if not root or not targetRoot then return end
    
    -- Teleport near target
    local originalCFrame = root.CFrame
    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    
    task.wait(0.15)
    
    -- Apply force
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.new(0, flingHeight, 0) + (targetRoot.CFrame.LookVector * flingPower)
    bodyVel.Parent = targetRoot
    
    game:GetService("Debris"):AddItem(bodyVel, 0.3)
    
    task.wait(0.1)
    root.CFrame = originalCFrame
end

local function flingAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            pcall(function()
                flingTarget(plr.Character)
            end)
            task.wait(0.2)
        end
    end
end

-- Anti-Detection Fly System
local function enableFly()
    if flyEnabled then return end
    
    local root = getRoot(character)
    if not root then return end
    
    flyEnabled = true
    
    -- Create smooth fly physics
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = root
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(0, 0, 0)
    flyBodyGyro.P = 9000
    flyBodyGyro.Parent = root
    
    -- Fly loop
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled or not character or not root then return end
        
        local cam = camera
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Get input
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (cam.CFrame.LookVector)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (cam.CFrame.LookVector)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - (cam.CFrame.RightVector)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + (cam.CFrame.RightVector)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Normalize and apply speed
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * flySpeed
        end
        
        -- Smooth movement
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = moveDirection
        
        -- Keep orientation
        flyBodyGyro.MaxTorque = Vector3.new(9000, 9000, 9000)
        flyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
        
        -- Anti-fall
        if humanoid then
            humanoid.PlatformStand = true
        end
    end)
    
    Rayfield:Notify({
        Title = "Fly Mode",
        Content = "Fly enabled! Use WASD + Space/Shift to fly.",
        Duration = 3,
        Image = 4483362458,
    })
end

local function disableFly()
    if not flyEnabled then return end
    
    flyEnabled = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    
    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- NoClip Function
local function enableNoClip()
    noClipEnabled = true
    
    RunService.Stepped:Connect(function()
        if not noClipEnabled then return end
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoClip()
    noClipEnabled = false
    
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- Third Person View
local function setThirdPerson(enabled)
    thirdPersonEnabled = enabled
    
    if enabled then
        player.CameraMaxZoomDistance = 50
        player.CameraMinZoomDistance = 10
        camera.CameraType = Enum.CameraType.Custom
        
        humanoid.CameraOffset = Vector3.new(0, 2, 0)
    else
        player.CameraMaxZoomDistance = defaultCameraDistance
        player.CameraMinZoomDistance = 0.5
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end
end

-- UI Tabs
local FlingTab = Window:CreateTab("🎯 Fling", 4483362458)
local FlyTab = Window:CreateTab("✈️ Fly", 4483362458)
local ViewTab = Window:CreateTab("👁️ View", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

-- Fling Tab
FlingTab:CreateToggle({
   Name = "Enable Fling Mode",
   CurrentValue = false,
   Flag = "FlingToggle",
   Callback = function(val)
      if val then
         enableFling()
      else
         disableFling()
      end
   end,
})

FlingTab:CreateButton({
   Name = "Fling All Players",
   Callback = function()
      if flingEnabled then
         flingAll()
         Rayfield:Notify({
            Title = "Fling All",
            Content = "Flinging all players!",
            Duration = 2,
            Image = 4483362458,
         })
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "Enable fling mode first!",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

local PlayerList = {}
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= player then
        table.insert(PlayerList, plr.Name)
    end
end

local targetPlayer = nil
local TargetDropdown = FlingTab:CreateDropdown({
   Name = "Select Target Player",
   Options = PlayerList,
   CurrentOption = {"None"},
   MultipleOptions = false,
   Flag = "TargetDropdown",
   Callback = function(option)
      targetPlayer = Players:FindFirstChild(option[1])
   end,
})

FlingTab:CreateButton({
   Name = "Fling Selected Player",
   Callback = function()
      if targetPlayer and targetPlayer.Character and flingEnabled then
         flingTarget(targetPlayer.Character)
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "Select target and enable fling mode!",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

FlingTab:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      local newList = {}
      for _, plr in pairs(Players:GetPlayers()) do
         if plr ~= player then
            table.insert(newList, plr.Name)
         end
      end
      TargetDropdown:Refresh(newList)
      Rayfield:Notify({
         Title = "Refreshed",
         Content = "Player list updated!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- Fly Tab
FlyTab:CreateToggle({
   Name = "Enable Fly Mode",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(val)
      if val then
         enableFly()
      else
         disableFly()
      end
   end,
})

FlyTab:CreateToggle({
   Name = "NoClip (Walk Through Walls)",
   CurrentValue = false,
   Flag = "NoClipToggle",
   Callback = function(val)
      if val then
         enableNoClip()
      else
         disableNoClip()
      end
   end,
})

FlyTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 200},
   Increment = 5,
   CurrentValue = 50,
   Flag = "FlySpeed",
   Callback = function(val)
      flySpeed = val
   end,
})

FlyTab:CreateButton({
   Name = "Reset Position",
   Callback = function()
      if rootPart then
         rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 5, 0))
      end
   end,
})

FlyTab:CreateParagraph({
   Title = "Controls",
   Content = "WASD - Move | Space - Up | Shift - Down"
})

-- View Tab
ViewTab:CreateToggle({
   Name = "Third Person View",
   CurrentValue = false,
   Flag = "ThirdPerson",
   Callback = function(val)
      setThirdPerson(val)
   end,
})

ViewTab:CreateSlider({
   Name = "Camera Distance",
   Range = {5, 100},
   Increment = 5,
   CurrentValue = 50,
   Flag = "CameraDistance",
   Callback = function(val)
      player.CameraMaxZoomDistance = val
   end,
})

ViewTab:CreateButton({
   Name = "Reset Camera",
   Callback = function()
      camera.CameraType = Enum.CameraType.Custom
      player.CameraMaxZoomDistance = defaultCameraDistance
      player.CameraMinZoomDistance = 0.5
      if humanoid then
         humanoid.CameraOffset = Vector3.new(0, 0, 0)
      end
   end,
})

-- Settings Tab
SettingsTab:CreateSlider({
   Name = "Fling Power",
   Range = {100, 3000},
   Increment = 50,
   CurrentValue = 500,
   Flag = "PowerSlider",
   Callback = function(val)
      flingPower = val
   end,
})

SettingsTab:CreateSlider({
   Name = "Fling Height",
   Range = {10, 300},
   Increment = 10,
   CurrentValue = 50,
   Flag = "HeightSlider",
   Callback = function(val)
      flingHeight = val
   end,
})

SettingsTab:CreateSlider({
   Name = "Rotation Speed",
   Range = {5, 100},
   Increment = 5,
   CurrentValue = 20,
   Flag = "SpinSlider",
   Callback = function(val)
      rotationSpeed = val
      if character then
         local root = getRoot(character)
         if root and root:FindFirstChild("FlingSpinner") then
            root.FlingSpinner.AngularVelocity = Vector3.new(0, rotationSpeed, 0)
         end
      end
   end,
})

SettingsTab:CreateButton({
   Name = "Reset Character",
   Callback = function()
      disableFling()
      disableFly()
      if humanoid then
         humanoid.Health = 0
      end
   end,
})

SettingsTab:CreateButton({
   Name = "Disable All",
   Callback = function()
      disableFling()
      disableFly()
      disableNoClip()
      setThirdPerson(false)
      Rayfield:Notify({
         Title = "Reset",
         Content = "All features disabled!",
         Duration = 2,
         Image = 4483362458,
      })
   end,
})

-- Character respawn handler
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    flingEnabled = false
    flyEnabled = false
    noClipEnabled = false
    
    disableFling()
    disableFly()
end)

-- Initial notification
Rayfield:Notify({
   Title = "Script Loaded",
   Content = "Fling & Fly system ready!",
   Duration = 5,
   Image = 4483362458,
})
