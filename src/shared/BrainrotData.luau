-- BrainrotData.luau
-- Brainrot Bandits: the cast. Twelve absurd, meme-born characters on a
-- ladder of six rarities, each earning money every second, plus four
-- mutations that multiply income and change how they walk the belt.
-- The server spawns from these tables; the client reads them for labels.

local BrainrotData = {}

-- Rarity ladder: weight is the spawn chance, color is the label color.
BrainrotData.Rarities = {
	Common = { Weight = 46, Color = Color3.fromRGB(180, 180, 180), Label = "COMMON" },
	Rare = { Weight = 26, Color = Color3.fromRGB(80, 160, 255), Label = "RARE" },
	Epic = { Weight = 14, Color = Color3.fromRGB(170, 90, 255), Label = "EPIC" },
	Legendary = { Weight = 8, Color = Color3.fromRGB(255, 180, 40), Label = "LEGENDARY" },
	Mythic = { Weight = 4, Color = Color3.fromRGB(255, 70, 120), Label = "MYTHIC" },
	God = { Weight = 2, Color = Color3.fromRGB(255, 230, 90), Label = "BRAINROT GOD" },
}

-- The cast: Name, Rarity, Cost to buy, Income per second.
-- Names and jokes are the game's own; nothing here copies another game.
BrainrotData.Cast = {
	{ Name = "Noodle Ned", Rarity = "Common", Cost = 25, Income = 5 },
	{ Name = "Sir Puddleduck", Rarity = "Common", Cost = 40, Income = 8 },
	{ Name = "Captain Toilet Roll", Rarity = "Rare", Cost = 150, Income = 20 },
	{ Name = "DJ Pickle", Rarity = "Rare", Cost = 250, Income = 30 },
	{ Name = "Professor Banana Peel", Rarity = "Epic", Cost = 800, Income = 75 },
	{ Name = "Queen Left Sock", Rarity = "Epic", Cost = 1500, Income = 120 },
	{ Name = "Grandma WiFi", Rarity = "Legendary", Cost = 5000, Income = 300 },
	{ Name = "Lord Croissant", Rarity = "Legendary", Cost = 9000, Income = 500 },
	{ Name = "Toaster of Destiny", Rarity = "Mythic", Cost = 30000, Income = 1500 },
	{ Name = "The Honking Goose", Rarity = "Mythic", Cost = 60000, Income = 2500 },
	{ Name = "Sir Reginald Noodle", Rarity = "God", Cost = 250000, Income = 10000 },
	{ Name = "The Almighty Soggy Cereal", Rarity = "God", Cost = 1000000, Income = 25000 },
}

-- Mutations: a brainrot can spawn mutated for multiplied income.
-- Frozen walks slower; the rest walk as usual.
BrainrotData.Mutations = {
	None = { Weight = 78, Multiplier = 1, Label = "", Walk = 1 },
	Golden = { Weight = 10, Multiplier = 2, Label = "GOLDEN", Walk = 1 },
	Frozen = { Weight = 5, Multiplier = 3, Label = "FROZEN", Walk = 0.6 },
	Lava = { Weight = 4, Multiplier = 7, Label = "LAVA", Walk = 1 },
	Rainbow = { Weight = 3, Multiplier = 10, Label = "RAINBOW", Walk = 1 },
}

-- Pick one entry from a weighted table: {Key = {Weight = n}}.
function BrainrotData.pickWeighted(weighted)
	local total = 0
	for _, entry in pairs(weighted) do
		total += entry.Weight
	end
	local roll = math.random() * total
	for key, entry in pairs(weighted) do
		roll -= entry.Weight
		if roll <= 0 then
			return key
		end
	end
	return next(weighted)
end

-- Roll a random cast member, weighted by its rarity.
function BrainrotData.rollCharacter()
	local rarity = BrainrotData.pickWeighted(BrainrotData.Rarities)
	local pool = {}
	for _, member in ipairs(BrainrotData.Cast) do
		if member.Rarity == rarity then
			table.insert(pool, member)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation for a spawn. Golden Magnet adds luck toward Rainbow.
function BrainrotData.rollMutation(luckBonus)
	local table_ = {}
	for name, mutation in pairs(BrainrotData.Mutations) do
		local entry = { Weight = mutation.Weight, Multiplier = mutation.Multiplier }
		if name == "Rainbow" then
			entry.Weight += (luckBonus or 0) * 100
		end
		table_[name] = entry
	end
	return BrainrotData.pickWeighted(table_)
end

-- The income a brainrot earns per second, with its mutation applied.
function BrainrotData.incomePerSecond(member, mutationName)
	local mutation = BrainrotData.Mutations[mutationName] or BrainrotData.Mutations.None
	return member.Income * mutation.Multiplier
end

-- The display name on the label above a brainrot.
function BrainrotData.displayName(member, mutationName)
	local mutation = BrainrotData.Mutations[mutationName] or BrainrotData.Mutations.None
	if mutation.Label == "" then
		return member.Name
	end
	return mutation.Label .. " " .. member.Name
end

return BrainrotData
