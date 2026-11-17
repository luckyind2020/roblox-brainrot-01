-- Spawning.luau
-- Brainrot Bandits: the conveyor. A new brainrot steps onto the west end
-- of the belt every few seconds, walks east past the players, and leaves
-- through the east exit if nobody buys it. Each one is a model of colored
-- parts with a floating label: name, rarity and money per second.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local Spawning = {}
Spawning.Active = {} -- the brainrots currently walking the belt

-- A brainrot's body: a chunky colored block with a face of eyes, built
-- from parts so the world needs no uploaded assets.
local function buildBrainrotModel(member, mutationName, rarityColor)
	local model = Instance.new("Model")
	model.Name = BrainrotData.displayName(member, mutationName)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4, 4, 4)
	body.Color = rarityColor
	body.Anchored = true
	body.CanCollide = false
	body.TopSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	-- Two eyes, so every brainrot has a face.
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.8, 1.2, 0.5)
		eye.Position = body.Position + Vector3.new(side * 0.9, 0.6, 2)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
	end

	-- A ClickDetector on the body: clicking buys it off the belt or
	-- steals it off a rival base, decided by the server at click time.
	local detector = Instance.new("ClickDetector")
	detector.Name = "BrainrotClick"
	detector.MaxActivationDistance = 32
	detector.Parent = body
	if member.Rarity == "Legendary" or member.Rarity == "Mythic" or member.Rarity == "God" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(3, 1, 3)
		crown.Position = body.Position + Vector3.new(0, 2.5, 0)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Anchored = true
		crown.CanCollide = false
		crown.Parent = model
	end

	-- The floating label every buyer reads: name, rarity, $/s.
	local label = Instance.new("BillboardGui")
	label.Name = "BrainrotLabel"
	label.Size = UDim2.fromOffset(160, 70)
	label.StudsOffset = Vector3.new(0, 4, 0)
	label.AlwaysOnTop = true
	label.Parent = body
	local name = Instance.new("TextLabel")
	name.Name = "NameLabel"
	name.Size = UDim2.fromScale(1, 0.5)
	name.BackgroundTransparency = 1
	name.Text = BrainrotData.displayName(member, mutationName)
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextScaled = true
	name.Font = Enum.Font.GothamBold
	name.Parent = label
	local rate = Instance.new("TextLabel")
	rate.Name = "RateLabel"
	rate.Size = UDim2.fromScale(1, 0.5)
	rate.Position = UDim2.fromScale(0, 0.5)
	rate.BackgroundTransparency = 1
	rate.Text = BrainrotData.Rarities[member.Rarity].Label
		.. "  $" .. BrainrotData.incomePerSecond(member, mutationName) .. "/s"
	rate.TextColor3 = rarityColor
	rate.TextScaled = true
	rate.Font = Enum.Font.GothamBold
	rate.Parent = label

	return model
end

-- Spawn one brainrot on the belt and walk it east until it is bought,
-- stolen away, or reaches the exit. onClicked(record, clicker) answers
-- every click on it: buy from the belt, steal from a rival base.
function Spawning.spawnBrainrot(world, luckBonus, onClicked)
	local member = BrainrotData.rollCharacter()
	local mutationName = BrainrotData.rollMutation(luckBonus or 0)
	local rarity = BrainrotData.Rarities[member.Rarity]
	local mutation = BrainrotData.Mutations[mutationName]
	local model = buildBrainrotModel(member, mutationName, rarity.Color)
	model.Parent = world.Folder

	local record = {
		Member = member,
		Mutation = mutationName,
		Model = model,
		Income = BrainrotData.incomePerSecond(member, mutationName),
		Price = member.Cost,
		Owner = nil,
		Slot = nil,
		CarriedBy = nil,
	}
	table.insert(Spawning.Active, record)

	-- Clicks on the body go to the server's handler: buy or steal.
	local detector = model.Body:FindFirstChild("BrainrotClick")
	if detector and onClicked then
		detector.MouseClick:Connect(function(clicker)
			onClicked(record, clicker)
		end)
	end

	-- Walk the belt in small steps; the loop ends when the record leaves.
	task.spawn(function()
		local start = world.Waypoints[1]
		local finish = world.Waypoints[2]
		local distance = (finish - start).Magnitude
		local speed = Config.ConveyorWalkSpeed * mutation.Walk
		local walked = 0
		model:PivotTo(CFrame.new(start))
		while record.Owner == nil and record.CarriedBy == nil and walked < distance do
			task.wait(0.1)
			walked += speed * 0.1
			local spot = start:Lerp(finish, math.min(walked / distance, 1))
			model:PivotTo(CFrame.new(spot))
		end
		if record.Owner == nil and record.CarriedBy == nil then
			Spawning.removeBrainrot(record)
		end
	end)

	return record
end

-- Take a brainrot off the belt or out of the world entirely.
function Spawning.removeBrainrot(record)
	for i, other in ipairs(Spawning.Active) do
		if other == record then
			table.remove(Spawning.Active, i)
			break
		end
	end
	if record.Model then
		record.Model:Destroy()
	end
end

-- The belt's heartbeat: keep spawning while there is room on it.
function Spawning.startLoop(world, getLuckBonus, onClicked)
	task.spawn(function()
		while true do
			task.wait(Config.SpawnEverySeconds)
			if #Spawning.Active < Config.MaxOnBelt then
				Spawning.spawnBrainrot(world, getLuckBonus(), onClicked)
			end
		end
	end)
end

return Spawning
