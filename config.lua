-- config.lua
-- Contains functions for initializing and writing a configuration.

g_Config = {}

local g_LoaderEnv = {}
for Key, Value in pairs(_G) do
	if (Key:match("E_.*")) then
		g_LoaderEnv[ItemTypeToString(Value)] = Value
	end
end

local g_ConfigDefault =
[[
WandItem = woodenaxe,
Limits =
{
	ButcherRadius = -1,
	MaxBrushRadius = 5,
	DisallowedBlocks = {6, 7, 14, 15, 16, 26, 27, 28, 29, 39, 31, 32, 33, 34, 36, 37, 38, 39, 40, 46, 50, 51, 56, 59, 69, 73, 74, 75, 76, 77, 81, 83},
},
Defaults =
{
	ButcherRadius = 20,
},
NavigationWand =
{
	Item = compass,
	MaxDistance = 120,
	TeleportNoHit = true,
},
Scripting =
{
	-- If true, an error will be logged when a craftscript fails.
	Debug = false,
	-- The amount of seconds that a script may be active. Any longer and the script will be aborted.
	-- If negative, the time a script can run will be unlimited.
	MaxExecutionTime = 5,
},
Schematics =
{
	OverrideExistingFiles = false,
},
Storage =
{
	-- If set to true, the selection of a player will be remembered once he leaves.
	RememberPlayerSelection = true,
	-- If Edits needs to change a format in the database, the database will be backed up first before changing.
	-- This does not mean when adding or removing data the database will be backed up. Only when the used database is outdated.
	BackupDatabaseWhenUpdating = true,
}
]]

local function WriteDefaultConfiguration(a_Path)
	LOGWARNING("Wrote the default Edits configuration to \"" .. a_Path .. "\".")
	local File = io.open(a_Path, "w")
	File:write(g_ConfigDefault)
	File:close()
end

local function GetDefaultConfigurationTable()
	local Loader = loadstring("return {" .. g_ConfigDefault .. "}")

	setfenv(Loader, g_LoaderEnv)

	return Loader()
end

local function LoadDefaultConfiguration()
	LOGWARNING("The default Edits configuration will be used.")
	g_Config = GetDefaultConfigurationTable()
end

local function FindErrorPosition(a_ErrorMessage)
	local ErrorPosition = a_ErrorMessage:match(":(.-):") or 0
	return ErrorPosition
end

function InitializeConfiguration(a_Path)
	local ConfigContent = cFile:ReadWholeFile(a_Path)

	if (ConfigContent == "") then
		WriteDefaultConfiguration(a_Path)
		LoadDefaultConfiguration()
		return
	end

	local ConfigLoader, Error = loadstring("return {" .. ConfigContent .. "}")
	if (not ConfigLoader) then
		local ErrorPosition = FindErrorPosition(Error)
		LOGWARNING("Found an error in the Edits configuration near (line) " .. ErrorPosition .. ".")
		LoadDefaultConfiguration()
		return
	end

	setfenv(ConfigLoader, g_LoaderEnv)

	local Success, Result = pcall(ConfigLoader)
	if (not Success) then
		local ErrorPosition = FindErrorPosition(Result)
		LOGWARNING("Found an error in the Edits configuration near (line) " .. ErrorPosition .. ".")
		LoadDefaultConfiguration()
		return
	end

	local DefaultConfig = GetDefaultConfigurationTable()
	table.merge(Result, DefaultConfig)

	if (Result.Limits and (type(Result.Limits.DisallowedBlocks) == "table")) then
		Result.Limits.DisallowedBlocks = table.todictionary(Result.Limits.DisallowedBlocks)
	end

	g_Config = Result
end