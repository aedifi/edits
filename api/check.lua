-- check.lua
-- Checks and passes operations.

-- Checks whether other plugins allow an operation.
-- Returns true to abort, returns false to continue.
-- Called by a_HookName and followed by hook arguments.
function CallHook(a_HookName, ...)
	assert(g_Hooks[a_HookName] ~= nil)
	for idx, callback in ipairs(g_Hooks[a_HookName]) do
		local res = cPluginManager:CallPlugin(callback.PluginName, callback.CallbackName, ...)
		if (res) then
			-- Abort the operation.
			return true
		end
	end
	return false
end

-- Are you kidding ney?
function GetMultipleBlockChanges(MinX, MaxX, MinZ, MaxZ, Player, World, Operation)
	local MinY = 256
	local MaxY = 0
	local Object = {}
	function Object:SetY(Y)
		if Y < MinY then
			MinY = Y
		elseif Y > MaxY then
			MaxY = Y
		end
	end
	function Object:Flush()
		local FinalCuboid = cCuboid(
			Vector3i(MinX, MinY, MinZ),
			Vector3i(MaxX, MaxY, MaxZ)
		)
		return CallHook("OnAreaChanging", FinalCuboid, Player, World, Operation)
	end
	return Object
end
