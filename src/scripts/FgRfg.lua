--[[
Generation of random flights to bring a bit of life to a mission

Requires :
- Moose 
- FgTools

TODO :
- liveries script (extend aircraft db)
- weight airports by size ? redo airports selection ? check if airports can accomodate aircrafts ?
]]

local Id = "FgRfg"
local function LogError(oLog) Fg.LogError(oLog, Id) end
local function LogInfo(oLog) Fg.LogInfo(oLog, Id) end
local function LogDebug(oLog) Fg.LogDebug(oLog, Id) end

FgRfg = {}

---------------------------------------------------------------------------------------------------
---  TOOLS  ---------------------------------------------------------------------------------------
local function PrintAirports(tabAirports)
	LogInfo("COUNT airports " .. #tabAirports)
	LogInfo("PRINT airports " .. Fg.ToString(tabAirports))
end

--------------------------------------------------------------------------------------------------
---  RFG DCS GROUPS  ---------------------------------------------------------------------------------
-- Groups in the mission that are marked to use for the random generation
local RfgDcsGroups =
{
	[coalition.side.NEUTRAL] = {},
	[coalition.side.RED] = {},
	[coalition.side.BLUE] = {}
}

function RfgDcsGroups.Initialize()
	LogInfo ("RfgDcsGroups.Initialize")
	for _, iCoalition in pairs { coalition.side.NEUTRAL, coalition.side.RED, coalition.side.BLUE } do
		for __, dcsGroup in pairs(coalition.getGroups(iCoalition)) do
			RfgDcsGroups.AddGroup(dcsGroup)
		end
	end
end

function RfgDcsGroups.AddGroup(dcsGroup)
	if (dcsGroup == nil) then
		LogInfo ("RfgDcsGroups.AddGroup : not generated, DCS Group is nil")
		return
	end

	local sGroupName = dcsGroup:getName()
	if (sGroupName == nil) then
		LogInfo ("RfgDcsGroups.AddGroup : not generated, DCS Group Name is nil")
		return
	end
	
	local iGroupCoalition = nil
	if (sGroupName:match('^RFG.*#[0-9]+')) then
		 iGroupCoalition = nil -- do not respawn generated rat groups - named for example RATCIV_B737#003 (mainly a test thing)
	elseif (sGroupName:match('^RFGCIV_')) then
		 iGroupCoalition = coalition.side.NEUTRAL -- neutral coalition cannot be set in editor, so we take it from a name convention
	elseif (sGroupName:match('^RFG_')) then
		iGroupCoalition = dcsGroup:getCoalition()
	end
			
	if (iGroupCoalition == nil) then
		--LogMessage ("RfgDcsGroups:AddGroup : not generated, Group Name is not eligible : " .. sGroupName)
		return
	end

	local sTypeName = Fg.GetGroupUnitType(dcsGroup)
	if (sTypeName == nil) then sTypeName = "unknown type" end
	LogInfo ("RfgDcsGroups.AddGroup : adding group " .. Fg.GetGroupDescription(dcsGroup) .. " in coalition " .. iGroupCoalition)

	table.insert(RfgDcsGroups[iGroupCoalition], dcsGroup)
end

function RfgDcsGroups.GetRandomGroup(iCoalition)
	local coalitionGroups = RfgDcsGroups[iCoalition]
	if (coalitionGroups == nil or #coalitionGroups <= 0) then
		return nil
	end
	
	local dcsGroup = coalitionGroups[math.random(#coalitionGroups)]
	return dcsGroup
end

function RfgDcsGroups.ToStringCoalition(iCoalition)
	local sString = ""
	local tab = RfgDcsGroups[iCoalition]
	if (tab and type(tab) == "table") then
		for _, dcsGroup in pairs(tab) do
			local s = Fg.GetGroupDescription(dcsGroup)
			if (s == nil) then s = "unknown group" end

			if (sString ~= "") then sString = sString .. "," end
			sString = sString .. s
		end
	
		sString = "{ " .. sString .. " }"
	end
	
	return sString
end

function RfgDcsGroups.LogContent()
	LogInfo ("RFG DCS GROUPS : NEUTRAL :  " .. RfgDcsGroups.ToStringCoalition( coalition.side.NEUTRAL))
	LogInfo ("RFG DCS GROUPS : RED :  " .. RfgDcsGroups.ToStringCoalition( coalition.side.RED))
	LogInfo ("RFG DCS GROUPS : BLUE :  " .. RfgDcsGroups.ToStringCoalition( coalition.side.BLUE))
end

--------------------------------------------------------------------------------------------------
---  RANDOM GENERATION  ---------------------------------------------------------------------------------
-- Generation of RAT flights based on the RfgDcsGroups templates
local iRatSuffix = 0
function FgRfg.SpawnRatFlight(dcsGroup, iGroupCoalition, parameters)
	if (parameters == nil) then
		return
	end
	if (dcsGroup == nil) then
		return
	end
	
	local iAirStartPercent = parameters["AirStartPercent"] or 50
	local iSpawnDelayMin = parameters["SpawnDelayMin"] or 5
	local iSpawnDelayMax = parameters["SpawnDelayMax"] or 30
	local iSpawnIntervalMin = parameters["SpawnIntervalMin"] or 10
	local iSpawnIntervalMax = parameters["SpawnIntervalMax"] or 30	
	local departureAirports = parameters["DepartureAirports"] or nil
	local departureZones = parameters["DepartureZones"] or nil
	local destinations = parameters["Destinations"] or nil
	
	-- Rat object creation
	local sGroupName = dcsGroup:getName()
	local sGroupType = Fg.GetGroupUnitType(dcsGroup)
	local sRatName = sGroupName .. "__" .. sGroupType .. "__" .. iRatSuffix
	iRatSuffix = iRatSuffix + 1
	local ratFlight = RAT:New(sGroupName, sRatName)
	if (ratFlight == nil) then
		LogInfo ("FgRfg.SpawnRatFlight : not generated, RAT:New failed")
		return
	end
	
	LogInfo ("FgRfg.SpawnRatFlight : generated group=" .. sGroupName .. "  ratName=" .. sRatName)
	
	--ratFlight:EnableATC(false)
	ratFlight:ATC_Messages(false)
	--ratFlight.radio = false
	--ratFlight.modulation = "FM"
	--ratFlight.frequency = ""
	--f10menu=false
	
	local selectedLiveries = FgRfgDb.GetLiveries(dcsGroup)
	if (selectedLiveries) then
		LogInfo ("FgRfg.SpawnRatFlight : liveries : " .. Fg.ToString(selectedLiveries))
		ratFlight:Livery(selectedLiveries)
	end

	local selectedFls = FgRfgDb.GetFlightLevels(dcsGroup)
	if (selectedFls and #selectedFls >= 3) then
		LogInfo ("SpawnRatFlight : flight levels : " .. Fg.ToString(selectedFls))
		ratFlight:SetFLmin(selectedFls[1])
		ratFlight:SetFLcruise(selectedFls[2])
		ratFlight:SetFLmax(selectedFls[3])
	end

	if (iGroupCoalition == coalition.side.NEUTRAL) then
		ratFlight:SetCoalitionAircraft("neutral")
	end
	ratFlight:SetCoalition ("same")

	-- air start
	if (iAirStartPercent == nil) then iAirStartPercent = 50 end
	local airStartRoll = math.random(0, 100)
	local airStart = false
	local sAirStartRoll = "air start percentage=" .. iAirStartPercent .. " rolled=" .. airStartRoll
	if (airStartRoll < iAirStartPercent) then
		LogInfo ("FgRfg.SpawnRatFlight : air start [ " .. sAirStartRoll .. " ]")
		ratFlight:SetTakeoff("air")
		airStart = true
	else
		LogInfo ("FgRfg.SpawnRatFlight : ground start [ " .. sAirStartRoll .. " ]")
	end
	
	-- departure
	if (departureZones and airStart) then
		LogInfo ("FgRfg.SpawnRatFlight : using zones for air departure : " .. Fg.ToString(departureZones))
		ratFlight:SetDeparture(departureZones)
	elseif (departureAirports) then
		LogInfo ("FgRfg.SpawnRatFlight : using airports for departure : " .. Fg.ToString(departureAirports))
		ratFlight:SetDeparture(departureAirports)
	elseif (departureZones) then
		LogInfo ("FgRfg.SpawnRatFlight : using zones for departure : " .. Fg.ToString(departureZones))
		ratFlight:SetDeparture(departureZones)		
	end
	
	-- destination
	if (destinations) then
		ratFlight:SetDestination(destinations)
	end
	
	-- delays
	if (iSpawnDelayMin and iSpawnDelayMax) then
		local iSpawnDelay = math.random(iSpawnDelayMin, iSpawnDelayMax)
		LogInfo ("FgRfg.SpawnRatFlight : spawn delay " .. iSpawnDelay .. " [ min=" .. iSpawnDelayMin .. " max=" .. iSpawnDelayMax .. " ]")
		ratFlight.spawndelay = iSpawnDelay
	end
	if (iSpawnIntervalMin and iSpawnIntervalMax) then
		local iSpawnInterval = math.random(iSpawnIntervalMin, iSpawnIntervalMax)
		LogInfo ("FgRfg.SpawnRatFlight : spawn interval " .. iSpawnInterval .. " [ min=" .. iSpawnIntervalMin .. " max=" .. iSpawnIntervalMax .. " ]")
		ratFlight.spawninterval = iSpawnInterval
	end
	
	LogInfo ("FgRfg.SpawnRatFlight : spawn")
	ratFlight:Spawn()
	
	-- TESTS
	--[[if (zoneDep) then
		LogMessage ("Departure zone airports")
		PrintAirports(ratFlight:_GetAirportsInZone(zoneDep))
	end
	if (zoneArr) then
		LogMessage ("Arrival zone airports")
		PrintAirports(ratFlight:_GetAirportsInZone(zoneArr))
	end--]]
	--
end

---- PUBLIC GENERATE RANDOM
function FgRfg.Generate(iCoalition, iCount, parameters)
	if (parameters == nil) then
		return
	end
	
	LogInfo ("FgRfg.Generate : " .. iCoalition .. " - " .. iCount)
	local coalitionGroups = RfgDcsGroups[iCoalition]
	if (coalitionGroups == nil or #coalitionGroups <= 0) then
		LogInfo ("FgRfg.Generate : no groups to generate for coalition " .. iCoalition)
		return
	end
	
	while iCount > 0 do
		local dcsGroup = RfgDcsGroups.GetRandomGroup(iCoalition)
		if (dcsGroup) then
			local iSize = dcsGroup:getSize()
			if (iSize == nil or iSize <= 0) then
				LogInfo ("FgRfg.Generate : not generating flight " .. Fg.GetGroupDescription(dcsGroup) .. " : no group size found")
			else
				LogInfo ("FgRfg.Generate : generating flight " .. Fg.GetGroupDescription(dcsGroup) .. " (" .. iSize .. ")")
				iCount = iCount - iSize
				
				FgRfg.SpawnRatFlight (dcsGroup, iCoalition, parameters)
			end
		end
	end
end

function FgRfg.Generate_Coalitions(iCountNeutral, iCountRed, iCountBlue, parameters)
	if (parameters == nil) then
		return
	end
	
	FgRfg.Generate(coalition.side.NEUTRAL, iCountNeutral, parameters)
	FgRfg.Generate(coalition.side.RED, iCountRed, parameters)
	FgRfg.Generate(coalition.side.BLUE, iCountBlue, parameters)
end

--[[
function FgRfg.Generate_NearPlayer(iCoalition, iCount, iZoneRadiusMetersDep, iZoneRadiusMetersArr, parameters)
	if (parameters == nil) then
		return
	end
	
	iZoneRadiusMetersDep = iZoneRadiusMetersDep or 6000
	iZoneRadiusMetersArr = iZoneRadiusMetersArr or 6000
	
	local playerUnit = FgTools.GetPlayerUnit()
	local sGroupName = playerUnit:getGroup():getName()
	LogInfo ("FgRfg.Generate_NearPlayer : generating with zones around player " .. playerUnit:getName() .. " in group : " .. sGroupName)
	local u = UNIT:FindByName(playerUnit:getName())	
	
	if (iZoneRadiusMetersDep > 0) then
		parameters["ZoneDep"] = ZONE_UNIT:New("RFG_PlayerZoneDep", u, iZoneRadiusMetersDep)
		--LogMessage ("SMOKING ZONE")
		--parameters["zoneDep"]:SmokeZone(SMOKECOLOR.Red, 90)
	end
	if (iZoneRadiusMetersArr > 0) then
		parameters["ZoneArr"] = ZONE_UNIT:New("RFG_PlayerZoneArr", u, iZoneRadiusMetersArr)
		--LogMessage ("SMOKING ZONE")
		--parameters["zoneArr"]:SmokeZone(SMOKECOLOR.Blue, 90)			
	end

	FgRfg.RfgGenerate(iCoalition, iCount, parameters)
end
]]
---------------------------------------------------------------------------------------------------
---  MAIN  ----------------------------------------------------------------------------------------
LogInfo ("Initialize")
RfgDcsGroups.Initialize()
RfgDcsGroups.LogContent()
