-- Waves.luau
-- Brainrot Bandits: the tsunami. Every three minutes a warning sounds
-- and a wall of water sweeps the map from north to south. Players caught
-- outside their own base are thrown back toward the plaza and drop
-- whatever they are carrying, so a steal always ends in a dash home.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Waves = {}
Waves.NextWaveAt = 0 -- os.time() of the next wave, read by the HUD

-- Throw a player back toward the plaza and make them drop their catch.
local function sweepPlayer(player, stealing, economy)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- Bases sit south (positive Z); the plaza is the safe middle.
	if root.Position.Z < 10 then
		local carried = stealing.carriedBy(player)
		if carried then
			stealing.dropCarried(player, carried, economy)
		end
		root.CFrame = CFrame.new(0, 3, 0)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(10)
		end
	end
end

-- One wave: warn, show the wall, sweep the map, hide the wall.
function Waves.runWave(world, stealing, economy, broadcast)
	Waves.NextWaveAt = os.time() + Config.WaveEverySeconds
	broadcast("TSUNAMI IN " .. Config.WaveWarningSeconds .. "s! GET TO YOUR BASE!")
	task.wait(Config.WaveWarningSeconds)
	broadcast("TSUNAMI! RUN HOME!")
	local wall = world.WaveWall
	wall.Transparency = 0.3
	for z = -110, 110, 4 do
		wall.Position = Vector3.new(0, 13, z)
		task.wait(0.05)
	end
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		sweepPlayer(player, stealing, economy)
	end
	task.wait(2)
	wall.Transparency = 1
	wall.Position = Vector3.new(0, 13, -110)
	broadcast("The wave has passed. Back to the belt!")
end

-- The wave timer runs forever: a wave every three minutes.
function Waves.startLoop(world, stealing, economy, broadcast)
	Waves.NextWaveAt = os.time() + Config.WaveEverySeconds
	task.spawn(function()
		while true do
			task.wait(Config.WaveEverySeconds)
			Waves.runWave(world, stealing, economy, broadcast)
		end
	end)
end

return Waves
