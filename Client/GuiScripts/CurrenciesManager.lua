--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local HUDGui = PlayerGui:WaitForChild("HUD")
local CurrenciesFrame = HUDGui:WaitForChild("Currencies")

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules

local DataReplicator = require(Modules.DataReplicator)

--// Funcs, Conns
while not DataReplicator.IsReady do
	task.wait(1)
end

for _, Currency in CurrenciesFrame:GetChildren() do
	if not Currency:IsA("Frame") then 
		continue 
	end
	
	if not DataReplicator.PlrReplica.Data[Currency.Name] then
		continue
	end
	
	Currency.Amount.Text = DataReplicator.PlrReplica.Data[Currency.Name]
	DataReplicator.PlrReplica:OnSet({Currency.Name}, function(OldAmount, NewAmount)
		Currency.Amount.Text = DataReplicator.PlrReplica.Data[Currency.Name]
	end)
end
