--// Vars
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Modules = ServerScriptService.Modules

local Remotes = ReplicatedStorage.Remotes
local InvRemotes = Remotes.Inventory

local DataManager = require(Modules.DataManager)

local DataVer = 1
local Name = `TSX_EX#{DataVer}`
local Datastore = DataStoreService:GetDataStore(Name)

--// Funcs, Conns
if RunService:IsStudio() then
	return
end

local CurrentTable = {}

function SetTable()
	local Pages
	local Succ, Err = pcall(function()
		Pages = Datastore:ListKeysAsync()
	end)
	if not Succ then task.wait(30) SetTable() return end

	while task.wait() do
		local Page = Pages:GetCurrentPage()

		for i, dataInstance in pairs(Page) do
			local Value
			pcall(function()
				Value = Datastore:GetAsync(dataInstance.KeyName)
			end)
			if Value then
				CurrentTable[dataInstance.KeyName] = Value
			end
		end

		if Pages.IsFinished then
			break
		else
			Pages:AdvanceToNextPageAsync()
		end
	end

	local Page = Pages:GetCurrentPage()

	InvRemotes.Exist:FireAllClients(CurrentTable)
end

local KeysDone = {}
function PlayerAdded(self)
	if not self.Profile then 
		return 
	end

	local PlrData = self.Profile
	if not PlrData or not PlrData.Data then 
		return 
	end

	local Towers = {}

	for _, Tower in PlrData.Data.Towers do
		if not Tower.Exist or Tower.Exist ~= Name then
			if not Towers[Tower.Name] then
				Towers[Tower.Name] = 1
			else
				Towers[Tower.Name] += 1
			end
		end
	end

	for TowerName, amount in Towers do
		local Succ, Err = pcall(function()
			local Count = Datastore:GetAsync(TowerName)
			if not Count and CurrentTable ~= {} and not CurrentTable[TowerName] then
				Count = 0
			end

			if KeysDone[TowerName] then
				KeysDone[TowerName] += amount
			else
				KeysDone[TowerName] = amount

				task.delay(10, function()
					Datastore:UpdateAsync(TowerName, function()
						return Count + KeysDone[TowerName]
					end)
					KeysDone[TowerName] = nil
				end)
			end
		end)

		task.wait(15)

		if Succ then
			for _, Tower in PlrData.Data.Towers do
				if TowerName == TowerName then
					Tower.Exist = Name
				end
			end
		end
	end
end

script.DecreaseExist.Event:Connect(function(Name: string, Count: number)
	task.wait(20)
	if not Name then 
		return 
	end

	task.delay(10, function()
		Datastore:UpdateAsync(Name, function()
			return Datastore:GetAsync(Name) - Count
		end)
		KeysDone[Name] = nil
	end)
end)

task.spawn(function()
	task.wait(10)
	while true do
		SetTable()
		task.wait(1600)
	end
end)
