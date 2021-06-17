-- biomes.lua
-- Handles biome listing and biome-related operations.

function HandleSetBiomeCommand(a_Split, a_Player)
	if #a_Split == 1 then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //setbiome [-p] <biome>")
		return true
	end

	if #a_Split > 3 then
		a_Player:SendMessage(cChatColor.LightGray .. "Usage: //setbiome [-p] <biome>")
		return true
	end

	local World = a_Player:GetWorld()
	local PosX = math.floor(a_Player:GetPosX())
	local PosZ = math.floor(a_Player:GetPosZ())

	if #a_Split == 3 then
		if a_Split[2] ~= "-p" then
			a_Player:SendMessage(cChatColor.LightGray .. "Usage: //setbiome [-p] <biome>")
			return true
		end

		local NewBiome = StringToBiome(a_Split[3])
		if NewBiome == biInvalidBiome then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that biome.")
			return true
		end

		World:SetAreaBiome(PosX, PosX, PosZ, PosZ, NewBiome)
		a_Player:SendMessage(cChatColor.LightGray .. "Set the biome to " .. a_Split[3] .. " at your location.")
		return true
	elseif #a_Split == 2 then
		local NewBiome = StringToBiome(a_Split[2])
		if NewBiome == biInvalidBiome then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find that biome.")
			return true
		end

		local State = GetPlayerState(a_Player)
		if not(State.Selection:IsValid()) then
			a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find any region to set.")
			return true
		end
		local MinX, MaxX = State.Selection:GetXCoordsSorted()
		local MinZ, MaxZ = State.Selection:GetZCoordsSorted()

		World:SetAreaBiome(MinX, MaxX, MinZ, MaxZ, NewBiome)
		a_Player:SendMessage(cChatColor.LightGray .. "Set the biome to " .. a_Split[2] .. ". " .. (1 + MaxX - MinX) * (1 + MaxZ - MinZ) .. " columns affected.")
		return true
	end
	return true
end

function HandleReadBiomeCommand(a_Split, a_Player)
	if (a_Split[2] == "-p") then
		local Biome = BiomeToString(a_Player:GetWorld():GetBiomeAt(math.floor(a_Player:GetPosX()), math.floor(a_Player:GetPosZ())))
		a_Player:SendMessage(cChatColor.LightGray .. "Biome: " .. Biome)
		return true
	end

	local State = GetPlayerState(a_Player)
	if not(State.Selection:IsValid()) then
		a_Player:SendMessage(cChatColor.LightGray .. "Couldn't find any region to read.")
		return true
	end

	local BiomesSet = {}
	local MinX, MaxX = State.Selection:GetXCoordsSorted()
	local MinZ, MaxZ = State.Selection:GetZCoordsSorted()
	local World = a_Player:GetWorld()
	for X = MinX, MaxX do
		for Z = MinZ, MaxZ do
			BiomesSet[World:GetBiomeAt(X, Z)] = true
		end
	end

	local BiomesArr = {}
	for b, val in pairs(BiomesSet) do
		if (val) then
			table.insert(BiomesArr, BiomeToString(b))
		end
	end

	a_Player:SendMessage(cChatColor.LightGray .. "Biomes (" .. #BiomesArr .. "): " .. table.concat(BiomesArr, ", "))
	return true
end

function HandleBiomeListCommand(a_Split, a_Player)
	-- local Page = a_Split[2] ~= nil and a_Split[2] or 1

	local Biomes = {}
	for Key, Value in pairs(_G) do
		if (Key:match("bi(.*)")) then
			table.insert(Biomes, BiomeToString(Value))
		end
	end
	table.sort(Biomes)

	a_Player:SendMessage(cChatColor.LightGray .. "Biomes (" .. #Biomes .. "): " .. table.concat(Biomes, ", "))

	local MinIndex = Page * 8
	local MaxIndex = MinIndex + 8
	for I = MinIndex, MaxIndex do
		local Biome = Biomes[I]
		if (not Biome) then
			break
		end

		a_Player:SendMessage(cChatColor.LightGray .. Biome)
	end
	return true
end
