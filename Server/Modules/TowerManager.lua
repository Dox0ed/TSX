--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Configs = ReplicatedStorage.Configs

local TowerConfig = require(Configs.TowerConfig)
local MainConfig = require(Configs.MainConfig)

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

function TowerManager:AddTower(Name: string, Amount: number, OtherSettings: any)
	if not self.Replica then
		return
	end
	
	local PlrData = self.Replica
	if not PlrData or not PlrData.Data then
		return
	end
	
	local ID = nil
	for _ = 1, Amount do
		ID = GenerateID(PlrData.Data.Towers)

		PlrData:Set({"Towers", ID}, {
			Name = Name,
			Settings = OtherSettings
		})
	end
	PlrData:Set({"Towers"}, PlrData.Data.Towers)
end

function TowerManager:RemoveTower(SellTable, GiveCash: boolean)
	if not self.Replica then
		return
	end
	
	local PlrData = self.Replica
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
					PlrData:Set({"Towers", ID}, nil)
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

			PlrData:Set({"Cash"}, PlrData.Data.Cash + (MainConfig.SellPrices[TowerConfig.Rarity] * RealStack))
			DecreaseExistEvent:Fire(TowerName, RealStack)
		end
	end
	
	PlrData:Set({"Towers"}, PlrData.Data.Towers)
end

function TowerManager:EquipTower(ID: string)
	if not self.Replica then
		return
	end

	local PlrData = self.Replica
	if not PlrData or not PlrData.Data then
		return
	end
	
	if ID == "UnequipAll" then
		for id, Tower in PlrData.Data.Towers do
			if Tower.Equipped  then
				PlrData.Data.Towers[id].Equipped = false
				self.Replica:Set({"Towers", id, "Equipped"}, false)
			end
		end
		PlrData:Set({"Towers"}, PlrData.Data.Towers)
		return
	end
	
	if not PlrData.Data.Towers[ID] then
		return
	end
	
	if PlrData.Data.Towers[ID]["Equipped"] then
		self.Replica:Set({"Towers", ID, "Equipped"}, false)
		PlrData:Set({"Towers"}, PlrData.Data.Towers)
	else
		local TowerName = PlrData.Data.Towers[ID].Name
		for _, Tower in PlrData.Data.Towers do
			if Tower.Name == TowerName and Tower["Equipped"] then
				return
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
		
		self.Replica:Set({"Towers", ID, "Equipped"}, SlotNum)
	end
	
	PlrData:Set({"Towers"}, PlrData.Data.Towers)
end

return TowerManager
