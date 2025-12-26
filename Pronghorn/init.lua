--!strict
--!optimize 2
--!native
--[[
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                                         ▓███                         ║
║             ▄█▀▄▄▓█▓                   █▓█ ██                        ║
║            ▐████                         █ ██                        ║
║             ████                        ▐█ ██                        ║
║             ▀████                       ▐▌▐██                        ║
║              ▓█▌██▄                     █████                        ║
║               ▀█▄▓██▄                  ▐█████                        ║
║                ▀▓▓████▄   ▄▓        ▓▄ █████     ▓ ▌                 ║
║             ▀██████████▓  ██▄       ▓██████▓    █   ▐                ║
║                 ▀▓▓██████▌▀ ▀▄      ▐██████    ▓  █                  ║
║                    ▀███████   ▀     ███████   ▀  █▀                  ║
║                      ███████▀▄     ▓███████ ▄▓  ▄█   ▐               ║
║                       ▀████   ▀▄  █████████▄██  ▀█   ▌               ║
║                        ████      █████  ▄ ▀██    █  █                ║
║                       ██▀▀███▓▄██████▀▀▀▀▀▄▀    ▀▄▄▀                 ║
║                       ▐█ █████████ ▄██▓██ █  ▄▓▓                     ║
║                      ▄███████████ ▄████▀███▓  ███                    ║
║                    ▓███████▀  ▐     ▄▀▀▀▓██▀ ▀██▌                    ║
║                ▄▓██████▀▀▌▀   ▄        ▄▀▓█     █▌                   ║
║               ████▓▓                 ▄▓▀▓███▄   ▐█                   ║
║               ▓▓                  ▄  █▓██████▄▄███▌                  ║
║                ▄       ▌▓█     ▄██  ▄██████████████                  ║
║                   ▀▀▓▓████████▀   ▄▀███████████▀████                 ║
║                          ▀████████████████▀▓▄▌▌▀▄▓██                 ║
║                           ██████▀██▓▌▀▌ ▄     ▄▓▌▐▓█▌                ║
║                                                                      ║
║                                                                      ║
║                    Pronghorn Framework  Rev. B113                    ║
║             https://github.com/Iron-Stag-Games/Pronghorn             ║
║                GNU Lesser General Public License v2.1                ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║      Pronghorn is a Roblox framework with a direct approach to       ║
║         Module scripting that facilitates rapid development.         ║
║                                                                      ║
╠═══════════════════════════════ Usage ════════════════════════════════╣
║                                                                      ║
║ - Pronghorn:Import() is used in a Script to import your Modules.     ║
║ - Modules as descendants of other Modules are not imported.          ║
║ - Pronghorn:SetEnabledChannels() controls the output of Modules.     ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

local a = if game:GetService("RunService"):IsServer() then "__s" else "__c"
if not script:GetAttribute(a) then script:SetAttribute(a, true) else error("Required Pronghorn from more than one Luau VM; please use BindableFunctions", 0) end

local Pronghorn = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dependencies
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Services
local Players = game:GetService("Players")

-- Core
local Debug = require(script.Debug)

local BindableEvent = Instance.new("BindableEvent")

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Types
type Module = {
	Object: ModuleScript;
	Return: any?;
}

-- Defines
local startWaits = math.huge

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Variables
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Temporarily excluded New usage
Pronghorn.Importing = false
Pronghorn.Imported = BindableEvent:Clone()
Pronghorn.DeferredComplete = BindableEvent:Clone()
Pronghorn.ModuleStatus = {} :: {[ModuleScript]: {Status: number}}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function addModules(allModules: {Module}, object: Instance): ()
	if object ~= script then
		if object:IsA("ModuleScript") then
			local alreadyAdded = false
			for _, moduleTable in allModules do
				if moduleTable.Object == object then
					alreadyAdded = true
					break
				end
			end
			if not alreadyAdded then
				table.insert(allModules, {Object = object, Return = require(object) :: any})
				Pronghorn.ModuleStatus[object] = {Status = 0}
			end
		else
			for _, child in object:GetChildren() do
				addModules(allModules, child)
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- @todo
function Pronghorn:SetEnabledChannels(newEnabledChannels: {[string]: boolean}): ()
	Debug:SetEnabledChannels(newEnabledChannels)
end

--- @todo
--- @yields
function Pronghorn:Import(paths: {Instance}): ()
	if Pronghorn.Importing then
		error("Pronghorn:Import() cannot be called more than once", 0)
	end

	Pronghorn.Importing = true

	local allModules: {Module} = {}

	for _, object in paths do
		addModules(allModules, object)
	end

	-- Init
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Init then
			local thread = task.spawn(moduleTable.Return.Init :: (self: typeof(moduleTable.Return)) -> (), moduleTable.Return)
			if coroutine.status(thread) ~= "dead" then
				error(`{moduleTable.Object:GetFullName()}: Yielded during Init function`, 0)
			end
		end
		Pronghorn.ModuleStatus[moduleTable.Object].Status = 1
	end

	-- Deferred
	startWaits = 0
	for _, moduleTable in allModules do
		if type(moduleTable.Return) == "table" and moduleTable.Return.Deferred then
			startWaits += 1
			task.spawn(function()
				local running = true
				task.delay(15, function()
					if running then
						warn(`{moduleTable.Object:GetFullName()}: Infinite yield possible in Deferred function`)
					end
				end)
				;(moduleTable.Return.Deferred :: (self: typeof(moduleTable.Return)) -> ())(moduleTable.Return)
				running = false
				Pronghorn.ModuleStatus[moduleTable.Object].Status = 2
				startWaits -= 1
				if startWaits == 0 then
					Pronghorn.DeferredComplete:Fire()
				end
			end)
		else
			Pronghorn.ModuleStatus[moduleTable.Object].Status = 2
		end
	end
	if startWaits == 0 then
		Pronghorn.DeferredComplete:Fire()
	end

	-- PlayerAdded
	local function playerAdded(player: Player): ()
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerAdded then
				task.spawn(moduleTable.Return.PlayerAdded :: (player: Player) -> (), player)
			end
		end
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerAddedDeferred then
				task.spawn(moduleTable.Return.PlayerAddedDeferred :: (player: Player) -> (), player)
			end
		end
	end
	Players.PlayerAdded:Connect(playerAdded)
	for _, player in Players:GetPlayers() do
		playerAdded(player)
	end

	-- PlayerRemoving / PlayerRemoved
	Players.PlayerRemoving:Connect(function(player: Player): ()
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemoving then
				task.spawn(moduleTable.Return.PlayerRemoving :: (player: Player) -> (), player)
			end
		end
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemovingDeferred then
				task.spawn(moduleTable.Return.PlayerRemovingDeferred :: (player: Player) -> (), player)
			end
		end
		if player.Parent then player.AncestryChanged:Wait() end
		pcall(player.Destroy, player)
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemoved then
				task.spawn(moduleTable.Return.PlayerRemoved :: (player: Player) -> (), player)
			end
		end
		for _, moduleTable in allModules do
			if type(moduleTable.Return) == "table" and moduleTable.Return.PlayerRemovedDeferred then
				task.spawn(moduleTable.Return.PlayerRemovedDeferred :: (player: Player) -> (), player)
			end
		end
	end)

	Pronghorn.Imported:Fire()

	-- Wait for Deferred Functions to complete
	Pronghorn.DeferredComplete.Event:Wait()
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Import Core Modules --

local coreModules = {}

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		coreModules[child.Name] = require(child) :: any
	end
end

-- Init
for _, coreModule in coreModules do
	if type(coreModule) == "table" and coreModule.Init then
		coreModule:Init()
	end
end

-- Deferred
for _, coreModule in coreModules do
	if type(coreModule) == "table" and coreModule.Deferred then
		task.spawn(coreModule.Deferred, coreModule)
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Pronghorn
