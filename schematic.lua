-- schematic.lua
-- Handlers for schematic-related commands.

function HandleSchematicMainCommand(a_Split, a_Player)
	a_Player:SendMessage(cChatColor.LightGray .. "Usage: //schem <import [...] | load [...] | save [...]>")
	return true
end

function HandleSchematicFormatsCommand(a_Split, a_Player)
	a_Player:SendMessage(cChatColor.LightGray .. "Formats (1): MCEdit")
	return true
end

function HandleSchematicListCommand(a_Split, a_Player)
	local FolderContents = cFile:GetFolderContents("schematics")

	-- Filter out non-files and non-".schematic" files.
	local FileList = {}
	for idx, fnam in ipairs(FolderContents) do
		if (
			cFile:IsFile("schematics/" .. fnam) and
			fnam:match(".*%.schematic")
		) then
			table.insert(FileList, fnam:sub(1, fnam:len() - 10))
		end
	end
	table.sort(FileList,
		function(f1, f2)
			return (string.lower(f1) < string.lower(f2))
		end
	)

	a_Player:SendMessage(cChatColor.LightGray .. "Schematics (" .. #FileList .. "): " .. table.concat(FileList, ", "))
	return true
end

function HandleSchematicLoadCommand(a_Split, a_Player)
	if (#a_Split ~= 3) then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //schem load <filename>")
		return true
	end
	local FileName = a_Split[3]

	local Path = "schematics/" .. FileName .. ".schematic"
	if not(cFile:IsFile(Path)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that schematic.")
		return true
	end

	local State = GetPlayerState(a_Player)
	if not(State.Clipboard:LoadFromSchematicFile(Path)) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that schematic.")
		return true
	end
	a_Player:SendMessage(cChatColor.LightGray .. "Loaded that schematic onto your clipboard.")
	-- a_Player:SendMessage(cChatColor.LightPurple .. "Clipboard size: " .. State.Clipboard:GetSizeDesc())
	return true
end

function HandleSchematicSaveCommand(a_Split, a_Player)
	local FileName
	if (#a_Split == 4) then
		FileName = a_Split[4]
	elseif (#a_Split == 3) then
		FileName = a_Split[3]
	else
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //schem save <filename>")
		return true
	end

	if (not g_Config.Schematics.OverrideExistingFiles and cFile:IsFile("schematics/" .. FileName .. ".schematic")) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't write to a filename that's already taken.")
		return true
	end

	local State = GetPlayerState(a_Player)
	if not(State.Clipboard:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find anything on your clipboard to save.")
		return true
	end

	State.Clipboard:SaveToSchematicFile("schematics/" .. FileName .. ".schematic")
	a_Player:SendMessage(cChatColor.LightGray .. "Saved your clipboard as an operable schematic.")
	return true
end

function HandleSchematicImportCommand(a_Split, a_Player)
	if (#a_Split ~= 3) == nil then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //schem import <url>")
	else
		local URL = a_Split[3]
		local FileName = URL:match("([^/]+)$")
		if not string.find(URL, ".schematic",0,true) then
			a_Player:SendMessageFailure(cChatColor.LightGray .. "Couldn't import a non-schematic file.")
		elseif cFile:IsFile("schematics/" .. FileName) then
			a_Player:SendMessageFailure(cChatColor.LightGray .. "Couldn't write to a filename that's already taken.")
		else
			os.execute("wget " .. URL .. " -P schematics/")
			a_Player:SendMessageSuccess(cChatColor.LightGray .. "Imported that schematic as operable.")
		end
	end
	return true
end
