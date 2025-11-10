-- Rayfield Fling Script
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fling Script",
   LoadingTitle = "Loading Fling System",
   LoadingSubtitle = "by Claude",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "FlingConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})

-- Variables
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local flingEnabled = false
local flingPower = 500
local flingHeight = 50
local autoFling = false
local targetPlayer = nil
local rotationSpeed = 20

-- Functions
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

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
    
    -- Create spinning attachment
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
        if v:IsA("BasePart") then
            v.CanCollide = true
            v.Massless = false
        end
    end
    
    flingEnabled = false
end

local function flingPlayer(targetChar)
    if not character or not targetChar then return end
    
    local root = getRoot(character)
    local targetRoot = getRoot(targetChar)
    
    if not root or not targetRoot then return end
    
    -- Position near target
    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    
    task.wait(0.1)
    
    -- Apply velocity
    local bodyVel = Instance.new("BodyVelocity", targetRoot)
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.new(0, flingHeight, 0) + (targetRoot.CFrame.LookVector * flingPower)
    
    game:GetService("Debris"):AddItem(bodyVel, 0.25)
end

local function flingAllPlayers()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            flingPlayer(plr.Character)
            task.wait(0.3)
        end
    end
end

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local TargetTab = Window:CreateTab("Targeting", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Main Tab
local FlingToggle = MainTab:CreateToggle({
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

MainTab:CreateButton({
   Name = "Fling All Players",
   Callback = function()
      if flingEnabled then
         flingAllPlayers()
      else
         Rayfield:Notify({
            Title = "Fling Disabled",
            Content = "Enable fling mode first!",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

MainTab:CreateButton({
   Name = "Reset Character",
   Callback = function()
      disableFling()
      humanoid.Health = 0
   end,
})

local AutoFlingToggle = MainTab:CreateToggle({
   Name = "Auto Fling (Spam)",
   CurrentValue = false,
   Flag = "AutoFling",
   Callback = function(val)
      autoFling = val
      if val then
         spawn(function()
            while autoFling and flingEnabled do
               flingAllPlayers()
               task.wait(2)
            end
         end)
      end
   end,
})

-- Target Tab
local PlayerList = {}
for _, plr in pairs(game.Players:GetPlayers()) do
    if plr ~= player then
        table.insert(PlayerList, plr.Name)
    end
end

local TargetDropdown = TargetTab:CreateDropdown({
   Name = "Select Target",
   Options = PlayerList,
   CurrentOption = {"None"},
   MultipleOptions = false,
   Flag = "TargetDropdown",
   Callback = function(option)
      targetPlayer = game.Players:FindFirstChild(option[1])
   end,
})

TargetTab:CreateButton({
   Name = "Fling Selected Target",
   Callback = function()
      if targetPlayer and targetPlayer.Character and flingEnabled then
         flingPlayer(targetPlayer.Character)
      else
         Rayfield:Notify({
            Title = "Error",
            Content = "Select a target and enable fling mode!",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

TargetTab:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      local newList = {}
      for _, plr in pairs(game.Players:GetPlayers()) do
         if plr ~= player then
            table.insert(newList, plr.Name)
         end
      end
      TargetDropdown:Refresh(newList)
   end,
})

-- Settings Tab
local PowerSlider = SettingsTab:CreateSlider({
   Name = "Fling Power",
   Range = {100, 2000},
   Increment = 50,
   CurrentValue = 500,
   Flag = "PowerSlider",
   Callback = function(val)
      flingPower = val
   end,
})

local HeightSlider = SettingsTab:CreateSlider({
   Name = "Fling Height",
   Range = {10, 200},
   Increment = 10,
   CurrentValue = 50,
   Flag = "HeightSlider",
   Callback = function(val)
      flingHeight = val
   end,
})

local SpinSlider = SettingsTab:CreateSlider({
   Name = "Rotation Speed",
   Range = {5, 50},
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

-- Character respawn handler
player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    flingEnabled = false
    FlingToggle:Set(false)
end)

Rayfield:Notify({
   Title = "Fling Script Loaded",
   Content = "Enable fling mode and start flinging!",
   Duration = 5,
   Image = 4483362458,
})
