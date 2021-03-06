-- shapes.lua
-- Generation of shapes in areas.  Predefined or formulaic.

cShapeGenerator = {}

cShapeGenerator.m_Coords =
{
	Vector3f(1, 0, 0), Vector3f(-1, 0, 0),
	Vector3f(0, 1, 0), Vector3f(0, -1, 0),
	Vector3f(0, 0, 1), Vector3f(0, 0, -1),
}

cShapeGenerator.m_HollowHandler = function(a_ShapeGenerator, a_BlockArea, a_BlockPos)
	for Idx, Coord in ipairs(cShapeGenerator.m_Coords) do
		local CoordAround = a_BlockPos + Coord
		local DoSet = a_ShapeGenerator:GetBlockInfoFromFormula(CoordAround)
		if (not DoSet) then
			return true
		end
	end
	return false
end

cShapeGenerator.m_SolidHandler = function(a_ShapeGenerator, a_BlockArea, a_BlockPos)
	return true
end

function cShapeGenerator:new(a_Zero, a_Unit, a_BlockTable, a_Expression, a_CanUseAllBlocks)
	local Obj = {}
	setmetatable(Obj, cShapeGenerator)
	self.__index = self
	a_Expression:AddReturnValue("Comp1")
	:AddParameter("x")
	:AddParameter("y")
	:AddParameter("z")
	:AddParameter("type"):AddReturnValue("type")
	:AddParameter("data"):AddReturnValue("data")
	if (not a_CanUseAllBlocks) then
		a_Expression:AddReturnValidator(
			function(shouldPlace, blocktype, blockdata)
				if (g_Config.Limits.DisallowedBlocks[math.floor(blocktype)]) then
					return false, ItemTypeToString(blocktype) .. ' is not allowed'
				else
					return true
				end
			end
		)
	end
	local Formula, Error = a_Expression:Compile()
	if (not Formula) then
		return false, "Invalid formula"
	end
	local Success, TestResult = pcall(Formula, 1, 1, 1, 1, 1)
	if (not Success or (type(TestResult) ~= "boolean")) then
		if ((type(TestResult) == 'string') and TestResult:match(" is not allowed$")) then
			return false, TestResult:match(':%d-: (.+)')
		end
		return false, "The formula isn't a comparison"
	end
	Obj.m_Cache      = {}
	Obj.m_BlockTable = a_BlockTable
	Obj.m_Formula    = Formula
	Obj.m_Unit = a_Unit
	Obj.m_Zero = a_Zero
	Obj.m_Size = Vector3f()
	return Obj
end

function cShapeGenerator:GetBlockInfoFromFormula(a_BlockPos)
	local Index = a_BlockPos.x + (a_BlockPos.z * self.m_Size.x) + (a_BlockPos.y * self.m_Size.x * self.m_Size.z)
	local BlockInfo = self.m_Cache[Index]
	if (BlockInfo) then
		return BlockInfo.DoSet, BlockInfo.BlockType, BlockInfo.BlockMeta
	end
	local scaled = (a_BlockPos - self.m_Zero) / self.m_Unit
	local BlockType, BlockMeta = self.m_BlockTable:Get(a_BlockPos.x, a_BlockPos.y, a_BlockPos.z)
	local DoSet, BlockType, BlockMeta = self.m_Formula(scaled.x, scaled.y, scaled.z, BlockType, BlockMeta)
	self.m_Cache[Index] = {DoSet = DoSet, BlockType = BlockType, BlockMeta = BlockMeta}
	return DoSet, BlockType, BlockMeta
end

function cShapeGenerator:MakeShape(a_BlockArea, a_MinVector, a_MaxVector, a_IsHollow, a_Mask)
	local DoCheckMask = a_Mask ~= nil
	local Handler = a_IsHollow and cShapeGenerator.m_HollowHandler or cShapeGenerator.m_SolidHandler
	local NumAffectedBlocks = 0
	self.m_Size = Vector3f(a_BlockArea:GetSize())
	local CurrentBlock = Vector3f(a_MinVector)
	for X = a_MinVector.x, a_MaxVector.x do
		CurrentBlock.x = X
		for Y = a_MinVector.y, a_MaxVector.y do
			CurrentBlock.y = Y
			for Z = a_MinVector.z, a_MaxVector.z do
				CurrentBlock.z = Z
				local DoSet, BlockType, BlockMeta = self:GetBlockInfoFromFormula(CurrentBlock)
				if (DoSet and DoCheckMask) then
					local CurrentType, CurrentMeta = a_BlockArea:GetRelBlockTypeMeta(X, Y, Z)
					if (not a_Mask:Contains(CurrentType, CurrentMeta)) then
						DoSet = false
					end
				end
				if (DoSet and Handler(self, a_BlockArea, CurrentBlock)) then
					a_BlockArea:SetRelBlockTypeMeta(X, Y, Z, BlockType, BlockMeta)
					NumAffectedBlocks = NumAffectedBlocks + 1
				end
			end
		end
	end
	return NumAffectedBlocks
end

function cShapeGenerator.MakeCylinder(a_BlockArea, a_BlockTable, a_IsHollow, a_Mask)
	local DoCheckMask = a_Mask ~= nil
	local SizeX, SizeY, SizeZ = a_BlockArea:GetCoordRange()
	local HalfX, HalfZ = SizeX / 2, SizeZ / 2
	local SqHalfX, SqHalfZ = HalfX ^ 2, HalfZ ^ 2
	local Expression = cExpression:new("x -= HalfX; z -= HalfZ; ((x * x) / SqHalfX) + ((z * z) / SqHalfZ) <= 1")
	:AddReturnValue("Comp1")
	:AddParameter("x")
	:AddParameter("z")
	:PredefineConstant("SqHalfX", SqHalfX)
	:PredefineConstant("SqHalfZ", SqHalfZ)
	:PredefineConstant("HalfX", HalfX)
	:PredefineConstant("HalfZ", HalfZ)
	local NumAffectedBlocks = 0
	local Formula = Expression:Compile()
	local function SetBlock(a_RelX, a_RelY, a_RelZ)
		if (DoCheckMask) then
			local CurrentBlock, CurrentMeta = a_BlockArea:GetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ)
			if (not a_Mask:Contains(CurrentBlock, CurrentMeta)) then
				return
			end
		end
		a_BlockArea:SetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ, a_BlockTable:Get(a_RelX, a_RelY, a_RelZ))
		NumAffectedBlocks = NumAffectedBlocks + 1
	end
	for X = 0, HalfX, 1 do
		for Z = 0, HalfZ, 1 do
			local PlaceColumn = Formula(X, Z)
			if (a_IsHollow and PlaceColumn) then
				if (Formula(X - 1, Z) and Formula(X, Z - 1) and Formula(X + 1, Z) and Formula(X, Z + 1)) then
					PlaceColumn = false
				end
			end
			if (PlaceColumn) then
				for Y = 0, SizeY, 1 do
					SetBlock(X,         Y,         Z)
					SetBlock(SizeX - X, Y,         Z)
					SetBlock(X,         Y, SizeZ - Z)
					SetBlock(SizeX - X, Y, SizeZ - Z)
				end
			end
		end
	end
	return NumAffectedBlocks
end

function cShapeGenerator.MakeSphere(a_BlockArea, a_BlockTable, a_IsHollow, a_Mask)
	local DoCheckMask = a_Mask ~= nil
	local SizeX, SizeY, SizeZ = a_BlockArea:GetCoordRange()
	local HalfX, HalfY, HalfZ = SizeX / 2, SizeY / 2, SizeZ / 2
	local SqHalfX, SqHalfY, SqHalfZ = HalfX ^ 2, HalfY ^ 2, HalfZ ^ 2
	local Expression = cExpression:new("x -= HalfX; y -= HalfY; z -= HalfZ; ((x * x) / SqHalfX) + ((y * y) / SqHalfY) + ((z * z) / SqHalfZ) <= 1")
	:AddReturnValue("Comp1")
	:AddParameter("x")
	:AddParameter("y")
	:AddParameter("z")
	:PredefineConstant("SqHalfX", SqHalfX)
	:PredefineConstant("SqHalfY", SqHalfY)
	:PredefineConstant("SqHalfZ", SqHalfZ)
	:PredefineConstant("HalfX", HalfX)
	:PredefineConstant("HalfY", HalfY)
	:PredefineConstant("HalfZ", HalfZ)
	local NumAffectedBlocks = 0
	local Formula = Expression:Compile()
	local function SetBlock(a_RelX, a_RelY, a_RelZ)
		if (DoCheckMask) then
			local CurrentBlock, CurrentMeta = a_BlockArea:GetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ)
			if (not a_Mask:Contains(CurrentBlock, CurrentMeta)) then
				return
			end
		end
		a_BlockArea:SetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ, a_BlockTable:Get(a_RelX, a_RelY, a_RelZ))
		NumAffectedBlocks = NumAffectedBlocks + 1
	end
	for X = 0, HalfX, 1 do
		for Y = 0, HalfY, 1 do
			for Z = 0, HalfZ do
				local PlaceBlocks = Formula(X, Y, Z)
				if (a_IsHollow and PlaceBlocks) then
					if (Formula(X - 1, Y, Z) and Formula(X, Y - 1, Z) and Formula(X, Y, Z - 1) and Formula(X + 1, Y, Z) and Formula(X, Y + 1, Z) and Formula(X, Y, Z + 1)) then
						PlaceBlocks = false
					end
				end
				if (PlaceBlocks) then
					SetBlock(X,         Y,         Z)
					SetBlock(SizeX - X, Y,         Z)
					SetBlock(X,         Y, SizeZ - Z)
					SetBlock(SizeX - X, Y, SizeZ - Z)
					SetBlock(X,         SizeY - Y,         Z)
					SetBlock(SizeX - X, SizeY - Y,         Z)
					SetBlock(X,         SizeY - Y, SizeZ - Z)
					SetBlock(SizeX - X, SizeY - Y, SizeZ - Z)
				end
			end
		end
	end
	return NumAffectedBlocks
end

function cShapeGenerator.MakePyramid(a_BlockArea, a_BlockTable, a_IsHollow, a_Mask)
	local DoCheckMask = a_Mask ~= nil
	local SizeX, SizeY, SizeZ = a_BlockArea:GetCoordRange()
	local NumAffectedBlocks = 0
	local function SetBlock(a_RelX, a_RelY, a_RelZ)
		if (DoCheckMask) then
			local CurrentBlock, CurrentMeta = a_BlockArea:GetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ)
			if (not a_Mask:Contains(CurrentBlock, CurrentMeta)) then
				return
			end
		end
		a_BlockArea:SetRelBlockTypeMeta(a_RelX, a_RelY, a_RelZ, a_BlockTable:Get(a_RelX, a_RelY, a_RelZ))
		NumAffectedBlocks = NumAffectedBlocks + 1
	end
	local StepSizeX = SizeX / SizeY / 2
	local StepSizeZ = SizeZ / SizeY / 2
	local HollowLayer = function(a_Y)
		local MinX = math.floor(a_Y * StepSizeX)
		local MaxX = math.ceil(SizeX - MinX)
		local MinZ = math.floor(a_Y * StepSizeZ)
		local MaxZ = math.ceil(SizeZ - MinZ)
		for X = MinX, MaxX do
			SetBlock(X, a_Y, MinZ)
			SetBlock(X, a_Y, MaxZ)
		end
		for Z = MinZ + 1, MaxZ - 1 do
			SetBlock(MinX, a_Y, Z)
			SetBlock(MaxX, a_Y, Z)
		end
	end
	local SolidLayer = function(a_Y)
		local MinX = math.floor(a_Y * StepSizeX)
		local MaxX = math.ceil(SizeX - MinX)
		local MinZ = math.floor(a_Y * StepSizeZ)
		local MaxZ = math.ceil(SizeZ - MinZ)
		for X = MinX, MaxX do
			for Z = MinZ, MaxZ do
				SetBlock(X, a_Y, Z)
			end
		end
	end
	local LayerHandler = (a_IsHollow and HollowLayer) or SolidLayer;
	for Y = 0, SizeY do
		LayerHandler(Y)
	end
	return NumAffectedBlocks;
end
