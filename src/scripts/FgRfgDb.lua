local Id = "FgRfg"
local function LogError(oLog) Fg.LogError(oLog, Id) end
local function LogInfo(oLog) Fg.LogInfo(oLog, Id) end
local function LogDebug(oLog) Fg.LogDebug(oLog, Id) end

FgRfgDb = {}

---------------------------------------------------------------------------------------------------
---  FLIGHT LEVELS  ---------------------------------------------------------------------------------
FgRfgDb.FlightLevels =
{
	["cessna_210n"] = { 35, 75, 95 },
	["Yak-52"] = { 35, 55, 75 },
	["a-10c"] = { 65, 95, 155 }
}

---------------------------------------------------------------------------------------------------
---  LIVERIES  ---------------------------------------------------------------------------------
FgRfgDb.Liveries =
{
  ["f-16c bl.52d"] = {
    ["usa"] = { "pacaf 14th fs (mj) misawa afb", "pacaf 35th fw (ww) misawa afb", "usaf 147th fig (ef) ellington afb", "usaf 412th tw (ed) edwards afb", "usaf 414th cts (wa) nellis afb", "usaf 77th fs (sw) shaw afb", "usafe 22nd fs (sp) spangdahlem afb", "usafe 555th fs (av) aviano afb" }
  },
  ["mq-9 reaper"] = {
    ["usa"] = { "'camo' scheme", "standard" },
    ["uk"] = { "standard UK" }
  },
  ["a_320"] = {
    ["any"] = { "Aeroflot", "Aeroflot 1", "Air Asia", "Air Berlin", "Air Berlin FFO", "Air Berlin OLT", "Air Berlin retro", "Air France", "Air Moldova", "Airbus Neo", "Al Maha", "Alitalia", "American Airlines", "British Airways", "Cebu Pacific", "Clean", "Condor", "Delta Airlines", "Easy Jet", "Easy Jet Berlin", "Easy Jet w", "Edelweiss", "Emirates", "Etihad", "Eurowings", "Eurowings BVB09", "Eurowings Europa Park", "Fly Georgia", "Fly Niki", "Frontier", "German Wings", "Gulf Air", "Iberia", "Iran Air", "Jet Blue NY", "JetBlue", "jetBlue FDNY", "Kish Air", "Kuwait Airways", "Lufthansa", "Lufthansa New", "MEA", "Qatar", "S7", "SAS", "Saudi Gulf", "Saudia", "Small Planet", "Star Alliance", "SWISS", "Thomas Cook", "Tunis Air", "Turkish Airlines", "United", "Ural Airlines", "US Airways", "Vietnam Airlines", "Virgin", "WiZZ", "WiZZ Budapest", "WOW" }
  },
  ["c-17a"] = {
    ["usa"] = { "usaf standard" }
  },
  ["ch-47d"] = {
    ["uk"] = { "ch-47_green uk" },
    ["usa"] = { "standard" }
  },
  ["a_380"] = {
    ["any"] = { "Air France", "BA", "China Southern", "Clean", "Emirates", "KA", "LH", "LHF", "Qantas Airways", "QTR", "SA", "TA" }
  },
  ["uh-60a"] = {
    ["usa"] = { "standard" },
    ["uk"] = { "standard" }
  },
  ["cessna_210n"] = {
    ["any"] = { "Blank", "D-EKVW", "HellenicAF", "Muster", "N9572H", "SEagle blue", "SEagle red", "USAF-Academy", "V5-BUG", "VH-JGA" }
  },
  ["b_747"] = {
    ["any"] = { "AF", "AF-One", "AI", "CP", "IM", "KLM", "LH", "NW", "PA", "QA", "TA" }
  },
  ["f_a-18c"] = {
    ["usa"] = { "NSAWC_25", "NSAWC_44", "VFA-94", "VFC-12" }
  },
  ["b_727"] = {
    ["any"] = { "AEROFLOT", "Air France", "Alaska", "Alitalia", "American Airlines", "Clean", "Delta Airlines", "Delta Airlines OLD", "FedEx", "Hapag Lloyd", "Lufthansa", "Lufthansa Oberhausen Old", "Northwest", "Pan Am", "Singapore Airlines", "Southwest", "UNITED", "UNITED Old", "ZERO G" }
  },
  ["a-10c"] = {
    ["usa"] = { "104th FS Maryland ANG, Baltimore (MD)", "118th FS Bradley ANGB, Connecticut (CT)", "118th FS Bradley ANGB, Connecticut (CT) N621", "172nd FS Battle Creek ANGB, Michigan (BC)", "184th FS Arkansas ANG, Fort Smith (FS)", "190th FS Boise ANGB, Idaho (ID)", "23rd TFW England AFB (EL)", "25th FS Osan AB, Korea (OS)", "354th FS Davis Monthan AFB, Arizona (DM)", "355th FS Eielson AFB, Alaska (AK)", "357th FS Davis Monthan AFB, Arizona (DM)", "358th FS Davis Monthan AFB, Arizona (DM)", "422nd TES Nellis AFB, Nevada (OT)", "47th FS Barksdale AFB, Louisiana (BD)", "66th WS Nellis AFB, Nevada (WA)", "74th FS Moody AFB, Georgia (FT)", "81st FS Spangdahlem AB, Germany (SP) 1", "81st FS Spangdahlem AB, Germany (SP) 2" },
    ["uk"] = { "A-10 Grey" }
  },
  ["tornado gr4"] = {
    ["uk"] = { "bb of 14 squadron raf lossiemouth", "no. 12 squadron raf lossiemouth ab (morayshire)", "no. 14 squadron raf lossiemouth ab (morayshire)", "no. 617 squadron raf lossiemouth ab (morayshire)", "no. 9 squadron raf marham ab (norfolk)", "o of ii (ac) squadron raf marham" }
  },
  ["f-15c"] = {
    ["usa"] = { "12th Fighter SQN (AK)", "390th Fighter SQN", "433rd Weapons SQN (WA)", "493rd Fighter SQN (LN)", "58th Fighter SQN (EG)", "65th Aggressor SQN (WA) Flanker", "65th Aggressor SQN (WA) MiG", "65th Aggressor SQN (WA) SUPER_Flanker", "Ferris Scheme" }
  },
  ["b_757"] = {
    ["any"] = { "AA", "BA", "C-32", "Delta", "DHL", "easyJet", "Swiss", "Thomson" }
  },
  ["ah-64d"] = {
    ["uk"] = { "ah-64_d_green uk" },
    ["usa"] = { "standard" }
  },
  ["b_737"] = {
    ["any"] = { "Air Algerie", "Air Berlin", "Air France", "airBaltic", "Airzena", "AM", "American_Airlines", "British Airways", "C40s", "Clean", "Disney", "EA", "easyJet", "FINNAIR", "HARIBO", "JA", "Jet2", "kulula", "LH", "Lufthansa BA", "Lufthansa KR", "OLD_BA", "OMAN AIR", "PAN AM", "Polskie Linie Lotnicze LOT", "QANTAS", "RYANAIR", "SouthWest Lone Star", "ThomsonFly", "TNT", "Ukraine Airlines", "UPS" }
  },
  ["c-130"] = {
    ["uk"] = { "Royal Air Force" },
    ["usa"] = { "US Air Force" }
  }
}

---------------------------------------------------------------------------------------------------
---  TOOLS  ---------------------------------------------------------------------------------
function FgRfgDb.GetLiveries(dcsGroup)
	local selectedLiveries = nil
	
	if (FgRfgDb.Liveries) then
		local dcsUnit = Fg.GetGroupFirstUnit(dcsGroup)
		if (dcsUnit) then
			local sTypeName = dcsUnit:getTypeName()
			local unitLiveries = FgRfgDb.Liveries[sTypeName:lower()]
			if (unitLiveries) then
				local iCountryId = dcsUnit:getCountry()
				local sCountryName = Fg.GetCountryShortName (iCountryId)
				if (sCountryName == nil) then sCountryName = "any" end
				
				LogInfo("Selecting liveries for type " .. sTypeName .. " country " .. sCountryName .. " (" .. iCountryId .. ")")
				
				selectedLiveries = unitLiveries[sCountryName:lower()]
				if (selectedLiveries == nil) then
					selectedLiveries = unitLiveries["any"]
				end
			end
		end
	end
	
	return selectedLiveries
end

function FgRfgDb.GetFlightLevels(dcsGroup)
	local selectedFls = nil
	
	if (FgRfgDb.FlightLevels) then
		local sTypeName = Fg.GetGroupUnitType(dcsGroup)
		local unitFls = FgRfgDb.FlightLevels[sTypeName:lower()]
		if (unitFls) then
			selectedFls = unitFls
		end
	end
	
	return selectedFls
end
