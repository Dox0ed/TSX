--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules

--// Funcs, Conns
for _, Module in Modules:GetChildren() do
	require(Module)
end
