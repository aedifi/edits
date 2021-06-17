-- selection.lua
-- Implements the cPlayerSelection class which represents block selections.

cPlayerSelection = {}

function cPlayerSelection:new(a_Obj, a_PlayerState)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cPlayerSelection)
	self.__index = self
	a_Obj.Cuboid = cCuboid()
	a_Obj.IsFirstPointSet = false
	a_Obj.IsSecondPointSet = false
	a_Obj.PlayerState = a_PlayerState
	a_Obj.OnChangeCallbacks = {}
	return a_Obj
end

function cPlayerSelection:Deselect()
	self.IsFirstPointSet = false
	self.IsSecondPointSet = false
	self.Cuboid = cCuboid()
	local DB = cSQLStorage:Get()
	DB:ExecuteCommand("remove_playerselection",
		{
			playeruuid = self.PlayerState:GetUUID()
		}
	)
	if (not self.PlayerState.IsWECUIActivated) then
		return
	end
	self.PlayerState:DoWithPlayer(
		function(a_Player)
			a_Player:GetClientHandle():SendPluginMessage("WECUI", "s|cuboid")
		end
	)
end

function cPlayerSelection:SaveSelection(a_SelectionName)
	if (not self:IsValid()) then
		return false, "Couldn't find any selection."
	end
	local Success = cSQLStorage:Get():ExecuteCommand("set_namedplayerselection",
		{
			playeruuid = self.PlayerState:GetUUID(),
			selname = a_SelectionName,
			MinX = self.Cuboid.p1.x,
			MinY = self.Cuboid.p1.y,
			MinZ = self.Cuboid.p1.z,
			MaxX = self.Cuboid.p2.x,
			MaxY = self.Cuboid.p2.y,
			MaxZ = self.Cuboid.p2.z,
		}
	)
	if (not Success) then
		return false, "Couldn't save that selection."
	end
	return true
end

function cPlayerSelection:LoadSelection(a_SelectionName)
	local FoundSelection = false
	local DatabaseSuccess = cSQLStorage:Get():ExecuteCommand("get_namedplayerselection",
		{
			playeruuid = self.PlayerState:GetUUID(),
			selname = a_SelectionName
		},
		function(a_Data)
			self:SetFirstPoint(a_Data.MinX, a_Data.MinY, a_Data.MinZ)
			self:SetSecondPoint(a_Data.MaxX, a_Data.MaxY, a_Data.MaxZ)
			FoundSelection = true
		end
	)
	if (not DatabaseSuccess) then
		return false, "Couldn't save that selection."
	end
	if (not FoundSelection) then
		return false, "Couldn't find any selection."
	end
	self:NotifySelectionChanged()
	return true
end

function cPlayerSelection:Expand(a_SubMinX, a_SubMinY, a_SubMinZ, a_AddMaxX, a_AddMaxY, a_AddMaxZ)
	assert(a_SubMinX ~= nil)
	assert(a_SubMinY ~= nil)
	assert(a_SubMinZ ~= nil)
	assert(a_AddMaxX ~= nil)
	assert(a_AddMaxY ~= nil)
	assert(a_AddMaxZ ~= nil)
	if (self.Cuboid.p1.x < self.Cuboid.p2.x) then
		self.Cuboid.p1.x = self.Cuboid.p1.x - a_SubMinX
	else
		self.Cuboid.p2.x = self.Cuboid.p2.x - a_SubMinX
	end
	if (self.Cuboid.p1.y < self.Cuboid.p2.y) then
		self.Cuboid.p1.y = self.Cuboid.p1.y - a_SubMinY
	else
		self.Cuboid.p2.y = self.Cuboid.p2.y - a_SubMinY
	end
	if (self.Cuboid.p1.z < self.Cuboid.p2.z) then
		self.Cuboid.p1.z = self.Cuboid.p1.z - a_SubMinZ
	else
		self.Cuboid.p2.z = self.Cuboid.p2.z - a_SubMinZ
	end
	if (self.Cuboid.p1.x > self.Cuboid.p2.x) then
		self.Cuboid.p1.x = self.Cuboid.p1.x + a_AddMaxX
	else
		self.Cuboid.p2.x = self.Cuboid.p2.x + a_AddMaxX
	end
	if (self.Cuboid.p1.y > self.Cuboid.p2.y) then
		self.Cuboid.p1.y = self.Cuboid.p1.y + a_AddMaxY
	else
		self.Cuboid.p2.y = self.Cuboid.p2.y + a_AddMaxY
	end
	if (self.Cuboid.p1.z > self.Cuboid.p2.z) then
		self.Cuboid.p1.z = self.Cuboid.p1.z + a_AddMaxZ
	else
		self.Cuboid.p2.z = self.Cuboid.p2.z + a_AddMaxZ
	end
	self:NotifySelectionChanged()
end

function cPlayerSelection:GetCoordDiffs()
	assert(self:IsValid())
	local DifX = self.Cuboid.p2.x - self.Cuboid.p1.x
	local DifY = self.Cuboid.p2.y - self.Cuboid.p1.y
	local DifZ = self.Cuboid.p2.z - self.Cuboid.p1.z
	if (DifX < 0) then
		DifX = -DifX
	end
	if (DifY < 0) then
		DifY = -DifY
	end
	if (DifZ < 0) then
		DifZ = -DifZ
	end
	return DifX, DifY, DifZ
end

function cPlayerSelection:GetMinCoords()
	local MinX, MinY, MinZ
	if (self.Cuboid.p1.x < self.Cuboid.p2.x) then
		MinX = self.Cuboid.p1.x
	else
		MinX = self.Cuboid.p2.x
	end
	if (self.Cuboid.p1.y < self.Cuboid.p2.y) then
		MinX = self.Cuboid.p1.y
	else
		MinX = self.Cuboid.p2.y
	end
	if (self.Cuboid.p1.z < self.Cuboid.p2.z) then
		MinX = self.Cuboid.p1.z
	else
		MinX = self.Cuboid.p2.z
	end
	return MinX, MinY, MinZ
end

function cPlayerSelection:GetSizeDesc()
	assert(self:IsValid())
	local DifX, DifY, DifZ = self:GetCoordDiffs()
	DifX = DifX + 1
	DifY = DifY + 1
	DifZ = DifZ + 1
	local Volume = DifX * DifY * DifZ
	local Dimensions = tostring(DifX) .. " * " .. DifY .. " * " .. DifZ
	if (Volume == 1) then
		return Dimensions .. ", volume 1 block"
	else
		return Dimensions .. ", volume " .. Volume .. " blocks"
	end
end

function cPlayerSelection:GetSortedCuboid()
	assert(self:IsValid())
	local SCuboid = cCuboid(self.Cuboid)
	SCuboid:Sort()
	return SCuboid;
end

function cPlayerSelection:GetVolume()
	assert(self:IsValid())
	local Volume = self.Cuboid.p2.x - self.Cuboid.p1.x
	Volume = Volume * (self.Cuboid.p2.y - self.Cuboid.p1.y)
	Volume = Volume * (self.Cuboid.p2.z - self.Cuboid.p1.z)
	if (Volume < 0) then
		return -Volume
	end
	return Volume
end

function cPlayerSelection:GetXCoordsSorted()
	assert(self:IsValid())
	if (self.Cuboid.p1.x < self.Cuboid.p2.x) then
		return self.Cuboid.p1.x, self.Cuboid.p2.x
	else
		return self.Cuboid.p2.x, self.Cuboid.p1.x
	end
end

function cPlayerSelection:GetYCoordsSorted()
	assert(self:IsValid())
	if (self.Cuboid.p1.y < self.Cuboid.p2.y) then
		return self.Cuboid.p1.y, self.Cuboid.p2.y
	else
		return self.Cuboid.p2.y, self.Cuboid.p1.y
	end
end

function cPlayerSelection:GetZCoordsSorted()
	assert(self:IsValid())
	if (self.Cuboid.p1.z < self.Cuboid.p2.z) then
		return self.Cuboid.p1.z, self.Cuboid.p2.z
	else
		return self.Cuboid.p2.z, self.Cuboid.p1.z
	end
end

function cPlayerSelection:IsValid()
	return (self.IsFirstPointSet and self.IsSecondPointSet)
end

function cPlayerSelection:NotifySelectionChanged(a_PointChanged)
	if (self.PlayerState.IsWECUIActivated) then
		local Volume = -1
		if (self:IsValid()) then
			Volume = self:GetVolume()
		end
		local c = self.Cuboid
		if (self.IsFirstPointSet and ((a_PointChanged == nil) or (a_PointChanged == 1))) then
			self.PlayerState:DoWithPlayer(
				function(a_Player)
					a_Player:GetClientHandle():SendPluginMessage("WECUI", string.format(
						"p|0|%i|%i|%i|%i",
						c.p1.x, c.p1.y, c.p1.z, Volume
					))
				end
			)
		end
		if (self.IsSecondPointSet and ((a_PointChanged == nil) or (a_PointChanged == 2))) then
			self.PlayerState:DoWithPlayer(
				function(a_Player)
					a_Player:GetClientHandle():SendPluginMessage("WECUI", string.format(
						"p|1|%i|%i|%i|%i",
						c.p2.x, c.p2.y, c.p2.z, Volume
					))
				end
			)
		end
	end
end

function cPlayerSelection:Move(a_OffsetX, a_OffsetY, a_OffsetZ)
	assert(a_OffsetX ~= nil)
	assert(a_OffsetY ~= nil)
	assert(a_OffsetZ ~= nil)
	self.Cuboid:Move(a_OffsetX, a_OffsetY, a_OffsetZ)
	self:NotifySelectionChanged()
end

function cPlayerSelection:SetFirstPoint(a_BlockX, a_BlockY, a_BlockZ)
	local BlockX = tonumber(a_BlockX)
	local BlockY = tonumber(a_BlockY)
	local BlockZ = tonumber(a_BlockZ)
	assert(BlockX ~= nil)
	assert(BlockY ~= nil)
	assert(BlockZ ~= nil)
	self.Cuboid.p1:Set(BlockX, BlockY, BlockZ)
	self.IsFirstPointSet = true
	self:NotifySelectionChanged(1)
end

function cPlayerSelection:SetSecondPoint(a_BlockX, a_BlockY, a_BlockZ)
	local BlockX = tonumber(a_BlockX)
	local BlockY = tonumber(a_BlockY)
	local BlockZ = tonumber(a_BlockZ)
	assert(BlockX ~= nil)
	assert(BlockY ~= nil)
	assert(BlockZ ~= nil)
	self.Cuboid.p2:Set(BlockX, BlockY, BlockZ)
	self.IsSecondPointSet = true
	self:NotifySelectionChanged(2)
end

function cPlayerSelection:SetPos(a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_PosName, a_ForceSet)
	if (a_BlockFace == BLOCK_FACE_NONE) then
		return false
	end
	if (not self.PlayerState.WandActivated and not a_ForceSet) then
		return false
	end
	local Abort = false
	self.PlayerState:DoWithPlayer(
		function(a_Player)
			if not(a_Player:HasPermission("edits.selection.pos")) then
				Abort = true
				return true
			end
			if (a_Player:IsCrouched()) then
				a_BlockX, a_BlockY, a_BlockZ = AddFaceDirection(a_BlockX, a_BlockY, a_BlockZ, a_BlockFace)
			end
		end
	)
	if (Abort) then
		return false
	end
	local SetFunc = (a_PosName == "First") and cPlayerSelection.SetFirstPoint or cPlayerSelection.SetSecondPoint
	SetFunc(self, a_BlockX, a_BlockY, a_BlockZ)
	return true, cChatColor.LightGray .. a_PosName .. " position set to X: " .. a_BlockX .. ", Y: " .. a_BlockY .. ", Z: " .. a_BlockZ .. "."
end

function cPlayerSelection:Load(a_PlayerUUID)
	local DB = cSQLStorage:Get()
	DB:ExecuteCommand("get_playerselection",
		{
			playeruuid = a_PlayerUUID
		},
		function(a_Data)
			self:SetFirstPoint(a_Data.MinX, a_Data.MinY, a_Data.MinZ)
			self:SetSecondPoint(a_Data.MaxX, a_Data.MaxY, a_Data.MaxZ)
		end
	)
	self:NotifySelectionChanged()
end

function cPlayerSelection:Save(a_PlayerUUID)
	if (not self:IsValid()) then
		return
	end
	local SrcCuboid = self:GetSortedCuboid()
	local DB = cSQLStorage:Get()
	DB:ExecuteCommand("set_playerselection",
		{
			playeruuid = a_PlayerUUID,
			MinX = SrcCuboid.p1.x,
			MinY = SrcCuboid.p1.y,
			MinZ = SrcCuboid.p1.z,
			MaxX = SrcCuboid.p2.x,
			MaxY = SrcCuboid.p2.y,
			MaxZ = SrcCuboid.p2.z,
		}
	)
end
