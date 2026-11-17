-- Stealing.luau
-- Brainrot Bandits: the threat. Walk up to a brainrot on another player's
-- base and carry it home -- but you walk slower while you carry, the
-- owner can slap it out of your hands, and a base locks for a while
-- after a steal so nobody is farmed twice in a row.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Stealing = {}

-- Pick a brainrot off someone else's base and carry it.
function Stealing.stealBrainrot(thief, record, economy)
	local ownerWallet = economy.Players[record.Owner]
	if not ownerWallet then
		return false, "No owner"
	end
	if record.Owner == thief then
		return false, "That one is yours"
	end
	if record.CarriedBy ~= nil then
		return false, "Already carried"
	end
	local plot = ownerWallet.Plot
	if plot and plot.LockedUntil and os.time() < plot.LockedUntil then
		return false, "Base is locked!"
	end
	-- Lift it out of its owner's collection and into the thief's hands.
	for i, owned in ipairs(ownerWallet.Brainrots) do
		if owned == record then
			table.remove(ownerWallet.Brainrots, i)
			break
		end
	end
	ownerWallet.OwnedValue.Value = #ownerWallet.Brainrots
	record.Owner = nil
	record.CarriedBy = thief
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if root then
		record.Model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
	end
	-- Lock the victim's base so the next thief has to wait.
	if plot then
		plot.LockedUntil = os.time() + Config.BaseLockSeconds
	end
	return true, "Stolen! Run home!"
end

-- Drop a carried brainrot where the thief stands: the walk home is over.
function Stealing.dropCarried(thief, record, economy)
	local wallet = economy.Players[thief]
	if not wallet or record.CarriedBy ~= thief then
		return false
	end
	record.CarriedBy = nil
	-- If the thief reached their own base, the brainrot is theirs now.
	if wallet.Plot and #wallet.Brainrots < Config.SlotsPerPlot then
		record.Owner = thief
		table.insert(wallet.Brainrots, record)
		wallet.OwnedValue.Value = #wallet.Brainrots
		local pad = wallet.Plot.Slots[#wallet.Brainrots]
		record.Slot = pad
		record.Model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 3, 0)))
		return true, "Secured on your base!"
	end
	-- Otherwise it drops on the floor where it can be picked up again.
	local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if root then
		record.Model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 3, 0)))
	end
	return true, "Dropped!"
end

-- Slap a thief: they drop whatever they are carrying, and you get a
-- breather before they can grab again.
function Stealing.slapThief(slapper, thief, economy)
	local carried = Stealing.carriedBy(thief)
	if not carried then
		return false, "They carry nothing"
	end
	Stealing.dropCarried(thief, carried, economy)
	return true, "Slapped! They dropped it!"
end

-- Find the brainrot a player is currently carrying, if any.
function Stealing.carriedBy(player)
	for _, record in ipairs(require(script.Parent.Spawning).Active) do
		if record.CarriedBy == player then
			return record
		end
	end
	return nil
end

-- How slow a player walks while carrying: 55% speed, from Config.
function Stealing.carrySpeedMultiplier()
	return Config.CarrySlowdown
end

return Stealing
