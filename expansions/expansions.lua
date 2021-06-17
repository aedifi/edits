-- expansions.lua
-- Contains functions to expand the string library.

-- Rounds any given number.
function math.round(a_GivenNumber)
	local Number, Decimal = math.modf(a_GivenNumber)
	if (Decimal >= 0.5) then
		return Number + 1
	else
		return Number
	end
end

-- Capitalizes the first character of a string and lowercases any remaining text.
function string.ucfirst(a_String)
	local firstChar = a_String:sub(1, 1):upper()
	local Rest = a_String:sub(2):lower()
	return firstChar .. Rest
end

-- Checks if the table is an array.
function table.isarray(a_Table)
	local i = 0
	for _, t in pairs(a_Table) do
		i = i + 1
		if (not rawget(a_Table, i)) then
			return false
		end
	end
	return true
end

-- Merges non-array values from a_DstTable into a_SrcTable if no key is present in the latter.
function table.merge(a_SrcTable, a_DstTable)
	for Key, Value in pairs(a_DstTable) do
		if (a_SrcTable[Key] == nil) then
			a_SrcTable[Key] = Value
		elseif ((type(Value) == "table") and (type(a_SrcTable[Key]) == "table")) then
			if (not table.isarray(a_SrcTable[Key])) then
				table.merge(a_SrcTable[Key], Value)
			end
		end
	end
end

-- Creates a table indexed from the values in a_Table.
function table.todictionary(a_Table)
	local res = {}
	for Key, Value in pairs(a_Table) do
		res[Value] = true
	end
	return res
end
