-- main.lua
-- Implements the plugin's main entrypoint.

-- Load the library expansions.
dofolder(cPluginManager:GetCurrentPlugin():GetLocalFolder() .. "/expansions")
g_ExcludedFolders = table.todictionary{
	"craftscripts",
	"expansions",
	".",
	"..",
}

-- Load all the folders.
local WorldEditPath = cPluginManager:GetCurrentPlugin():GetLocalFolder()
for _, Folder in ipairs(cFile:GetFolderContents(WorldEditPath)) do repeat
	local Path = WorldEditPath .. "/" .. Folder
	if (not cFile:IsFolder(Path)) then
		break
	end

	if (g_ExcludedFolders[Folder]) then
		break
	end

	dofolder(Path)
until true end

PLUGIN = nil

function Initialize(Plugin)
    Plugin:SetName("Edits")
    Plugin:SetVersion(tonumber(g_PluginInfo["Version"]))

    InitializeConfiguration(Plugin:GetLocalFolder() .. "/config.cfg")

    -- Load the InfoReg shared library...
    dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

    -- Bind all the commands...
    RegisterPluginInfoCommands()
    
	-- Bind to cSQLStorage...
    cSQLStorage:Get()
    cFile:CreateFolder("schematics")

    return true
end

function OnDisable()
	ForEachPlayerState(
		function(a_State)
			a_State:Save(a_State:GetUUID())
		end
	)
end
