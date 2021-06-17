-- state.lua
-- Implements the cPlayerState object which represents information remembered per player.
-- GetPlayerState () retrives and initializes the player state.

local g_PlayerStates = {}

local cPlayerState = {}

function cPlayerState:new(a_Obj, a_PlayerKey, a_Player)
	assert(a_PlayerKey ~= nil)
	assert(a_Player ~= nil)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cPlayerState)
	self.__index = self
	local ClientHandle = a_Player:GetClientHandle()
	a_Obj.Clipboard = cClipboard:new()
	if (ClientHandle ~= nil) then
		a_Obj.IsWECUIActivated = ClientHandle:HasPluginChannel("WECUI")
	end
	a_Obj.PlayerKey = a_PlayerKey
	a_Obj.Selection = cPlayerSelection:new({}, a_Obj)
	a_Obj.UndoStack = cUndoStack:new({}, 10, a_Obj)
	a_Obj.WandActivated = true
	a_Obj.ToolRegistrator = cToolRegistrator:new({})
	a_Obj.CraftScript = cCraftScript:new({})
	return a_Obj
end

function cPlayerState:DoWithPlayer(a_Callback)
	local HasCalled = false
	cRoot:Get():ForEachPlayer(
		function(a_Player)
			if (a_Player:GetName() == self.PlayerKey) then
				HasCalled = true
				a_Callback(a_Player)
				return true
			end
		end
	)
	return HasCalled
end

function cPlayerState:GetUUID()
	local UUID = nil
	self:DoWithPlayer(
		function(a_Player)
			UUID = a_Player:GetUUID()
		end
	)
	return UUID
end

function cPlayerState:Load()
	local UUID = self:GetUUID()

	if (g_Config.Storage.RememberPlayerSelection) then
		self.Selection:Load(UUID)
	end
end

function cPlayerState:PushUndoInSelection(a_World, a_UndoName)
	local Area = cBlockArea()
	local MinX, MaxX = self.Selection:GetXCoordsSorted()
	local MinY, MaxY = self.Selection:GetYCoordsSorted()
	local MinZ, MaxZ = self.Selection:GetZCoordsSorted()
	Area:Read(a_World, MinX, MaxX, MinY, MaxY, MinZ, MaxZ)
	self.UndoStack:PushUndo(a_World, Area, a_UndoName)
end

function cPlayerState:Save(a_PlayerUUID)
	if (g_Config.Storage.RememberPlayerSelection) then
		self.Selection:Save(a_PlayerUUID)
	end
end

function GetPlayerState(a_Player)
	assert(tolua.type(a_Player) == "cPlayer")
	local Key = a_Player:GetName()
	local res = g_PlayerStates[Key]
	if (res ~= nil) then
		return res
	end
	res = cPlayerState:new({}, Key, a_Player)
	g_PlayerStates[Key] = res
	res:Load()
	return res
end

local function OnPlayerDestroyed(a_Player)
	local State = g_PlayerStates[a_Player:GetName()]
	if (State == nil) then
		return false
	end
	State:Save(a_Player:GetUUID())
	g_PlayerStates[a_Player:GetName()] = nil
end

function ForEachPlayerState(a_Callback)
	assert(type(a_Callback) == "function")
	for _, State in pairs(g_PlayerStates) do
		if (a_Callback(State)) then
			break
		end
	end
end

local function OnPluginMessage(a_Client, a_Channel, a_Message)
	if (a_Channel ~= "REGISTER") then
		return
	end
	local Player = a_Client:GetPlayer()
	if (Player == nil) then
		return
	end
	local State = GetPlayerState(Player)
	State.IsWECUIActivated = a_Client:HasPluginChannel("WECUI")
	State.Selection:NotifySelectionChanged()
end

cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)
cPluginManager.AddHook(cPluginManager.HOOK_PLUGIN_MESSAGE, OnPluginMessage)
