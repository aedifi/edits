-- clipboard.lua
-- Implements handlers for clipboard-related commands.

function HandleCopyCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	if not(State.Selection:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find any region to copy.")
		return true
	end

	local SrcCuboid = State.Selection:GetSortedCuboid()
	local World = a_Player:GetWorld()
	if (CallHook("OnAreaCopying", a_Player, World, SrcCuboid)) then
		return
	end

	local NumBlocks = State.Clipboard:Copy(World, SrcCuboid, SrcCuboid.p1 - Vector3i(a_Player:GetPosition()))

	CallHook("OnAreaCopied", a_Player, World, SrcCuboid)

	a_Player:SendMessage(cChatColor.LightGray .. "Copied " .. NumBlocks .. " (blocks) to your clipboard.")
	-- a_Player:SendMessage(cChatColor.LightGray .. "Size: " .. State.Clipboard:GetSizeDesc())
	return true
end

function HandleCutCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	if not(State.Selection:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find any region to cut.")
		return true
	end

	local SrcCuboid = State.Selection:GetSortedCuboid()
	local World = a_Player:GetWorld()
	if (CallHook("OnAreaChanging", SrcCuboid, a_Player, World, "cut")) then
		return
	end

	State.UndoStack:PushUndoFromCuboid(World, SrcCuboid, "cut")

	local NumBlocks = State.Clipboard:Cut(World, SrcCuboid, SrcCuboid.p1 - Vector3i(a_Player:GetPosition()))

	CallHook("OnAreaChanged", SrcCuboid, a_Player, World, "cut")

	a_Player:SendMessage(cChatColor.LightGray .. "Cut and copied " .. NumBlocks .. " (blocks) to your clipboard.")
	-- a_Player:SendMessage(cChatColor.LightGray .. "Size: " .. State.Clipboard:GetSizeDesc())
	return true
end

function HandlePasteCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	if not(State.Clipboard:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find anything on your clipboard to paste.")
		return true
	end

	local UseOffset = true

	for Idx, Parameter in ipairs(a_Split) do
		if (Parameter == "-no") then
			UseOffset = false
		end
	end

	local DstCuboid = State.Clipboard:GetPasteDestCuboid(a_Player, UseOffset)
	if (CallHook("OnAreaChanging", DstCuboid, a_Player, a_Player:GetWorld(), "paste")) then
		return
	end

	State.UndoStack:PushUndoFromCuboid(a_Player:GetWorld(), DstCuboid, "paste")
	local NumBlocks = State.Clipboard:Paste(a_Player, DstCuboid.p1)

	CallHook("OnAreaChanged", DstCuboid, a_Player, a_Player:GetWorld(), "paste")

    if (UseOffset) then
        a_Player:SendMessage(cChatColor.LightGray .. "Pasted " .. NumBlocks .. " (blocks) relative to you.")
    else
        a_Player:SendMessage(cChatColor.LightGray .. "Pasted " .. NumBlocks .. " (blocks) next to you.")
	end
	return true
end

function HandleRotateCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	if not(State.Clipboard:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find anything on your clipboard to rotate.")
		return true
	end

	local Angle = tonumber(a_Split[2])
	if (Angle == nil) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //rotate <90 | 180 | 270 | -90 | -180 | -270>")
		return true
	end

	local NumRots = math.floor(Angle / 90 + 0.5)  -- round to nearest 90-degree step...
	State.Clipboard:Rotate(NumRots)
	a_Player:SendMessage(cChatColor.LightGray .. "Rotated the clipboard by " .. (NumRots * 90) .. " (degrees, CCW).")
	-- a_Player:SendMessage(cChatColor.LightGray .. "Size: " .. State.Clipboard:GetSizeDesc())
	return true
end
