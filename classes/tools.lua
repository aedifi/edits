-- tools.lua
-- Represents the tools used by a player.

cToolRegistrator = {}

function cToolRegistrator:new(a_Obj)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cToolRegistrator)
	self.__index = self
	a_Obj.RightClickTools = {}
	a_Obj.LeftClickTools  = {}
	a_Obj.Masks = {}
	a_Obj:BindAbsoluteTools()
	return a_Obj
end

function cToolRegistrator:BindAbsoluteTools()
	local function RightClickCompassCallback(a_Player, _, _, _, a_BlockFace)
		if (not a_Player:HasPermission("worldedit.navigation.thru.tool")) then
			return false
		end
		if (a_BlockFace ~= BLOCK_FACE_NONE) then
			return true
		end
		RightClickCompass(a_Player)
		return true
	end
	local LastLeftClick = -math.huge
	local function LeftClickCompassCallback(a_Player, _, _, _, a_BlockFace)
		if (not a_Player:HasPermission("worldedit.navigation.jumpto.tool")) then
			return false
		end
		if (a_BlockFace ~= BLOCK_FACE_NONE) then
			return true
		end
		if ((os.clock() - LastLeftClick) < 0.20) then
			return true
		end
		LastLeftClick = os.clock()
		LeftClickCompass(a_Player)
		return true
	end
	local LastRightClick = -math.huge
	local function OnPlayerRightClick(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		local Succ, Message = GetPlayerState(a_Player).Selection:SetPos(a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, "Second")
		if (not Succ) then
			return false
		end
		-- Protection against the second packet when the second position is indicated.
		if ((os.clock() - LastRightClick) < 0.005) then
			return true
		end
		LastRightClick = os.clock()
		a_Player:SendMessage(Message)
		return true
	end
	local LastLeftClick = -math.huge
	local function OnPlayerLeftClick(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		local Succ, Message = GetPlayerState(a_Player).Selection:SetPos(a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, "First")
		if (not Succ) then
			return false
		end
		-- Protection against the second packet when the first position is indicated.
		if ((os.clock() - LastLeftClick) < 0.005) then
			return true
		end
		LastLeftClick = os.clock()
		a_Player:SendMessage(Message)
		return true
	end
	self:BindRightClickTool(g_Config.NavigationWand.Item, RightClickCompassCallback, "thru tool", true)
	self:BindRightClickTool(g_Config.WandItem,            OnPlayerRightClick, "selection", true)
	self:BindLeftClickTool(g_Config.NavigationWand.Item,  LeftClickCompassCallback, "jumpto tool", true)
	self:BindLeftClickTool(g_Config.WandItem,             OnPlayerLeftClick, "selection", true)
end

function cToolRegistrator:GetMask(a_ItemType)
	if (self.Masks[a_ItemType] == nil) then
		return nil
	end
	return self.Masks[a_ItemType]
end

function cToolRegistrator:BindMask(a_ItemType, a_Blocks)
	self.Masks[a_ItemType] = a_Blocks
	return true
end

function cToolRegistrator:UnbindMask(a_ItemType)
	if (self.Masks[a_ItemType] == nil) then
		return false, "Couldn't find any masks bound to that item."
	end

	self.Masks[a_ItemType] = nil
	return true
end

function cToolRegistrator:BindRightClickTool(a_ItemType, a_UsageCallback, a_ToolName, a_IsAbsolute)
	if (type(a_ItemType) == "table") then
		local Success, Error = nil, {}
		for Idx, ItemType in ipairs(a_ItemType) do
			local Suc, Err = self:BindRightClickTool(ItemType, a_UsageCallback, a_ToolName)
			Success = Success and Suc, not Suc and table.insert(Error, Err)
		end
		return Success, Error
	end
	if ((self.RightClickTools[a_ItemType] ~= nil) and self.RightClickTools[a_ItemType].IsAbsolute) then
		return false, "Couldn't bind a tool to an item that's already bound."
	end
	self.RightClickTools[a_ItemType] = {Callback = a_UsageCallback, ToolName = a_ToolName, IsAbsolute = a_IsAbsolute}
	return true
end

function cToolRegistrator:UseRightClickTool(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_ItemType)
	if (self.RightClickTools[a_ItemType] == nil) then
		return false
	end
	return self.RightClickTools[a_ItemType].Callback(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
end

function cToolRegistrator:GetRightClickCallbackInfo(a_ItemType)
	return self.RightClickTools[a_ItemType] or false
end

function cToolRegistrator:BindLeftClickTool(a_ItemType, a_UsageCallback, a_ToolName, a_IsAbsolute)
	if (type(a_ItemType) == "table") then
		local Success, Error = nil, {}
		for Idx, ItemType in ipairs(a_ItemType) do
			local Suc, Err = self:BindLeftClickTool(ItemType, a_UsageCallback, a_ToolName)
			Success = Success and Suc, not Suc and table.insert(Error, Err)
		end
		return Success, Error
	end
	if ((self.LeftClickTools[a_ItemType] ~= nil) and self.LeftClickTools[a_ItemType].IsAbsolute) then
		return false, "Couldn't bind a tool to an item that's already bound."
	end
	self.LeftClickTools[a_ItemType] = {Callback = a_UsageCallback, ToolName = a_ToolName, IsAbsolute = a_IsAbsolute}
	return true
end

function cToolRegistrator:UseLeftClickTool(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_ItemType)
	if (self.LeftClickTools[a_ItemType] == nil) then
		return false
	end
	return self.LeftClickTools[a_ItemType].Callback(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
end

function cToolRegistrator:GetLeftClickCallbackInfo(a_ItemType)
	return self.LeftClickTools[a_ItemType] or false
end

function cToolRegistrator:UnbindTool(a_ItemType, a_ToolName)
	if (type(a_ItemType) == "table") then
		local Success, Errors = nil, {}
		for Idx, ItemType in ipairs(a_ItemType) do
			local Suc, Err = self:UnbindTool(ItemType, a_ToolName)
			Success = Success and Suc, not Suc and table.insert(Errors, Err)
		end
		return Success, Errors
	end
	if ((self.RightClickTools[a_ItemType] == nil) and (self.LeftClickTools[a_ItemType] == nil)) then
		return false, "Couldn't find any tools bound to that item."
	end
	if (a_ToolName) then
		if ((self.RightClickTools[a_ItemType] or {}).ToolName == a_ToolName) then
			self.RightClickTools[a_ItemType] = nil
		end
		if ((self.LeftClickTools[a_ItemType] or {}).ToolName == a_ToolName) then
			self.LeftClickTools[a_ItemType] = nil
		end

		return true
	end
	if ((self.LeftClickTools[a_ItemType] ~= nil) and (not self.LeftClickTools[a_ItemType].IsAbsolute)) then
		self.LeftClickTools[a_ItemType] = nil
	end
	if ((self.RightClickTools[a_ItemType] ~= nil) and (not self.RightClickTools[a_ItemType].IsAbsolute)) then
		self.RightClickTools[a_ItemType] = nil
	end
	return true
end

local function RightClickToolsHook(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_CursorX, a_CursorY, a_CursorZ)
	local State = GetPlayerState(a_Player)
	return State.ToolRegistrator:UseRightClickTool(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_Player:GetEquippedItem().m_ItemType)
end

local function LeftClickToolsHook(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_Action)
	if (a_Action ~= 0) then
		return false
	end
	local State = GetPlayerState(a_Player)
	State.ToolRegistrator:UseLeftClickTool(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_Player:GetEquippedItem().m_ItemType)
end

local function PlayerBrokeBlockHook(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
	if a_Player:GetEquippedItem().m_ItemType == E_ITEM_WOODEN_AXE then
		a_Player:GetWorld():SetBlock(a_BlockX, a_BlockY, a_BlockZ, a_BlockType, a_BlockMeta)
	end
end

local function LeftClickToolsAnimationHook(a_Player, a_Animation)
	local LeftClickAnimation = (a_Player:GetClientHandle():GetProtocolVersion() > 5) and 0 or 1
	if (a_Animation ~= LeftClickAnimation) then
		return false
	end
	local State = GetPlayerState(a_Player)
	return State.ToolRegistrator:UseLeftClickTool(a_Player, 0, 0, 0, BLOCK_FACE_NONE, a_Player:GetEquippedItem().m_ItemType)
end

cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_RIGHT_CLICK, RightClickToolsHook);
cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_LEFT_CLICK, LeftClickToolsHook);
cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_BROKEN_BLOCK, PlayerBrokeBlockHook);
cPluginManager.AddHook(cPluginManager.HOOK_PLAYER_ANIMATION, LeftClickToolsAnimationHook);