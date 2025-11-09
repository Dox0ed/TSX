--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local HUDGui = PlayerGui:WaitForChild("HUD")
local ButtonsFrame = HUDGui:WaitForChild("Buttons")

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules

--// Funcs, Conns
for _, Button: Frame in ButtonsFrame:GetChildren() do
	if not Button:IsA("Frame") then
		continue
	end
	
	if not Button:FindFirstChild("Button") then
		continue
	end
	
	Button.Button.Activated:Connect(function()
		if not Button:GetAttribute("GUIName") then
			return
		end
		
		local GUIName = Button:GetAttribute("GUIName")
		if not PlayerGui:FindFirstChild(GUIName) then
			return
		end
		
		PlayerGui[GUIName].Enabled = not PlayerGui[GUIName].Enabled
	end)
end
