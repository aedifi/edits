-- craftscripts.lua
-- Implements the cCraftScript class which represents a player's script.

local function LOGSCRIPTERROR(a_Msg)
	if (not g_Config.Scripting.Debug) then
		return
	end
	LOGERROR(a_Msg)
end

local g_BlockedFunctions = table.todictionary{
	"rawset",
	"rawget",
	"setfenv",
	"io",
	"os",
	"debug",
	"cFile",
	"loadstring",
	"loadfile",
	"load",
	"dofile",
	"ExecuteString",
	"_G",
	"cPluginManager",
}

local g_CraftScriptEnvironment = setmetatable({}, {
    __index = function(_, a_Key)
        if (g_BlockedFunctions[a_Key]) then
            local ScriptInfo = debug.getinfo(2)
            error("Edits tried to use blocked variable at line " .. ScriptInfo.currentline .. " in file " .. ScriptInfo.short_src .. ".")
            return nil
        end
        return _G[a_Key]
    end
}
)

cCraftScript = {}

function cCraftScript:new(a_Obj)
	a_Obj = a_Obj or {}
	setmetatable(a_Obj, cCraftScript)
	self.__index = self
	a_Obj.SelectedScript = nil
	return a_Obj;
end

function cCraftScript:SelectScript(a_ScriptName)
	local Path = cPluginManager:GetCurrentPlugin():GetLocalFolder() .. "/craftscripts/" .. a_ScriptName .. ".lua"
	if (not cFile:IsFile(Path)) then
		return false, "Couldn't find that script."
	end
	local Function, Err = loadfile(Path)
	if (not Function) then
		LOGSCRIPTERROR(Err)
		return false, "Couldn't execute that script."
	end
	setfenv(Function, g_CraftScriptEnvironment)
	self.SelectedScript = Function
	return true
end

function cCraftScript:Execute(a_Player, a_Split)
	if (not self.SelectedScript) then
		return false, "Couldn't find a script."
	end
	if (g_Config.Scripting.MaxExecutionTime > 0) then
		local TimeLimit = os.clock() + g_Config.Scripting.MaxExecutionTime
		debug.sethook(function()
			if (TimeLimit < os.clock()) then
				debug.sethook()
				error("Exceeded the time limit for script executions.")
			end
		end, "", 100000)
	end
	local Success, Err = pcall(self.SelectedScript, a_Player, a_Split)
	debug.sethook()
	if (not Success) then
		LOGSCRIPTERROR(Err)
		return false, "Couldn't execute that script."
	end
	return true
end
