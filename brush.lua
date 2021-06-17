-- brush.lua
-- Implements handlers for brush-related commands.

function HandleBrushMainCommand(a_Split, a_Player)
	a_Player:SendMessage(cChatColor.LightGray .. "Usage: //brush <cylinder [...] | sphere [...]>")
	return true
end

function HandleMaskCommand(a_Split, a_Player)
	if (#a_Split == 1) then
		local State = GetPlayerState(a_Player)
		local Success, error = State.ToolRegistrator:UnbindMask(a_Player:GetEquippedItem().m_ItemType)

		if (not Success) then
			a_Player:SendMessage(cChatColor.LightGray .. error)
			return true
		end
		a_Player:SendMessage(cChatColor.LightGray .. "Disabled your brush mask.")
		return true
	end

	local Mask, ErrBlock = cMask:new(a_Split[2])
	if not(Mask) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local State = GetPlayerState(a_Player)
	local Success, error = State.ToolRegistrator:BindMask(a_Player:GetEquippedItem().m_ItemType, Mask)

	if (not Success) then
		a_Player:SendMessage(cChatColor.LightGray .. error)
		return true
	end
	a_Player:SendMessage(cChatColor.LightGray .. "Set your brush mask.")
	return true
end

function HandleSphereBrush(a_Split, a_Player)
	if (#a_Split < 4) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //brush sphere [-h] <block> <radius>")
		return true
	end

	local Hollow = false
	if (a_Split[3] == "-h") then
		Hollow = true
		table.remove(a_Split, 3)
	end

	local BlockTable, ErrBlock = GetBlockDst(a_Split[3], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local Radius = tonumber(a_Split[4])
	if not(Radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
		return true
	end

	if (Radius > g_Config.Limits.MaxBrushRadius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert a radius over the limit of " .. g_Config.Limits.MaxBrushRadius .. ".")
		return true
	end

	local State = GetPlayerState(a_Player)
	local function BrushHandler(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		local Position = (a_BlockFace == BLOCK_FACE_NONE and GetTargetBlock(a_Player)) or Vector3i(a_BlockX, a_BlockY, a_BlockZ)

		if (not Position) then
			return true
		end

		local AffectedArea = cCuboid(Position, Position)
		AffectedArea:Expand(Radius, Radius, Radius, Radius, Radius, Radius)
		AffectedArea:Sort()

		-- Get the mask. We can't put this outside the brush handler, because the player might have changed it already.
		local Mask = State.ToolRegistrator:GetMask(a_Player:GetEquippedItem().m_ItemType)

		CreateSphereInCuboid(a_Player, AffectedArea, BlockTable, Hollow, Mask)
		return true
	end

	local Success, error = State.ToolRegistrator:BindRightClickTool(a_Player:GetEquippedItem().m_ItemType, BrushHandler, "brush")
	if (not Success) then
		a_Player:SendMessage(cChatColor.LightGray .. error)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Equipped a sphere brush shape of " .. Radius .. ".")
	return true
end

function HandleCylinderBrush(a_Split, a_Player)
	if (#a_Split < 5) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //brush cylinder [-h] <block> <radius> <height>")
		return true
	end

	local Hollow = false
	if (a_Split[3] == "-h") then
		Hollow = true
		table.remove(a_Split, 3)
	end

	local BlockTable, ErrBlock = GetBlockDst(a_Split[3], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local Radius = tonumber(a_Split[4])
	if not(Radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
		return true
	end

	if (Radius > g_Config.Limits.MaxBrushRadius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert a radius over the limit of " .. g_Config.Limits.MaxBrushRadius .. ".")
		return true
	end

	local Height = tonumber(a_Split[5])
	if not(Height) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that height numerically.")
		return true
	end

	local UsedHeight = (Height > 0 and (Height - 1)) or (Height + 1)

	local State = GetPlayerState(a_Player)

	local function BrushHandler(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
		local Position = (a_BlockFace == BLOCK_FACE_NONE and GetTargetBlock(a_Player)) or Vector3i(a_BlockX, a_BlockY, a_BlockZ)

		if (not Position) then
			return true
		end

		local AffectedArea = cCuboid(Position, Position)
		AffectedArea:Expand(Radius, Radius, 0, UsedHeight, Radius, Radius)
		AffectedArea:Sort()

		-- Get the mask. We can't put this outside the brush handler, because the player might have changed it already.
		local Mask = State.ToolRegistrator:GetMask(a_Player:GetEquippedItem().m_ItemType)

		CreateCylinderInCuboid(a_Player, AffectedArea, BlockTable, Hollow, Mask)
		return true
	end

	local Success, error = State.ToolRegistrator:BindRightClickTool(a_Player:GetEquippedItem().m_ItemType, BrushHandler, "brush")
	if (not Success) then
		a_Player:SendMessage(cChatColor.LightGray .. error)
		return true
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Equipped a cylinder brush shape of " .. Radius .. " x " .. Height .. ".")
	return true
end
