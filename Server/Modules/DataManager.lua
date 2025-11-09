--// Vars
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Libs = ServerScriptService.Libs
local Modules = ServerScriptService.Modules

local DataTemplate = require(Modules.DataTemplate)
local ProfileStore = require(Libs.ProfileStore)
local Replica = require(Libs.ReplicaServer)

local ReplicaToken = Replica.Token("PlayerData")

local DataStoreVer = 2

--// Class
local DataManager = {}

DataManager.DataStore = ProfileStore.New(`TSX_Data#{DataStoreVer}`, DataTemplate)
DataManager.Profiles = {}

function DataManager.AddPlayer(Player: Player?)
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
	
	DataManager.Profiles[Player.UserId] = {
		Replica = Replica.New({
			Token = ReplicaToken,
			Tags = {UserId = Player.UserId},
			Data = table.clone(PlrProfile.Data)
		}),
		Profile = PlrProfile
	}
	
	if PlrProfile.Data.FirstJoin then
		PlrProfile.Data.FirstJoin = false
		
		PlrProfile.Data.Cash = 10000
	end
	
	DataManager.Profiles[Player.UserId].Replica:Replicate()
	
	PlrProfile.OnSessionEnd:Connect(function()
		DataManager.Profiles[Player.UserId].Replica:Destroy()
		DataManager.Profiles[Player.UserId] = nil
		
		Player:Kick("Data error, try rejoin.")
		return
	end)
	
	if not Player:IsDescendantOf(Players) then
		PlrProfile:EndSession()
		return
	end
	
	if PlrProfile == nil or DataManager.Profiles[Player.UserId].Replica == nil then
		Player:Kick("Data error, try rejoin.")
		return
	end
end

function DataManager.RemovePlayer(Player: Player?)
	local PlrProfile = DataManager.Profiles[Player.UserId].Profile
	
	if not PlrProfile then 
		return 
	end
	
	PlrProfile:EndSession()
end

local CD = {}
function DataManager.ChangeSettings(Player: Player?, Name: string)
	if not Player or not Name or CD[Player] then
		return
	end
	
	CD[Player] = true
	
	local PlrData = DataManager.Profiles[Player.UserId].Profile
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
		CD[Player] = nil
	end)
	
	DataManager.Profiles[Player.UserId].Replica:Set({"Settings"}, PlrData.Data.Settings)
end

return DataManager
