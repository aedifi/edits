-- expression.lua
-- Allows forumlas to be executed in a safe container.

cExpression = {}

cExpression.m_ExpressionTemplate =
[[
local assert, pairs = assert, pairs
local abs, acos, asin, atan, atan2,
ceil, cos, cosh, exp, floor, ln,
log, log10, max, min, round, sin,
sinh, sqrt, tan, tanh, random, pi, e
=
math.abs, math.acos, math.asin, math.atan, math.atan2,
math.ceil, math.cos, math.cosh, math.exp, math.floor, math.log,
math.log, math.log10, math.max, math.min, math.round, math.sin,
math.sinh, math.sqrt, math.tan, math.tanh, math.random, math.pi, math.exp(1)
local cbrt = function(x) return sqrt(x^(1/3)) end
local randint = function(max) return random(0, max) end
local rint = function(num) local Number, Decimal = math.modf(num); return (Decimal <= 0.5) and Number or (Number + 1) end
%s
local validators = {...}
return function(%s)
	%s
	for _, validator in pairs(validators) do
		assert(validator(%s))
	end
	return %s
end]]

cExpression.m_LoaderEnv =
{
	math = math,
	assert = assert,
	pairs = pairs,
}

cExpression.m_Assignments =
{
	"%+=",
	"%-=",
	"%*=",
	"%%=",
	"%^=",
	"/=",
}

cExpression.m_Comparisons =
{
	{Usage = "if%s%((.*)%)%s(.*)%selse%s(.*)", Result = "%s and %s or %s"},
	{Usage = "if%s%((.*)%)%s(.*)", Result = "%s and %s"},
	{Usage = "(.*)<(.*)", Result = "%s<%s"},
	{Usage = "(.*)>(.*)", Result = "%s>%s"},
	{Usage = "(.*)<=(.*)", Result = "%s<=%s"},
	{Usage = "(.*)>=(.*)", Result = "%s>=%s"},
	{Usage = "(.*)==(.*)", Result = "%s==%s"},
	{Usage = "(.*)!=(.*)", Result = "%s~=%s"},
	{Usage = "(.*)~=(.*)", Result = "%s~=%s"},
}

function cExpression:new(a_Formula)
	local Obj = {}
	a_Formula = a_Formula
	:gsub("&&", " and ")
	:gsub("||", " or ")
	setmetatable(Obj, cExpression)
	self.__index = self
	Obj.m_Formula = a_Formula
	Obj.m_Parameters = {}
	Obj.m_ReturnValues = {}
	Obj.m_PredefinedConstants = {}
	Obj.m_ReturnValidators = {}
	return Obj
end

function cExpression:AddParameter(a_Name)
	table.insert(self.m_Parameters, a_Name)
	return self
end

function cExpression:AddReturnValue(a_Name)
	table.insert(self.m_ReturnValues, a_Name)
	return self
end

function cExpression:AddReturnValidator(a_Validator)
	table.insert(self.m_ReturnValidators, a_Validator)
	return self
end

function cExpression:PredefineConstant(a_VarName, a_Value)
	table.insert(self.m_PredefinedConstants, {name = a_VarName, value = a_Value})
	return self
end

function cExpression:Compile()
	local Arguments    = table.concat(self.m_Parameters, ", ")
	local ReturnValues = table.concat(self.m_ReturnValues, ", ")
	local PredefinedVariables = ""
	for _, Variable in ipairs(self.m_PredefinedConstants) do
		local Value = Variable.value
		if (type(Value) == "string") then
			Value = "\"" .. Value .. "\""
		end
		PredefinedVariables = PredefinedVariables .. "local " .. Variable.name .. " = " .. Value .. "\n"
	end
	local NumComparison = 1
	local Actions = StringSplitAndTrim(self.m_Formula, ";")
	for Idx, Action in ipairs(Actions) do
		local IsAssignment = Action:match("[%a%d%s]=[%(%a%d%s]") ~= nil
		for Idx, Assignment in pairs(cExpression.m_Assignments) do
			if (Action:match(Assignment)) then
				IsAssignment = true
			end
		end
		for _, Comparison in ipairs(cExpression.m_Comparisons) do
			if (Action:match(Comparison.Usage)) then
				Action = Comparison.Result:format(Action:match(Comparison.Usage))
			end
		end
		if (IsAssignment) then
			for Idx, Assignment in pairs(cExpression.m_Assignments) do
				local Operator = Assignment:match(".="):sub(1, 1)
				local Pattern = "(.*)" .. Assignment .. "(.*)"
				Action:gsub(Pattern,
					function(a_Variable, a_Val2)
						Action = a_Variable .. " = " .. a_Variable .. Operator .. a_Val2
					end
				)
			end
			Actions[Idx] = "local " .. Action
		else
			Actions[Idx]  = "local Comp" .. NumComparison .. " = " .. Action
			NumComparison = NumComparison + 1
		end
	end
	local formulaLoaderSrc = cExpression.m_ExpressionTemplate:format(PredefinedVariables, Arguments, table.concat(Actions, "\n\t"), ReturnValues, ReturnValues)
	local FormulaLoader = loadstring(formulaLoaderSrc)
	if (not FormulaLoader) then
		return false, "Invalid formula"
	end
	setfenv(FormulaLoader, cExpression.m_LoaderEnv)
	local Success, Formula = pcall(FormulaLoader, unpack(self.m_ReturnValidators))
	if (not Success) then
		return false, "Invalid formula"
	end
	setfenv(Formula, {})
	return Formula
end
