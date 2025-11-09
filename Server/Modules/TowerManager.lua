--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Configs = ReplicatedStorage.Configs

local TowerConfig = require(Configs.TowerConfig)
local MainConfig = require(Configs.MainConfig)
local DataManager = require(Modules.DataManager)

local DecreaseExistEvent = ServerScriptService:WaitForChild("Exist"):WaitForChild("DecreaseExist")

--// LFuncs
local function GenerateID(Towers): number
	local ID = HttpService:GenerateGUID(false)
	
	while Towers[ID] do
		ID = HttpService:GenerateGUID(false)
	end
	
	return ID
end

--// Class
local TowerManager = {}

function TowerManager.AddTower(Player: Player?, Name: string, Amount: number, OtherSettings: any)
	if not Player then
		return
	end
	
	local PlrData = DataManager.Profiles[Player.UserId].Profile
	if not PlrData or not PlrData.Data then
		return
	end
	
	local ID = nil
	for _ = 1, Amount do
		ID = GenerateID(PlrData.Data.Towers)

		PlrData.Data.Towers[ID] = {
			Name = Name,
			Settings = OtherSettings
		}
	end
	
	DataManager.Profiles[Player.UserId].Replica:Set({"Towers"}, PlrData.Data.Towers)
	return ID
end

function TowerManager.RemoveTower(Player: Player?, SellTable, GiveCash: boolean)
	if not Player then
		return
	end
	
	local PlrData = DataManager.Profiles[Player.UserId].Profile
	if not PlrData or not PlrData.Data then
		return
	end
	
	for TowerName, Stack in SellTable do
		if Stack < 1 then
			return
		end
		
		local RealStack = 0
		for _ = Stack, 1, -1 do
			for ID, Tower in PlrData.Data.Towers do
				if Tower.Name == TowerName then
					PlrData.Data.Towers[ID] = nil
					RealStack += 1
					break
				end
			end
		end
		
		if GiveCash then
			local TowerConfig = TowerConfig[TowerName]
			if not TowerConfig then
				return
			end

			PlrData.Data.Cash += (MainConfig.SellPrices[TowerConfig.Rarity] * RealStack)
			DecreaseExistEvent:Fire(TowerName, RealStack)
		end
	end
	
	DataManager.Profiles[Player.UserId].Replica:Set({"Cash"}, PlrData.Data.Cash)
	DataManager.Profiles[Player.UserId].Replica:Set({"Towers"}, PlrData.Data.Towers)
	return true
end

function TowerManager.EquipTower(Player: Player?, ID: string)
	if not Player then
		return
	end

	local PlrData = DataManager.Profiles[Player.UserId].Profile
	if not PlrData or not PlrData.Data then
		return
	end
	
	if ID == "UnequipAll" then
		for id, Tower in PlrData.Data.Towers do
			if Tower.Equipped  then
				PlrData.Data.Towers[id].Equipped = false
				DataManager.Profiles[Player.UserId].Replica:Set({"Towers", id}, PlrData.Data.Towers[id])
			end
		end
		
		DataManager.Profiles[Player.UserId].Replica:Set({"Towers"}, PlrData.Data.Towers)
		return true
	end
	
	if not PlrData.Data.Towers[ID] then
		return
	end
	
	if PlrData.Data.Towers[ID]["Equipped"] then
		PlrData.Data.Towers[ID].Equipped = nil
	else
		local TowerName = PlrData.Data.Towers[ID].Name
		for _, Tower in PlrData.Data.Towers do
			if Tower.Name == TowerName and Tower["Equipped"] then
				return false
			end
		end
		
		local SlotNum = false
		local Used = {}
		
		for i = 1, MainConfig.MaxEquipped do
			Used[i] = true
		end
		
		for _, Tower in pairs(PlrData.Data.Towers) do
			if Tower.Equipped then
				Used[Tower.Equipped] = false
			end
		end
		
		for i = 1, MainConfig.MaxEquipped do
			if Used[i] == true then
				SlotNum = i
				break
			end
		end
		
		if not SlotNum then
			return
		end
		
		PlrData.Data.Towers[ID].Equipped = SlotNum
	end
	
	DataManager.Profiles[Player.UserId].Replica:Set({"Towers"}, PlrData.Data.Towers)
	return true
end

return TowerManager
