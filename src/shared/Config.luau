-- Config.luau
-- Brainrot Bandits: every tuning number for the game in one place.
-- The server reads these; the client reads the ones it needs for labels.
-- Change a number here and the whole game retunes: spawn rates, money,
-- wave timing, steal rules, rebirth costs and upgrade prices.

local Config = {}

-- Money
Config.StartMoney = 100 -- cash a new player joins with
Config.MaxMoney = 10_000_000_000 -- hard cap so leaderstats never overflows

-- Conveyor: brainrots walk from the west spawn pad to the east exit.
Config.ConveyorStartX = -90
Config.ConveyorEndX = 90
Config.ConveyorZ = -40
Config.ConveyorWalkSpeed = 6 -- studs per second, before mutation slows it
Config.SpawnEverySeconds = 4 -- a new brainrot steps onto the belt
Config.MaxOnBelt = 14 -- the belt never holds more than this

-- Bases: 8 plots, each with 8 slots for brainrots.
Config.PlotCount = 8
Config.SlotsPerPlot = 8
Config.PlotSize = 24 -- studs square

-- Stealing
Config.CarrySlowdown = 0.55 -- carrying a brainrot slows you to 55% speed
Config.SlapCooldownSeconds = 5 -- slapping an enemy drops what they carry
Config.BaseLockSeconds = 45 -- a base locks for this long after a steal
Config.LockCooldownSeconds = 90 -- and cannot lock again until this passes

-- Tsunami: the wave that sweeps the map and sends everyone home.
Config.WaveEverySeconds = 180 -- a wave rolls in every 3 minutes
Config.WaveWarningSeconds = 12 -- the warning horn sounds this long first
Config.WaveKnockback = 60 -- studs a caught player is thrown

-- Rebirth: cash in your total earnings for a permanent income boost.
Config.RebirthCost = 100_000 -- total earned needed for the next rebirth
Config.RebirthBonus = 0.25 -- +25% income per rebirth, stacking

-- Upgrades, bought with cash from the shop.
Config.Upgrades = {
	SpeedBoots = { Name = "Speed Boots", Cost = 2_500, WalkBoost = 4 },
	BigSlap = { Name = "Big Slap", Cost = 5_000, SlapCut = 2 },
	ExtraSlot = { Name = "Extra Slot", Cost = 15_000, Slots = 2 },
	GoldenMagnet = { Name = "Golden Magnet", Cost = 40_000, Luck = 0.05 },
}

-- Income ticks once a second for every brainrot on a base.
Config.IncomeTickSeconds = 1

return Config
