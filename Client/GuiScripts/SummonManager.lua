--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local SummonGui = PlayerGui:WaitForChild("Summon")
local Background = SummonGui:WaitForChild("Background")

local List = Background:WaitForChild("List")
local SummonScroll = List:WaitForChild("SummonScroll")

local ShowSummonFrame = SummonGui:WaitForChild("ShowSummon")
local ShowScroll = ShowSummonFrame:WaitForChild("List"):WaitForChild("ShowScroll")

local Remotes = ReplicatedStorage.Remotes
local SummonRemotes = Remotes.Summon

local Configs = ReplicatedStorage.Configs

local MainConfig = require(Configs.MainConfig)
local TowerConfig = require(Configs.TowerConfig)

local RarityBacks = StarterPlayerScripts:WaitForChild("RarityBackgrounds")

local ShowExample = script:WaitForChild("ExampleSummon")

local Banner = "Default"

--// Funcs, Conns
function UpdateSummon(ChoosedTowers)
	for _, Rarity in SummonScroll:GetChildren() do
		if not Rarity:IsA("ImageButton") then
			continue
		end

		Rarity.Chance.Text = `{MainConfig.RarityChances[Rarity.Name]}%`
		Rarity.Info.Text = ChoosedTowers[Rarity.Name]
		Rarity.ImageTower.Image = TowerConfig[ChoosedTowers[Rarity.Name]].Image
	end
end

function ShowSummon(Towers)
	for _, Tower in ShowScroll:GetChildren() do
		if Tower:IsA("ImageButton") then
			Tower:Destroy()
		end
	end
	
	ShowSummonFrame.Visible = true
	Background.Visible = false
	
	for _, TowerName in Towers do
		local Config = TowerConfig[TowerName]
		if not Config then
			return
		end
		
		local ShowInstance = ShowExample:Clone()
		ShowInstance.Parent = workspace
		ShowInstance.Info.Text = TowerName
		ShowInstance.TowerImage.Image = Config.Image
		RarityBacks[Config.Rarity]:Clone().Parent = ShowInstance
		
		ShowInstance.Parent = ShowScroll
		task.wait(0.05)
	end
	
	local CloseConnection = {}
	CloseConnection = ShowSummonFrame.Close.Activated:Connect(function()
		ShowSummonFrame.Visible = false
		Background.Visible = true
		CloseConnection:Disconnect()
	end)
end

Background.SummonX1Button.Activated:Connect(function()
	SummonRemotes.Summon:FireServer(1, Banner)
end)

Background.SummonX10Button.Activated:Connect(function()
	SummonRemotes.Summon:FireServer(10, Banner)
end)

Background.DefaultBanner.Activated:Connect(function()
	Background.DefaultBanner.BackgroundColor3 = Color3.new(0,1,0)
	Background.BoostedBanner.BackgroundColor3 = Color3.new(0, 0, 1)
	Banner = "Default"
end)

Background.BoostedBanner.Activated:Connect(function()
	Background.BoostedBanner.BackgroundColor3 = Color3.new(0,1,0)
	Background.DefaultBanner.BackgroundColor3 = Color3.new(0, 0, 1)
	Banner = "Boosted"
end)

Background.Close.Activated:Connect(function()
	SummonGui.Enabled = false
end)

SummonRemotes.Summon.OnClientEvent:Connect(UpdateSummon)
SummonRemotes.AskSummon.OnClientEvent:Connect(ShowSummon)
SummonRemotes.AskSummon:FireServer()
