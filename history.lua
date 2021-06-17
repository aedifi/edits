-- history.lua
-- Implements undo-redo commands.

function HandleUndoCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	local IsSuccess, Msg = State.UndoStack:Undo(a_Player:GetWorld())
	if (IsSuccess) then
		a_Player:SendMessage(cChatColor.LightGray .. "Reversed your previous edit.")
	else
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't reverse your previous edit.")
	end
	return true
end

function HandleRedoCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	local IsSuccess, Msg = State.UndoStack:Redo(a_Player:GetWorld())
	if (IsSuccess) then
		a_Player:SendMessage(cChatColor.LightGray .. "Restored your reversed edit.")
	else
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't restore your reversed edit.")
	end
	return true
end
