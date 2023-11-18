local Id = "Mission"
local function LogError(oLog) Fg.LogError(oLog, Id) end
local function LogInfo(oLog) Fg.LogInfo(oLog, Id) end
local function LogDebug(oLog) Fg.LogDebug(oLog, Id) end

local Debug = false
if (Debug) then
    Fg.LogLevel = Fg.LogLevels.Debug
else
    Fg.LogLevel = Fg.LogLevels.Error
end

_SETTINGS:SetPlayerMenuOff()

LogInfo("")
LogInfo("Random flights generation")

local airportsCiv = 
{
AIRBASE.Syria.Megiddo,
AIRBASE.Syria.Haifa,
AIRBASE.Syria.Rosh_Pina,
AIRBASE.Syria.Damascus,
AIRBASE.Syria.Beirut_Rafic_Hariri,
AIRBASE.Syria.Palmyra,
AIRBASE.Syria.Aleppo,
AIRBASE.Syria.Bassel_Al_Assad,
AIRBASE.Syria.Hatay,
AIRBASE.Syria.Gaziantep,
AIRBASE.Syria.Adana_Sakirpasa,
AIRBASE.Syria.Incirlik
}
local airportsBlue = 
{
AIRBASE.Syria.Khalkhalah,
AIRBASE.Syria.Rayak,
AIRBASE.Syria.King_Hussein_Air_College,
AIRBASE.Syria.Jirah,
AIRBASE.Syria.Ramat_David,
AIRBASE.Syria.H4,
AIRBASE.Syria.Megiddo
}

-- neutral civilian flights
local parameters = 
{
	["SpawnDelayMin"] = 10,
	["SpawnDelayMax"] = 120,
	["SpawnIntervalMin"] = 60,
	["SpawnIntervalMax"] = 300,
	["DepartureAirports"] = airportsCiv,
	["DepartureZones"] = "RFG_ZONE",
	["Destinations"] = airportsCiv
}
FgRfg.Generate(coalition.side.NEUTRAL, math.random(12, 20), parameters)

-- blue flights
local parameters = 
{
	["SpawnDelayMin"] = 10,
	["SpawnDelayMax"] = 120,
	["SpawnIntervalMin"] = 60,
	["SpawnIntervalMax"] = 300,
	["DepartureAirports"] = airportsBlue,
	["DepartureZones"] = "RFG_ZONE",
	["Destinations"] = airportsBlue
}
FgRfg.Generate(coalition.side.BLUE, math.random(3, 6), parameters)

-- blue flights start @ player
local parameters = 
{
	["AirStartPercent"] = 0,
	["SpawnDelayMin"] = 2,
	["SpawnDelayMax"] = 4,
	["SpawnIntervalMin"] = 60,
	["SpawnIntervalMax"] = 300,
	["DepartureAirports"] = {AIRBASE.Syria.Incirlik},
	["Destinations"] = airportsBlue
}
FgRfg.Generate(coalition.side.BLUE, math.random(3, 4), parameters)

-- blue flights arrive @ player
local parameters = 
{
	["AirStartPercent"] = 100,
	["SpawnDelayMin"] = 1,
	["SpawnDelayMax"] = 1,
	["SpawnIntervalMin"] = 60,
	["SpawnIntervalMax"] = 300,
	["DepartureZones"] = "RFG_ZONE",
	["Destinations"] = AIRBASE.Syria.Incirlik
}
FgRfg.Generate(coalition.side.BLUE, math.random(2, 3), parameters)

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---  Timed navigation
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local tnParameters = 
{
	NavGroupNames =
	{
		"Tester-A10", "Tester-F18"
	},
	EndingAction = nil,
	StartZoneName = "Start zone",
	WpZoneRadius = 2500,
	LastStage = 4,
	Destinations = {AIRBASE.Syria.Ramat_David, AIRBASE.Syria.King_Hussein_Air_College, AIRBASE.Syria.Megiddo},
	RefuelEndStage = 4, -- this is the stage before which the refuel will take place. If refuel stage is 3, then the refuel will take place between stages 2 and 3
	RefuelEndZoneName = "End refuel zone",
	AdditionalData =
	{
		--0
		["Minakh airbase"] = { Description = "High value transport reported to depart from the airbase by helicopter." },
		["Al-Rai town"] = { Description = "Ground personnel are reported to stock military equipment in the city center." },
		--1
		["Salt lake parking"] = { Description = "Large concentration of military equipment parked in a dry area of the lake." },
		["Jirah dam"] = { Description = "Small armed boats anchored in the river near the dam." },
		["Military research base"] = { Description = "Some kind of radar equipement has been installed on the site." },
		--2
		["Desert FARP"] = { Description = "Military helicopter FARP installed along a dirt road." },
		["Suruj roadblock"] = { Description = "A roadblock installed in the middle of the town of Suruj." },
		["Wadi Shatnat"] = { Description = "SAM site in the desert near the wadi." },
		--3
		["Tartus port"] = { Description = "Attack submarines spotted in the commercial port." },
		["Jihar industrial zone"] = { Description = "Chemical tanks and processing facility." },
		["Homs highway"] = { Description = "Artillery units stopped alongside the highway." },
		--4
		["Dark rock"] = { Description = "Oil derricks on top of the mountain." },
		["Kiryat"] = { Description = "Airshow on the airfield." },
		["As Sawara"] = { Description = "Forest fire east of the town." }
	}
}
-----------------------

LogInfo("Weather menu initialization")
FgWeatherMenu.Start()

LogInfo("Timed navigation initialization")
FgTn.Start(tnParameters)
