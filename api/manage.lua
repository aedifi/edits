-- manage.lua
-- Implements functions for external plugins to manipulate the state.

g_Hooks = {
	["OnAreaChanging"] = {}, -- function(a_AffectedAreaCuboid, a_Player, a_World, a_Operation)
	["OnAreaChanged"] = {}, -- function(a_AffectedAreaCuboid, a_Player, a_World, a_Operation)
	["OnAreaCopied"] = {}, -- function(a_Player, a_World, a_CopiedAreaCuboid)
	["OnAreaCopying"] = {}, -- function(a_Player, a_World, a_CopiedAreaCuboid)
	["OnPlayerSelectionChanging"] = {}, -- function(a_Player, a_PosX, a_PosY, a_PosZ, a_PointNr)
	["OnPlayerSelectionChanged"] = {}, -- function(a_Player, a_PosX, a_PosY, a_PosZ, a_PointNr)
}

-- Registers a hook.
-- All arguments are strings.
function AddHook(a_HookName, a_PluginName, a_CallbackName)
	if (
		(type(a_HookName) ~= "string") or
		(type(a_PluginName)   ~= "string") or (a_PluginName   == "") or not cPluginManager:Get():IsPluginLoaded(a_PluginName) or
		(type(a_CallbackName) ~= "string") or (a_CallbackName == "")
	) then
		LOGWARNING("Invalid callback registration parameters for Edits.")
		LOGWARNING("AddHook() was called with params " ..
			tostring(a_HookName     or "<nil>") .. ", " ..
			tostring(a_PluginName   or "<nil>") .. ", " ..
			tostring(a_CallbackName or "<nil>")
		)
		return false
	end

	if (not g_Hooks[a_HookName]) then
		LOGWARNING("Plugin \"" .. a_PluginName .. "\" tried to register an unexisting hook for Edits called \"" .. a_HookName .. "\".")
		return false
	end

	table.insert(g_Hooks[a_HookName], {PluginName = a_PluginName, CallbackName = a_CallbackName})
	return true
end

function RegisterAreaCallback(a_PluginName, a_FunctionName, a_WorldName)
	LOGWARNING("RegisterAreaCallback for Edits is obsolete. Please use AddHook(\"OnAreaChanging\", ...).")
	LOGWARNING("The callback signature changed as well. All individual coordinates are now a single cCuboid.")
	return AddHook("OnAreaChanging", a_PluginName, a_FunctionName)
end

function RegisterPlayerSelectingPoint(a_PluginName, a_FunctionName)
	LOGWARNING("RegisterPlayerSelectingPoint for Edits is obsolete. Please use AddHook(\"OnPlayerSelectionChanging\", ...).")
	LOGWARNING("The callback signature changed as well. All individual coordinates are now a single cCuboid.")
	return AddHook("OnPlayerSelectionChanging", a_PluginName, a_FunctionName)
end

function SetPlayerCuboidSelection(a_Player, a_Cuboid)
	if (
		(tolua.type(a_Player) ~= "cPlayer") or
		(tolua.type(a_Cuboid) ~= "cCuboid")
	) then
		LOGWARNING("Invalid SetPlayerCuboidSelection for Edits API function parameters.")
		LOGWARNING("SetPlayerCuboidSelection() was called with param types \"" ..
			tolua.type(a_Player) .. "\" (\"cPlayer\" wanted) and \"" ..
			tolua.type(a_Cuboid) .. "\" (\"cCuboid\" wanted)."
		)
		return false
	end

	local State = GetPlayerState(a_Player)
	State.Selection:SetFirstPoint(a_Cuboid.p1.x, a_Cuboid.p1.y, a_Cuboid.p1.z)
	State.Selection:SetSecondPoint(a_Cuboid.p2.x, a_Cuboid.p2.y, a_Cuboid.p2.z)
	return true
end

function SetPlayerCuboidSelectionPoint(a_Player, a_PointNumber, a_CoordVector)
	if (
		(tolua.type(a_Player)      ~= "cPlayer") or
		(tonumber(a_PointNumber)   == nil)  or
		(tolua.type(a_CoordVector) ~= "Vector3i")
	) then
		LOGWARNING("Invalid SetPlayerCuboidSelectionPoint for Edits API function parameters.")
		LOGWARNING("SetPlayerCuboidSelection() was called with param types \"" ..
			tolua.type(a_Player) .. "\" (\"cPlayer\" wanted), \"" ..
			type(a_PointNumber) .. "\" (\"number\" wanted) and \"" ..
			tolua.type(a_CoordVector) .. "\" (\"cVector3i\" wanted)."
		)
		return false
	end

	local State = GetPlayerState(a_Player)
	if (tonumber(a_PointNumber) == 1) then
		State.Selection:SetFirstPoint(a_CoordVector)
	elseif (tonumber(a_PointNumber) == 2) then
		State.Selection:SetSecondPoint(a_CoordVector)
	else
		LOGWARNING("Invalid SetPlayerCuboidSelectionPoint for Edits API function parameters.")
		LOGWARNING("SetPlayerCuboidSelection() was called with invalid point number " .. a_PointNumber)
		return false
	end
	return true
end

function IsPlayerSelectionCuboid(a_Player)
	return true
end

function GetPlayerCuboidSelection(a_Player, a_CuboidToSet)
	if (
		(tolua.type(a_Player)      ~= "cPlayer") or
		(tolua.type(a_CuboidToSet) ~= "cCuboid")
	) then
		LOGWARNING("Invalid SetPlayerCuboidSelection for Edits API function parameters.")
		LOGWARNING("SetPlayerCuboidSelection() was called with param types \"" ..
			tolua.type(a_Player) .. "\" (\"cPlayer\" wanted) and \"" ..
			tolua.type(a_CuboidToSet) .. "\" (\"cCuboid\" wanted)."
		)
		return false
	end

	local State = GetPlayerState(a_Player)
	a_CuboidToSet:Assign(State.Selection.Cuboid)
	return true
end

function WEPushUndo(a_Player, a_World, a_Cuboid, a_Description)
	if (
		(tolua.type(a_Player) ~= "cPlayer") or
		(tolua.type(a_World)  ~= "cWorld")  or
		(tolua.type(a_Cuboid) ~= "cCuboid") or
		(type(a_Description)  ~= "string")
	) then
		LOGWARNING("Invalid WEPushUndo for Edits API function parameters.")
		LOGWARNING("WePushUndo() was called with these param types:")
		LOGWARNING("    " .. tolua.type(a_Player) .. " (cPlayer wanted),")
		LOGWARNING("    " .. tolua.type(a_World)  .. " (cWorld  wanted),")
		LOGWARNING("    " .. tolua.type(a_Cuboid) .. " (cCuboid wanted),")
		LOGWARNING("    " .. type(a_Description)  .. " (string  wanted),")
		return false, "bad params"
	end

	local State = GetPlayerState(a_Player)
	return State.UndoStack:PushUndoFromCuboid(a_World, a_Cuboid, a_Description)
end

function WEPushUndoAsync(a_Player, a_World, a_Cuboid, a_Description, a_CallbackPluginName, a_CallbackFunctionName)
	if (
		(tolua.type(a_Player)         ~= "cPlayer") or
		(tolua.type(a_World)          ~= "cWorld")  or
		(tolua.type(a_Cuboid)         ~= "cCuboid") or
		(type(a_Description)          ~= "string") or
		(type(a_CallbackPluginName)   ~= "string") or
		(type(a_CallbackFunctionName) ~= "string")
	) then
		LOGWARNING("Invalid WEPushUndoAsync() for Edits API function parameters.")
		LOGWARNING("WePushUndo() was called with these param types:")
		LOGWARNING("    " .. tolua.type(a_Player)         .. " (cPlayer wanted),")
		LOGWARNING("    " .. tolua.type(a_World)          .. " (cWorld  wanted),")
		LOGWARNING("    " .. tolua.type(a_Cuboid)         .. " (cCuboid wanted),")
		LOGWARNING("    " .. type(a_Description)          .. " (string  wanted),")
		LOGWARNING("    " .. type(a_CallbackPluginName)   .. " (string  wanted),")
		LOGWARNING("    " .. type(a_CallbackFunctionName) .. " (string  wanted),")
		return false, "bad params"
	end

	if not(a_Cuboid:IsSorted()) then
		a_Cuboid = cCuboid(a_Cuboid)
		a_Cuboid:Sort()
	end

	local State = GetPlayerState(a_Player)
	local OnAllChunksAvailable = function()
		local IsSuccess, Msg = State.UndoStack:PushUndoFromCuboid(a_World, a_Cuboid, a_Description)
		cPluginManager:CallPlugin(a_CallbackPluginName, a_CallbackFunctionName, IsSuccess, Msg)
	end

	local Chunks = ListChunksForCuboid(a_Cuboid)

	a_World:ChunkStay(Chunks, nil, OnAllChunksAvailable)
	return true
end

function ExecuteString(a_String, ...)
	local Function, Error = loadstring(a_String)
	if (not Function) then
		return false, Error
	end

	return pcall(Function, ...)
end