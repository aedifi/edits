-- generation.lua
-- Implements generation-related commands.

function HandleGenerationShapeCommand(a_Split, a_Player)
	local IsHollow     = false
	local UseRawCoords = false
	local Offset       = false
	local OffsetCenter = false

	local NumFlags = 0
	for Idx, Value in ipairs(a_Split) do
		NumFlags = NumFlags + 1
		if (Value == "-h") then
			IsHollow = true
		elseif (Value == "-r") then
			UseRawCoords = true
		elseif (Value == "-o") then
			Offset = true
		elseif (Value == "-c") then
			OffsetCenter = true
		else
			NumFlags = NumFlags - 1
		end
	end

	if ((a_Split[2 + NumFlags] == nil) or (a_Split[3 + NumFlags] == nil)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //generate [flags] <block> <formula>")
		return true
	end

	local State = GetPlayerState(a_Player)
	if not(State.Selection:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find any region to generate within.")
		return true
	end

	local BlockTable, ErrBlock = GetBlockDst(a_Split[2 + NumFlags], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local SrcCuboid = State.Selection:GetSortedCuboid()
	local World = a_Player:GetWorld()

	SrcCuboid:Expand(1, 1, 1, 1, 1, 1)
	SrcCuboid:ClampY(0, 255)
	SrcCuboid:Sort()

	local FormulaString = table.concat(a_Split, " ", 3 + NumFlags)

	local zero, unit

	local BA = cBlockArea()
	BA:Read(World, SrcCuboid)

	local SizeX, SizeY, SizeZ = BA:GetCoordRange()
	SizeX = SizeX - 1
	SizeY = SizeY - 1
	SizeZ = SizeZ - 1

	if (UseRawCoords) then
		zero = Vector3f(0, 0, 0)
		unit = Vector3f(1, 1, 1)
	elseif (Offset) then
		zero = Vector3f(SrcCuboid.p1) - Vector3f(a_Player:GetPosition())
		unit = Vector3f(1, 1, 1)
	elseif (OffsetCenter) then
		local Min = Vector3f(0, 0, 0)

		local Max = Vector3f(SizeX, SizeY, SizeZ)

		zero = (Max + Min) * 0.5
		unit = Vector3f(1, 1, 1)
	else
		local Min = Vector3f(0, 0, 0)

		local Max = Vector3f(SizeX, SizeY, SizeZ)

		zero = (Max + Min) * 0.5
		unit = Max - zero
	end

	local Expression = cExpression:new(FormulaString)

	local ShapeGenerator, Error = cShapeGenerator:new(zero, unit, BlockTable, Expression, a_Player:HasPermission('worldedit.anyblock'))
	if (not ShapeGenerator) then
		a_Player:SendMessage(cChatColor.LightGray .. Error)
		return true
	end

	if (CallHook("OnAreaChanging", SrcCuboid, a_Player, World, "generate")) then
		return true
	end

	State.UndoStack:PushUndoFromCuboid(World, SrcCuboid, "generation")

	local Mask = State.ToolRegistrator:GetMask(a_Player:GetEquippedItem().m_ItemType)

	local Success, NumAffectedBlocks = pcall(cShapeGenerator.MakeShape, ShapeGenerator, BA, Vector3f(1, 1, 1), Vector3f(SizeX, SizeY, SizeZ), IsHollow, Mask)
	if (not Success) then
		a_Player:SendMessage(cChatColor.LightGray .. NumAffectedBlocks:match(":%d-: (.+)"))
		return true;
	end

    a_Player:SendMessage(cChatColor.LightGray .. "Modified " .. NumAffectedBlocks .. " block(s) in total.")

	BA:Write(World, SrcCuboid.p1)

	CallHook("OnAreaChanged", SrcCuboid, a_Player, World, "generate")
	return true
end

function HandleCylinderCommand(a_Split, a_Player)
	if ((a_Split[2] == nil) or (a_Split[3] == nil)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: " .. a_Split[1] .. " <block> <radius>[,<radius>] [height]")
		return true
	end

	local BlockTable, ErrBlock = GetBlockDst(a_Split[2], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local RadiusX, RadiusZ
	local Radius = tonumber(a_Split[3])
	if (Radius) then
		RadiusX, RadiusZ = Radius, Radius, Radius
	else
		local Radius = StringSplit(a_Split[3], ",")
		if (#Radius == 1) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
			return true
		end

		if (#Radius ~= 2) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert more than two radius values.")
			return true
		end

		for Idx = 1, 2 do
			if (not tonumber(Radius[Idx])) then
				a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert those radii numerically.")
				return true
			end
		end

		RadiusX, RadiusZ = tonumber(Radius[1]) + 1, tonumber(Radius[2]) + 1
	end

	local Height = tonumber(a_Split[4] or 1) - 1
	local Pos = a_Player:GetPosition():Floor()

	local Cuboid = cCuboid(Pos, Pos)
	Cuboid:Expand(RadiusX, RadiusX, 0, Height, RadiusZ, RadiusZ)
	Cuboid:Sort()

	local NumAffectedBlocks = CreateCylinderInCuboid(a_Player, Cuboid, BlockTable, a_Split[1] == "//hcylinder")

    a_Player:SendMessage(cChatColor.LightGray .. "Created " .. NumAffectedBlocks .. " block(s) in total.")
	return true
end

function HandleSphereCommand(a_Split, a_Player)
	-- //sphere <BlockType> <Radius>
	-- //hsphere <BlockType> <Radius>

	if ((a_Split[2] == nil) or (a_Split[3] == nil)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: " .. a_Split[1] .. " <block> <radius>[,<radius>,<radius>]")
		return true
	end

	-- Retrieve the blocktypes from the params:
	local BlockTable, ErrBlock = GetBlockDst(a_Split[2], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local RadiusX, RadiusY, RadiusZ
	local Radius = tonumber(a_Split[3])
	if (Radius) then
		-- Same radius for all axis
		RadiusX, RadiusY, RadiusZ = Radius, Radius, Radius
	else
		-- The player might want to specify the radius for each axis.
		local Radius = StringSplit(a_Split[3], ",")
		if (#Radius == 1) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
			return true
		end

		if (#Radius ~= 3) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert more than one or three radius values.")
			return true
		end

		for Idx = 1, 3 do
			if (not tonumber(Radius[Idx])) then
				a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert those radii numerically.")
				return true
			end
		end

		RadiusX, RadiusY, RadiusZ = tonumber(Radius[1]) + 1, tonumber(Radius[2]) + 1, tonumber(Radius[3]) + 1
	end

	local Pos = a_Player:GetPosition():Floor()

	local Cuboid = cCuboid(Pos, Pos)
	Cuboid:Expand(RadiusX, RadiusX, RadiusY, RadiusY, RadiusZ, RadiusZ)
	Cuboid:Sort()

	local NumAffectedBlocks = CreateSphereInCuboid(a_Player, Cuboid, BlockTable, a_Split[1] == "//hsphere")

	a_Player:SendMessage(cChatColor.LightGray .. "Created " .. NumAffectedBlocks .. " block(s) in total.")
	return true
end

function HandlePyramidCommand(a_Split, a_Player)
	if ((a_Split[2] == nil) or (a_Split[3] == nil)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: " .. a_Split[1] .. " <block> <size>[,<size>,<size>]")
		return true
	end

	local BlockTable, ErrBlock = GetBlockDst(a_Split[2], a_Player)
	if not(BlockTable) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that block.")
		return true
	end

	local RadiusX, RadiusY, RadiusZ
	local Radius = tonumber(a_Split[3])
	if (Radius) then
		RadiusX, RadiusY, RadiusZ = Radius, Radius, Radius
	else
		local Radius = StringSplit(a_Split[3], ",")
		if (#Radius == 1) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert that radius numerically.")
			return true
		end

		if (#Radius ~= 3) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert more than one or three radius values.")
			return true
		end

		for Idx = 1, 3 do
			if (not tonumber(Radius[Idx])) then
				a_Player:SendMessage(cChatColor.LightGray .. "Couldn't convert those radii numerically.")
				return true
			end
		end

		RadiusX, RadiusY, RadiusZ = tonumber(Radius[1]) + 1, tonumber(Radius[2]) + 1, tonumber(Radius[3]) + 1
	end

	local Pos = a_Player:GetPosition():Floor()

	local Cuboid = cCuboid(Pos, Pos)
	Cuboid:Expand(RadiusX, RadiusX, 0, RadiusY, RadiusZ, RadiusZ)
	Cuboid:ClampY(0, 255)
	Cuboid:Sort()

	local World = a_Player:GetWorld()

	if (CallHook("OnAreaChanging", Cuboid, a_Player, World, a_Split[1]:sub(3, -1))) then
		return true
	end

	local State = GetPlayerState(a_Player)
	State.UndoStack:PushUndoFromCuboid(World, Cuboid)

	local BlockArea = cBlockArea()

	BlockArea:Read(World, Cuboid)

	local Mask = State.ToolRegistrator:GetMask(a_Player:GetEquippedItem().m_ItemType)

	local AffectedBlocks = cShapeGenerator.MakePyramid(BlockArea, BlockTable, a_Split[1] == "//hpyramid", Mask);

	BlockArea:Write(World, Cuboid.p1)

	CallHook("OnAreaChanged", Cuboid, a_Player, World, a_Split[1]:sub(3, -1))

	a_Player:SendMessage(cChatColor.LightGray .. "Created " .. NumAffectedBlocks .. " block(s) in total.")
	return true
end
