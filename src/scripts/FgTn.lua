--[[
Management of a timed navigation based on named units in the mission editor

Requires :
- Moose 
- FgTools

TODO
- Better menu management (remove unused)
]]

local Id = "FgTn"
local function LogError(oLog) Fg.LogError(oLog, Id) end
local function LogInfo(oLog) Fg.LogInfo(oLog, Id) end
local function LogDebug(oLog) Fg.LogDebug(oLog, Id) end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Enums and global statics
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local LegState = { NotStarted = 0, InProgress = 1, Ended = 2 }
local Debug = (Fg.LogLevel >= Fg.LogLevels.Debug)

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTnTools static class
---  Global tools for timed navigation
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTnTools = {}

function FgTnTools.OutTextForGroup(mooseGroup, sText)
	trigger.action.outTextForGroup(mooseGroup:GetDCSObject():getID(), sText, 59, false)
	if (Debug) then
		trigger.action.outText(mooseGroup.GroupName .. " DEBUG > " .. sText, 59, false)
	end
end

---------------------------------------------------------------------------------------------------
---  Marks
function FgTnTools.CreateMark(mooseZone, sText, mooseGroup)
	LogDebug("Mark for " ..mooseGroup.GroupName)
	LogDebug(sText)

	local vec = mooseZone:GetVec3()
	local iMarkId = UTILS.GetMarkID()
	trigger.action.markToGroup(iMarkId, sText, vec, mooseGroup:GetDCSObject():getID(), true, nil)
	if (Debug) then
		trigger.action.markToAll(iMarkId + 100, mooseGroup.GroupName .. " DEBUG > " .. sText, vec, true, nil)
	end
	
	return iMarkId
end

---------------------------------------------------------------------------------------------------
---  Speed and time
function FgTnTools.GetRandomSpeedMs (mooseGroup)
	local iUpThreshold = 1000
	local iMaxSpeed = mooseGroup:GetSpeedMax() * 0.75 -- km/h
	if (iMaxSpeed > iUpThreshold) then iMaxSpeed = iUpThreshold end
	local iMinSpeed = iMaxSpeed / 2
	
	local iSpeed = math.random(iMinSpeed, iMaxSpeed)
	local iSpeedMs = math.floor (UTILS.KmphToMps (iSpeed))
	LogDebug("Random speed - " .. mooseGroup.GroupName .. " - " .. iSpeed .. " kmh - " .. iSpeedMs .. " ms")
	return iSpeedMs -- m/s
end

function FgTnTools.GetTimeOfFlightS(mooseGroup, mooseCoordTo, iSpeed, iAdditionalTime)
	iAdditionalTime = iAdditionalTime or 0
	local mooseCoordFrom = mooseGroup:GetCoordinate()
	local iDistance = mooseCoordFrom:Get2DDistance(mooseCoordTo) -- Distance in meters
	return 60 + iAdditionalTime + iDistance / iSpeed -- seconds
end

---------------------------------------------------------------------------------------------------
---  AI group tasking
function FgTnTools.TaskGroupToZone(mooseGroup, mooseZone, iSpeedKmh, iAltitudeM, bLand)
	if (mooseGroup:GetPlayerCount() <= 0) then
		local coord = mooseZone:GetCoordinate()
		coord:SetAltitude(iAltitudeM, true)
		
		local pointType = POINT_VEC3.RoutePointType.TurningPoint
		if (bLand) then pointType = POINT_VEC3.RoutePointType.Land end
		local pointAction = POINT_VEC3.RoutePointAction.TurningPoint
		if (bLand) then pointAction = POINT_VEC3.RoutePointAction.Landing end
		
		mooseGroup:RouteAirTo(coord, COORDINATE.WaypointAltType.BARO, pointType, pointAction, iSpeedKmh, 3)
	end
end

function FgTnTools.TaskGroupToLand(mooseGroup, mooseZone, iSpeedKmh, iAltitudeM)
	FgTnTools.TaskGroupToZone(mooseGroup, mooseZone, iSpeedKmh, iAltitudeM, true)
end

function FgTnTools.TaskGroupToWp(mooseGroup, wp, iSpeedKmh, iAltitudeM)
	FgTnTools.TaskGroupToZone(mooseGroup, wp.MooseZone, iSpeedKmh, iAltitudeM, false)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTnWaypoint class
---  Waypoints based on a unit group in the mission editor
---  Units in the editor must be named NAVWP_[stage]_[waypoint label] - ex NAVWP_1_Kobuleti will create a waypoint at stage 1 named Kobuleti
---  Stages are used to order the waypoints. If multiple wayoints are on the same stage one will be chosen at random
---  Additional description can be specified for a waypoint, using a parameter when initializing the waypoint list
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTnWaypoint = {}
FgTnWaypoint.__index = FgTnWaypoint
---------------------------------------------------------------------------------------------------
---  CTORS
function FgTnWaypoint:Create(iStage, mooseZone, sLabel)
	local this =
	{
		Stage = iStage, -- stage of the navigation - each stage can have multiple wp and one is chosen at random
		MooseZone = mooseZone, -- dynamically generated zone representing the waypoint
		Altitude = 0,
		Label = sLabel, -- name of the waypoint, based on the dcs group name
		Description = nil, -- additional description can be specified if the label is not enough
		AdditionalAction = nil,
		AdditionalTime = 0,
		Localisation = nil -- description of the center coordinates
	}
		
	local coordinates = this.MooseZone:GetCoordinate()
	this.Localisation = coordinates:ToStringLLDDM(nil) .. "\n" .. coordinates:ToStringMGRS(nil)
	this.Altitude = coordinates:GetLandHeight()

	setmetatable(this, self)
	return this
end

function FgTnWaypoint:CreateFromGoupName(sGroupName, iWpZoneRadius)
	local iStage = tonumber(string.match(sGroupName, "^NAVWP_(%d+)_.*"))
	if (iStage) then
		local sLabel = string.match(sGroupName, ".*NAVWP_%d+_(.*)")
		if (sLabel == nil or sLabel == "") then sLabel = sGroupName end
		
		local mooseGroup = GROUP:FindByName(sGroupName)
		local mooseZone = ZONE_GROUP:New("Z_"..sGroupName, mooseGroup, iWpZoneRadius)
		return FgTnWaypoint:Create(iStage, mooseZone, sLabel)
	else
		return nil
	end
end

function FgTnWaypoint:CreateFromDscGoup(dcsGroup, iWpZoneRadius)
	return FgTnWaypoint:CreateFromGoupName(dcsGroup:getName(), iWpZoneRadius)
end

---------------------------------------------------------------------------------------------------
---  METHODS
function FgTnWaypoint:ToString()
	local sZone = "-no zone-"
	if (self.MooseZone) then sZone = self.MooseZone.ZoneName end
	return "Stage=" .. self.Stage .. " Zone=" .. sZone .. " Alt=" .. self.Altitude .. " Label=" .. self.Label .. " Additional time=" .. self.AdditionalTime
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTnWaypointList static class
---  List of all waypoints in the mission created by calling Initialize
---  Additional waypoints can be added for refueling and destinations
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTnWaypointList =
{
	StartZone = nil,
	LastStage = nil,
	RefuelWaypoint = nil,
	Stages = {},
	Destinations = {}
}

---------------------------------------------------------------------------------------------------
---  METHODS
function FgTnWaypointList.AddWaypoint(wp)
	if (wp) then
		if (FgTnWaypointList.Stages[wp.Stage] == nil) then
			FgTnWaypointList.Stages[wp.Stage] = {}
		end

		table.insert(FgTnWaypointList.Stages[wp.Stage], wp)	
	end
end

function FgTnWaypointList.Initialize(parameters)
	LogInfo("Initializing waypoint list")

	local sStartZoneName = parameters.StartZoneName or "FgTnStartZone"
	local iWpZoneRadius = parameters.WpZoneRadius or 2500
	local iLastStage = parameters.LastStage or nil
	local destinations = parameters.Destinations or {}
	local iRefuelEndStage = parameters.RefuelEndStage or nil
	local sRefuelEndZoneName = parameters.RefuelEndZoneName or nil
	local additionalData = parameters.AdditionalData or nil

	LogDebug("  sStartZoneName=" .. Fg.ToString(sStartZoneName))
	LogDebug("  iWpZoneRadius=" .. Fg.ToString(iWpZoneRadius))
	LogDebug("  iLastStage=" .. Fg.ToString(iLastStage))
	LogDebug("  destinations=" .. Fg.ToString(destinations))
	LogDebug("  iRefuelEndStage=" .. Fg.ToString(iRefuelEndStage))
	LogDebug("  sRefuelEndZoneName=" .. Fg.ToString(sRefuelEndZoneName))

	FgTnWaypointList.StartZone = ZONE:FindByName(sStartZoneName)
	FgTnWaypointList.LastStage = iLastStage

	for _, iCoalition in pairs { coalition.side.NEUTRAL, coalition.side.RED, coalition.side.BLUE } do
		for __, dcsGroup in pairs(coalition.getGroups(iCoalition)) do
			local wp = FgTnWaypoint:CreateFromDscGoup(dcsGroup, iWpZoneRadius)
			if (wp) then
				if (additionalData and additionalData[wp.Label]) then
					wp.Description = additionalData[wp.Label].Description
					wp.AdditionalAction = additionalData[wp.Label].AdditionalAction
					wp.AdditionalTime = additionalData[wp.Label].AdditionalTime or 0
				end

				FgTnWaypointList.AddWaypoint (wp)
			end
			
		end
	end
	
	for _, sDestination in pairs (destinations) do
		local airbaseMooseZone = ZONE_AIRBASE:New(sDestination)
		if (airbaseMooseZone) then
			table.insert(FgTnWaypointList.Destinations, airbaseMooseZone)	
		end
	end
	
	if (iRefuelEndStage and sRefuelEndZoneName) then
		local refuelEndMooseZone = ZONE:FindByName(sRefuelEndZoneName)
		if (refuelEndMooseZone) then
			FgTnWaypointList.RefuelWaypoint = FgTnWaypoint:Create(iRefuelEndStage, refuelEndMooseZone, "Refuel end")
			FgTnWaypointList.RefuelWaypoint.Description = "Navigate here when you are done with the refuel phase, or just skip to the next waypoint."
		end
	end

	LogInfo (FgTnWaypointList.ToString())
end

function FgTnWaypointList.ToString()
	local sString = ""
	if (FgTnWaypointList.LastStage) then sString = sString .. "\nLastStage=" .. FgTnWaypointList.LastStage end
	if (FgTnWaypointList.RefuelWaypoint) then sString = sString .. "\nRefuelWaypoint=[" .. FgTnWaypointList.RefuelWaypoint:ToString() .. "]" end
	
	sString = sString .. "\nStages-"
	for iStage, stageWps in pairs(FgTnWaypointList.Stages) do
		sString = sString .. "\n  Stage=" .. iStage
		for _, wp in pairs(stageWps) do
			sString = sString .. "\n    " .. wp:ToString()
			if (wp.Description) then
				sString = sString .. "\n      " .. wp.Description
			end
		end
	end

	sString = sString .. "\nDestinations-"
	for _, destination in pairs(FgTnWaypointList.Destinations) do
		sString = sString .. "\n  " .. destination.ZoneName
	end
	
	return sString
end

function FgTnWaypointList.GetWaypoint(iStage)
	LogDebug("GetWaypoint - iStage=" .. iStage)
	local stageWaypoints = FgTnWaypointList.Stages[iStage]
	if (stageWaypoints == nil) then
		return nil
	else
		return stageWaypoints[math.random(#stageWaypoints)]
	end
end

function FgTnWaypointList.GetNextWaypoint(currentWp)
	local iNextStage = currentWp.Stage + 1
	local refuelWp = FgTnWaypointList.RefuelWaypoint
	if (refuelWp) then
		if (refuelWp == currentWp) then
			-- if a refuel point exists and is the current point, advance to the same stage normal waypoints
			iNextStage = refuelWp.Stage
			LogDebug("TnWaypointList:GetWaypoint - on refuel point keep stage " .. iNextStage)
		elseif (refuelWp.Stage == iNextStage) then
			-- if a refuel point exists and is NOT the current point, and the next stage is the refuel one, return the refuel point
			LogDebug("TnWaypointList:GetWaypoint - refuel is next")
			return refuelWp
		end
	end

	if (FgTnWaypointList.LastStage and iNextStage > FgTnWaypointList.LastStage) then
		LogInfo("TnWaypointList:GetWaypoint - last stage past")
		return nil
	end
	
	LogDebug("GetWaypoint - move to " .. iNextStage)
	return FgTnWaypointList.GetWaypoint(iNextStage)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTnLeg class
---  Leg of navigation for a dcs group, to a waypoint
---  The leg manages messages and markers to its group, computes ToT
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTnLeg = {}
FgTnLeg.__index = FgTnLeg
---------------------------------------------------------------------------------------------------
---  CTOR
function FgTnLeg:Create()
	local this =
	{
		MooseGroup = nil, -- moose group doing the leg
		WaypointTo = nil, -- moose zone where to end the leg
		TimeTo = 0, -- target time when to arrive at the destination
		Speed = 0,
		MarkId = 0,
		State = LegState.NotStarted
	}
	setmetatable(this, self)
	return this
end

---------------------------------------------------------------------------------------------------
---  METHODS
function FgTnLeg:ToString()
	local sWpTo = "-nowp-"
	if (self.WaypointTo) then sWpTo = "[" .. self.WaypointTo:ToString() .. "]" end
	return "MooseGroup=" .. self.MooseGroup.GroupName .. " - WaypointTo=" .. sWpTo .. " - TimeTo=".. Fg.TimeToString(self.TimeTo) .. " - Speed=" .. UTILS.MpsToKnots(self.Speed) .. " kts - MarkId=" .. self.MarkId
end

function FgTnLeg:GetMessage(bWithDescription, bWithLocalisation)
	LogDebug ("GetMessage - bWithDescription=" .. Fg.ToString(bWithDescription) .. " - bWithLocalisation=" .. Fg.ToString(bWithLocalisation))
	local sMessage = "No destination"
	if (self.WaypointTo) then
		sMessage = self.WaypointTo.Label
		if (bWithDescription and self.WaypointTo.Description) then
			sMessage = sMessage .. "\n" .. self.WaypointTo.Description
		end
		if (bWithLocalisation and self.WaypointTo.Localisation) then
			sMessage = sMessage .. "\n\n" .. self.WaypointTo.Localisation
			sMessage = sMessage .. "\nAltitude " .. UTILS.Round (UTILS.MetersToFeet(self.WaypointTo.Altitude or 0)) .. " feet"
		end
		
		if (self.TimeTo and self.TimeTo > 0) then
			local timeToZulu = Fg.TimeToZulu(self.TimeTo)
			sMessage = sMessage .. "\n\nTOT " .. Fg.TimeToString(timeToZulu) .. " zulu"
			sMessage = sMessage .. "\nTOT " .. Fg.TimeToString(self.TimeTo) .. " local"
			
			if (Debug) then
				sMessage = sMessage .. "\nDEBUG > Speed " .. UTILS.MpsToKnots(self.Speed) .. " kts"
			end
		end
	end
	
	return sMessage
end

function FgTnLeg:CreateMark()
	if (self.WaypointTo) then
		self.MarkId = FgTnTools.CreateMark(self.WaypointTo.MooseZone, self:GetMessage(false, false), self.MooseGroup)
	else
		self.MarkId = 0
	end
end

function FgTnLeg:RemoveMark()
	if (self.MarkId and self.MarkId > 0) then
		trigger.action.removeMark(self.MarkId)
		self.MarkId = 0
	end
end

function FgTnLeg:UpdateLegTime()
	self.Speed = 0
	self.TimeTo = 0
	self.Speed = FgTnTools.GetRandomSpeedMs(self.MooseGroup)
		
	if (self.WaypointTo) then
		if (FgTnWaypointList.RefuelWaypoint == nil or self.WaypointTo ~= FgTnWaypointList.RefuelWaypoint) then
			local iTimeOfFlightS = FgTnTools.GetTimeOfFlightS(self.MooseGroup, self.WaypointTo.MooseZone:GetCoordinate(), self.Speed, self.WaypointTo.AdditionalTime)
			
			local oTime = Fg.TimeFromAbsSeconds(timer.getAbsTime() + iTimeOfFlightS, Fg.TimePrecisions.Minute)
			self.TimeTo = Fg.TimeToAbsSeconds(oTime)
		end
	end
end

function FgTnLeg:TaskGroupToLeg()
	FgTnTools.TaskGroupToWp(self.MooseGroup, self.WaypointTo, UTILS.MpsToKmph(self.Speed), self.MooseGroup:GetHeight())
end

function FgTnLeg:OutTextForGroup(sText)
	FgTnTools.OutTextForGroup(self.MooseGroup, sText)
end

function FgTnLeg:FlareZone(color)
	self.WaypointTo.MooseZone:FlareZone(color, 90, 60, self.MooseGroup:GetHeight() - 500)
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTnLegList static class
---  List of all active legs for all groups in the mission
---  It is used to advance through the stages when a waypiont is reached
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTnLegList =
{
	MenuNav = {},
	EndingAction = nil
}

---------------------------------------------------------------------------------------------------
---  METHODS
local function SkipActiveLeg(sGroupName)
	LogDebug("SkipActiveLeg - " .. sGroupName)
	local leg = FgTnLegList[sGroupName]
	if (leg) then
		FgTnLegList.AdvanceLeg(leg, true)
	end
end

local function ActiveLegInfo(sGroupName)
	LogDebug("ActiveLegInfo - " .. sGroupName)
	local leg = FgTnLegList[sGroupName]
	if (leg) then
		leg:OutTextForGroup(leg:GetMessage(true, true))
	end
end

function FgTnLegList.GetGroupMenu(mooseGroup)
	if (FgTnLegList.MenuNav == nil) then
		LogInfo("MenuNav initialize")
		FgTnLegList.MenuNav = {}
	end
	if (FgTnLegList.MenuNav[mooseGroup.GroupName] == nil) then
		FgTnLegList.MenuNav[mooseGroup.GroupName] = MENU_GROUP:New(mooseGroup, "Timed navigation")
	end

	return FgTnLegList.MenuNav[mooseGroup.GroupName]
end

function FgTnLegList.GetActiveLeg(mooseGroup)
	local leg = FgTnLegList[mooseGroup.GroupName]
	
	if (leg == nil) then
		leg = FgTnLeg:Create()
		leg.MooseGroup = mooseGroup
		FgTnLegList[mooseGroup.GroupName] = leg
	end

	return leg
end

function FgTnLegList.EndNavigation(leg)
	if (FgTnWaypointList.Destinations and #FgTnWaypointList.Destinations > 0) then
		local zoneAirbase = FgTnWaypointList.Destinations[math.random(#FgTnWaypointList.Destinations)]
	
		leg.markId = nil
		leg:OutTextForGroup("Navigation terminated\nYour final destination for landing is " .. zoneAirbase.ZoneName)

		FgTnTools.TaskGroupToLand(leg.MooseGroup, zoneAirbase, UTILS.MpsToKmph(leg.Speed), leg.MooseGroup:GetHeight())
	end
	
	if (FgTnLegList.EndingAction) then
		LogDebug("Executing ending action")
		FgTnLegList.EndingAction(leg.MooseGroup)
	end

	leg.State = LegState.Ended		
end

function FgTnLegList.AdvanceLeg(leg, bSkip)
	bSkip = bSkip or false
	
	LogInfo("AdvanceLeg - " .. leg.MooseGroup.GroupName .. " in destination zone [" .. leg.WaypointTo.MooseZone.ZoneName .. "]")
	if (not bSkip) then
		leg:OutTextForGroup("Destination reached: \n" .. leg:GetMessage(true, false))
	
		-- check the timing, and prepare the next leg
		local timeAbs = timer.getAbsTime()
		local timeTolerance = 45 -- seconds
		local onTime = nil

		if (leg.TimeTo and leg.TimeTo > 0) then
			local legTime = leg.TimeTo - timeAbs
			if (legTime < -timeTolerance) then
				onTime = 1
				leg:OutTextForGroup ("You are LATE")
				--leg:FlareZone(FLARECOLOR.Red)
			elseif (legTime > timeTolerance) then
				onTime = -1
				leg:OutTextForGroup ("You are EARLY")
				--leg:FlareZone(FLARECOLOR.Red )
			else -- on time
				onTime = 0
				leg:OutTextForGroup ("You are ON TIME")
				--leg:FlareZone(FLARECOLOR.Green)
			end		
		else
			--leg:FlareZone(FLARECOLOR.White)
		end

		if (leg.WaypointTo.AdditionalAction) then
			leg.WaypointTo.AdditionalAction(leg.MooseGroup, onTime)
		end	
	end

	leg.WaypointTo = FgTnWaypointList.GetNextWaypoint(leg.WaypointTo)
	leg:RemoveMark()
	if (leg.WaypointTo) then
		leg:UpdateLegTime()
		leg:CreateMark()
		leg:TaskGroupToLeg()
		
		LogInfo("AdvanceLeg - " .. leg.MooseGroup.GroupName .. " next leg - " .. leg:ToString())
		leg:OutTextForGroup("Next waypoint (mark created): \n" .. leg:GetMessage(true, true))
	else
		LogInfo("AdvanceLeg - " .. leg.MooseGroup.GroupName .. " no next wp found, ending navigation")
		FgTnLegList.EndNavigation(leg)
	end
end

function FgTnLegList.AdvanceLegInitial(leg)
	leg.WaypointTo = FgTnWaypointList.GetWaypoint(0)
	if (leg.WaypointTo) then
		leg.State = LegState.InProgress
		leg:UpdateLegTime()
		leg:CreateMark()
		leg:TaskGroupToLeg()

		local groupMenuNav = FgTnLegList.GetGroupMenu(leg.MooseGroup)
		MENU_GROUP_COMMAND:New(leg.MooseGroup, "Active leg info", groupMenuNav, ActiveLegInfo, leg.MooseGroup.GroupName)
		MENU_GROUP_COMMAND:New(leg.MooseGroup, "Skip active leg", groupMenuNav, SkipActiveLeg, leg.MooseGroup.GroupName)

		LogInfo("AdvanceLegInitial - " .. leg.MooseGroup.GroupName .. " first leg=[" .. leg:ToString() .. "]")
		leg:OutTextForGroup("First waypoint (mark created): \n" .. leg:GetMessage(true, true))
	else
		LogInfo("AdvanceLegInitial - " .. leg.MooseGroup.GroupName .. " no first wp found at stage 0")
		FgTnLegList.EndNavigation(leg)
	end
end

function FgTnLegList.CheckActiveLeg(mooseGroup)
	local leg = FgTnLegList.GetActiveLeg(mooseGroup)
	
	if (leg.State == LegState.NotStarted) then
		if (mooseGroup:IsPartlyOrCompletelyInZone(FgTnWaypointList.StartZone)) then
			FgTnLegList.AdvanceLegInitial(leg)
		end
	elseif(leg.State == LegState.InProgress) then
		if (mooseGroup:IsPartlyOrCompletelyInZone(leg.WaypointTo.MooseZone)) then
			FgTnLegList.AdvanceLeg(leg)
		end
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  FgTn static class
---  Main logic, scheduler to monitor the navigating groups
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
FgTn =
{
    NavGroupNames = nil,
    Scheduler = nil
}

function FgTn.CheckActiveGroups()
	for _, sGroupName in pairs(FgTn.NavGroupNames) do
       	local mooseGroup = GROUP:FindByName(sGroupName)
		if (mooseGroup) then
			FgTnLegList.CheckActiveLeg(mooseGroup)
		else
			LogDebug("CheckActiveGroups - group not found - " .. sGroupName)
		end
	end
end

function FgTn.Start(parameters)
    FgTn.NavGroupNames = parameters.NavGroupNames
	FgTnLegList.EndingAction = parameters.EndingAction

    FgTnWaypointList.Initialize(parameters)
	
    if (FgTn.Scheduler) then
        LogInfo("Stop nav scheduler")
        FgTn.Scheduler:Stop()
     end
     LogInfo("Start nav scheduler")
     FgTn.Scheduler = SCHEDULER:New(nil, 
     function()
        FgTn.CheckActiveGroups()
     end,
     {},
     1, 10
     )
     
end
