--[[
	@class ServerMain
]]

local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.menuprompt:FindFirstChild("loader", true).Parent
require(loader).bootstrapGame(ServerScriptService.menuprompt)