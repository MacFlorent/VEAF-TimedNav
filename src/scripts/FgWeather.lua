--[[
Weather informations collection from various sim data
Generation of weather reports for airfields (ATIS and METAR)
Menu options for requesting ATIS on any near airfield, and display F10 markers with METAR data on all airbases of the map

Requires :
- Moose
- FgTools
]]

local Id = "FgWeather"
local function LogError(oLog) Fg.LogError(oLog, Id) end
local function LogInfo(oLog) Fg.LogInfo(oLog, Id) end
local function LogDebug(oLog) Fg.LogDebug(oLog, Id) end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Local defines
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local DcsPresetDensity =
{
    -- {density, precipitation, visibility}
    Preset1 = {2, false, nil}, -- LS1 -- FEW/SCT
    Preset2 = {2, false, nil}, -- LS2 -- FEW/SCT
    Preset3 = {3, false, nil}, -- HS1 -- SCT
    Preset4 = {3, false, nil}, -- HS2 -- SCT
    Preset5 = {3, false, nil}, -- S1 -- SCT
    Preset6 = {4, false, nil}, -- S2 -- SCT/BKN
    Preset7 = {3, false, nil}, -- S3 -- BKN
    Preset8 = {4, false, nil}, -- HS3 -- SCT/BKN
    Preset9 = {5, false, nil}, -- S4 -- BKN
    Preset10 = {4, false, nil}, -- S5 -- SCT/BKN
    Preset11 = {6, false, nil}, -- S6 -- BKN
    Preset12 = {6, false, nil}, -- S7 -- BKN
    Preset13 = {6, false, nil}, -- B1 -- BKN
    Preset14 = {6, false, nil}, -- B2 -- BKN
    Preset15 = {4, false, nil}, -- B3 -- SCT/BKN
    Preset16 = {6, false, nil}, -- B4 -- BKN
    Preset17 = {7, false, nil}, -- B5 -- BKN/OVC
    Preset18 = {7, false, nil}, -- B6 -- BKN/OVC
    Preset19 = {8, false, nil}, -- B7 -- OVC
    Preset20 = {7, false, nil}, -- B8 -- BKN/OVC
    Preset21 = {7, false, nil}, -- O1 -- BKN/OVC
    Preset22 = {6, false, nil}, -- O2 -- BKN
    Preset23 = {6, false, nil}, -- O3  -- BKN
    Preset24 = {7, false, nil}, -- O4 -- BKN/OVC
    Preset25 = {8, false, nil}, -- O5 -- OVC
    Preset26 = {8, false, nil}, -- O6 -- OVC
    Preset27 = {8, false, nil}, -- O7 -- OVC
    RainyPreset1 = {8, true, 4000}, -- OVC
    RainyPreset2 = {7, true, 5000}, -- BKN/OVC
    RainyPreset3 = {8, true, 4000} -- OVC
}

local CloudDensityLabel = { Clear = 0, Few = 1, Scattered = 2, Broken = 3, Overcast = 4, Cavok = 5 }
local CloudDensityLabelOktas =
{
    [0] = CloudDensityLabel.Clear,
    [1] = CloudDensityLabel.Few,
    [2] = CloudDensityLabel.Few,
    [3] = CloudDensityLabel.Scattered,
    [4] = CloudDensityLabel.Scattered,
    [5] = CloudDensityLabel.Broken,
    [6] = CloudDensityLabel.Broken,
    [7] = CloudDensityLabel.Overcast,
    [8] = CloudDensityLabel.Overcast
}

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Weather menus
---  To use just call FgWeatherMenu.Start(iInterval, iNumberNearest) at mission start
---  "Weather" menus will be added for each player group
---  -- ATIS for the iNumberNearest (default 5) nearest airfields, refresh every iInterval (default 30) seconds
---  -- Display / Hide METAR group markers on map
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgWeatherMenu = {}
FgWeatherMenu.Scheduler = nil
FgWeatherMenu.NumberNearestAtis = 5 
FgWeatherMenu.AtisMenus = {}
FgWeatherMenu.ActiveMarks = {}

local function MenuOutTextAtis(sGroupName, sAirbaseName)
	LogDebug("MenuOutTextAtis - " .. sGroupName .. " - " .. sAirbaseName)
    local mooseGroup = GROUP:FindByName(sGroupName)
	local sAtis = FgAtis.GetCurrentAtisString(sAirbaseName)
    trigger.action.outTextForGroup(mooseGroup:GetDCSObject():getID(), sAtis, 45, false)
end

local function MenuCreateMarkMetars(sGroupName)
	LogDebug("MenuCreateMarkMetars - " .. sGroupName)
    local mooseGroup = GROUP:FindByName(sGroupName)

    FgWeatherMenu.RemoveExistingMetarMarks(sGroupName)

    for _, ab in pairs(AIRBASE.GetAllAirbases()) do
        local iMarkId = FgWeather.CreateMetarMark(ab:GetCoordinate(), mooseGroup)
        if (FgWeatherMenu.ActiveMarks [sGroupName] == nil) then
            FgWeatherMenu.ActiveMarks [sGroupName] = {iMarkId}
        else
            table.insert (FgWeatherMenu.ActiveMarks [sGroupName], iMarkId)
        end
    end
end

local function MenuRemoveMarkMetars(sGroupName)
    LogDebug("MenuRemoveMarkMetars - " .. sGroupName)
    local mooseGroup = GROUP:FindByName(sGroupName)

    FgWeatherMenu.RemoveExistingMetarMarks(sGroupName)
end

function FgWeatherMenu.GetRootMenu(mooseGroup)
    if (FgWeatherMenu[mooseGroup.GroupName] == nil) then
        FgWeatherMenu[mooseGroup.GroupName]  = MENU_MISSION:New("Weather informations")
    end
    return FgWeatherMenu[mooseGroup.GroupName]
end

function FgWeatherMenu.BuildMenuAll()
    local groupsDone = {}
    
    for _, mooseUnit in pairs(_DATABASE.PLAYERUNITS) do
        local mooseGroup = mooseUnit:GetGroup()
        if (mooseGroup == nil) then
            LogDebug("FgWeatherMenu nil group")
        elseif (groupsDone[mooseGroup.GroupName]) then
            LogDebug("FgWeatherMenu group already done")
        elseif (not mooseGroup:IsAlive() or  #mooseGroup:GetPlayerUnits() < 1) then
            LogDebug("FgWeatherMenu not alive or no player - " .. mooseGroup.GroupName)
        else
            FgWeatherMenu.BuildMenuGroup(mooseGroup)
            groupsDone[mooseGroup.GroupName] = true
        end
    end
end

function FgWeatherMenu.BuildMenuGroup(mooseGroup)
    LogDebug("FgWeatherMenu check for " .. mooseGroup.GroupName)

    local bRebuild = false
    if (FgWeatherMenu[mooseGroup.GroupName] == nil) then
        FgWeatherMenu[mooseGroup.GroupName]  = MENU_MISSION:New("Weather")
        bRebuild = true
    end
    local menuGroup = FgWeatherMenu.GetRootMenu(mooseGroup)

    local nearestList = Fg.GetNearestAirbaseListNames(mooseGroup, FgWeatherMenu.NumberNearest)

    if (not bRebuild) then
        if (FgWeatherMenu.AtisMenus[mooseGroup.GroupName]) then
            for _, sAbName in pairs (nearestList) do
                if (not FgWeatherMenu.AtisMenus[mooseGroup.GroupName][sAbName]) then
                    bRebuild = true
                    break 
                end
            end
        else
            bRebuild = true
        end
    end

    if (bRebuild) then
        LogDebug("FgWeatherMenu rebuild for " .. mooseGroup.GroupName)
        menuGroup:RemoveSubMenus()
        
        FgWeatherMenu.AtisMenus[mooseGroup.GroupName] = {}
        for _, sAbName in ipairs(nearestList) do
            MENU_GROUP_COMMAND:New(mooseGroup, "ATIS " .. sAbName, menuGroup, MenuOutTextAtis, mooseGroup.GroupName, sAbName)
            FgWeatherMenu.AtisMenus[mooseGroup.GroupName][sAbName] = true
        end

        MENU_GROUP_COMMAND:New(mooseGroup, "METAR display on map", menuGroup, MenuCreateMarkMetars, mooseGroup.GroupName)
        MENU_GROUP_COMMAND:New(mooseGroup, "METAR remove from map", menuGroup, MenuRemoveMarkMetars, mooseGroup.GroupName)
    end
end

function FgWeatherMenu.RemoveExistingMetarMarks(sGroupName)
    if (FgWeatherMenu.ActiveMarks [sGroupName]) then
        for _, iMarkId in pairs (FgWeatherMenu.ActiveMarks[sGroupName]) do
            trigger.action.removeMark(iMarkId)
        end
        FgWeatherMenu.ActiveMarks [sGroupName] = nil
    end
end

function FgWeatherMenu.Start(iInterval, iNumberNearest)
    iInterval = iInterval or 30
    FgWeatherMenu.NumberNearest = iNumberNearest or 5

    if (FgWeather.SchedulerMenu) then
        LogInfo("Stop weather menu scheduler")
        FgWeatherMenu.Scheduler:Stop()
     end
     LogInfo("Start weather menu scheduler")
     FgWeatherMenu.Scheduler = SCHEDULER:New(nil, 
     function()
        FgWeatherMenu.BuildMenuAll()
     end,
     {},
     1, iInterval
     )
     
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Weather management class
---  Collects and compile wheather data form various sources in the sim at a location
---  Can be output to string as METAR or ATIS informations
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgWeather = {}
FgWeather.__index = FgWeather
---------------------------------------------------------------------------------------------------
---  CTORS
function FgWeather:Create(mooseCoord, iTimeAbs)
    iTimeAbs = iTimeAbs or timer.getAbsTime()
    local iGroundAltitude = mooseCoord:GetLandHeight()
    local iWindDir, iWindSpeedMs = mooseCoord:GetWind()

    local iLatitude, iLongitude = mooseCoord:GetLLDDM()
    local iZuluDiff = UTILS.GMTToLocalTimeDifference()
    local iDayOfYear = UTILS.GetMissionDayOfYear(iTimeAbs or timer.getAbsTime())
    local iSunset = UTILS.GetSunRiseAndSet(iDayOfYear, iLatitude, iLongitude, false, iZuluDiff)

    local iVisibilityMeters = env.mission.weather.visibility.distance
    local bFog = env.mission.weather.enable_fog
    if (bFog) then
        -- ground + 75 meters seems to be the point where it can be counted as a real impact on visibility
        if(env.mission.weather.fog.thickness < iGroundAltitude + 75) then
            bFog = false
        elseif (env.mission.weather.fog.visibility < iVisibilityMeters) then
            iVisibilityMeters = env.mission.weather.fog.visibility
        end
    end

    local clouds = nil
    local bPrecipitation = false;
    local sCloudPreset = env.mission.weather.clouds.preset
    if (Fg.IsNullOrEmpty(sCloudPreset)) then
        if (env.mission.weather.clouds.density > 0) then
            clouds = {Density = env.mission.weather.clouds.density, Base = env.mission.weather.clouds.base}
        end
        bPrecipitation = (env.mission.weather.clouds.iprecptns > 0)
    else
        if (DcsPresetDensity[sCloudPreset]) then
            clouds = {Density = DcsPresetDensity[sCloudPreset][1], Base = env.mission.weather.clouds.base}
            bPrecipitation = DcsPresetDensity[sCloudPreset][2]
            if (DcsPresetDensity[sCloudPreset][3] and DcsPresetDensity[sCloudPreset][3] < iVisibilityMeters) then
                iVisibilityMeters = DcsPresetDensity[sCloudPreset][3]
            end
        end
    end
    
    local this =
    {
        TimeAbs = iTimeAbs,
        Coordinates = mooseCoord,
        GroundAltitudeMeter = iGroundAltitude,
        WindDirection = UTILS.Round(iWindDir),
        WindSpeedMs = iWindSpeedMs,
        VisibilityMeters = iVisibilityMeters,
        Dust = env.mission.weather.enable_dust,
        Fog = bFog,
        Clouds = clouds,
        Precipitation = bPrecipitation,
        TemperatureCelcius = mooseCoord:GetTemperature(),
        --DewPoint, -- Magnus Formula, will need humidity to compute
        QnhHpa = mooseCoord:GetPressure(0),
        QfeHpa = mooseCoord:GetPressure(),
        Sunset = iSunset
    }

    setmetatable(this, self)

    LogDebug(this:ToString())
    return this
end

---------------------------------------------------------------------------------------------------
---  METHODS
function FgWeather:GetFormattedWind(bMagnetic)
    bMagnetic = bMagnetic or false

    local iWindForce = UTILS.Round(UTILS.MpsToKnots(self.WindSpeedMs))
    local iWindDirection = self.WindDirection
    if (bMagnetic) then
        iWindDirection = iWindDirection - UTILS.GetMagneticDeclination()
        if (iWindDirection) < 0 then
            iWindDirection = iWindDirection + 360
        end    
    end

    if (iWindDirection == 0) then
        iWindDirection = 360
    end
    return iWindForce, iWindDirection
end

function FgWeather:GetFormattedClouds()
    if (self.Clouds == nil or self.Clouds.Density <= 0) then
        return CloudDensityLabel.Clear
    else
        local iCloudBase = UTILS.Round(UTILS.MetersToFeet(self.Clouds.Base - self.GroundAltitudeMeter) / 100) * 100
        if (self.VisibilityMeters >= 10000 and iCloudBase >= 5000 and not self.Precipitation and not self.Fog and not self.Dust) then
            return CloudDensityLabel.Cavok
        else
            return CloudDensityLabelOktas[self.Clouds.Density], iCloudBase
        end
    end
end

function FgWeather:ToString(bWithClouds)
    bWithClouds = bWithClouds or false

    local sString = "Time=" .. Fg.TimeToStringDate(self.TimeAbs)
    sString = sString .. " - Coord=" .. self.Coordinates:ToStringLLDMS() .. " m"
    sString = sString .. " - Altitude=" .. UTILS.Round(self.GroundAltitudeMeter) .. " m"
    sString = sString .. " - Wind=" .. self.WindDirection .. "@" .. UTILS.Round(self.WindSpeedMs) .. " ms [decl=" .. UTILS.GetMagneticDeclination() .. "]"
    sString = sString .. " - Visibility=" .. self.VisibilityMeters .. " m"
    if (self.Fog) then
        sString = sString .. " - fog"
    end
    if (self.Dust) then
        sString = sString .. " - dust"
    end
    if (self.Precipitation) then
        sString = sString .. " - precipitations"
    end
    sString = sString .. " - Temperature=" .. UTILS.Round(self.TemperatureCelcius) .. " °C"
    sString = sString .. " - Qnh=" .. UTILS.Round(self.QnhHpa) .. " Hpa"
    sString = sString .. " - Qfe=" .. UTILS.Round(self.QfeHpa) .. " Hpa"
    sString = sString .. " - Sunset=" .. Fg.TimeToString(self.Sunset)

    if (bWithClouds) then
        sString = sString .. " - Clouds=\n" .. Fg.ToString(self.Clouds)
    end

    return sString
end

function FgWeather:ToStringAtis()
    local iWindForce, iWindDirection = self:GetFormattedWind(true)
    local sWind
    if (iWindForce <= 1) then
        sWind = "Wind calm"
    else
        iWindDirection = UTILS.Round(iWindDirection / 5) * 5
        sWind = string.format("Wind %03d @ %d kt", iWindDirection, iWindForce)
    end

    local iVisibility = UTILS.Round(self.VisibilityMeters / 1000)
    if (iVisibility > 10) then
        iVisibility = 10
    end
    local sVisibility = string.format("Visibility %d km", iVisibility)

    if (self.Precipitation) then
        sVisibility = sVisibility .. " Rain" -- TODO rain will be snow if season+map+t° ?
    end
    if (self.Fog) then
        sVisibility = sVisibility .. " Fog"
    end
    if (self.Dust) then
        sVisibility = sVisibility .. " Dust"
    end

    local sClouds
    local cloudDensity, iCloudBase = self:GetFormattedClouds()
    if (cloudDensity == CloudDensityLabel.Clear) then
        sClouds = "No clouds"
    elseif (cloudDensity == CloudDensityLabel.Cavok) then
        sClouds = "CAVOK"
        sVisibility = nil
    else
        local sDensity = "Few"
        if (cloudDensity == CloudDensityLabel.Scattered) then
            sDensity = "Scattered"
        elseif (cloudDensity == CloudDensityLabel.Broken) then
            sDensity = "Broken"
        elseif (cloudDensity == CloudDensityLabel.Overcast) then
            sDensity = "Overcast"
        end
           
        sClouds = sDensity .. " clouds @ " .. iCloudBase .. " feet"
    end

    local sAtis = sWind
    sAtis = Fg.AppendWithSeparator (sAtis, sVisibility, "\n")
    sAtis = sAtis .. "\n" .. sClouds
    sAtis = sAtis .. "\nTemperature " .. UTILS.Round(self.TemperatureCelcius) .. " °C"
    sAtis = sAtis .. string.format("\nQNH %d hPa - %.2f inHg", self.QnhHpa, UTILS.hPa2inHg(self.QnhHpa))
    sAtis = sAtis .. string.format("\nQFE %d hPa - %.2f inHg", self.QfeHpa, UTILS.hPa2inHg(self.QfeHpa))
    sAtis = sAtis .. "\nSunset " .. Fg.TimeToString(self.Sunset, false) .. "Z"

    return sAtis
end

function FgWeather:ToStringMetar()
    local iWindForce, iWindDirection = self:GetFormattedWind()
    local sWind
    if (iWindForce < 1) then
        sWind = "00000KT"
    else
        iWindDirection = UTILS.Round(iWindDirection / 10) * 10
        if (iWindDirection == 0) then
            iWindDirection = 360
        end
        sWind = string.format("%03d%02dKT", iWindDirection, iWindForce)
    end

    local iVisibility = UTILS.Round(self.VisibilityMeters / 100) * 100
    if (iVisibility >= 10000) then
        iVisibility = 9999
    end
    local sVisibility = string.format("%04d", iVisibility)

    local sSignificativeWeather = nil
    if (self.Precipitation) then
        sSignificativeWeather = "RA" -- TODO rain will be snow if season+map+t° ?
    end
    if (self.Fog) then
        sSignificativeWeather = Fg.AppendWithSeparator(sSignificativeWeather, "FG")
    end
    if (self.Dust) then
        sSignificativeWeather = Fg.AppendWithSeparator(sSignificativeWeather, "DU")
    end

    sVisibility = Fg.AppendWithSeparator(sVisibility, sSignificativeWeather)

    local sClouds
    local cloudDensity, iCloudBase = self:GetFormattedClouds()
    if (cloudDensity == CloudDensityLabel.Clear) then
        sClouds = "SKC"
    elseif (cloudDensity == CloudDensityLabel.Cavok) then
        sClouds = "CAVOK"
        sVisibility = nil
    else
        local sDensity = "FEW"
        if (cloudDensity == CloudDensityLabel.Scattered) then
            sDensity = "SCT"
        elseif (cloudDensity == CloudDensityLabel.Broken) then
            sDensity = "BKN"
        elseif (cloudDensity == CloudDensityLabel.Overcast) then
            sDensity = "OVC"
        end
           
        sClouds = string.format("%s%03d", sDensity, iCloudBase)
    end

    local sTemperature
    local iTemperature = UTILS.Round(self.TemperatureCelcius)
    if (iTemperature >= 0) then
        sTemperature = string.format("%02d", iTemperature)
    else
        sTemperature = string.format("M%02d", -iTemperature)
    end

    local sQnh = string.format("Q%d/%.2f", self.QnhHpa, UTILS.hPa2inHg(self.QnhHpa))

    local sMetar = Fg.TimeToStringMetar()
    sMetar = sMetar .. " " .. sWind
    sMetar = Fg.AppendWithSeparator (sMetar, sVisibility, " ")
    sMetar = sMetar .. " " .. sClouds
    sMetar = sMetar .. " " .. sTemperature
    sMetar = sMetar .. " " .. sQnh

    return sMetar
end

function FgWeather.CreateMetarMark(mooseCoord, mooseGroup)
    local weather = FgWeather:Create(mooseCoord)
    local sMetar = weather:ToStringMetar()

    local vec3 = mooseCoord:GetVec3()
    local iMarkId = UTILS.GetMarkID()
    if (mooseGroup) then
        trigger.action.markToGroup(iMarkId, sMetar, vec3, mooseGroup:GetDCSObject():getID(), false, nil)
    else
        trigger.action.markToAll(iMarkId, sMetar, vec3, false, nil)
    end

    return iMarkId
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  ATIS management class
---  Simulation of the recording of an ATIS information per hour per airfield
---  For each info a recording time and corresponding letter is generated (just to fluff it)
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgAtis = {}
FgAtis.__index = FgAtis
FgAtis.ListInEffect = {}
---------------------------------------------------------------------------------------------------
---  CTORS
function FgAtis:Create(mooseAirbase, sLetter, iZuluHoursSinceMidnight)
    local this = {
        AirbaseName = mooseAirbase.AirbaseName,
        Letter = sLetter,
        Message = ""
    }

    local iRecordedAt = math.floor(iZuluHoursSinceMidnight) + math.random(2, 11) / 60
    if (iRecordedAt > iZuluHoursSinceMidnight) then
        iRecordedAt = iZuluHoursSinceMidnight - math.random(2, 11) / 60
    end

    local mooseRunway = mooseAirbase:GetActiveRunway()
    local sActiveRunway = string.format("[%02d]", mooseRunway.idx) 

    this.Message =
        mooseAirbase.AirbaseName ..
        " information " .. sLetter .. " recorded at " .. Fg.TimeToString(iRecordedAt * 3600, false) .. "Z"
    this.Message = this.Message .. "\nRunway in use " .. sActiveRunway
    
    local weatherReport = FgWeather:Create(mooseAirbase:GetCoordinate())
    this.Message = this.Message .. "\n" .. weatherReport:ToStringAtis()

    setmetatable(this, self)
    return this
end

---------------------------------------------------------------------------------------------------
---  METHODS
function FgAtis.GetCurrentAtisString(sAirbaseName)
    if (Fg.IsNullOrEmpty(sAirbaseName)) then
        LogError("FgAtis : no airbase name given")
        return ""
    end

    local mooseAirbase = AIRBASE:FindByName(sAirbaseName)
    if (mooseAirbase == nil) then
        LogError("FgAtis : airbase " .. sAirbaseName .. " not found")
        return ""
    end

    local iZulu = Fg.TimeToZulu()
	local iZuluHoursSinceMidnight = iZulu / 3600
    local sLetter = string.char(math.floor(iZuluHoursSinceMidnight) + string.byte("A"))

    LogDebug("Zulu hours=" .. iZuluHoursSinceMidnight .. " - Letter=" .. sLetter)

    local currentInEffect = FgAtis.ListInEffect[mooseAirbase.AirbaseName]
    if (currentInEffect and currentInEffect.Letter == sLetter) then
        LogDebug("ATIS already in effect")
        return currentInEffect.Message
    else
        LogDebug("New recorded ATIS")
        currentInEffect = FgAtis:Create(mooseAirbase, sLetter, iZuluHoursSinceMidnight)
        FgAtis.ListInEffect[sAirbaseName] = currentInEffect
    end

    return currentInEffect.Message
end

function FgAtis.GetCurrentAtisStringNearest(mooseGroup)
	local mooseAirbase = Fg.GetNearestAirbase(mooseGroup)
	return FgAtis.GetCurrentAtisString(mooseAirbase.AirbaseName)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  TEST CODE FOR FUTURE REFERENCE
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--[[
TESTS

local mooseAirbase = AIRBASE:FindByName(AIRBASE.Syria.Beirut_Rafic_Hariri)
local iLandHeight = mooseAirbase:GetCoordinate():GetLandHeight()

local weather = FgWeather:Create(mooseAirbase:GetCoordinate())
LogInfo(weather:ToString())
LogInfo(veaf.weatherReport(mooseAirbase:GetVec3(), nil, false))

local function PrintWind(vec3, iAlt)
	vec3.y = iAlt
	local wind = atmosphere.getWind(vec3)	
	local str = math.sqrt(wind.x^2 + wind.z^2)
	LogInfo("Wind " .. UTILS.MetersToFeet(iAlt) .. " x=".. wind.x .." z=".. wind.z .." y=".. wind.y .. " str=" .. str .. " ms | " .. UTILS.MpsToKnots(str) .. " kts")
end

local vec3 = mooseAirbase:GetCoordinate():GetVec3()
PrintWind(vec3, 0)
PrintWind(vec3, UTILS.FeetToMeters (33))
PrintWind(vec3, iLandHeight)
PrintWind(vec3, iLandHeight+1)
PrintWind(vec3, UTILS.FeetToMeters (1600))
PrintWind(vec3, UTILS.FeetToMeters (6600))
PrintWind(vec3, UTILS.FeetToMeters (26000))

--
for _, abName in pairs (AIRBASE.Syria) do
	local ab = AIRBASE:FindByName(abName)
    LogInfo(ab.AirbaseName)
	local weather = FgWeather:Create(ab:GetCoordinate())
	--LogInfo(weather:ToStringMetar())	
	LogInfo(weather:ToStringAtis())	
end

]]