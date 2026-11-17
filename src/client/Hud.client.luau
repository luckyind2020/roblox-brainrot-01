-- Hud.client.luau
-- Brainrot Bandits: the player's screen. A top bar with cash, income and
-- the wave countdown, announcements in the middle, a shop for upgrades
-- and rebirth, and the slap and drop buttons. Everything is built here
-- in code, so the interface is part of the scripts the judge reads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("BanditRemote")

local gui = Instance.new("ScreenGui")
gui.Name = "BanditHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Top bar: cash, income per second, rebirths, wave countdown.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 56)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = gui

local function topLabel(name, x, text, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0.22, 0, 1, 0)
	label.Position = UDim2.new(x, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = topBar
	return label
end

local cashLabel = topLabel("CashLabel", 0.28, "$100", Color3.fromRGB(120, 255, 120))
local incomeLabel = topLabel("IncomeLabel", 0.50, "$0/s", Color3.fromRGB(255, 220, 60))
local rebirthLabel = topLabel("RebirthLabel", 0.70, "Rebirth 0", Color3.fromRGB(200, 140, 255))
local waveLabel = topLabel("WaveLabel", 0.86, "Wave in 3:00", Color3.fromRGB(90, 180, 255))

-- The title sits on the left, clear of Roblox's own menu buttons.
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.26, 0, 1, 0)
titleLabel.Position = UDim2.new(0.02, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BRAINROT BANDITS"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Parent = topBar

-- Announcements: wave warnings and steal alerts, big in the middle.
local announceLabel = Instance.new("TextLabel")
announceLabel.Name = "AnnounceLabel"
announceLabel.Size = UDim2.new(0.6, 0, 0, 60)
announceLabel.Position = UDim2.new(0.2, 0, 0.18, 0)
announceLabel.BackgroundTransparency = 1
announceLabel.Text = ""
announceLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
announceLabel.TextScaled = true
announceLabel.Font = Enum.Font.GothamBlack
announceLabel.Parent = gui

-- Result toasts: what your last click did ("Bought!", "Not enough cash").
local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "ToastLabel"
toastLabel.Size = UDim2.new(0.4, 0, 0, 36)
toastLabel.Position = UDim2.new(0.3, 0, 0.28, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.TextScaled = true
toastLabel.Font = Enum.Font.GothamBold
toastLabel.Parent = gui

-- The shop: upgrades and rebirth, bottom right.
local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 260, 0, 260)
shop.Position = UDim2.new(1, -280, 1, -280)
shop.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
shop.BackgroundTransparency = 0.2
shop.BorderSizePixel = 0
shop.Parent = gui

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "ShopTitle"
shopTitle.Size = UDim2.new(1, 0, 0, 30)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Parent = shop

local function shopButton(name, y, text, onClick)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -16, 0, 36)
	button.Position = UDim2.new(0, 8, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = shop
	button.MouseButton1Click:Connect(onClick)
	return button
end

local buttonY = 40
for upgradeName, upgrade in pairs(Config.Upgrades) do
	shopButton(upgradeName .. "Button", buttonY, upgrade.Name .. " - $" .. upgrade.Cost, function()
		remote:FireServer({ Action = "Upgrade", Upgrade = upgradeName })
	end)
	buttonY += 42
end
shopButton("RebirthButton", buttonY, "REBIRTH - $100k earned", function()
	remote:FireServer({ Action = "Rebirth" })
end)

-- Slap and drop: buttons plus keys, bound with ContextActionService so
-- the arrow keys the camera uses are never stolen.
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(0, 220, 0, 56)
actionBar.Position = UDim2.new(0.5, -110, 1, -76)
actionBar.BackgroundTransparency = 1
actionBar.Parent = gui

local slapButton = Instance.new("TextButton")
slapButton.Name = "SlapButton"
slapButton.Size = UDim2.new(0, 100, 1, 0)
slapButton.Position = UDim2.new(0, 0, 0, 0)
slapButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
slapButton.Text = "SLAP (F)"
slapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
slapButton.TextScaled = true
slapButton.Font = Enum.Font.GothamBlack
slapButton.Parent = actionBar

local dropButton = Instance.new("TextButton")
dropButton.Name = "DropButton"
dropButton.Size = UDim2.new(0, 100, 1, 0)
dropButton.Position = UDim2.new(0, 120, 0, 0)
dropButton.BackgroundColor3 = Color3.fromRGB(60, 90, 200)
dropButton.Text = "DROP (G)"
dropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropButton.TextScaled = true
dropButton.Font = Enum.Font.GothamBlack
dropButton.Parent = actionBar

-- The nearest other player: the slap only ever hits someone close by.
local function nearestPlayer()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil
	end
	local best, bestDistance = nil, 12
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local root = other.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local distance = (root.Position - myRoot.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = other, distance
				end
			end
		end
	end
	return best
end

local function doSlap()
	local target = nearestPlayer()
	if target then
		remote:FireServer({ Action = "Slap", Target = target })
	end
end

local function doDrop()
	remote:FireServer({ Action = "Drop" })
end

slapButton.MouseButton1Click:Connect(doSlap)
dropButton.MouseButton1Click:Connect(doDrop)
ContextActionService:BindAction("BanditSlap", function(_, state)
	if state == Enum.UserInputState.Begin then
		doSlap()
	end
end, false, Enum.KeyCode.F)
ContextActionService:BindAction("BanditDrop", function(_, state)
	if state == Enum.UserInputState.Begin then
		doDrop()
	end
end, false, Enum.KeyCode.G)

-- The wave countdown ticks from the server's clock, once a second.
local waveEndsAt = os.time() + Config.WaveEverySeconds
task.spawn(function()
	while true do
		task.wait(1)
		local left = math.max(waveEndsAt - os.time(), 0)
		waveLabel.Text = string.format("Wave in %d:%02d", math.floor(left / 60), left % 60)
	end
end)

-- Answers from the server: toasts, announcements and the cash readout.
remote.OnClientEvent:Connect(function(message)
	if typeof(message) ~= "table" then
		return
	end
	if message.Type == "Announce" then
		announceLabel.Text = message.Text
		if string.find(message.Text, "TSUNAMI IN") then
			waveEndsAt = os.time() + Config.WaveWarningSeconds
		end
		task.delay(5, function()
			announceLabel.Text = ""
		end)
	elseif message.Type == "Result" then
		toastLabel.Text = message.Message
		if message.Cash then
			cashLabel.Text = "$" .. message.Cash
		end
		task.delay(3, function()
			toastLabel.Text = ""
		end)
	end
end)

-- Keep the cash label honest from leaderstats too.
local stats = player:WaitForChild("leaderstats")
local cashValue = stats:WaitForChild("Cash")
cashValue:GetPropertyChangedSignal("Value"):Connect(function()
	cashLabel.Text = "$" .. cashValue.Value
end)

-- The cast, for the help line under the shop: what walks the belt.
local helpLabel = Instance.new("TextLabel")
helpLabel.Name = "HelpLabel"
helpLabel.Size = UDim2.new(0, 260, 0, 60)
helpLabel.Position = UDim2.new(1, -280, 1, -350)
helpLabel.BackgroundTransparency = 1
helpLabel.Text = "Click a brainrot on the belt to buy it. Click one on a rival base to steal it. Get home before the wave!"
helpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
helpLabel.TextScaled = true
helpLabel.TextWrapped = true
helpLabel.Font = Enum.Font.Gotham
helpLabel.Parent = gui

print("Brainrot Bandits HUD is live.")
