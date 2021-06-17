-- undostack.lua
-- Represents a single stack of undo and redo operations.

cUndoStack = {}

function cUndoStack:new(a_Obj, a_MaxDepth, a_PlayerState)
	assert(a_MaxDepth ~= nil)
	assert(a_PlayerState ~= nil)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cUndoStack)
	self.__index = self
	a_Obj.MaxDepth = a_MaxDepth
	a_Obj.UndoStack = {}
	a_Obj.RedoStack = {}
	return a_Obj
end

function cUndoStack:ApplySnapshot(a_SrcStack, a_DstStack, a_World)
	assert(type(a_SrcStack) == "table")
	assert(type(a_DstStack) == "table")
	assert(a_World ~= nil)
	local Src = self:PopLastSnapshotInWorld(a_SrcStack, a_World:GetName())
	if (Src == nil) then
		return false, "Couldn't find any snapshot to apply."
	end
	local MinX, MinY, MinZ = Src.Area:GetOrigin()
	local MaxX = MinX + Src.Area:GetSizeX()
	local MaxY = MinY + Src.Area:GetSizeY()
	local MaxZ = MinZ + Src.Area:GetSizeZ()
	local BackupArea = cBlockArea()
	if not(BackupArea:Read(a_World, MinX, MaxX, MinY, MaxY, MinZ, MaxZ)) then
		return false, "Couldn't capture the destination."
	end
	table.insert(a_DstStack, {WorldName = Src.WorldName, Area = BackupArea, Name = Src.Name})
	Src.Area:Write(a_World, MinX, MinY, MinZ)
	a_World:WakeUpSimulatorsInArea(cCuboid(
		Vector3i(MinX - 1, MinY - 1, MinZ - 1),
		Vector3i(MaxX + 1, MaxY + 1, MaxZ + 1)
    ))
	Src.Area:Clear()
	return true
end

function cUndoStack:DropAllRedo()
	for _, redo in ipairs(self.RedoStack) do
		redo.Area:Clear()
	end
	self.RedoStack = {}
end

function cUndoStack:PopLastSnapshotInWorld(a_Stack, a_WorldName)
	assert(type(a_Stack) == "table")
	assert(type(a_WorldName) == "string")
	for idx = #a_Stack, 1, -1 do
		if (a_Stack[idx].WorldName == a_WorldName) then
			local res = a_Stack[idx]
			table.remove(a_Stack, idx)
			return res
		end
	end
	return nil
end

function cUndoStack:PushUndo(a_World, a_Area, a_Name)
	assert(a_World ~= nil)
	assert(a_Area ~= nil)
	self:DropAllRedo()
	table.insert(self.UndoStack, {WorldName = a_World:GetName(), Area = a_Area, Name = a_Name})
	if (#self.UndoStack > self.MaxDepth) then
		self.UndoStack[1].Area:Clear()
		table.remove(self.UndoStack, 1)
	end
end

function cUndoStack:PushUndoFromCuboid(a_World, a_Cuboid, a_Name)
	assert(tolua.type(a_World) == "cWorld")
	assert(tolua.type(a_Cuboid) == "cCuboid")
	local Area = cBlockArea()
	if not(Area:Read(
		a_World,
		a_Cuboid.p1.x, a_Cuboid.p2.x,
		a_Cuboid.p1.y, a_Cuboid.p2.y,
		a_Cuboid.p1.z, a_Cuboid.p2.z
	)) then
		return false, "Couldn't read that block area."
	end
	self:PushUndo(a_World, Area, a_Name)
	return true
end

function cUndoStack:Redo(a_World)
	return self:ApplySnapshot(self.RedoStack, self.UndoStack, a_World)
end

function cUndoStack:Undo(a_World)
	return self:ApplySnapshot(self.UndoStack, self.RedoStack, a_World)
end
