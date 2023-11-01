--[[
General and miscellaneous odd tools form mission management

Requires :
- Moose
]]

local Id = "FgTools"
Fg = {}

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Miscellaneous tools
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function Fg.ToString(o, iDepth, iDepthMax)
    iDepthMax = iDepthMax or 20
    iDepth = iDepth or 0

    if (iDepth > iDepthMax) then
        Fg.LogDebug("ToString - max depth reached")
        return ""
    end

    local sString = ""
    if (type(o) == "table") then
        sString = "\n"
        for key, value in pairs(o) do
            for i = 0, iDepth do
                sString = sString .. " "
            end
            sString = sString .. "." .. key .. "=" .. Fg.ToString(value, iDepth + 1, iDepthMax) .. "\n"
        end
    elseif (type(o) == "function") then
        sString = "[function]"
    elseif (type(o) == "boolean") then
        if o == true then
            sString = "[true]"
        else
            sString = "[false]"
        end
    else
        if o == nil then
            sString = "[nil]"
        else
            sString = tostring(o)
        end
    end
    return sString
end

function Fg.IsNullOrEmpty(s)
    return (s == nil or (type(s) == "string" and s == ""))
end

function Fg.AppendWithSeparator(s, sAppend, sSeparator)
    sAppend = sAppend or ""
    sSeparator = sSeparator or " "

    if (Fg.IsNullOrEmpty(s)) then
        return sAppend
    elseif (Fg.IsNullOrEmpty(sAppend)) then
        return s
    else
        return s .. sSeparator .. sAppend
    end
end

function Fg.GetKeyString(table, oValue)

    for key, value in pairs(table) do
      if value==oValue then
        return key
      end
    end
  
    return nil
end

function Fg.GetRandomEnumValue(enumTable)
    local flatTable = {}

    for _, oValue in pairs (enumTable) do
        table.insert(flatTable, oValue)
    end

    return flatTable [math.random(#flatTable)]
end

function Fg.Contains(table, element)
    for _, e in pairs(table) do
        if e == element then 
            return true 
        end
    end
    return false
end
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Logs
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
Fg.LogLevels = {Error = 0, Info = 1, Debug = 2}
Fg.LogLevel = Fg.LogLevels.Error

function Fg.Log(iLogLevel, oLog, sId)
    if (oLog == nil) then
        return
    end
    iLogLevel = iLogLevel or 0
    if (iLogLevel > Fg.LogLevel) then
        return
    end

    local sLogLevel = "???"
    if (iLogLevel == Fg.LogLevels.Error) then sLogLevel = "ERR"
    elseif (iLogLevel == Fg.LogLevels.Info) then sLogLevel = "INF"
    elseif (iLogLevel == Fg.LogLevels.Debug) then sLogLevel = "DBG" end
    
    local sPrefix = ">>> " .. sLogLevel .. " > "
    if (not Fg.IsNullOrEmpty(sId)) then
        sPrefix = sPrefix .. sId .. " > "
    end

    env.info(sPrefix .. tostring(oLog))
end

function Fg.LogError(oLog, sId)
    Fg.Log(Fg.LogLevels.Error, oLog, sId)
end

function Fg.LogInfo(oLog, sId)
    Fg.Log(Fg.LogLevels.Info, oLog, sId)
end

function Fg.LogDebug(oLog, sId)
    Fg.Log(Fg.LogLevels.Debug, oLog, sId)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Date & Time tools
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
Fg.TimePrecisions = {Second = 0, Minute = 1, Hour = 2}
function Fg.TimeFromAbsSeconds(iAbsSeconds, precision)
    iAbsSeconds = iAbsSeconds or timer.getAbsTime()
    precision = precision or Fg.TimePrecisions.Second

    local iDayOffset = math.floor(iAbsSeconds / 86400)
    local iHour = math.floor((iAbsSeconds % 86400) / 3600)

    local iMinute = 0
    if (precision <= Fg.TimePrecisions.Minute) then
        iMinute = math.floor((iAbsSeconds % 3600) / 60)
    end

    local iSecond = 0
    if (precision <= Fg.TimePrecisions.Second) then
        iSecond = math.floor(iAbsSeconds % 60)
    end

    local this = {
        DayOffset = iDayOffset,
        Day = env.mission.date.Day + iDayOffset,
        Month = env.mission.date.Month,
        Year = env.mission.date.Year,
        Hour = iHour,
        Minute = iMinute,
        Second = iSecond
    }

    setmetatable(this, self)
    return this
end

function Fg.TimeToAbsSeconds(oTime)
    return oTime.DayOffset * 86400 + oTime.Hour * 3600 + oTime.Minute * 60 + oTime.Second
end

function Fg.TimeToZulu(iAbsSeconds)
    iAbsSeconds = iAbsSeconds or timer.getAbsTime()
    return iAbsSeconds - (UTILS.GMTToLocalTimeDifference() * 3600)
end

function Fg.TimeToString(iAbsSeconds, bWithSeconds)
    local oTime = Fg.TimeFromAbsSeconds(iAbsSeconds)
    if (bWithSeconds == nil) then
        bWithSeconds = true
    end

    if (bWithSeconds) then
        return string.format("%02d:%02d:%02d", oTime.Hour, oTime.Minute, oTime.Second)
    else
        return string.format("%02d:%02d", oTime.Hour, oTime.Minute)
    end
end

function Fg.TimeToStringDate(iAbsSeconds, bWithSeconds)
    local oTime = Fg.TimeFromAbsSeconds(iAbsSeconds)
    return string.format(
        "%02d/%02d/%d %s",
        oTime.Day,
        oTime.Month,
        oTime.Year,
        Fg.TimeToString(iAbsSeconds, bWithSeconds)
    )
end

function Fg.TimeToStringMetar(iAbsSeconds)
    local oTime = Fg.TimeFromAbsSeconds(iAbsSeconds)
    return string.format("%02d%02dZ", oTime.Hour, oTime.Minute)
end

function Fg.TimeSunriseSunset(mooseCoord, iDayOfYear)
    if (iDayOfYear == nil) then
        iDayOfYear = UTILS.GetMissionDayOfYear()
    end

    local iLatitude, iLongitude = mooseCoord:GetLLDDM()
    local iSunrise = UTILS.GetSunRiseAndSet(iDayOfYear, iLatitude, iLongitude, true, UTILS.GMTToLocalTimeDifference())
    local iSunset = UTILS.GetSunRiseAndSet(iDayOfYear, iLatitude, iLongitude, false, UTILS.GMTToLocalTimeDifference())

    return iSunrise, iSunset
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Dcs units and groups management
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function Fg.GetGroupFirstUnit(dcsGroup)
    if (dcsGroup) then
        return dcsGroup:getUnit(1)
    end
end

function Fg.GetGroupUnitType(dcsGroup)
    local dcsUnit = Fg.GetGroupFirstUnit(dcsGroup)
    if (dcsUnit) then
        return dcsUnit:getTypeName()
    end
end

function Fg.GetGroupDescription(dcsGroup)
    local sString = ""
    if (dcsGroup) then
        local sGroupName = dcsGroup:getName()
        local sTypeName = Fg.GetGroupUnitType(dcsGroup)
        if (sTypeName == nil) then
            sTypeName = "unknown type"
        end
        sString = sGroupName .. "__" .. sTypeName
    end

    return sString
end

function Fg.GetUnitDescription(dcsUnit)
    local sString = ""
    if (dcsUnit) then
        local sUnitName = dcsUnit:getName()
        local sTypeName = dcsUnit:getTypeName()
        local dcsGroup = dcsUnit:getGroup()
        local sGroupName = dcsGroup:getName()

        if (sTypeName == nil) then
            sTypeName = "unknown_type"
        end
        if (sGroupName == nil) then
            sGroupName = "unknown_grp"
        end
        sString = sUnitName .. "__" .. sGroupName .. "__" .. sTypeName
    end

    return sString
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Country and airbases
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function Fg.GetCountryShortName(iId)
    if (iId and iId > 0) then
        for _, countryData in pairs(country.by_country) do
            if (countryData["WorldID"] == iId) then
                return countryData["ShortName"]
            end
        end
    end
end



function Fg.GetNearestAirbaseList(mooseGroup, iCount)
    local groupCoordinates = mooseGroup:GetCoordinate()
    local iMinDistance = nil
    local nearestList = {}

    local function Sort(a, b)
        if (a == nil and b == nil) then
            return false
        elseif (a == nil) then
            return false
        elseif (b == nil) then
            return true
        else
            return a[2] < b[2]
        end
    end

    for _, ab in pairs(AIRBASE.GetAllAirbases()) do
        if (not ab:IsShip()) then
            local iDistance = groupCoordinates:Get2DDistance(ab:GetCoordinate())
            local bDone = false

            -- first fill the nil positions
            for i = 1, iCount, 1 do
                if (nearestList[i] == nil) then
                    nearestList[i] = {ab.AirbaseName, iDistance}
                    bDone = true
                    break
                end
            end

            if (not bDone) then
                -- then, replace the farthest one if the current one is closer
                for i = iCount, 1, -1 do
                    if (iDistance < nearestList[i][2]) then
                        nearestList[i] = {ab.AirbaseName, iDistance}
                        bDone = true
                        break
                    end
                end
            end

            if (bDone) then
                table.sort(nearestList, Sort)
            end
        end
    end

    return nearestList
end

function Fg.GetNearestAirbaseListNames(mooseGroup, iCount)
    local nearestList = Fg.GetNearestAirbaseList(mooseGroup, iCount)
    local nearestListNames = {}
    for _, ab in ipairs(nearestList) do
        table.insert(nearestListNames, ab[1])
    end

    return nearestListNames
end

function Fg.GetNearestAirbaseName(mooseGroup)
    local nearestListNames = Fg.GetNearestAirbaseList(mooseGroup, 1)
    if (nearestListNames and #nearestListNames > 0) then
        return nearestListNames[1]
    else
        return nil
    end
end

function Fg.FlareRunway(mooseAirbase, iMinDistance, flareColors, iRepetitions)
    iMinDistance = iMinDistance or 100
    iRepetitions = iRepetitions or 1
    if (flareColors == nil or #flareColors <= 0) then
        flareColors = { FLARECOLOR.White, FLARECOLOR.Yellow, FLARECOLOR.Red, FLARECOLOR.Green }
    end

    local runwayData = mooseAirbase:GetRunwayData()

    if (runwayData and #runwayData == 2) then
        local coord1 = runwayData[1].position:GetCoordinate()
        local coord2 = runwayData[2].position:GetCoordinate()
        local coordTable = {coord1, coord2}
        
        local function AddMedCoord(coordTable, coord1, coord2, iMinDistance)
            local iDistance = coord1:Get2DDistance(coord2)
            --LogDebug ("AddMedCoord - iDistance=" .. iDistance .. " - iMinInterval=" .. iMinInterval)
            if (iDistance < iMinDistance) then
                return
            else
                local medCoord = coord1:GetIntermediateCoordinate(coord2)
                table.insert(coordTable, medCoord)
                AddMedCoord(coordTable, coord1, medCoord, iMinDistance)
                AddMedCoord(coordTable, medCoord, coord2, iMinDistance)
            end
        end

        AddMedCoord(coordTable, coord1, coord2, iMinDistance)

        local flareScheduler = SCHEDULER:New( nil, 
        function()
            local flareColor = flareColors [math.random(#flareColors)]
            Fg.LogDebug("FLARING " .. timer.getAbsTime() .. " " .. flareColor)

            for _, c in pairs(coordTable) do
                c:Flare(flareColor)
            end
        end, {}, 0, 1, nil, iRepetitions)     
    end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  VEAF
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function Fg.CreateVeafPointFromAirbase(sAirbaseName)
    local mooseAirbase = AIRBASE:FindByName(sAirbaseName)
    local mooseRunways = mooseAirbase:GetRunwayData()

    local veafPoint = {}
    --veafPoint.tower = "TOWER"
    veafPoint.x = mooseAirbase:GetVec3().x
    veafPoint.y = mooseAirbase:GetVec3().y
    veafPoint.z = mooseAirbase:GetVec3().z
    veafPoint.atc = true

    veafPoint.runways = {}
    for _, r in pairs(mooseRunways) do
        local veafRunway = {name = r.idx, hdg = math.floor(r.heading + 0.5)}
        table.insert(veafPoint.runways, veafRunway)
    end

    veafNamedPoints._addPoint(mooseAirbase.AirbaseName, veafPoint)
    veafNamedPoints._refreshAtcRadioMenu()
    veafNamedPoints._refreshWeatherReportsRadioMenu()
end