--// Vars
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer.PlayerGui
local HUDGui = PlayerGui:WaitForChild("HUD")
local InventoryGui = PlayerGui:WaitForChild("Inventory")

local Libs = StarterPlayerScripts.Libs
local Modules = StarterPlayerScripts.Modules
local Configs = ReplicatedStorage.Configs

local Remotes = ReplicatedStorage.Remotes
local InvRemotes = Remotes.Inventory

local DataReplicator = require(Modules.DataReplicator)
local TowerConfig = require(Configs.TowerConfig)

local Background = InventoryGui:WaitForChild("Background")
local ScrollFrame = Background:WaitForChild("InventoryScroll")
local ExampleTower = script:WaitForChild("ExampleTower")
local RarityBacks = StarterPlayerScripts:WaitForChild("RarityBackgrounds")
local Hotbar = HUDGui.Hotbar
local TowerInfo = HUDGui.TowerInfo

local ChooseState = false
local SellState = false
local SellText = {"Start Sell", "End Sell"}
local SellTable = {}

local LayoutOrderTable = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}

local CurrentExist = {}

--// Funcs, Conns
while not DataReplicator.IsReady do
	task.wait(1)
end

function ClearScrollFrame()
	for _, Tower in ScrollFrame:GetChildren() do
		if Tower:IsA("Frame") then
			Tower:Destroy()
		end
	end
end

function UpdateInv(Towers)
	if Towers == nil then
		return
	end

	ClearScrollFrame()

	local UsedSlots = {}

	for id, Tower in Towers do
		if not ScrollFrame:FindFirstChild(Tower.Name) then
			if not TowerConfig[Tower.Name] then
				continue
			end
			local TowerInstance = ExampleTower:Clone()
			TowerInstance.Name = Tower.Name

			local Config: Config = TowerConfig[Tower.Name]

			TowerInstance.TowerImage.Image = Config.Image
			TowerInstance.Price.Text = `${Config.Price}`

			TowerInstance.LayoutOrder = -table.find(LayoutOrderTable, Config.Rarity)

			RarityBacks[Config.Rarity]:Clone().Parent = TowerInstance

			if table.find(SellTable, id) then
				TowerInstance.SellYes.Visible = true
			end

			if Tower["Equipped"] then
				TowerInstance.Price.TextColor3 = Color3.new(0,1,0)
				TowerInstance.LayoutOrder -= 1000
				TowerInstance.LayoutOrder += Tower.Equipped * 100
				UsedSlots[Tower.Equipped] = Tower.Name
			end
			
			TowerInstance:SetAttribute("ID", id)
			TowerInstance:SetAttribute("Stack", 1)

			TowerInstance.MouseEnter:Connect(function()
				TowerInfo.Visible = true

				TowerInfo.TowerName.Text = Tower.Name
				TowerInfo.Stats.Text = Config.Info
				TowerInfo.Exist.Text = `Exists: {CurrentExist[Tower.Name] and CurrentExist[Tower.Name] or "???"}`
			end)

			TowerInstance.MouseMoved:Connect(function()
				local Mouse = game.Players.LocalPlayer:GetMouse()
				local ViewportSize = workspace.CurrentCamera.ViewportSize
				local isKeyboard = not game.UserInputService.TouchEnabled

				local offsetY, offsetX

				if isKeyboard then
					offsetY = TowerInfo.AbsolutePosition.Y + TowerInfo.AbsoluteSize.Y > ViewportSize.Y and 0.06 or 0.08
					offsetX = 0
				else
					offsetY = 0.15
					offsetX = TowerInfo.AbsolutePosition.Y + TowerInfo.AbsoluteSize.Y > ViewportSize.Y and 0 or 0.025
				end

				TowerInfo.Position = UDim2.new(TowerInfo.AnchorPoint.X + offsetX, Mouse.X, TowerInfo.AnchorPoint.Y + offsetY, Mouse.Y)
			end)

			TowerInstance.MouseLeave:Connect(function()
				TowerInfo.Visible = false
			end)

			TowerInstance.Trigger.Activated:Connect(function()
				if not SellState then
					InvRemotes.Equip:FireServer(id)
				else
					if SellTable[Tower.Name] then
						SellTable[Tower.Name] = nil
						TowerInstance.SellYes.Visible = false
					elseif not ChooseState and TowerInstance:GetAttribute("Stack") > 1 then
						ChooseState = true
						InventoryGui.SellChoose.Visible = true
						
						InventoryGui.SellChoose.Trigger.Activated:Once(function()
							if tonumber(InventoryGui.SellChoose.AmountBox.Text) < 1 then
								ChooseState = false
								InventoryGui.SellChoose.Visible = false
								return
							end
							SellTable[Tower.Name] = tonumber(InventoryGui.SellChoose.AmountBox.Text)
							TowerInstance.SellYes.Visible = true
							InventoryGui.SellChoose.Visible = false
							ChooseState = false
						end)
					else
						SellTable[Tower.Name] = 1
						TowerInstance.SellYes.Visible = true
					end
				end
			end)

			TowerInstance.Parent = ScrollFrame
		else
			local TowerInstance = ScrollFrame[Tower.Name]
			
			TowerInstance:SetAttribute("Stack", TowerInstance:GetAttribute("Stack") + 1)
			TowerInstance.Stack.Text = `x{TowerInstance:GetAttribute("Stack")}`
			
			if Tower["Equipped"] then
				TowerInstance:SetAttribute("ID", id)
				TowerInstance.Price.TextColor3 = Color3.new(0,1,0)
				TowerInstance.LayoutOrder -= 1000
				TowerInstance.LayoutOrder += Tower.Equipped * 100
				UsedSlots[Tower.Equipped] = Tower.Name
			end
		end
	end

	for Num = 1, 5 do
		if not UsedSlots[Num] then
			local UnUsedSlot = Hotbar[`Slot{Num}`]
			UnUsedSlot.TowerImage.Image = ""
			UnUsedSlot.Price.Visible = false
			UnUsedSlot:SetAttribute("Tower", nil)
			continue
		end

		if not TowerConfig[UsedSlots[Num]] then
			continue
		end

		local Config: Config = TowerConfig[UsedSlots[Num]]
		local Slot = Hotbar[`Slot{Num}`]

		Slot:SetAttribute("Tower", UsedSlots[Num])
		Slot.TowerImage.Image = Config.Image

		Slot.Price.Text = Config.Price
		Slot.Price.Visible = true
	end
end

for _, Slot in Hotbar:GetChildren() do
	if not Slot:IsA("Frame") then
		continue
	end
	
	Slot.MouseEnter:Connect(function()
		if not Slot:GetAttribute("Tower") then
			return
		end

		TowerInfo.Visible = true

		TowerInfo.TowerName.Text = Slot:GetAttribute("Tower")
		TowerInfo.Stats.Text = TowerConfig[Slot:GetAttribute("Tower")].Info
		TowerInfo.Exist.Text = `Exists: {CurrentExist[Slot:GetAttribute("Tower")] and CurrentExist[Slot:GetAttribute("Tower")] or "???"}`
	end)

	Slot.MouseMoved:Connect(function()
		local Mouse = game.Players.LocalPlayer:GetMouse()
		local ViewportSize = workspace.CurrentCamera.ViewportSize
		local isKeyboard = not game.UserInputService.TouchEnabled

		local offsetY, offsetX

		if isKeyboard then
			offsetY = TowerInfo.AbsolutePosition.Y + TowerInfo.AbsoluteSize.Y > ViewportSize.Y and 0.06 or 0.08
			offsetX = 0
		else
			offsetY = 0.15
			offsetX = TowerInfo.AbsolutePosition.Y + TowerInfo.AbsoluteSize.Y > ViewportSize.Y and 0 or 0.025
		end

		TowerInfo.Position = UDim2.new(TowerInfo.AnchorPoint.X - offsetX, Mouse.X, TowerInfo.AnchorPoint.Y - offsetY, Mouse.Y)
	end)

	Slot.MouseLeave:Connect(function()
		TowerInfo.Visible = false
	end)
end

DataReplicator.PlrReplica:OnSet({"Towers"}, UpdateInv)

Background.UnequipAll.Activated:Connect(function()
	InvRemotes.Equip:FireServer("UnequipAll")
end)

Background.Sell.Activated:Connect(function()
	SellState = not SellState
	if SellState then
		SellTable = {}
		Background.Sell.Text = SellText[2]
	else
		InvRemotes.Sell:FireServer(SellTable)
		Background.Sell.Text = SellText[1]
	end
end)

Background.Close.Activated:Connect(function()
	InventoryGui.Enabled = false
end)

InvRemotes.Exist.OnClientEvent:Connect(function(Exists)
	CurrentExist = Exists
end)

InventoryGui.SellChoose.Close.Activated:Connect(function()
	InventoryGui.SellChoose.Visible = false
end)

UpdateInv(DataReplicator.PlrReplica.Data.Towers)
