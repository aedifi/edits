-- special.lua
-- Basic commands and handshake functions.

function HandleWorldEditCuiCommand(a_Split, a_Player)
	-- /cui
	local State = GetPlayerState(a_Player)
	State.IsWECUIActivated = true
    State.Selection:NotifySelectionChanged()
    a_Player:SendMessage(cChatColor.LightGray .. "Completed the visualizer handshake.")
	return true
end

function HandleWandCommand(a_Split, a_Player)
	local Item = cItem(g_Config.WandItem)
	if (a_Player:GetInventory():AddItem(Item)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Gave you the selection wand.")
	else
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't fit the wand into your inventory.")
	end
	return true
end

function HandleToggleEditWandCommand(a_Split, a_Player)
	local State = GetPlayerState(a_Player)
	if not(State.WandActivated) then
		State.WandActivated = true
		a_Player:SendMessage(cChatColor.LightGray .. "Disabled the selection wand for you.")
	else
		State.WandActivated = false
		a_Player:SendMessage(cChatColor.LightGray .. "Enabled the selection wand for you.")
	end
	return true
end
