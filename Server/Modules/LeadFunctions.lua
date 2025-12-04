--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Libs = ServerScriptService.Libs
local Modules = ServerScriptService.Modules

local TowerManager = require(Modules.TowerManager)
local SummonManager = require(Modules.SummonManager)
local ShopManager = require(Modules.ShopManager)

local CD = {}

--// Class
local LeadFunctions = {}
LeadFunctions.__index = LeadFunctions

LeadFunctions.AddTower = TowerManager.AddTower
LeadFunctions.RemoveTower = TowerManager.RemoveTower
LeadFunctions.EquipTower = TowerManager.EquipTower

LeadFunctions.Summon = SummonManager.Summon

LeadFunctions.ReceiptProccess = ShopManager.ReceiptProccess
LeadFunctions.CheckPass = ShopManager.CheckPass

LeadFunctions.Destroy = function(self)
	if not self.Profile then 
		return 
	end
	
	self.Profile.Data = self.Replica.Data
	self.Profile:EndSession()
	self.Replica:Destroy()
end

LeadFunctions.ChangeSettings = function(self, Name: string)
	if not self.Player or not Name or CD[self.Player] then
		return
	end

	CD[self.Player] = true

	local PlrData = self.Profile
	if not PlrData or not PlrData.Data then
		return
	end

	if Name == "Trades" then
		PlrData.Data.Settings.Trades += 1
		if PlrData.Data.Settings.Trades >= 4 then
			PlrData.Data.Settings.Trades = 1
		end
	elseif Name == "Time" then
		PlrData.Data.Settings.Time += 1
		if PlrData.Data.Settings.Time >= 3 then
			PlrData.Data.Settings.Time = 1
		end
	elseif Name == "Music" then
		PlrData.Data.Settings.Music += 1
		if PlrData.Data.Settings.Music >= 3 then
			PlrData.Data.Settings.Music = 1
		end
	end

	task.delay(.3, function()
		CD[self.Player] = nil
	end)

	self.Replica:Set({"Settings"}, PlrData.Data.Settings)
end

return LeadFunctions
