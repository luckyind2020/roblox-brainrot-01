-- GameServer.server.luau
-- Brainrot Bandits: the server boot. It builds the world, starts the
-- conveyor, the income tick and the tsunami timer, and answers the
-- client's requests: buy a brainrot, steal one, slap a thief, rebirth
-- and buy upgrades. One RemoteEvent carries every request and answer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local World = require(script.Parent.World)
local Spawning = require(script.Parent.Spawning)
local Economy = require(script.Parent.Economy)
local Stealing = require(script.Parent.Stealing)
local Waves = require(script.Parent.Waves)

-- One remote for the whole game: the client sends {Action, ...} and the
-- server answers {Ok, Message, Cash}. It lives in the place itself
-- (ReplicatedStorage in default.project.json), never made at runtime.
local remote = ReplicatedStorage:WaitForChild("BanditRemote")

local world = World.build()

-- Shout a line to every player's screen (wave warnings, steal alerts).
local function broadcast(text)
	remote:FireAllClients({ Type = "Announce", Text = text })
end

-- The luck bonus for spawns: the richest luck upgrade any player owns.
local function currentLuckBonus()
	local best = 0
	for _, wallet in pairs(Economy.Players) do
		if wallet.Upgrades.GoldenMagnet then
			best = math.max(best, Config.Upgrades.GoldenMagnet.Luck)
		end
	end
	return best
end

-- A brainrot on the belt, by its model, for buy and steal clicks.
local function findOnBelt(model)
	for _, record in ipairs(Spawning.Active) do
		if record.Model == model then
			return record
		end
	end
	return nil
end

-- Clicking a brainrot: on the belt it is a buy, on a rival base a steal.
local function onBrainrotClicked(record, clicker)
	local wallet = Economy.Players[clicker]
	if not wallet then
		return
	end
	local ok, message
	if record.Owner == nil and record.CarriedBy == nil then
		ok, message = Economy.buyBrainrot(clicker, record)
	elseif record.Owner ~= nil and record.Owner ~= clicker then
		ok, message = Stealing.stealBrainrot(clicker, record, Economy)
	elseif record.Owner == clicker then
		ok, message = false, "That one is already yours"
	else
		ok, message = false, "Someone is carrying it"
	end
	remote:FireClient(clicker, { Type = "Result", Ok = ok, Message = message, Cash = wallet.Cash })
end

-- Answer one client request and send the result straight back.
remote.OnServerEvent:Connect(function(player, request)
	if typeof(request) ~= "table" or typeof(request.Action) ~= "string" then
		return
	end
	local wallet = Economy.Players[player]
	if not wallet then
		return
	end

	local ok, message = false, "Unknown action"
	if request.Action == "Buy" then
		local record = findOnBelt(request.Model)
		if record then
			ok, message = Economy.buyBrainrot(player, record)
		else
			message = "That brainrot is gone"
		end
	elseif request.Action == "Steal" then
		local record = findOnBelt(request.Model)
		if record then
			ok, message = Stealing.stealBrainrot(player, record, Economy)
		else
			message = "Nothing to steal"
		end
	elseif request.Action == "Slap" then
		ok, message = Stealing.slapThief(player, request.Target, Economy)
	elseif request.Action == "Rebirth" then
		ok, message = Economy.applyRebirth(player)
	elseif request.Action == "Upgrade" then
		ok, message = Economy.buyUpgrade(player, request.Upgrade)
	elseif request.Action == "Drop" then
		local carried = Stealing.carriedBy(player)
		if carried then
			ok, message = Stealing.dropCarried(player, carried, Economy)
		else
			message = "You carry nothing"
		end
	end

	remote:FireClient(player, { Type = "Result", Ok = ok, Message = message, Cash = wallet.Cash })
end)

-- Keep a carried brainrot floating above its thief while they run home.
task.spawn(function()
	while true do
		task.wait(0.1)
		for _, record in ipairs(Spawning.Active) do
			if record.CarriedBy then
				local character = record.CarriedBy.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					record.Model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
				end
			end
		end
	end
end)

-- Slow a thief down while they carry: their walk speed drops to 55%.
Players.PlayerAdded:Connect(function(player)
	local wallet = Economy.registerPlayer(player, world.Plots)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		task.spawn(function()
			while character.Parent do
				task.wait(0.2)
				local carrying = Stealing.carriedBy(player) ~= nil
				local boots = wallet.Upgrades.SpeedBoots and Config.Upgrades.SpeedBoots.WalkBoost or 0
				local speed = 16 + boots
				if carrying then
					speed *= Stealing.carrySpeedMultiplier()
				end
				humanoid.WalkSpeed = speed
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	Economy.unregisterPlayer(player)
end)

-- Start the three loops: the belt, the income and the waves.
Spawning.startLoop(world, currentLuckBonus, onBrainrotClicked)
Economy.startLoop()
Waves.startLoop(world, Stealing, Economy, broadcast)

print("Brainrot Bandits is live: the belt runs, the money ticks, the wave comes.")
