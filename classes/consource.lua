-- consource.lua
-- Always returns the same block.

cConstantBlockTypeSource = {}

function cConstantBlockTypeSource:new(a_BlockString)
	local BlockType, BlockMeta = GetBlockTypeMeta(a_BlockString)
	if (not BlockType) then
		return false, a_BlockString
	end
	local Obj = {}
	setmetatable(Obj, cConstantBlockTypeSource)
	self.__index = self
	Obj.m_BlockType = BlockType
	Obj.m_BlockMeta = BlockMeta
	return Obj
end

function cConstantBlockTypeSource:Get(a_X, a_Y, a_Z)
	return self.m_BlockType, self.m_BlockMeta
end

function cConstantBlockTypeSource:Contains(a_BlockTypeList)
	if (a_BlockTypeList[self.m_BlockType]) then
		return true, self.m_BlockType
	end
	return false
end
