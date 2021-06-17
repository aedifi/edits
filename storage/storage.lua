-- storage.lua
-- Implements the database storage.

-- Current database version.
local g_CurrentDatabaseVersion = 1

local g_Queries = {}
local QueryPath = cPluginManager:Get():GetCurrentPlugin():GetLocalFolder() .. "/storage/queries"
for _, FileName in ipairs(cFile:GetFolderContents(QueryPath)) do
	if (FileName:match("%.sql$")) then
		g_Queries[FileName:match("^(.*)%.sql$")] = cFile:ReadWholeFile(QueryPath .. "/" .. FileName)
	end
end

local g_ChangeScripts = {}
local ChangeScriptPath = cPluginManager:Get():GetCurrentPlugin():GetLocalFolder() .. "/storage/changescripts"
for _, FileName in ipairs(cFile:GetFolderContents(ChangeScriptPath)) do
	if (FileName:match("%.sql$")) then
		g_ChangeScripts[FileName:match("^(.*)%.sql$")] = cFile:ReadWholeFile(ChangeScriptPath .. "/" .. FileName)
	end
end

cSQLStorage = {}

-- Creates a new object and initializes/updates the database.
local function cSQLStorage_new()
	local Obj = {}
	setmetatable(Obj, cSQLStorage)
	cSQLStorage.__index = cSQLStorage
	local PluginRoot = cPluginManager:Get():GetCurrentPlugin():GetLocalFolder()
	local ErrorCode, ErrorMsg;
	Obj.DB, ErrorCode, ErrorMsg = sqlite3.open(PluginRoot .. "/storage/storage.sqlite")
	if (Obj.DB == nil) then
		LOGWARNING("Couldn't open the database.");
		error(ErrorMsg);
	end
	local SavedDatabaseVersion = -1
	Obj:ExecuteStatement("SELECT * FROM sqlite_master WHERE name = 'DatabaseInfo' AND type='table'", nil,
		function()
			Obj:ExecuteStatement("SELECT `DatabaseVersion` FROM DatabaseInfo", nil,
				function(a_Data)
					SavedDatabaseVersion = a_Data["DatabaseVersion"]
				end
			)
		end
	)
	if (SavedDatabaseVersion < g_CurrentDatabaseVersion) then
		if (g_Config.BackupDatabaseWhenUpdating) then
			if (SavedDatabaseVersion ~= -1) then
				if (not cFile:IsFolder(PluginRoot .. "/storage/backups")) then
					cFile:CreateDirectory(PluginRoot .. "/storage/backups")
				end

				cFile:Copy(PluginRoot .. "/storage/storage.sqlite", PluginRoot .. ("/storage/Backups/storage %s.sqlite"):format(os.date("%Y-%m-%d")))
			end
		end
		for I = math.max(SavedDatabaseVersion, 1), g_CurrentDatabaseVersion do
			Obj:ExecuteChangeScript(tostring(I))
		end
	elseif (SavedDatabaseVersion > g_CurrentDatabaseVersion) then
		error("Couldn't recognize this database's version.")
	end
	return Obj
end

function cSQLStorage:Get()
	if (not cSQLStorage.Storage) then
		cSQLStorage.Storage = cSQLStorage_new()
	end
	return cSQLStorage.Storage
end

function cSQLStorage:ExecuteCommand(a_QueryName, a_Parameters, a_Callback)
	local Command = assert(g_Queries[a_QueryName], "Couldn't find that query.")
	local Commands = StringSplit(Command, ";")
	for _, Sql in ipairs(Commands) do
		local CommandExecuted, ErrMsg = self:ExecuteStatement(Sql, a_Parameters, a_Callback)
		if (not CommandExecuted) then
			return false, ErrMsg
		end
	end
	return true
end

function cSQLStorage:ExecuteChangeScript(a_ChangeScriptName)
	local Command = assert(g_ChangeScripts[a_ChangeScriptName], "Couldn't find that changescript.")
	local Commands = StringSplit(Command, ";")
	for _, Sql in ipairs(Commands) do
		local CommandExecuted, ErrMsg = self:ExecuteStatement(Sql)
		if (not CommandExecuted) then
			return false, ErrMsg
		end
	end
end

function cSQLStorage:ExecuteStatement(a_Sql, a_Parameters, a_Callback)
	local Stmt, ErrCode, ErrMsg = self.DB:prepare(a_Sql)
	if (not Stmt) then
		LOGWARNING("Couldn't prepare query >>" .. a_Sql .. "<<: " .. (ErrCode or "<unknown>") .. " (" .. (ErrMsg or "<no message>") .. ")")
		return false, ErrMsg or "<no message>"
	end
	if (a_Parameters ~= nil) then
		Stmt:bind_names(a_Parameters)
    end
	if (a_Callback ~= nil) then
		for val in Stmt:nrows() do
			if (a_Callback(val)) then
				break
			end
		end
	else
		Stmt:step()
	end
	Stmt:finalize()
	return true
end
