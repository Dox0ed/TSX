--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Modules = ServerScriptService.Modules
local Libs = ServerScriptService.Libs
local Configs = ReplicatedStorage.Configs

local Remotes = ReplicatedStorage.Remotes

local DataManager = require(Modules.DataManager)
local ShopConfig = require(Configs.ShopConfig)

local Instances = {}

--// Conns
local function ConstructData(Player)
	local Data = DataManager.Construct(Player)
	Instances[Player] = Data
	
	for _, GamePassID in ShopConfig.Passes do
		Data:CheckPass(GamePassID)
	end
end

local function GetData(Player)
	if Instances[Player] then
		return Instances[Player]
	end
	return nil
end

for _, Player: Player in ipairs(Players:GetPlayers()) do
	task.spawn(DataManager.Construct, Player)
end

Players.PlayerAdded:Connect(ConstructData)
Players.PlayerRemoving:Connect(function(Player) if not Instances[Player] then return end Instances[Player]:Destroy() Instances[Player] = nil end)

Remotes.Settings.Change.OnServerEvent:Connect(function(Player, Name)
	local Data = GetData(Player)
	if not Data then
		return
	end
	
	Data:ChangeSettings(Name)
end)

Remotes.Inventory.Equip.OnServerEvent:Connect(function(Player, ID)
	local Data = GetData(Player)
	if not Data then
		return
	end
	
	Data:EquipTower(ID)
end)
Remotes.Inventory.Sell.OnServerEvent:Connect(function(Player, SellTable)
	local Data = GetData(Player)
	if not Data then
		return
	end
	
	Data:RemoveTower(SellTable, true)
end)

Remotes.Summon.Summon.OnServerEvent:Connect(function(Player, Amount)
	local Data = GetData(Player)
	if not Data then
		return
	end
	
	Data:Summon(Amount)
end)

MarketplaceService.ProcessReceipt = function(Player, Info) local Data = GetData(Player) if not Data then return end Data:ProccessReceipt(Info) end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, GamePassID, WasPurchased)
	if not WasPurchased then 
		return 
	end
	
	local Data = GetData(Player)
	if not Data then
		return
	end

	Data:CheckPass(GamePassID)
end)

game:BindToClose(function()
	for _, Player: Player in ipairs(Players:GetPlayers()) do
		task.spawn(function(Player) local Data = GetData(Player) if not Data then return end Data:Destroy() Instances[Player] = nil end, Player)
	end
end)
