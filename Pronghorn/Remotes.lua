--!strict
--!optimize 2
--!native
--[[
╔═══════════════════════════════════════════════╗
║              Pronghorn Framework              ║
║  https://iron-stag-games.github.io/Pronghorn  ║
╚═══════════════════════════════════════════════╝
]]

local a = if game:GetService("RunService"):IsServer() then "__s" else "__c"
if not script:GetAttribute(a) then script:SetAttribute(a, true) else error("Required Pronghorn/Remotes from more than one Luau VM; please use BindableFunctions", 0) end

local Jolt = require(script.Parent.Jolt)

local Remotes = {
	Server = Jolt.Server;
	Client = Jolt.Client;
}

function Remotes:Init()
	-- Jolt initializes automatically
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Remotes
