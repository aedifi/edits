-- mask.lua
-- Implements the cMask class used in masks and replacements.

cMask = {}

local function ParseBlockArray(a_BlockArray)
	local BlockTable = {}
	for Idx, Block in ipairs(a_BlockArray) do
		local BlockInfo = BlockTable[Block.BlockType] or {TypeOnly = false, BlockMetas = {}}
		BlockInfo.TypeOnly = BlockInfo.TypeOnly or Block.TypeOnly
		if (not BlockInfo.TypeOnly) then
			BlockInfo.BlockMetas[Block.BlockMeta] = true
		end
		BlockTable[Block.BlockType] = BlockInfo
	end
	return BlockTable;
end

local function Contains(a_BlockTable, a_BlockType, a_BlockMeta)
	local BlockInfo = a_BlockTable[a_BlockType]
	if (not BlockInfo) then
		return false
	end
	if (BlockInfo.TypeOnly) then
		return true
	end
	return BlockInfo.BlockMetas[a_BlockMeta] or false
end

function cMask:new(a_PositiveBlocks, a_NegativeBlocks)
	local Obj = {}
	setmetatable(Obj, cMask)
	self.__index = self
	Obj.m_PositiveBlockTable = {}
	Obj.m_NegativeBlockTable = nil
	if (a_PositiveBlocks ~= nil) then
		local BlockArray, ErrorBlock = RetrieveBlockTypes(a_PositiveBlocks)
		if (not BlockArray) then
			return false, ErrorBlock
		end
		Obj.m_PositiveBlockTable = ParseBlockArray(BlockArray)
	end
	if (a_NegativeBlocks ~= nil) then
		local BlockArray, ErrorBlock = RetrieveBlockTypes(a_NegativeBlocks)
		if (not BlockArray) then
			return false, ErrorBlock
		end
		Obj.m_NegativeBlockTable = ParseBlockArray(BlockArray)
	end
	return Obj
end

function cMask:Contains(a_BlockType, a_BlockMeta)
	if (self.m_NegativeBlockTable ~= nil and not Contains(self.m_NegativeBlockTable, a_BlockType, a_BlockMeta)) then
		return true;
	end
	if (not Contains(self.m_PositiveBlockTable, a_BlockType, a_BlockMeta)) then
		return false;
	end
	return true;
end
