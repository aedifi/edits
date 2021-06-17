-- terraforming.lua
-- Handlers for terraforming commands.

function HandleDrainCommand(a_Split, a_Player)
	local Radius = tonumber(a_Split[2] or "")
	if (Radius == nil) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //drain <radius>")
		return true
	end

	local Position = a_Player:GetPosition():Floor()
	local Cuboid = cCuboid(Position, Position)
	Cuboid:Expand(Radius, Radius, Radius, Radius, Radius, Radius)
	Cuboid:ClampY(0, 255)
	Cuboid:Sort()

	local World = a_Player:GetWorld()

	if (CallHook("OnAreaChanging", Cuboid, a_Player, World, "drain")) then
		return true
	end

	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, Cuboid, "drain")

	local BlockArea = cBlockArea()
	BlockArea:Read(World, Cuboid)
	local SizeX, SizeY, SizeZ = BlockArea:GetCoordRange()

	local NumBlocks = 0

	for X = 0, SizeX do
		for Y = 0, SizeY do
			for Z = 0, SizeZ do
				local BlockType = BlockArea:GetRelBlockType(X, Y, Z)
				if ((BlockType == E_BLOCK_LAVA) or (BlockType == E_BLOCK_STATIONARY_LAVA) or (BlockType == E_BLOCK_WATER) or (BlockType == E_BLOCK_STATIONARY_WATER)) then
					BlockArea:SetRelBlockType(X, Y, Z, E_BLOCK_AIR)
					NumBlocks = NumBlocks + 1
				end
			end
		end
	end

	BlockArea:Write(World, Cuboid.p1)

	CallHook("OnAreaChanged", Cuboid, a_Player, World, "drain")

	a_Player:SendMessage(cChatColor.LightGray .. "Modified " .. NumBlocks .. " block(s) in total.")
	return true
end

function HandleExtinguishCommand(a_Split, a_Player)
	if a_Split[2] == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //extinguish [radius]")
		return true
	elseif tonumber(a_Split[2]) == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
		return true
	end

	local Radius   = tonumber(a_Split[2])
	local Position = a_Player:GetPosition():Floor()
	local Cuboid   = cCuboid(Position, Position)
	Cuboid:Expand(Radius, Radius, Radius, Radius, Radius, Radius)
	Cuboid:ClampY(0, 255)
	Cuboid:Sort()

	local NumAffectedBlocks = ReplaceBlocksInCuboid(a_Player, Cuboid, cMask:new("51"), GetBlockDst("0"), "extinguish")

	a_Player:SendMessage(cChatColor.LightGray .. "Extinguished " .. NumAffectedBlocks .. " fire(s) in total.")
	return true
end

function HandleGreenCommand(a_Split, a_Player)
	if tonumber(a_Split[2]) == nil or a_Split[2] == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //green <radius>")
		return true
	end

	local Radius = tonumber(a_Split[2])

	local World = a_Player:GetWorld()
	local MinX = math.floor(a_Player:GetPosX()) - Radius
	local MaxX = math.floor(a_Player:GetPosX()) + Radius
	local MinZ = math.floor(a_Player:GetPosZ()) - Radius
	local MaxZ = math.floor(a_Player:GetPosZ()) + Radius
	local YCheck = GetMultipleBlockChanges(MinX, MaxX, MinZ, MaxZ, a_Player, World, "green")
	local PossibleBlockChanges = {}

	for x=MinX, MaxX do
		for z=MinZ, MaxZ do
			local IsValid, y = World:TryGetHeight(x, z)
			if IsValid then
				YCheck:SetY(y)
				if World:GetBlock(x, y, z) == E_BLOCK_DIRT then
					table.insert(PossibleBlockChanges, {X = x, Y = y, Z = z, BlockType = E_BLOCK_GRASS})
				end
			end
		end
	end

	if not YCheck:Flush() then
		for idx, value in ipairs(PossibleBlockChanges) do
			World:SetBlock(value.X, value.Y, value.Z, value.BlockType, 0)
		end
		a_Player:SendMessage(cChatColor.LightGray .. "Greened " .. #PossibleBlockChanges .. " surface(s) in total.")
	end
	return true
end

function HandleFillrCommand(a_Split, a_Player)
	if (#a_Split < 3) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //fillr <block> <radius> [depth] [allowup]");
		return true;
	elseif (#a_Split > 5) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //fillr <block> <radius> [depth] [allowup]");
		return true;
	end

	local blockDst, errorBlock = GetBlockDst(a_Split[2]);
	if (not blockDst) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.");
		return true;
	end

	local radius = tonumber(a_Split[3]);
	if (not radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that radius.")
		return true
	end
	radius = math.floor(radius)

	local depth = radius;
	if (a_Split[4]) then
		depth = tonumber(a_Split[4]);
		if (not depth) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that depth.")
			return true
		end
	end

	local allowUp = true
	if (a_Split[5]) then
		if (a_Split[5]:lower() == "false") then
			allowUp = false
		elseif (a_Split[5]:lower() ~= "true") then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that string.")
			return true
		end
	end

	local playerPos = a_Player:GetPosition():Floor();
	playerPos.y = playerPos.y - 1
	local region = cCuboid(playerPos, playerPos)
	region:Expand(radius, radius, depth, 0, radius, radius)
	region:Sort();

	local numBlocks = FillRecursively(a_Player, region, blockDst, allowUp)

	a_Player:SendMessage(cChatColor.LightGray .. "Modified " .. numBlocks .. " block(s) in total.")
	return true;
end

function HandleFillCommand(a_Split, a_Player)
	if (#a_Split < 3) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //fill <block> <radius> [depth]");
		return true;
	elseif (#a_Split > 4) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //fill <block> <radius> [depth]");
		return true;
	end

	local blockDst, errorBlock = GetBlockDst(a_Split[2]);
	if (not blockDst) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true;
	end

	local radius = tonumber(a_Split[3]);
	if (not radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that radius.")
		return true
	end
	radius = math.floor(radius)

	local depth = radius;
	if (a_Split[4]) then
		depth = tonumber(a_Split[4]);
		if (not depth) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that depth.")
			return true
		end
	end

	local playerPos = a_Player:GetPosition():Floor();
	playerPos.y = playerPos.y - 1
	local region = cCuboid(playerPos, playerPos)
	region:Expand(radius, radius, depth, 0, radius, radius)
	region:Sort();

	local numBlocks = FillNormal(a_Player, region, blockDst)

	a_Player:SendMessage(cChatColor.LightGray .. "Modified " .. numBlocks .. " block(s) in total.")
	return true;
end

function HandleReplaceNearCommand(a_Split, a_Player)
	if (#a_Split < 4) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //replacenear <radius> <src block> <dst block>")
		return true
	elseif (#a_Split > 4) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //replacenear <radius> <src block> <dst block>")
		return true
	end

	local Radius = tonumber(a_Split[2])
	if (not Radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't quantify that radius.")
		return true
	end

	local SrcBlockTable, ErrBlock = cMask:new(a_Split[3])
	if (not SrcBlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local DstBlockTable, ErrBlock = GetBlockDst(a_Split[4], a_Player)
	if (not DstBlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local Cuboid = cCuboid(a_Player:GetPosition():Floor(), a_Player:GetPosition():Floor())
	Cuboid:Expand(Radius, Radius, Radius, Radius, Radius, Radius)
	Cuboid:ClampY(0, 255)
	Cuboid:Sort()

	local NumBlocks = ReplaceBlocksInCuboid(a_Player, Cuboid, SrcBlockTable, DstBlockTable, "replacenear")
	a_Player:SendMessage(cChatColor.LightGray .. "Modified " .. NumBlocks .. " block(s) in total.")

	return true
end

function HandleSnowCommand(a_Split, a_Player)
	if tonumber(a_Split[2]) == nil or a_Split[2] == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //snow <radius>")
		return true
	end

	local Radius = tonumber(a_Split[2])

	local World = a_Player:GetWorld()
	local MinX = math.floor(a_Player:GetPosX()) - Radius
	local MaxX = math.floor(a_Player:GetPosX()) + Radius
	local MinZ = math.floor(a_Player:GetPosZ()) - Radius
	local MaxZ = math.floor(a_Player:GetPosZ()) + Radius
	local YCheck = GetMultipleBlockChanges(MinX, MaxX, MinZ, MaxZ, a_Player, World, "snow")
	local PossibleBlockChanges = {}

	for x=MinX, MaxX do
		for z=MinZ, MaxZ do
			local IsValid, y = World:TryGetHeight(x, z)
			if IsValid then
				YCheck:SetY(y)
				if World:GetBlock(x, y , z) == E_BLOCK_STATIONARY_WATER then
					table.insert(PossibleBlockChanges, {X = x, Y = y, Z = z, BlockType = E_BLOCK_ICE})
				elseif World:GetBlock(x, y , z) == E_BLOCK_LAVA then
					table.insert(PossibleBlockChanges, {X = x, Y = y, Z = z, BlockType = E_BLOCK_OBSIDIAN})
				else
					if cBlockInfo:IsSnowable(World:GetBlock(x, y, z)) then
						table.insert(PossibleBlockChanges, {X = x, Y = y + 1, Z = z, BlockType = E_BLOCK_SNOW})
					end
				end
			end
		end
	end

	if not YCheck:Flush() then
		for idx, value in ipairs(PossibleBlockChanges) do
			World:SetBlock(value.X, value.Y, value.Z, value.BlockType, 0)
		end
		a_Player:SendMessage(cChatColor.LightGray .. "Covered " .. #PossibleBlockChanges .. " surface(s) in total.")
	end
	return true
end

function HandleThawCommand(a_Split, a_Player)
	if tonumber(a_Split[2]) == nil or a_Split[2] == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //thaw <radius>")
		return true
	end

	local Radius = tonumber(a_Split[2])

	local World = a_Player:GetWorld()
	local MinX = math.floor(a_Player:GetPosX()) - Radius
	local MaxX = math.floor(a_Player:GetPosX()) + Radius
	local MinZ = math.floor(a_Player:GetPosZ()) - Radius
	local MaxZ = math.floor(a_Player:GetPosZ()) + Radius
	local YCheck = GetMultipleBlockChanges(MinX, MaxX, MinZ, MaxZ, a_Player, World, "thaw")
	local PossibleBlockChanges = {}

	for x=MinX, MaxX do
		for z=MinZ, MaxZ do
			local IsValid, y = World:TryGetHeight(x, z)
			if IsValid then
				YCheck:SetY(y)
				if World:GetBlock(x, y, z) == E_BLOCK_SNOW then
					table.insert(PossibleBlockChanges, {X = x, Y = y, Z = z, BlockType = E_BLOCK_AIR})
				elseif World:GetBlock(x, y, z) == E_BLOCK_ICE then
					table.insert(PossibleBlockChanges, {X = x, Y = y, Z = z, BlockType = E_BLOCK_WATER})
				end
			end
		end
	end

	if not YCheck:Flush() then
		for idx, value in ipairs(PossibleBlockChanges) do
			World:SetBlock(value.X, value.Y, value.Z, value.BlockType, 0)
		end
		a_Player:SendMessage(cChatColor.LightGray .. "Thawed " .. #PossibleBlockChanges .. " surface(s) in total.")
	end
	return true
end

function HandlePumpkinsCommand(a_Split, a_Player)
	local Radius = not a_Split[2] and 10 or tonumber(a_Split[2])
	if (not Radius) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //pumpkins <radius>")
		return true
	end


	local PosX = math.floor(a_Player:GetPosX())
	local PosZ = math.floor(a_Player:GetPosZ())
	local World = a_Player:GetWorld()

	local YCheck = GetMultipleBlockChanges(PosX - Radius, PosX + Radius, PosZ - Radius, PosZ + Radius, a_Player, World, "pumpkins")
	local PossibleBlockChanges = {}

	for I=1, Radius * 2 do
		local X = PosX + math.random(-Radius, Radius)
		local Z = PosZ + math.random(-Radius, Radius)
		local IsValid, Y = World:TryGetHeight(X, Z)
		if IsValid then
			Y = Y + 1
			if World:GetBlock(X, Y - 1, Z) == E_BLOCK_GRASS or World:GetBlock(X, Y, Z) - 1 == E_BLOCK_DIRT then
				YCheck:SetY(Y)
				table.insert(PossibleBlockChanges, {X = X, Y = Y, Z = Z, BlockType = E_BLOCK_LOG, BlockMeta = 0})
				for i=1, math.random(1, 6) do
					X = X + math.random(-2, 2)
					Z = Z + math.random(-2, 2)
					Y = World:GetHeight(X, Z) + 1
					YCheck:SetY(Y)

					local Block = World:GetBlock(X, Y - 1, Z)
					if (Block == E_BLOCK_GRASS) or Block == E_BLOCK_DIRT then
						table.insert(PossibleBlockChanges, {X = X, Y = Y, Z = Z, BlockType = E_BLOCK_LEAVES, BlockMeta = 0})
					end
				end
				for i=1, math.random(1, 4) do
					X = X + math.random(-2, 2)
					Z = Z + math.random(-2, 2)
					if World:GetBlock(X, Y - 1, Z) == E_BLOCK_GRASS or World:GetBlock(X, Y, Z) - 1 == E_BLOCK_DIRT then
						table.insert(PossibleBlockChanges, {X = X, Y = Y, Z = Z, BlockType = E_BLOCK_PUMPKIN, BlockMeta = math.random(0, 3)})
					end
				end
			end
		end
	end

	if not YCheck:Flush() then
		for idx, value in ipairs(PossibleBlockChanges) do
			World:SetBlock(value.X, value.Y, value.Z, value.BlockType, value.BlockMeta)
		end
		a_Player:SendMessage(cChatColor.LightGray .. "Created " .. #PossibleBlockChanges .. " patch(es) in total.")
	end
	return true
end

function HandleRemoveColumnCommand(a_Split, a_Player)
	local Pos = a_Player:GetPosition():Floor()

	local IsValid, WorldHeight = a_Player:GetWorld():TryGetHeight(Pos.x, Pos.z)
	if not(IsValid) then
		a_Player:SendMessage(cChatColor.LightGray .. "Removed 0 block(s) in total.")
		return true
	end

	local Cuboid = cCuboid(Pos, Pos)
	Cuboid.p1.y = (a_Split[1] == "//removeabove") and (WorldHeight + 1) or 1
	Cuboid:Sort()

	local World = a_Player:GetWorld()
	if (CallHook("OnAreaChanging", Cuboid, a_Player, World, a_Split[1]:sub(3, -1))) then
		return false
	end

	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, Cuboid, a_Split[1])

	local Area = cBlockArea()
	Area:Create(Cuboid:DifX() + 1, Cuboid:DifY() + 1, Cuboid:DifZ() + 1)
	Area:Write(World, Cuboid.p1)
	Area:Clear()

	CallHook("OnAreaChanged", Cuboid, a_Player, World, a_Split[1]:sub(3, -1))

	local ChangedBlocks = Cuboid.p2.y - Cuboid.p1.y
	a_Player:SendMessage(cChatColor.LightGray .. "Removed " .. ChangedBlocks .. " block(s) in total.")
	return true
end
