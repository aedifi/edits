-- tool.lua
-- Handlers for tool functions.

function HandleReplCommand(a_Split, a_Player)
	if a_Split[2] == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //repl <block>")
		return true
	end

	local BlockType, BlockMeta = GetBlockTypeMeta(a_Split[2])

	if (not BlockType) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	if not IsValidBlock(BlockType) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local function ReplaceHandler(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		if (a_BlockFace == BLOCK_FACE_NONE) then
			return true
		end

		local AffectedBlock = cCuboid(a_BlockX, a_BlockY, a_BlockZ)
		if (CallHook("OnAreaChanging", AffectedBlock, a_Player, a_Player:GetWorld(), "replacetool")) then
			return true
		end

		a_Player:GetWorld():SetBlock(a_BlockX, a_BlockY, a_BlockZ, BlockType, BlockMeta)
		CallHook("OnAreaChanged", AffectedBlock, a_Player, a_Player:GetWorld(), "replacetool")
		return false
	end

	local State = GetPlayerState(a_Player)
	local Success, error = State.ToolRegistrator:BindRightClickTool(a_Player:GetEquippedItem().m_ItemType, ReplaceHandler, "replacetool")

	if (not Success) then
		a_Player:SendMessage(cChatColor.LightGray .. error)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Bound the tool to your " .. ItemToString(a_Player:GetEquippedItem()) .. ".")
	return true
end

function HandleUnbindCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	local Success, error = State.ToolRegistrator:UnbindTool(a_Player:GetEquippedItem().m_ItemType)
	local SuccessMask, errorMask = State.ToolRegistrator:UnbindMask(a_Player:GetEquippedItem().m_ItemType)

	if ((not Success) and (not SuccessMask)) then
		a_Player:SendMessage(cChatColor.LightGray .. error)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Stripped your item of any bindings.")
	return true
end

function HandleTreeCommand(a_Split, a_Player)
	local function HandleTree(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		if (a_BlockFace == BLOCK_FACE_NONE) then
			return false
		end

		local World = a_Player:GetWorld()
		if (World:GetBlock(a_BlockX, a_BlockY, a_BlockZ) == E_BLOCK_GRASS) or (World:GetBlock(a_BlockX, a_BlockY, a_BlockZ) == E_BLOCK_DIRT) then
			World:GrowTree(a_BlockX, a_BlockY + 1, a_BlockZ)
		else
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't put a tree there.")
		end
	end

	local State = GetPlayerState(a_Player)
	local Success, error = State.ToolRegistrator:BindRightClickTool(a_Player:GetEquippedItem().m_ItemType, HandleTree, "tree")

	if (not Success) then
		a_Player:SendMessage(cChatColor.Rose .. error)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Bound the tool to your " .. ItemToString(a_Player:GetEquippedItem()) .. ".")
	return true
end

function HandlePickaxeCommand(a_Split, a_Player)
	local Pickaxes =
	{
		E_ITEM_WOODEN_PICKAXE,
		E_ITEM_STONE_PICKAXE,
		E_ITEM_IRON_PICKAXE,
		E_ITEM_GOLD_PICKAXE,
		E_ITEM_DIAMOND_PICKAXE,
	}

	local function SuperPickaxe(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		local AffectedArea = cCuboid(a_BlockX, a_BlockY, a_BlockZ)
		if (CallHook("OnAreaChanging", AffectedArea, a_Player, a_Player:GetWorld(), "superpickaxe")) then
			return true
		end

		local World = a_Player:GetWorld()
		World:BroadcastSoundParticleEffect(2001, Vector3i(a_BlockX, a_BlockY, a_BlockZ), World:GetBlock(a_BlockX, a_BlockY, a_BlockZ))
		World:DigBlock(a_BlockX, a_BlockY, a_BlockZ)

		CallHook("OnAreaChanged", AffectedArea, a_Player, a_Player:GetWorld(), "superpickaxe")
	end

    local State = GetPlayerState(a_Player)
    
	local WasActivated = false
	for Idx, Pickaxe in ipairs(Pickaxes) do
		local Info = State.ToolRegistrator:GetLeftClickCallbackInfo(Pickaxe)
		if (Info) then
			WasActivated = WasActivated or (Info.ToolName == "superpickaxe")
		end
	end

	if (WasActivated) then
		a_Player:SendMessage(cChatColor.LightGray .. "Disabled your super pickaxe.")
		State.ToolRegistrator:UnbindTool(Pickaxes, "superpickaxe")
	else
		a_Player:SendMessage(cChatColor.LightGray .. "Enabled your super pickaxe.")
		State.ToolRegistrator:BindLeftClickTool(Pickaxes, SuperPickaxe, "superpickaxe")
	end
	return true
end

function HandleFarwandCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)

	local FarWand = function(a_Player, a_BlockFace, a_Point)
		if (a_BlockFace ~= BLOCK_FACE_NONE) then
			return true
		end

		local TargetBlock, BlockFace = GetTargetBlock(a_Player)
		if (not TargetBlock) then
			return true
		end

		local Success, Msg = State.Selection:SetPos(TargetBlock.x, TargetBlock.y, TargetBlock.z, BlockFace, a_Point)
		a_Player:SendMessage(Msg)
		return true
	end

	local LeftClick = function(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		return FarWand(a_Player, a_BlockFace, "First")
	end

	local RightClick = function(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		return FarWand(a_Player, a_BlockFace, "Second")
	end

	local EquippedItemType = a_Player:GetInventory():GetEquippedItem().m_ItemType
	local Success, Err = State.ToolRegistrator:BindRightClickTool(EquippedItemType, RightClick, "farwand")
	if (not Success) then
		a_Player:SendMessage(cChatColor.Rose .. Err)
		return true
	end

	Success, Err = State.ToolRegistrator:BindLeftClickTool(EquippedItemType, LeftClick, "farwand")
	if (not Success) then
		a_Player:SendMessage(cChatColor.Rose .. Err)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Bound the tool to your " .. ItemToString(a_Player:GetEquippedItem()) .. ".")
	return true
end
