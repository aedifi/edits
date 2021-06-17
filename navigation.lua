-- navigation.lua
-- Implements navigation-related commands.

function HandleUpCommand(a_Split, a_Player)
	if #a_Split < 2 then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //up <height>")
		return true
	elseif #a_Split > 2 then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //up <height>")
		return true
	end

	local Height = tonumber(a_Split[2])
	if (Height == nil) then -- The given string isn't a number, so bail out.
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't move you to a non-numeric height.")
		return true
	end

	local P1 = a_Player:GetPosition():Floor()
	local P2 = a_Player:GetPosition():Floor()
	P2.y = P2.y + Height

	local World = a_Player:GetWorld()
	for Y = P1.y, P2.y + 1 do
		if (World:GetBlock(P1.x, Y, P1.z) ~= E_BLOCK_AIR) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't move you because you'd hit something.")
			return true
		end
	end

	local ChangeCuboid = cCuboid(P2, P2)
	if (CallHook("OnAreaChanging", ChangeCuboid, a_Player, World, "up")) then
		return true
	end

	World:SetBlock(P1.x, P2.y - 1, P1.z, E_BLOCK_GLASS, 0)
	a_Player:TeleportToCoords(P1.x + 0.5, P2.y, P1.z + 0.5)
	a_Player:SendMessage(cChatColor.LightGray .. "Sent you upward.")

	CallHook("OnAreaChanged", ChangeCuboid, a_Player, World, "up")
	return true
end

function HandleAscendCommand(a_Split, a_Player)
	local World = a_Player:GetWorld()
	local XPos = math.floor(a_Player:GetPosX())
	local YPos = a_Player:GetPosY()
	local ZPos = math.floor(a_Player:GetPosZ())

	local IsValid, WorldHeight = World:TryGetHeight(XPos, ZPos)

	if not IsValid then
		a_Player:SendMessage(cChatColor.LightGray .. "Ascended you to the clouds.")
		return true
	end

	if a_Player:GetPosY() == WorldHeight then
		a_Player:SendMessage(cChatColor.LightGray .. "Ascended you to the clouds.")
		return true
	end

	local WentThroughBlock = false

	for Y = math.floor(a_Player:GetPosY()), WorldHeight + 1 do
		if World:GetBlock(XPos, Y, ZPos) == E_BLOCK_AIR then
			if WentThroughBlock then
				YPos = Y
				break
			end
		else
			WentThroughBlock = true
		end
	end

	if WentThroughBlock then
		a_Player:TeleportToCoords(a_Player:GetPosX(), YPos, a_Player:GetPosZ())
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Ascended you to the clouds.")
	return true
end

function HandleDescendCommand(a_Split, a_Player)
	local World = a_Player:GetWorld()
	if a_Player:GetPosY() < 1 then
		a_Player:SendMessage(cChatColor.LightGray .. "Descended you to the depths.")
		return true
	end

	local FoundYCoordinate = false
	local WentThroughBlock = false
	local XPos = math.floor(a_Player:GetPosX())
	local YPos = a_Player:GetPosY()
	local ZPos = math.floor(a_Player:GetPosZ())

	for Y = math.floor(YPos), 1, -1 do
		if World:GetBlock(XPos, Y, ZPos) ~= E_BLOCK_AIR then
			WentThroughBlock = true
		else
			if WentThroughBlock then
				for y = Y, 1, -1 do
					if cBlockInfo:IsSolid(World:GetBlock(XPos, y, ZPos)) then
						YPos = y
						FoundYCoordinate = true
						break
					end
				end

				if FoundYCoordinate then
					break
				end
			end
		end
	end

	if FoundYCoordinate then
		a_Player:TeleportToCoords(a_Player:GetPosX(), YPos + 1, a_Player:GetPosZ())
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Descended you to the depths.")
	return true
end

function HandleThruCommand(Split, a_Player)
	if (#Split ~= 1) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: /thru")
		return true
	end

	RightClickCompass(a_Player, a_Player:GetWorld())
	a_Player:SendMessage(cChatColor.LightGray .. "Took you through a level.")
	return true
end
