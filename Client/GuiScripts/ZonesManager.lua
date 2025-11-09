--// Vars
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local ZoneModule = require(ReplicatedStorage.Libs.Zone)
local ZonesFolder = workspace:WaitForChild("Zones")

--// Funcs, Conns
ZonesFolder:WaitForChild("SummonTrigger")

for _, ZoneInstance: Part in ZonesFolder:GetChildren() do
	if not ZoneInstance:GetAttribute("GUIName") then
		continue
	end
	
	local GUIName = ZoneInstance:GetAttribute("GUIName")
	local Zone = ZoneModule.new(ZoneInstance)
	
	Zone.localPlayerEntered:Connect(function()
		if not PlayerGui:FindFirstChild(GUIName) then
			return
		end
		
		PlayerGui[GUIName].Enabled = true
	end)
	
	Zone.localPlayerExited:Connect(function()
		if not PlayerGui:FindFirstChild(GUIName) then
			return
		end

		PlayerGui[GUIName].Enabled = false
	end)
end
