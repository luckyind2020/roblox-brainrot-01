-- World.luau
-- Brainrot Bandits: builds the parts of the 3D world the place file does
-- not hold. The static ground, belt and lamps live in default.project.json;
-- this module raises the player bases, their brainrot slots, the big sign
-- over the plaza and the tsunami wall, and hands the server their spots.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local World = {}

-- Plot centers: two rows of four on the south side of the map.
local PLOT_ROWS = { 20, 70 }
local PLOT_COLS = { -75, -25, 25, 75 }

local function newPart(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- One player base: a colored floor, a back wall, a name pole and 8 slots
-- where bought brainrots stand and earn money.
function World.buildBasePlots(folder)
	local plots = {}
	for row, z in ipairs(PLOT_ROWS) do
		for col, x in ipairs(PLOT_COLS) do
			local index = (row - 1) * 4 + col
			local center = Vector3.new(x, 0.5, z)
			local plot = Instance.new("Folder")
			plot.Name = "Plot" .. index
			plot.Parent = folder

			local floor = newPart("Floor", Vector3.new(Config.PlotSize, 1, Config.PlotSize), center, Color3.fromRGB(120, 200, 120), plot)
			floor.CanCollide = false
			newPart("BackWall", Vector3.new(Config.PlotSize, 8, 1), center + Vector3.new(0, 4, Config.PlotSize / 2), Color3.fromRGB(90, 160, 90), plot)

			-- The pole the owner's name hangs from, filled in on claim.
			local pole = newPart("NamePole", Vector3.new(1, 10, 1), center + Vector3.new(0, 5, -Config.PlotSize / 2), Color3.fromRGB(60, 60, 60), plot)
			local sign = Instance.new("BillboardGui")
			sign.Name = "OwnerSign"
			sign.Size = UDim2.fromOffset(200, 50)
			sign.StudsOffset = Vector3.new(0, 6, 0)
			sign.AlwaysOnTop = true
			sign.Parent = pole
			local label = Instance.new("TextLabel")
			label.Name = "OwnerLabel"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = "FREE BASE"
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.Parent = sign

			-- Eight slots in two rows of four.
			local slots = {}
			for slot = 1, Config.SlotsPerPlot do
				local sx = x - 9 + ((slot - 1) % 4) * 6
				local sz = z - 6 + math.floor((slot - 1) / 4) * 12
				local pad = newPart("Slot" .. slot, Vector3.new(5, 0.5, 5), Vector3.new(sx, 1.25, sz), Color3.fromRGB(220, 220, 180), plot)
				pad.CanCollide = false
				slots[slot] = pad
			end

			plots[index] = {
				Folder = plot,
				Center = center,
				Slots = slots,
				Owner = nil,
				OwnerLabel = label,
			}
		end
	end
	return plots
end

-- The big sign over the central plaza, so the world reads at a glance.
function World.buildPlazaSign(folder)
	local post = newPart("SignPost", Vector3.new(2, 18, 2), Vector3.new(0, 9, 0), Color3.fromRGB(60, 60, 60), folder)
	local board = Instance.new("SurfaceGui")
	board.Name = "TitleBoard"
	board.Face = Enum.NormalId.Front
	board.Parent = post
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
	title.Text = "BRAINROT BANDITS"
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = board
	return post
end

-- The tsunami wall: invisible until a wave comes, then it sweeps the map.
function World.buildWaveWall(folder)
	local wall = newPart("WaveWall", Vector3.new(220, 26, 4), Vector3.new(0, 13, -110), Color3.fromRGB(40, 140, 255), folder)
	wall.Transparency = 1
	wall.CanCollide = false
	wall.CanQuery = false
	return wall
end

-- Conveyor waypoints, west to east, for the brainrots to walk.
function World.conveyorWaypoints()
	return {
		Vector3.new(Config.ConveyorStartX, 2, Config.ConveyorZ),
		Vector3.new(Config.ConveyorEndX, 2, Config.ConveyorZ),
	}
end

-- Build every runtime part and return the handles the services need.
function World.build()
	local folder = Instance.new("Folder")
	folder.Name = "BanditWorld"
	folder.Parent = workspace
	return {
		Folder = folder,
		Plots = World.buildBasePlots(folder),
		Sign = World.buildPlazaSign(folder),
		WaveWall = World.buildWaveWall(folder),
		Waypoints = World.conveyorWaypoints(),
	}
end

return World
