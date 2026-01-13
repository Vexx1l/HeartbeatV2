-- VERSION: 5.5.5 (PRECISE UPTIME FORMATTING)
-- [FULL SCRIPT: NO SKIPS]

if _G.HeartbeatRunning then _G.HeartbeatRunning = false end
task.wait(0.2)
_G.HeartbeatRunning = true
local SESSION_ID = tick()
_G.CurrentSession = SESSION_ID

local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = game.Players.LocalPlayer

-- 1. CLEANUP
local function deepClean()
    for _, p in pairs({game.CoreGui, player:FindFirstChild("PlayerGui")}) do
        if p then for _, c in pairs(p:GetChildren()) do
            if c.Name == "MonitorGui" or c.Name == "HeartbeatMonitor" then c:Destroy() end
        end end
    end
end
deepClean()

-- 2. GLOBAL & LOCAL SETTINGS
local GLOBAL_FILE = "ForgeHeartbeat_GLOBAL.json"
local LOCAL_FILE = "ForgeHeartbeat_" .. player.Name .. ".json"

local function loadGlobal()
    if isfile and isfile(GLOBAL_FILE) then
        local s, d = pcall(function() return HttpService:JSONDecode(readfile(GLOBAL_FILE)) end)
        if s then return d end
    end
    return {LastBuild = "0"}
end

local function loadLocal()
    local default = {Timer = 600, Webhook = "PASTE_WEBHOOK_HERE", UserID = "958143880291823647"}
    if isfile and isfile(LOCAL_FILE) then
        local s, d = pcall(function() return HttpService:JSONDecode(readfile(LOCAL_FILE)) end)
        if s then return d end
    end
    return default
end

local globalSet = loadGlobal()
local mySettings = loadLocal()
local HEARTBEAT_INTERVAL = mySettings.Timer
local WEBHOOK_URL = mySettings.Webhook
local DISCORD_USER_ID = mySettings.UserID
local startTime = os.time()
local forceRestartLoop = false

-- 3. UPTIME FORMATTER (Match image_710cc8.png)
local function getUptimeString()
    local diff = os.time() - startTime
    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)
    local secs = diff % 60
    return string.format("%dh %dm %ds", hours, mins, secs)
end

-- 4. DYNAMIC DETECTION
local placeNameOverrides = {
    [76558904092080]  = "The Forge (World 1)",
    [129009554587176] = "The Forge (World 2)",
    [131884594917121] = "The Forge (World 3)"
}
local success, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
local currentGameName = placeNameOverrides[game.PlaceId] or (success and info.Name) or "Unknown Game"

-- 5. WEBHOOK ENGINE
local function sendWebhook(title, reason, color, isUpdateLog)
    if WEBHOOK_URL == "" or WEBHOOK_URL == "PASTE_WEBHOOK_HERE" or not _G.HeartbeatRunning then return end
    local content = (not isUpdateLog and title ~= "🔄 Heartbeat") and "<@" .. DISCORD_USER_ID .. ">" or nil
    local embed = {
        title = title,
        color = color or 1752220,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    if isUpdateLog then
        embed.description = "**What's New:**\n" .. reason .. "\n\n*Auto-update log • Build 5.5.5*"
    else
        embed.description = "Status for **" .. player.Name .. "**"
        embed.fields = {
            { name = "🎮 Game", value = currentGameName, inline = false },
            { name = "📊 Session Info", value = "Uptime: " .. getUptimeString(), inline = false }, -- UPDATED FORMAT
            { name = "🔔 Next Update", value = "<t:" .. (os.time() + HEARTBEAT_INTERVAL) .. ":R>", inline = true },
            { name = "💬 Status", value = "```" .. reason .. "```", inline = false }
        }
    end
    
    local payload = HttpService:JSONEncode({ content = content, embeds = {embed} })
    local req = (request or http_request or syn.request)
    if req then pcall(function() req({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end) end
end

-- 6. GLOBAL UPDATE LOG
local CURRENT_BUILD = "5.5.5"
task.spawn(function()
    task.wait(1.5)
    if globalSet.LastBuild ~= CURRENT_BUILD then
        local changelog = "• Updated Session format to 'Uptime: Xh Xm Xs'\n• Improved time calculation logic for long sessions\n• Synced Global settings across accounts"
        sendWebhook("📜 Heartbeat Monitor Updated: " .. CURRENT_BUILD, changelog, 16763904, true)
        
        globalSet.LastBuild = CURRENT_BUILD
        if writefile then writefile(GLOBAL_FILE, HttpService:JSONEncode(globalSet)) end
    end
end)

-- 7. UI CONSTRUCTION
local screenGui = Instance.new("ScreenGui", (game:GetService("CoreGui") or player.PlayerGui))
screenGui.Name = "MonitorGui"; screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 240, 0, 115); mainFrame.Position = UDim2.new(0.5, -120, 0, 15)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); mainFrame.BorderSizePixel = 0; mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", mainFrame); stroke.Color = Color3.fromRGB(0, 170, 255); stroke.Thickness = 2

local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 25, 0, 25); closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.BackgroundTransparency = 1; closeBtn.TextSize = 18; closeBtn.Font = Enum.Font.GothamBold; closeBtn.ZIndex = 20
closeBtn.MouseButton1Click:Connect(function() _G.HeartbeatRunning = false; screenGui:Destroy() end)

local mainView = Instance.new("Frame", mainFrame); mainView.Size = UDim2.new(1,0,1,0); mainView.BackgroundTransparency = 1; mainView.ZIndex = 1

local headerLabel = Instance.new("TextLabel", mainView)
headerLabel.Size = UDim2.new(1, 0, 0.2, 0); headerLabel.Position = UDim2.new(0, 0, 0.08, 0)
headerLabel.TextColor3 = Color3.fromRGB(100, 150, 255); headerLabel.BackgroundTransparency = 1; headerLabel.TextSize = 14; headerLabel.Font = Enum.Font.GothamBold
headerLabel.Text = player.Name .. " (" .. math.floor(HEARTBEAT_INTERVAL/60) .. "m)"

local timerLabel = Instance.new("TextLabel", mainView)
timerLabel.Size = UDim2.new(1, 0, 0.4, 0); timerLabel.Position = UDim2.new(0, 0, 0.25, 0)
timerLabel.Text = "WAITING"; timerLabel.TextColor3 = Color3.fromRGB(0, 170, 255); timerLabel.BackgroundTransparency = 1; timerLabel.TextSize = 32; timerLabel.Font = Enum.Font.GothamBold

-- 8. OVERLAYS & BUTTONS
local function createOverlay(placeholder, accentColor)
    local overlay = Instance.new("Frame", mainFrame); overlay.Size = UDim2.new(1,0,1,0); overlay.BackgroundColor3 = Color3.fromRGB(20, 20, 25); overlay.Visible = false; overlay.ZIndex = 10
    Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 10)
    local back = Instance.new("TextButton", overlay); back.Size = UDim2.new(0, 30, 0, 30); back.Position = UDim2.new(0, 5, 0, 5); back.Text = "↩"; back.TextColor3 = Color3.new(1,1,1); back.BackgroundTransparency = 1; back.TextSize = 24; back.ZIndex = 11
    back.MouseButton1Click:Connect(function() overlay.Visible = false; mainView.Visible = true end)
    local txt = Instance.new("TextBox", overlay); txt.Size = UDim2.new(0.8, 0, 0.3, 0); txt.Position = UDim2.new(0.1, 0, 0.25, 0); txt.PlaceholderText = placeholder; txt.Text = ""; txt.BackgroundColor3 = Color3.fromRGB(35, 35, 45); txt.TextColor3 = Color3.new(1,1,1); txt.TextSize = 11; txt.ZIndex = 11; Instance.new("UICorner", txt).CornerRadius = UDim.new(0, 5)
    local ok = Instance.new("TextButton", overlay); ok.Size = UDim2.new(0.8, 0, 0.25, 0); ok.Position = UDim2.new(0.1, 0, 0.65, 0); ok.Text = "CONFIRM"; ok.BackgroundColor3 = Color3.fromRGB(35, 35, 45); ok.TextColor3 = accentColor; ok.Font = Enum.Font.GothamBold; ok.ZIndex = 11; Instance.new("UICorner", ok).CornerRadius = UDim.new(0, 5)
    return overlay, txt, ok
end

local timeF, timeI, timeO = createOverlay("Minutes (e.g. 5)", Color3.fromRGB(0, 255, 127))
local cfgF, cfgI, cfgO = createOverlay("Webhook URL", Color3.fromRGB(255, 170, 0))
local idF, idI, idO = createOverlay("Discord User ID", Color3.fromRGB(255, 170, 0))

timeO.MouseButton1Click:Connect(function()
    local n = tonumber(timeI.Text); if n then 
        HEARTBEAT_INTERVAL = n * 60; headerLabel.Text = player.Name .. " (" .. n .. "m)"
        mySettings.Timer = HEARTBEAT_INTERVAL; forceRestartLoop = true 
    end
    timeF.Visible = false; mainView.Visible = true; if writefile then writefile(LOCAL_FILE, HttpService:JSONEncode(mySettings)) end
end)

cfgO.MouseButton1Click:Connect(function() mySettings.Webhook = cfgI.Text; WEBHOOK_URL = cfgI.Text; cfgF.Visible = false; idF.Visible = true end)
idO.MouseButton1Click:Connect(function()
    mySettings.UserID = idI.Text; DISCORD_USER_ID = idI.Text; idF.Visible = false; mainView.Visible = true
    if writefile then writefile(LOCAL_FILE, HttpService:JSONEncode(mySettings)) end
    sendWebhook("✅ Config Saved", "Monitor Ready.", 3066993, false)
end)

local function createBtn(name, pos, color)
    local btn = Instance.new("TextButton", mainView); btn.Size = UDim2.new(0.22, 0, 0.25, 0); btn.Position = pos; btn.Text = name; btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); btn.TextColor3 = color; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6); return btn
end

local b1 = createBtn("TIME", UDim2.new(0.03, 0, 0.65, 0), Color3.fromRGB(0, 255, 127))
local b2 = createBtn("CFG", UDim2.new(0.28, 0, 0.65, 0), Color3.fromRGB(255, 170, 0))
local b3 = createBtn("TEST", UDim2.new(0.53, 0, 0.65, 0), Color3.fromRGB(255, 85, 255))
local b4 = createBtn("MIN", UDim2.new(0.78, 0, 0.65, 0), Color3.fromRGB(0, 255, 255))

b1.MouseButton1Click:Connect(function() mainView.Visible = false; timeF.Visible = true end)
b2.MouseButton1Click:Connect(function() mainView.Visible = false; cfgF.Visible = true end)
b3.MouseButton1Click:Connect(function() b3.Text = "..."; sendWebhook("🧪 Test", "Working!", 10181046, false); task.wait(0.5); b3.Text = "TEST" end)

local isMinimized = false
b4.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        pcall(function() mainFrame:TweenSize(UDim2.new(0, 120, 0, 45), "Out", "Quad", 0.2, true) end)
        b1.Visible = false; b2.Visible = false; b3.Visible = false; closeBtn.Visible = false; headerLabel.Visible = false
        timerLabel.Position = UDim2.new(0,0,0,0); timerLabel.Size = UDim2.new(0.7,0,1,0); timerLabel.TextSize = 20
        b4.Size = UDim2.new(0.25,0,0.7,0); b4.Position = UDim2.new(0.72,0,0.15,0)
    else
        pcall(function() mainFrame:TweenSize(UDim2.new(0, 240, 0, 115), "Out", "Quad", 0.2, true) end)
        b1.Visible = true; b2.Visible = true; b3.Visible = true; closeBtn.Visible = true; headerLabel.Visible = true
        timerLabel.Position = UDim2.new(0, 0, 0.25, 0); timerLabel.Size = UDim2.new(1, 0, 0.4, 0); timerLabel.TextSize = 32
        b4.Size = UDim2.new(0.22, 0, 0.25, 0); b4.Position = UDim2.new(0.78, 0, 0.65, 0)
    end
end)

-- 9. KICK DETECTION & DRAG
GuiService.ErrorMessageChanged:Connect(function()
    if _G.HeartbeatRunning and _G.CurrentSession == SESSION_ID then
        local msg = GuiService:GetErrorMessage()
        if msg and #msg > 1 and not msg:lower():find("teleport") then sendWebhook("⚠️ Disconnected", msg, 15548997, false) end
    end
end)

local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = obj.Position end end)
    obj.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end
makeDraggable(mainFrame)

-- 10. MAIN LOOP
task.spawn(function()
    sendWebhook("🔄 Heartbeat", "Monitor Active.", 1752220, false)
    while _G.HeartbeatRunning and _G.CurrentSession == SESSION_ID do
        local timeLeft = HEARTBEAT_INTERVAL
        forceRestartLoop = false
        while timeLeft > 0 and _G.HeartbeatRunning and not forceRestartLoop and _G.CurrentSession == SESSION_ID do
            timerLabel.Text = string.format("%02d:%02d", math.floor(timeLeft/60), timeLeft%60)
            task.wait(1); timeLeft = timeLeft - 1
        end
        if _G.HeartbeatRunning and not forceRestartLoop and _G.CurrentSession == SESSION_ID then
            sendWebhook("🔄 Heartbeat", "Stable.", 1752220, false)
        end
    end
end)
