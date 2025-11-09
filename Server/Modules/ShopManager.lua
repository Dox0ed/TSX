--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Configs = ReplicatedStorage.Configs

local ShopConfig = require(Configs.ShopConfig)
local DataManager = require(Modules.DataManager)
local TowerManager = require(Modules.TowerManager)

local DevFunctions = {
	[ShopConfig.DevProducts.Cash100] = function(Player: Player?, PlrData: any)
		PlrData.Data.Cash += 100
		DataManager.Profiles[Player.UserId].Replica:Set({"Cash"}, PlrData.Data.Cash)
	end,

	[ShopConfig.DevProducts.ExclusiveTower1] = function(Player: Player?, PlrData: any)
		TowerManager.AddTower(Player, "DonateTowerUWU", 1, nil)
	end
}

local PassFunctions = {
	[ShopConfig.Passes.LuckX2] = function(Player: Player?, PlrData: any)
		PlrData.Data.Stats.Luck += 1
		DataManager.Profiles[Player.UserId].Replica:Set({"Stats"}, PlrData.Data.Stats)
	end,
}

--// Class
local ShopManager = {}

function ShopManager.ReceiptProccess(ReceiptInfo)
	local PlrData = DataManager.Profiles[ReceiptInfo.PlayerId].Profile
	if not PlrData or not PlrData.Data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlrData.Data.Spent += ReceiptInfo.CurrencySpent

	DevFunctions[ReceiptInfo.ProductId](Players:GetPlayerByUserId(ReceiptInfo.PlayerId), PlrData)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopManager.CheckPass(Player: Player?, GamePassID: number)
	if not MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GamePassID) then
		return
	end

	local PassName = nil

	for Name, ID in ShopConfig.Passes do
		if GamePassID == ID then
			PassName = Name
		end
	end

	if not PassName then
		return
	end

	local PlrData = DataManager.Profiles[Player.UserId].Profile
	if not PlrData or not PlrData.Data or PlrData.Data.PurchasedPasses[PassName] == true then
		return
	end

	PlrData.Data.PurchasedPasses[PassName] = true

	PassFunctions[GamePassID](Player, PlrData)
end

return ShopManager
