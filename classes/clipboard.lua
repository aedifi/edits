-- clipboard.lua
-- Implements the cClipboard class which represents a player's clipboard.

cClipboard = {}

function cClipboard:new(a_Obj)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cClipboard)
	self.__index = self
	-- Initialize the object members...
	a_Obj.Area = cBlockArea()
	return a_Obj
end

-- Copies the blocks from any specified cuboid into a clipboard.
function cClipboard:Copy(a_World, a_Cuboid, a_Offset)
	assert(tolua.type(a_World) == "cWorld")
	assert(tolua.type(a_Cuboid) == "cCuboid")
	local Offset = a_Offset or Vector3i()
	self.Area:Read(a_World,
		a_Cuboid.p1.x, a_Cuboid.p2.x,
		a_Cuboid.p1.y, a_Cuboid.p2.y,
		a_Cuboid.p1.z, a_Cuboid.p2.z
	)
	self.Area:SetWEOffset(Offset)
	return self.Area:GetVolume()
end

-- Replaces the cuboid with air blocks.
function cClipboard:Cut(a_World, a_Cuboid, a_Offset)
	self:Copy(a_World, a_Cuboid, a_Offset)
	-- Replace everything with air.
	local Area = cBlockArea()
	Area:Create(a_Cuboid:DifX() + 1, a_Cuboid:DifY() + 1, a_Cuboid:DifZ() + 1)
	Area:Write(a_World, a_Cuboid.p1.x, a_Cuboid.p1.y, a_Cuboid.p1.z)
	-- Wake up the simulators in the area.
	a_World:WakeUpSimulatorsInArea(cCuboid(
		Vector3i(a_Cuboid.p1.x - 1, a_Cuboid.p1.y - 1, a_Cuboid.p1.z - 1),
		Vector3i(a_Cuboid.p2.x + 1, a_Cuboid.p2.y + 1, a_Cuboid.p2.z + 1)
	))
	return self.Area:GetVolume()
end

-- Returns the cuboid holding the area to be affected by a paste operation.
function cClipboard:GetPasteDestCuboid(a_Player, a_UseOffset)
	assert(tolua.type(a_Player) == "cPlayer")
	assert(self:IsValid())
	local MinX, MinY, MinZ = math.floor(a_Player:GetPosX()), math.floor(a_Player:GetPosY()), math.floor(a_Player:GetPosZ())
	if (a_UseOffset) then
		local Offset = self.Area:GetWEOffset()
		MinX = MinX + Offset.x
		MinY = MinY + Offset.y
		MinZ = MinZ + Offset.z
	end
	local XSize, YSize, ZSize = self.Area:GetSize()
	return cCuboid(Vector3i(MinX, MinY, MinZ), Vector3i(MinX + XSize, MinY + YSize, MinZ + ZSize))
end

function cClipboard:GetSizeDesc()
	if not(self:IsValid()) then
		return "Couldn't find any clipboard data."
	end
	local XSize, YSize, ZSize = self.Area:GetSize()
	local Volume = XSize * YSize * ZSize
	local Dimensions = XSize .. " * " .. YSize .. " * " .. ZSize .. " (volume: "
	if (Volume == 1) then
		return Dimensions .. "1 block)"
	else
		return Dimensions .. Volume .. " blocks)"
	end
end

function cClipboard:IsValid()
	return (self.Area:GetDataTypes() ~= 0)
end

function cClipboard:LoadFromSchematicFile(a_FileName)
	return self.Area:LoadFromSchematicFile(a_FileName)
end

function cClipboard:Paste(a_Player, a_DstPoint)
	local World = a_Player:GetWorld()
	-- Write the area.
	self.Area:Write(World, a_DstPoint.x, a_DstPoint.y, a_DstPoint.z)
	-- Wake up simulators in the area.
	local XSize, YSize, ZSize = self.Area:GetSize()
	World:WakeUpSimulatorsInArea(cCuboid(
		Vector3i(a_DstPoint.x - 1, a_DstPoint.y, a_DstPoint.z - 1),
		Vector3i(a_DstPoint.x + XSize + 1, a_DstPoint.y + YSize + 1, a_DstPoint.z + ZSize + 1)
	))
	return XSize * YSize * ZSize
end

function cClipboard:Rotate(a_NumCCWQuarterRotations)
	local NumRots = math.fmod(a_NumCCWQuarterRotations, 4)
	if ((NumRots == -3) or (NumRots == 1)) then
		self.Area:RotateCCW()
	elseif ((NumRots == -2) or (NumRots == 2)) then
		self.Area:RotateCCW()
		self.Area:RotateCCW()
	elseif ((NumRots == -1) or (NumRots == 3)) then
		self.Area:RotateCW()
	elseif (NumRots == 0) then
	else
		error("Found a bad quarter result.")
	end
end

function cClipboard:SaveToSchematicFile(a_FileName)
	assert(self:IsValid())
	return self.Area:SaveToSchematicFile(a_FileName)
end
