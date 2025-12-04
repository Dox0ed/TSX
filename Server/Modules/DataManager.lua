--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Libs = ServerScriptService.Libs
local Modules = ServerScriptService.Modules

local DataTemplate = require(Modules.DataTemplate)
local LeadFunctions = require(script.LeadFunctions)

local ProfileStore = require(Libs.ProfileStore)
local Replica = require(Libs.ReplicaServer)

local ReplicaToken = Replica.Token("PlayerData")

local DataStoreVer = 2

--// Class
local DataManager = {}
DataManager.__index = DataManager

if not DataManager.DataStore then
	DataManager.DataStore = ProfileStore.New(`TSX_Data#{DataStoreVer}`, DataTemplate)
end

function DataManager.Construct(Player: Player?)
	if not Player then
		return 
	end
	
	local PlrProfile = DataManager.DataStore:StartSessionAsync(`id_{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})
	
	PlrProfile:AddUserId(Player.UserId)
	PlrProfile:Reconcile()
	
	if PlrProfile.Data.FirstJoin then
		PlrProfile.Data.FirstJoin = false
		
		PlrProfile.Data.Cash = 100
	end
	
	local self = setmetatable({
		Profile = PlrProfile,
		Player = Player,
		Replica = Replica.New({
			Token = ReplicaToken,
			Tags = {UserId = Player.UserId},
			Data = table.clone(PlrProfile.Data)
		})
	}, LeadFunctions)
	
	self.Replica:Replicate()
	
	PlrProfile.OnSessionEnd:Connect(function()
		self.Replica:Destroy()
		self:Destroy()
		
		Player:Kick("Data error, try rejoin.")
		return
	end)
	
	if not Player:IsDescendantOf(Players) then
		PlrProfile:EndSession()
		return
	end
	
	if PlrProfile == nil or self.Replica == nil then
		Player:Kick("Data error, try rejoin.")
		return
	end
	
	return self
end

return DataManager
