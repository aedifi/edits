-- functions.lua
-- Functions called upon plugin initialization.

-- Returns the block's type and meta from a string.
-- If a string with a percentage sign is provided, it will take the second half.
function GetBlockTypeMeta(a_BlockString)
	if (a_BlockString:find("%%")) then
		local ItemInfo = StringSplit(a_BlockString, "%")
		if (#ItemInfo ~= 2) then
			return false
		end
		a_BlockString = ItemInfo[2]
	end
	local BlockID = tonumber(a_BlockString)
	-- Is it a normal number?
	if (BlockID) then
		return BlockID, g_DefaultMetas[BlockID] or 0, true
	end
	-- Does it have block meta?
	local HasMeta = string.find(a_BlockString, ":")
	-- Is it a name?
	local Item = cItem()
	if (not StringToItem(a_BlockString, Item)) then
		return false
	else
		if (HasMeta or (Item.m_ItemDamage ~= 0)) then
			return Item.m_ItemType, Item.m_ItemDamage
		else
			return Item.m_ItemType, g_DefaultMetas[Item.m_ItemType] or 0, true
		end
	end
end

-- Loads the files with lua/luac extensions.
function dofolder(a_Path)
	for Idx, FileName in ipairs(cFile:GetFolderContents(a_Path)) do
		local FilePath = a_Path .. "/" .. FileName
		if (cFile:IsFile(FilePath) and FileName:match("%.lua[c]?$")) then
			dofile(FilePath)
		end
	end
end

-- Returns a table of chunk coordinates which intersect the given cuboid.
function ListChunksForCuboid(a_Cuboid)
	-- Check parameters...
	assert(tolua.type(a_Cuboid) == "cCuboid")
	-- Get the minimum and maximum chunk coordinates.
	local MinChunkX = math.floor(a_Cuboid.p1.x / 16)
	local MinChunkZ = math.floor(a_Cuboid.p1.z / 16)
	local MaxChunkX = math.floor((a_Cuboid.p2.x + 15.5) / 16)
	local MaxChunkZ = math.floor((a_Cuboid.p2.z + 15.5) / 16)
	-- Create the table.
	local res = {}
	local idx = 1
	for x = MinChunkX, MaxChunkX do for z = MinChunkZ, MaxChunkZ do
		res[idx] = {x, z}
		idx = idx + 1
	end end
	return res
end

-- Gets the number of blocks in that region.
function CountBlocksInCuboid(a_World, a_Cuboid, a_Mask)
	-- Make sure the cuboid is sorted.
	if (not a_Cuboid:IsSorted()) then
		a_Cuboid:Sort()
	end
	-- Read the area...
	local Area = cBlockArea()
	Area:Read(a_World, a_Cuboid)
	-- Replace the blocks...
	local SizeX, SizeY, SizeZ = Area:GetCoordRange()
	local NumBlocks = 0
	for X = 0, SizeX do
		for Y = 0, SizeY do
			for Z = 0, SizeZ do
				if (a_Mask:Contains(Area:GetRelBlockTypeMeta(X, Y, Z))) then
					NumBlocks = NumBlocks + 1
				end
			end
		end
	end
	return NumBlocks
end

function FillWalls(a_PlayerState, a_Player, a_World, a_DstBlockTable)
	-- Check with other plugins.
	if (CallHook("OnAreaChanging", a_PlayerState.Selection:GetSortedCuboid(), a_Player, a_World, "walls")) then
		return
	end
	-- Push an undo onto the stack.
	a_PlayerState:PushUndoInSelection(a_World, "walls")
	local Area = cBlockArea()
	local SrcCuboid = a_PlayerState.Selection:GetSortedCuboid()
	-- Read the area.
	Area:Read(a_World, SrcCuboid)
	local SizeX, SizeY, SizeZ = Area:GetCoordRange()
	-- Place the walls.
	for Y = 0, SizeY do
		for X = 0, SizeX do
			Area:SetRelBlockTypeMeta(X, Y, 0, a_DstBlockTable:Get(X, Y, 0))
			Area:SetRelBlockTypeMeta(X, Y, SizeZ, a_DstBlockTable:Get(X, Y, SizeZ))
		end
		for Z = 1, SizeZ - 1 do
			Area:SetRelBlockTypeMeta(0, Y, Z, a_DstBlockTable:Get(0, Y, Z))
			Area:SetRelBlockTypeMeta(SizeX, Y, Z, a_DstBlockTable:Get(SizeX, Y, Z))
		end
	end
	Area:Write(a_World, SrcCuboid.p1)
	Area:Clear()
	a_World:WakeUpSimulatorsInArea(cCuboid(
		Vector3i(SrcCuboid.p1.x - 1, SrcCuboid.p1.y - 1, SrcCuboid.p1.z - 1),
		Vector3i(SrcCuboid.p2.x + 1, SrcCuboid.p2.y + 1, SrcCuboid.p2.z + 1)
	))
	CallHook("OnAreaChanged", a_PlayerState.Selection:GetSortedCuboid(), a_Player, a_World, "walls")
	-- Calculate the number of changed blocks.
	local VolumeIncluding = (SizeX + 1) * (SizeY + 1) * (SizeZ + 1)  -- Volume of the cuboid INcluding the walls
	local VolumeExcluding = (SizeX - 1) * (SizeY + 1) * (SizeZ - 1)  -- Volume of the cuboid EXcluding the walls
	if (VolumeExcluding < 0) then
		VolumeExcluding = 0
	end
	return VolumeIncluding - VolumeExcluding
end

function FillFaces(a_PlayerState, a_Player, a_World, a_DstBlockTable)
	-- Check with other plugins.
	if (CallHook("OnAreaChanging", a_PlayerState.Selection:GetSortedCuboid(), a_Player, a_World, "faces")) then
		return
	end
	-- Push an undo onto the stack.
	a_PlayerState:PushUndoInSelection(a_World, "faces")
	-- Fill the faces.
	local Area = cBlockArea()
	local SrcCuboid = a_PlayerState.Selection:GetSortedCuboid()
	-- Read the area.
	Area:Read(a_World, SrcCuboid)
	local SizeX, SizeY, SizeZ = Area:GetCoordRange()
	-- Place the walls.
	for Y = 0, SizeY do
		for X = 0, SizeX do
			Area:SetRelBlockTypeMeta(X, Y, 0, a_DstBlockTable:Get(X, Y, 0))
			Area:SetRelBlockTypeMeta(X, Y, SizeZ, a_DstBlockTable:Get(X, Y, SizeZ))
		end
		for Z = 1, SizeZ - 1 do
			Area:SetRelBlockTypeMeta(0, Y, Z, a_DstBlockTable:Get(0, Y, Z))
			Area:SetRelBlockTypeMeta(SizeX, Y, Z, a_DstBlockTable:Get(SizeX, Y, Z))
		end
	end
	-- Place the ceiling and floor.
	for Y = 0, SizeY, ((SizeY == 0 and 1) or SizeY) do
		for X = 0, SizeX do
			for Z = 0, SizeZ do
				Area:SetRelBlockTypeMeta(X, Y, Z, a_DstBlockTable:Get(X, Y, Z))
			end
		end
	end
	Area:Write(a_World, SrcCuboid.p1)
	Area:Clear()
	a_World:WakeUpSimulatorsInArea(cCuboid(
		Vector3i(SrcCuboid.p1.x - 1, SrcCuboid.p1.y - 1, SrcCuboid.p1.z - 1),
		Vector3i(SrcCuboid.p2.x + 1, SrcCuboid.p2.y + 1, SrcCuboid.p2.z + 1)
	))
	CallHook("OnAreaChanged", a_PlayerState.Selection:GetSortedCuboid(), a_Player, a_World, "faces")
	-- Calculate the number of changed blocks.
	local VolumeIncluding = (SizeX + 1) * (SizeY + 1) * (SizeZ + 1)  -- Volume of the cuboid INcluding the faces
	local VolumeExcluding = (SizeX - 1) * (SizeY - 1) * (SizeZ - 1)  -- Volume of the cuboid EXcluding the faces
	if (VolumeExcluding < 0) then
		VolumeExcluding = 0
	end
	return VolumeIncluding - VolumeExcluding
end

function SetBlocksInCuboid(a_Player, a_Cuboid, a_DstBlockTable, a_Action)
	-- If no action was given we use "fill" as a default.
	a_Action = a_Action or "fill"
	-- Make sure the cuboid is sorted.
	if (not a_Cuboid:IsSorted()) then
		a_Cuboid:Sort()
	end
	local World = a_Player:GetWorld()
	-- Check with other plugins.
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, a_Action)) then
		return
	end
	-- Get the player state.
	local State = GetPlayerState(a_Player)
	-- Push an undo onto the stack.
	State:PushUndoInSelection(World, a_Cuboid)
	-- Create a block area.
	local Area = cBlockArea()
	Area:Create(a_Cuboid:DifX() + 1, a_Cuboid:DifY() + 1, a_Cuboid:DifZ() + 1)
	local SizeX, SizeY, SizeZ = Area:GetCoordRange()
	-- Fill the selection.
	for X = 0, SizeX do
		for Y = 0, SizeY do
			for Z = 0, SizeZ do
				Area:SetRelBlockTypeMeta(X, Y, Z, a_DstBlockTable:Get(X, Y, Z))
			end
		end
	end
	-- Write the area.
	Area:Write(World, a_Cuboid.p1)
	Area:Clear()
	World:WakeUpSimulatorsInArea(a_Cuboid)
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, a_Action)
	return a_Cuboid:GetVolume()
end

function ReplaceBlocksInCuboid(a_Player, a_Cuboid, a_Mask, a_DstBlockTable, a_Action)
	local State = GetPlayerState(a_Player)
	local World = a_Player:GetWorld()
	-- Check with other plugins.
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, a_Action)) then
		return
	end
	-- Push an undo onto the stack.
	State.UndoStack:PushUndoFromCuboid(World, a_Cuboid)
	-- Read the area.
	local Area = cBlockArea()
	Area:Read(World, a_Cuboid)
	-- Replace the blocks.
	local SizeX, SizeY, SizeZ = Area:GetCoordRange()
	local NumBlocks = 0
	for X = 0, SizeX do
		for Y = 0, SizeY do
			for Z = 0, SizeZ do
				if (a_Mask:Contains(Area:GetRelBlockTypeMeta(X, Y, Z))) then
					Area:SetRelBlockTypeMeta(X, Y, Z, a_DstBlockTable:Get(X, Y, Z))
					NumBlocks = NumBlocks + 1
				end
			end
		end
	end
	-- Write the area.
	Area:Write(World, a_Cuboid.p1)
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, a_Action)
	World:WakeUpSimulatorsInArea(a_Cuboid)
	return NumBlocks
end

local RetrieveBlockTypesTemp = {}
function RetrieveBlockTypes(Input)
	if (RetrieveBlockTypesTemp[Input] ~= nil) then
		return RetrieveBlockTypesTemp[Input]
	end
	local RawDstBlockTable = StringSplit(Input, ",")
	local BlockTable = {}
	for Idx, Value in ipairs(RawDstBlockTable) do
		local Chance = 1
		if (string.find(Value, "%", 1, true) ~= nil) then
			local SplittedValues = StringSplit(Value, "%")
			if (#SplittedValues ~= 2) then
				return false
			end
			Chance = tonumber(SplittedValues[1])
			Value = SplittedValues[2]
			if (Chance == nil) then
				return false, Value
			end
		end
		local BlockType, BlockMeta, TypeOnly = GetBlockTypeMeta(Value)
		if not(BlockType) then
			return false, Value
		end
		table.insert(BlockTable, {BlockType = BlockType, BlockMeta = BlockMeta, TypeOnly = TypeOnly or false, Chance = Chance})
	end
	RetrieveBlockTypesTemp[Input] = BlockTable
	return BlockTable
end

function GetBlockDst(a_Blocks, a_Player)
	local Handler, Error
	if (a_Blocks:sub(1, 1) == "#") then
		if ((a_Blocks ~= "#clipboard") and (a_Blocks ~= "#copy")) then
			return false, "#clipboard or #copy is acceptable for patterns starting with #"
		end
		Handler, Error = cClipboardBlockTypeSource:new(a_Player)
	end
	if (not Handler and not Error) then
		local NumBlocks = #StringSplit(a_Blocks, ",")
		if (NumBlocks == 1) then
			Handler, Error = cConstantBlockTypeSource:new(a_Blocks)
		else
			Handler, Error = cRandomBlockTypeSource:new(a_Blocks)
		end
	end
	if (Error) then
		return false, Error
	end
	if (a_Player and not a_Player:HasPermission("edits.anyblock")) then
		local DoesContain, DisallowedBlock = Handler:Contains(g_Config.Limits.DisallowedBlocks)
		if (DoesContain) then
			return false, DisallowedBlock .. " isn't allowed"
		end
	end
	return Handler
end

function GetTargetBlock(a_Player)
	local MaxDistance = 150  -- A max distance of 150 blocks.
	local FoundBlock = nil
	local BlockFace = BLOCK_FACE_NONE
	local Callbacks = {
		OnNextBlock = function(a_BlockPos, a_BlockType, a_BlockMeta, a_BlockFace)
			if (a_BlockType ~= E_BLOCK_AIR) then
				FoundBlock = a_BlockPos
				BlockFace = a_BlockFace
				return true
			end
		end
	};
	local EyePos = a_Player:GetEyePosition()
	local LookVector = a_Player:GetLookVector()
	LookVector:Normalize()
	local Start = EyePos + LookVector + LookVector
	local End = EyePos + LookVector * MaxDistance
	local HitNothing = cLineBlockTracer.Trace(a_Player:GetWorld(), Callbacks, Start, End)
	if (HitNothing) then
		-- No block found.
		return nil
	end
	return FoundBlock, BlockFace
end

function CreateSphereInCuboid(a_Player, a_Cuboid, a_BlockTable, a_IsHollow, a_Mask)
	local World = a_Player:GetWorld()
	local ActionName = (a_IsHollow and "hsphere") or "sphere"
	-- Check with other plugins.
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, ActionName)) then
		return 0
	end
	if (not a_Cuboid:IsSorted()) then
		a_Cuboid:Sort()
	end
	local AffectedChunks = ListChunksForCuboid(a_Cuboid)
	local NumAffectedBlocks = 0
	local CutBottom, CutTop = (a_Cuboid.p1.y > 0) and 0 or -a_Cuboid.p1.y, (a_Cuboid.p2.y < 255) and 0 or (a_Cuboid.p2.y - 255)
	a_Cuboid:ClampY(0, 255)
	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, a_Cuboid)
	local BlockArea = cBlockArea()
	World:ChunkStay(AffectedChunks, nil,
		function()
			BlockArea:Read(World, a_Cuboid)
			BlockArea:Expand(0, 0, CutBottom, CutTop, 0, 0)
			NumAffectedBlocks = cShapeGenerator.MakeSphere(BlockArea, a_BlockTable, a_IsHollow, a_Mask)
			BlockArea:Crop(0, 0, CutBottom, CutTop, 0, 0)
			BlockArea:Write(World, a_Cuboid.p1)
		end
	)
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, ActionName)
	return NumAffectedBlocks
end

function CreateCylinderInCuboid(a_Player, a_Cuboid, a_BlockTable, a_IsHollow, a_Mask)
	local World = a_Player:GetWorld()
	local ActionName = (a_IsHollow and "hcylinder") or "cylinder"
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, ActionName)) then
		return 0
	end
	if (not a_Cuboid:IsSorted()) then
		a_Cuboid:Sort()
	end
	local AffectedChunks = ListChunksForCuboid(a_Cuboid)
	local CutBottom, CutTop = (a_Cuboid.p1.y > 0) and 0 or -a_Cuboid.p1.y, (a_Cuboid.p2.y < 255) and 0 or (a_Cuboid.p2.y - 255)
	a_Cuboid:ClampY(0, 255)
	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, a_Cuboid)
	local NumAffectedBlocks = 0
	local BlockArea = cBlockArea()
	World:ChunkStay(AffectedChunks, nil,
		function()
			BlockArea:Read(World, a_Cuboid)
			BlockArea:Expand(0, 0, CutBottom, CutTop, 0, 0)
			NumAffectedBlocks = cShapeGenerator.MakeCylinder(BlockArea, a_BlockTable, a_IsHollow, a_Mask)
			BlockArea:Crop(0, 0, CutBottom, CutTop, 0, 0)
			BlockArea:Write(World, a_Cuboid.p1)
		end
	)
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, ActionName)
	return NumAffectedBlocks
end

function FillRecursively(a_Player, a_Cuboid, a_BlockDst, a_AllowUp)
	local World = a_Player:GetWorld();
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, "fillr")) then
		return 0
	end
	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, a_Cuboid)
	local blockArea = cBlockArea();
	blockArea:Read(World, a_Cuboid);
	local sizeX = a_Cuboid:DifX()
	local sizeY = a_Cuboid:DifY()
	local sizeZ = a_Cuboid:DifZ()
	local numBlocks = 0
	local cache = {}
	local function MakeIndex(a_RelX, a_RelY, a_RelZ)
		return a_RelX + (a_RelZ * sizeX) + (a_RelY * sizeX * sizeZ);
	end
	local function IsInside(a_RelX, a_RelY, a_RelZ)
		return not (
			(a_RelX < 0) or (a_RelX > sizeX) or
			(a_RelY < 0) or (a_RelY > sizeY) or
			(a_RelZ < 0) or (a_RelZ > sizeZ)
		)
	end
	local function Next(a_X, a_Y, a_Z, a_AllowSolid)
		if (not IsInside(a_X, a_Y, a_Z)) then
			return;
		end
		local index = MakeIndex(a_X, a_Y, a_Z)
		if (cache[index]) then
			return;
		end
		cache[index] = true
		local isSolid = cBlockInfo:IsSolid(blockArea:GetRelBlockType(a_X, a_Y, a_Z));
		if (not isSolid) then
			numBlocks = numBlocks + 1
			blockArea:SetRelBlockTypeMeta(a_X, a_Y, a_Z, a_BlockDst:Get(a_X, a_Y, a_Z));
		end
		if ((not isSolid) or a_AllowSolid) then
			Next(a_X + 1, a_Y, a_Z)
			Next(a_X - 1, a_Y, a_Z)
			Next(a_X, a_Y, a_Z - 1)
			Next(a_X, a_Y, a_Z + 1)
			Next(a_X, a_Y - 1, a_Z)
			if (a_AllowUp) then
				Next(a_X, a_Y + 1, a_Z)
			end
		end
	end
	Next(math.floor(sizeX / 2), sizeY, math.floor(sizeZ / 2), true);
	blockArea:Write(World, a_Cuboid.p1)
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, "fillr")
	return numBlocks
end

function FillNormal(a_Player, a_Cuboid, a_BlockDst)
	local World = a_Player:GetWorld();
	if (CallHook("OnAreaChanging", a_Cuboid, a_Player, World, "fill")) then
		return 0
	end
	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, a_Cuboid)
	local blockArea = cBlockArea();
	blockArea:Read(World, a_Cuboid);
	local sizeX = a_Cuboid:DifX()
	local sizeY = a_Cuboid:DifY()
	local sizeZ = a_Cuboid:DifZ()
	local numBlocks = 0
	local cache = {}
	local function MakeIndex(a_RelX, a_RelZ)
		return a_RelX + (a_RelZ * sizeX);
	end
	local function IsInside(a_RelX, a_RelZ)
		return not (
			(a_RelX < 0) or (a_RelX > sizeX) or
			(a_RelZ < 0) or (a_RelZ > sizeZ)
		)
	end
	local function Next(a_RelX, a_RelZ, a_AllowSolid)
		if (not IsInside(a_RelX, a_RelZ)) then
			return;
		end
		local index = MakeIndex(a_RelX, a_RelZ);
		if (cache[index]) then
			return;
		end
		cache[index] = true;
		local didPlaceColumn = false;
		for y = sizeY, 0, -1 do
			local isSolid = cBlockInfo:IsSolid(blockArea:GetRelBlockType(a_RelX, y, a_RelZ));
			if (not isSolid) then
				didPlaceColumn = true;
				numBlocks = numBlocks + 1
				blockArea:SetRelBlockTypeMeta(a_RelX, y, a_RelZ, a_BlockDst:Get(a_RelX, y, a_RelZ));
			else
				break;
			end
		end
		if (didPlaceColumn or a_AllowSolid) then
			Next(a_RelX + 1, a_RelZ);
			Next(a_RelX - 1, a_RelZ);
			Next(a_RelX, a_RelZ - 1);
			Next(a_RelX, a_RelZ + 1);
		end
	end
	Next(math.floor(sizeX / 2), math.floor(sizeZ / 2), true);
	blockArea:Write(World, a_Cuboid.p1);
	CallHook("OnAreaChanged", a_Cuboid, a_Player, World, "fill");
	return numBlocks;
end

function RightClickCompass(a_Player)
	local World = a_Player:GetWorld()
	local FreeSpot = nil
	local WentThroughBlock = false
	local Callbacks = {
		OnNextBlock = function(a_BlockPos, a_BlockType, a_BlockMeta)
			if (cBlockInfo:IsSolid(a_BlockType)) then
				WentThroughBlock = true
				return false
			end
			if (not WentThroughBlock) then
				return false
			end
			FreeSpot = a_BlockPos
			return true
		end;
	};
	local EyePos = a_Player:GetEyePosition()
	local LookVector = a_Player:GetLookVector()
	LookVector:Normalize()
	local Start = EyePos
	local End = EyePos + LookVector * g_Config.NavigationWand.MaxDistance
	cLineBlockTracer.Trace(World, Callbacks, Start, End)
	if (not FreeSpot) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find anything to pass through.")
		return false
	end
	for y = FreeSpot.y, 0, -1 do
		local BlockType = World:GetBlock(FreeSpot.x, y, FreeSpot.z)
		if (cBlockInfo:IsSolid(BlockType)) then
			a_Player:TeleportToCoords(FreeSpot.x + 0.5, cBlockInfo:GetBlockHeight(BlockType) + y, FreeSpot.z + 0.5)
			return true
		end
	end
	return false
end

function LeftClickCompass(a_Player)
	local World = a_Player:GetWorld()
	local BlockPos = false
	local Callbacks = {
		OnNextBlock = function(a_BlockPos, a_BlockType, a_BlockMeta)
			if (not cBlockInfo:IsSolid(a_BlockType)) then
				return false
			end

			BlockPos = a_BlockPos
			return true
		end
	};
	local EyePos = a_Player:GetEyePosition()
	local LookVector = a_Player:GetLookVector()
	LookVector:Normalize()
	local Start = EyePos
	local End = EyePos + LookVector * g_Config.NavigationWand.MaxDistance
	cLineBlockTracer.Trace(World, Callbacks, Start, End)
	if (not BlockPos) then
		if (g_Config.NavigationWand.TeleportNoHit) then
			a_Player:TeleportToCoords(End.x + 0.5, End.y, End.z + 0.5)
		else
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find anything in sight.")
		end
		return g_Config.NavigationWand.TeleportNoHit
	end
	local IsValid, Height = World:TryGetHeight(BlockPos.x, BlockPos.z)
	if (not IsValid) then
		return false
	end
	local LastBlock;
	for Y = BlockPos.y, Height do
		local BlockType = World:GetBlock(BlockPos.x, Y, BlockPos.z)
		if (not cBlockInfo:IsSolid(BlockType)) then
			a_Player:TeleportToCoords(BlockPos.x + 0.5, Y + cBlockInfo:GetBlockHeight(LastBlock) - 1, BlockPos.z + 0.5)
			return true
		end
		LastBlock = BlockType
	end
	a_Player:TeleportToCoords(BlockPos.x + 0.5, Height + cBlockInfo:GetBlockHeight(World:GetBlock(BlockPos.x, Height, BlockPos.z)), BlockPos.z + 0.5)
	return true
end

function HPosSelect(a_Player, a_MaxDistance)
	assert(tolua.type(a_Player) == "cPlayer")
	a_MaxDistance = a_MaxDistance or 150
	local Start = a_Player:GetEyePosition()
	local LookVector = a_Player:GetLookVector()
	LookVector:Normalize()
	local End = Start + LookVector * a_MaxDistance
	local hpos = nil
	local Callbacks =
	{
		OnNextBlock = function(a_BlockPos, a_BlockType, a_BlockMeta)
			if ((a_BlockType ~= E_BLOCK_AIR) and not(cBlockInfo:IsOneHitDig(a_BlockType))) then
				hpos = a_BlockPos
				return true
			end
		end
	}
	if (cLineBlockTracer.Trace(a_Player:GetWorld(), Callbacks, Start, End)) then
		return nil
	end
	return hpos
end
