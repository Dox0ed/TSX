--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Configs = ReplicatedStorage.Configs

local TowerConfig = require(Configs.TowerConfig)
local MainConfig = require(Configs.MainConfig)
local DataManager = require(Modules.DataManager)
local TowerManager = require(Modules.TowerManager)

local Remotes = ReplicatedStorage.Remotes
local SummonRemotes = Remotes.Summon

local Cooldown = {}

local ChoosedSummonItems = {}
local CurrentHour = nil

local LuckBoost = 1

local TowersByRarities = {}

--// Class
local SummonManager = {}

for TowerName, Config in TowerConfig do
	if not TowersByRarities[Config.Rarity] then
		TowersByRarities[Config.Rarity] = {}
	end
	
	table.insert(TowersByRarities[Config.Rarity], TowerName)
end

function UpdateSummon(Hour: number)
	local RNG = Random.new(Hour)
	local NewSummonItems = {}

	local function Generate(Rarity)
		local SummonItem = TowersByRarities[Rarity][RNG:NextInteger(1, #TowersByRarities[Rarity])]

		for _, v in pairs(NewSummonItems) do
			local duplicate = v.Tower == SummonItem and v.Rarity == Rarity
			if duplicate then
				repeat
					SummonItem = TowersByRarities[Rarity][RNG:NextInteger(1, #TowersByRarities[Rarity])]
				until SummonItem ~= v.Tower
			end
		end

		if TowerConfig[tostring(SummonItem)].Summon == false then return Generate(Rarity) end

		NewSummonItems[Rarity] = SummonItem
	end

	for Rarity in MainConfig.RarityChances do
		Generate(Rarity)
	end

	Generate = nil

	return NewSummonItems
end

function ChooseTowers(Amount: number, Luck: number)
	local ChoosedTowers = {}
	
	for _ = 1, Amount do
		local Summon = {}

		for Rarity, TowerName in ChoosedSummonItems do
			table.insert(Summon, {TowerName = TowerName, Chance = MainConfig.RarityChances[Rarity]})
		end
		
		table.sort(Summon, function(a, b)
			return a.Chance < b.Chance
		end)

		local PlrChance = Random.new():NextNumber(0, 100)
		local TowerChosen = nil

		for _, TowerData in ipairs(Summon) do
			local TowerName = TowerData.TowerName
			local Chance = TowerData.Chance
			
			PlrChance -= Chance * Luck * LuckBoost
			if PlrChance < 0 then
				TowerChosen = TowerName
				break
			end
		end

		if not TowerChosen then TowerChosen = ChoosedSummonItems["Common"] end

		table.insert(ChoosedTowers, TowerChosen)
	end
	
	return ChoosedTowers
end

function SummonManager.Summon(Player: Player?, Amount: number, Banner: string?)
	if not Player or Cooldown[Player] then
		return
	end
	
	if not Banner then
		Banner = "Default"
	end
	
	local PlrData = DataManager.Profiles[Player.UserId].Profile
	if not PlrData or not PlrData.Data then
		return
	end
	
	if Amount ~= 1 and Amount ~= 10 then
		return
	end
	
	local Price = if Amount == 1 then 100 else 900
	if Banner == "Boosted" then Price *= 3 end
	if PlrData.Data.Cash < Price then
		return
	end
	
	PlrData.Data.Cash -= Price
	
	task.delay(2, function()
		Cooldown[Player] = nil
	end)
	
	local ChoosedTowers = ChooseTowers(Amount, if Banner == "Boosted" then PlrData.Data.Stats.Luck * 2 else PlrData.Data.Stats.Luck)
	
	for _, TowerName in ChoosedTowers do
		TowerManager.AddTower(Player, TowerName, 1, nil)
	end
	
	DataManager.Profiles[Player.UserId].Replica:Set({"Cash"}, PlrData.Data.Cash)
	SummonRemotes.AskSummon:FireClient(Player, ChoosedTowers)
	return true
end

SummonRemotes.AskSummon.OnServerEvent:Connect(function()
	SummonRemotes.Summon:FireAllClients(ChoosedSummonItems)
end)

task.spawn(function()
	while true do
		local Hour = math.floor(os.time() / (60 * 60))
		local T = (math.floor(os.time()))
		local Daypass = T % 3600
		local Timeleft = 3600 - Daypass

		if Hour ~= CurrentHour then
			CurrentHour = Hour
			ChoosedSummonItems = UpdateSummon(Hour) 
			SummonRemotes.Summon:FireAllClients(ChoosedSummonItems)
		end
		task.wait(1)
	end
end)

return SummonManager
