-- clipsource.lua
-- Allows operations to be done using the player's clipboard.

cClipboardBlockTypeSource = {}

function cClipboardBlockTypeSource:new(a_Player)
	local State = GetPlayerState(a_Player)
	if (not State.Clipboard:IsValid()) then
		return false, "Couldn't find any clipboard data."
	end
	local Area = State.Clipboard.Area
	local Size = Vector3i(Area:GetSize())
	local Obj = {}
	setmetatable(Obj, cClipboardBlockTypeSource)
	self.__index = self
	Obj.m_Area = Area
	Obj.m_Size = Size
	return Obj
end

function cClipboardBlockTypeSource:Get(a_X, a_Y, a_Z)
	local PosX = math.floor(a_X % self.m_Size.x)
	local PosY = math.floor(a_Y % self.m_Size.y)
	local PosZ = math.floor(a_Z % self.m_Size.z)
	return self.m_Area:GetRelBlockTypeMeta(PosX, PosY, PosZ)
end

function cClipboardBlockTypeSource:Contains(a_BlockTypeList)
	local SizeX, SizeY, SizeZ = self.m_Area:GetCoordRange()
	for X = 0, SizeX do
		for Y = 0, SizeY do
			for Z = 0, SizeZ do
				local BlockType = self.m_Area:GetRelBlockType(X, Y, Z)
				if (a_BlockTypeList[BlockType]) then
					return true, BlockType
				end
			end
		end
	end
	return false
end
