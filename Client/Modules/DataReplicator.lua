--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules

local Replica = require(Libs.ReplicaClient)

--// Class
local DataReplicator = {}
DataReplicator.PlrReplica = {}
DataReplicator.IsReady = false

Replica.OnNew("PlayerData", function(NewPlrReplica)
	if NewPlrReplica.Tags.UserId ~= Players.LocalPlayer.UserId then
		return
	end
	
	DataReplicator.IsReady = true
	DataReplicator.PlrReplica = NewPlrReplica
end)

Replica.RequestData()

return DataReplicator
