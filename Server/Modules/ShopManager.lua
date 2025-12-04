--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ServerScriptService.Modules
local Configs = ReplicatedStorage.Configs

local ShopConfig = require(Configs.ShopConfig)

local DevFunctions = {
	[ShopConfig.DevProducts.Cash100] = function(self)
		self.Replica:Set({"Cash"}, self.Replica.Data.Cash + 100)
	end,

	[ShopConfig.DevProducts.ExclusiveTower1] = function(self)
		self:AddTower("DonateTowerUWU", 1, nil)
	end
}

local PassFunctions = {
	[ShopConfig.Passes.LuckX2] = function(self)
		self.Replica:Set({"Stats"}, self.Replica.Data.Stats.Luck + 1)
	end
}

--// Class
local ShopManager = {}

function ShopManager:ReceiptProccess(ReceiptInfo)
	local PlrData = self.Replica
	if not PlrData or not PlrData.Data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlrData.Data.Spent += ReceiptInfo.CurrencySpent

	DevFunctions[ReceiptInfo.ProductId](Players:GetPlayerByUserId(self))

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopManager:CheckPass(GamePassID: number)
	if not MarketplaceService:UserOwnsGamePassAsync(self.Player.UserId, GamePassID) then
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

	local PlrData = self.Replica
	if not PlrData or not PlrData.Data or PlrData.Data.PurchasedPasses[PassName] == true then
		return
	end

	PlrData:Set({"PurchasedPasses", PassName}, true)

	PassFunctions[GamePassID](self)
end

return ShopManager
