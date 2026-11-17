-- Economy.luau
-- Brainrot Bandits: money. Every brainrot on a base earns its rate once
-- a second; players spend cash on brainrots, upgrades and rebirths.
-- One table per player holds their cash, total earned, rebirths, upgrades
-- and plot, and leaderstats mirrors cash for the leaderboard.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Economy = {}
Economy.Players = {} -- [Player] = {Cash, Earned, Rebirths, Upgrades, Plot}

-- Hand a joining player their wallet, their leaderstats and a free plot.
function Economy.registerPlayer(player, plots)
	local wallet = {
		Cash = Config.StartMoney,
		Earned = 0,
		Rebirths = 0,
		Upgrades = {},
		Plot = nil,
		Brainrots = {},
	}
	for _, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player
			plot.OwnerLabel.Text = player.Name .. "'s BASE"
			wallet.Plot = plot
			break
		end
	end
	Economy.Players[player] = wallet

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = wallet.Cash
	cash.Parent = stats
	local owned = Instance.new("IntValue")
	owned.Name = "Brainrots"
	owned.Value = 0
	owned.Parent = stats
	wallet.CashValue = cash
	wallet.OwnedValue = owned
	return wallet
end

-- Give a player back their plot when they leave.
function Economy.unregisterPlayer(player)
	local wallet = Economy.Players[player]
	if wallet and wallet.Plot then
		wallet.Plot.Owner = nil
		wallet.Plot.OwnerLabel.Text = "FREE BASE"
	end
	Economy.Players[player] = nil
end

-- The income multiplier from rebirths: +25% each, stacking.
function Economy.incomeMultiplier(wallet)
	return 1 + wallet.Rebirths * Config.RebirthBonus
end

-- Pay out one second of income for every brainrot on the player's base.
function Economy.tickIncome()
	for player, wallet in pairs(Economy.Players) do
		local perSecond = 0
		for _, record in ipairs(wallet.Brainrots) do
			perSecond += record.Income
		end
		local earned = math.floor(perSecond * Economy.incomeMultiplier(wallet))
		if earned > 0 then
			Economy.addCash(player, earned)
			wallet.Earned += earned
		end
	end
end

-- Add cash (and total earned), clamped to the cap.
function Economy.addCash(player, amount)
	local wallet = Economy.Players[player]
	if not wallet then
		return
	end
	wallet.Cash = math.min(wallet.Cash + amount, Config.MaxMoney)
	wallet.CashValue.Value = wallet.Cash
end

-- Take cash if the player can afford it; false when they cannot.
function Economy.spendCash(player, amount)
	local wallet = Economy.Players[player]
	if not wallet or wallet.Cash < amount then
		return false
	end
	wallet.Cash -= amount
	wallet.CashValue.Value = wallet.Cash
	return true
end

-- Buy a brainrot off the belt: pay its price, walk it to a free slot.
function Economy.buyBrainrot(player, record)
	local wallet = Economy.Players[player]
	if not wallet or not wallet.Plot then
		return false, "No base yet"
	end
	if record.Owner ~= nil or record.CarriedBy ~= nil then
		return false, "Already taken"
	end
	if #wallet.Brainrots >= Config.SlotsPerPlot + (wallet.Upgrades.ExtraSlot and 2 or 0) then
		return false, "Base is full"
	end
	if not Economy.spendCash(player, record.Price) then
		return false, "Not enough cash"
	end
	record.Owner = player
	table.insert(wallet.Brainrots, record)
	wallet.OwnedValue.Value = #wallet.Brainrots
	local slot = wallet.Brainrots
	local pad = wallet.Plot.Slots[#slot]
	record.Slot = pad
	record.Model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 3, 0)))
	return true, "Bought!"
end

-- Rebirth: cash in total earnings for a permanent +25% income boost.
function Economy.applyRebirth(player)
	local wallet = Economy.Players[player]
	if not wallet then
		return false, "No wallet"
	end
	local cost = Config.RebirthCost * (wallet.Rebirths + 1)
	if wallet.Earned < cost then
		return false, "Need $" .. cost .. " earned"
	end
	wallet.Rebirths += 1
	wallet.Cash = Config.StartMoney
	wallet.CashValue.Value = wallet.Cash
	-- The brainrots stay; only the cash resets, so the climb continues.
	return true, "Rebirth " .. wallet.Rebirths .. "! Income x" .. Economy.incomeMultiplier(wallet)
end

-- Buy an upgrade from the shop.
function Economy.buyUpgrade(player, upgradeName)
	local wallet = Economy.Players[player]
	local upgrade = Config.Upgrades[upgradeName]
	if not wallet or not upgrade then
		return false, "No such upgrade"
	end
	if wallet.Upgrades[upgradeName] then
		return false, "Already owned"
	end
	if not Economy.spendCash(player, upgrade.Cost) then
		return false, "Not enough cash"
	end
	wallet.Upgrades[upgradeName] = true
	return true, upgrade.Name .. " bought!"
end

-- The income tick runs forever, once a second.
function Economy.startLoop()
	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickSeconds)
			Economy.tickIncome()
		end
	end)
end

return Economy
