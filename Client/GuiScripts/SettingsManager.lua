--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local SettingsGui = PlayerGui:WaitForChild("Settings")

local Remotes = ReplicatedStorage.Remotes
local SettingsRemotes = Remotes.Settings

local Background = SettingsGui:WaitForChild("Background")
local SettingsScroll = Background:WaitForChild("List"):WaitForChild("SettingsScroll")

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules

local DataReplicator = require(Modules.DataReplicator)
local TopBarPlus = require(Libs.Icon)

local NewTweenInfo = TweenInfo.new(1.5)

--// Funcs, Conns
while not DataReplicator.IsReady do
	task.wait(1)
end

local function Setup()
	TopBarPlus.new()
		:setName("SettingsButton")
		:setImage(4492476121)
		:oneClick(true)
		.selected:Connect(function()
			SettingsGui.Enabled = not SettingsGui.Enabled
		end)
	
	UpdateSettings()
end

local OldSettings = {Music = 0, Time = 0, Trades = 0}
function UpdateSettings()
	local SettingsData = DataReplicator.PlrReplica.Data.Settings
	
	local TradesFrame = SettingsScroll.Trades.Trigger
	local MusicFrame = SettingsScroll.Music.Trigger
	local TimeFrame = SettingsScroll.Time.Trigger
	
	if OldSettings.Music ~= SettingsData.Music then
		if SettingsData.Music == 1 then
			SoundService.Music:Play()
			MusicFrame.BackgroundColor3 = Color3.new(0,1,0)
			MusicFrame.Text = "On"
		else
			SoundService.Music:Stop()
			MusicFrame.BackgroundColor3 = Color3.new(1, 0, 0)
			MusicFrame.Text = "Off"
		end
	end
	
	if OldSettings.Time ~= SettingsData.Time then
		if SettingsData.Time == 1 then
			TweenService:Create(Lighting, NewTweenInfo, {ClockTime = 14.5}):Play()
			TimeFrame.BackgroundColor3 = Color3.new(0,1,0)
			TimeFrame.Text = "Day"
		else
			TweenService:Create(Lighting, NewTweenInfo, {ClockTime = 0}):Play()
			TimeFrame.BackgroundColor3 = Color3.new(0, 0, 1)
			TimeFrame.Text = "Night"
		end
	end
	
	if OldSettings.Trades ~= SettingsData.Trades then
		if SettingsData.Trades == 1 then
			TradesFrame.BackgroundColor3 = Color3.new(0, 1, 0)
			TradesFrame.Text = "Everyone"
		elseif SettingsData.Trades == 2 then
			TradesFrame.BackgroundColor3 = Color3.new(1, 1, 0)
			TradesFrame.Text = "Friends"
		else
			TradesFrame.BackgroundColor3 = Color3.new(1, 0, 0)
			TradesFrame.Text = "Off"
		end
	end
	
	OldSettings = SettingsData
end

for _, Setting in SettingsScroll:GetChildren() do
	if not Setting:IsA("Frame") then
		continue
	end
	
	if not Setting:FindFirstChild("Trigger") then
		continue
	end
	
	Setting.Trigger.Activated:Connect(function()
		SettingsRemotes.Change:FireServer(Setting.Name)
	end)
end

DataReplicator.PlrReplica:OnSet({"Settings"}, UpdateSettings)

Setup()

Background.Close.Activated:Connect(function()
	SettingsGui.Enabled = false
end)
