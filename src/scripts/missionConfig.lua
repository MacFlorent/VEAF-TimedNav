-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission configuration file for the VEAF framework
-- see https://github.com/VEAF/VEAF-Mission-Creation-Tools
-------------------------------------------------------------------------------------------------------------------------------------------------------------
veaf.config.MISSION_NAME = "VEAF-TimedNav"
veaf.config.MISSION_EXPORT_PATH = nil -- use default folder

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize QRA
-------------------------------------------------------------------------------------------------------------------------------------------------------------

if veafQraManager then
    -- VeafQRA.ToggleAllSilence(false) --this will set all QRA messages ON if the argument is "true" and all QRA messages to OFF is the argument is "false".
    
    -- to create a QRA, define it below. You can have a look at the following example to get started.
    
    --[[
    QRA_Minevody = VeafQRA:new()
    :setName("QRA_Minevody")
    :setTriggerZone("QRA_Minevody")
    :setZoneRadius(106680) -- 350,000 feet
    :addGroup("QRA_Minevody") --you can use this to add multiple groups to the QRA. They will be chosen depending on how many ennemy players are in the zone.

        --NOTE 1 : Remember that only one aircraft group at a time is deployed for each QRA

    :setQRAcount(QRAcount) --Superior or equal to -1 : Current number of aircraft groups available for deployement. By default this is set to -1 meaning an infinite amount of groups are available, no warehousing is done. -> This is you master arm for the rest of these options.
    :setQRAmaxCount(maxQRAcount) --Superior or equal to -1 : Maximum number of aircraft groups deployable at any time for the QRA. By default this is set to -1 meaning an infinite amount of aircrafts can be accumulated for deployement. -> Example: a QRA has 2 out of 6 groups ready for deployement, 6 is your maxQRAcount, 2 is your current QRAcount.
    :setQRAmaxResupplyCount(maxResupplyCount) --Superior or equal to -1 : Total number of aircraft groups which can be resupplied to the QRA. By default this is set to -1 meaning an infinite amount of stock is available. 0 means no stock is available, no resupplies will occur, this is your master arm for resupplies  -> Take the previous example : We are missing 4 groups but only have 3 in stock to resupply the QRA, 3 is your QRAmaxResupplyCount
    :setQRAminCountforResupply(minCountforResupply) --Equal to -1 or superior to 0 : Number of aircraft groups which the QRA needs to have at all times, otherwise a resupply will be started. By default this is set at -1 which means that a resupply will be started as soon as an aircraft group is lost. -> Take the previous example : This minimum number of deployable groups we desire at all times for our QRA is 1, but we have 2, so no resupply will happen for now. 1 is your minCountforResupply.
    :setResupplyAmount(resupplyAmount) --Superior or equal to 1 : Number of aircraf groups that will be resupplied to the QRA when a resupply happens. By default it is equal to 1. -> Take the previous example : We just lost both of our groups meaning we only have none left, this will trigger a resupply, a resupply the desired amount of aircraft groups or of however many aircrafts we have in stock if this amount is less. The resupply will also be constrained by the maximum number of groups we can have ready for deployement at once.
    :setQRAresupplyDelay(resupplyDelay) --Superior or equal to 0 : Time that a resupply will need in order to happen.

        --NOTE 2 : only one resupply can happen at a time, they may be scheduled at every possible occasion but will happen one at a time.
        --NOTE 3 : QRA groups that have just arrived from the supply chain will need to be rearmed (see associated delay and constraints)

    :setAirportLink(airbase_name) --Unit name of the airbase in between " " : QRA will be linked to this airport and will stop operating if the airport is lost (This can be a FARP (use the FARP's unit name), a Ship (use the ship's unit name), an airfield or a building (oil rigs etc.))
    :setAirportMinLifePercent(value) --Ranges from 0 to 1 : minimum life percentage of the linked airport for the QRA to operate. Airports (runways) and Ships only should lose life when bombed, this needs manual testing to know what works best. Not currently functional due to a DCS bug.
    :setAirportLink("Mineralnye Vody")

        --NOTE 1 : QRA that are just being recomissioned after an airbase is retaken will need to be rearmed (see associated delay and constraints)

    :setDelayBeforeRearming(value) --Delay between the death of a QRA and it being ready for action
    :setNoNeedToLeaveZoneBeforeRearming() --QRA will be rearmed (and later deployed) even though players are still in the area
    :setResetWhenLeavingZone() --The QRA will be despawned (and ready-ed up again immediatly) when all players leave the zone. Otherwise the QRA will patrol until they RTB at which point they will despawn on landing and be ready immediatly.
    :setDelayBeforeActivating(value) --activation delay between units entering the QRA zone and the QRA actually deploying

    :setCoalition(coalition.side.RED)
    :addEnnemyCoalition(coalition.side.BLUE)
    :setReactOnHelicopters() --Sets if the QRA reacts to helicopters entering the zone
    :setSilent() --mutes this QRA only, VeafQRA.AllSilence has to be false for this to have an effect
    :start()
    ]]
end

--if QRA_Minevody then QRA_Minevody:stop() end --use this if you wish to stop the QRA from operating at any point (in a trigger etc.). It can be restarted with : if QRA_Minevody then QRA_Minevody:start() end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize all the scripts
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafRadio then
    -- the RADIO module is mandatory as it is used by many other modules
    veaf.loggers.get(veaf.Id):info("init - veafRadio")
    veafRadio.initialize(true)
end
if veafSpawn then
    -- the SPAWN module is mandatory as it is used by many other modules
    veaf.loggers.get(veaf.Id):info("init - veafSpawn")
    veafSpawn.initialize()
end
if veafGrass then
    -- uncomment (and adapt) the following lines to enable the Grass Runways and FARP decoration
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafGrass")
    veafGrass.initialize()
    ]]
end
if veafCasMission then
    -- uncomment (and adapt) the following lines to enable the CAS mission module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafCasMission")
    veafCasMission.initialize()
    ]]
end
if veafTransportMission then
    -- uncomment (and adapt) the following lines to enable the Transport mission module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafTransportMission")
    veafTransportMission.initialize()
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- change some default parameters
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- here you can redefine the parameters you want (see in the source files)
veaf.DEFAULT_GROUND_SPEED_KPH = 25

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize SHORTCUTS
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafShortcuts then
    -- the SHORTCUTS module is mandatory as it is used by many other modules
    veaf.loggers.get(veaf.Id):info("init - veafShortcuts")
    veafShortcuts.initialize()

    -- you can add all the shortcuts you want here. Shortcuts can be any VEAF command, as entered in a map marker.
    -- here are some examples :

    --[[
     veafShortcuts.AddAlias(
         VeafAlias:new()
             :setName("-sa11")
             :setDescription("SA-11 Gadfly (9K37 Buk) battery")
             :setVeafCommand("_spawn group, name sa11")
             :setBypassSecurity(true)
     )
     ]]
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure ASSETS
-------------------------------------------------------------------------------------------------------------------------------------------------------------

if veafAssets then
    -- uncomment (and adapt) the following lines to enable the ASSETS module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("Loading configuration")
    veafAssets.Assets = {
		-- list the assets in the mission below
		-- {sort=1, name="CSG-01 Tarawa", description="Tarawa (LHA)", information="Tacan 11X TAA\nU226 (11)"},  
		-- {sort=2, name="CSG-74 Stennis", description="Stennis (CVN)", information="Tacan 10X STS\nICLS 10\nU225 (10)"},  
		-- {sort=2, name="CSG-71 Roosevelt", description="Roosevelt (CVN)", information="Tacan 12X RHR\nICLS 11\nU227 (12)"},  
		-- {sort=3, name="T1-Arco-1", description="Arco-1 (KC-135)", information="Tacan 64Y\nU290.50 (20)\nZone OUEST", linked="T1-Arco-1 escort"}, 
		-- {sort=4, name="T2-Shell-1", description="Shell-1 (KC-135 MPRS)", information="Tacan 62Y\nU290.30 (18)\nZone EST", linked="T2-Shell-1 escort"},  
		-- {sort=5, name="T3-Texaco-1", description="Texaco-1 (KC-135 MPRS)", information="Tacan 60Y\nU290.10 (17)\nZone OUEST", linked="T3-Texaco-1 escort"},  
		-- {sort=6, name="T4-Shell-2", description="Shell-2 (KC-135)", information="Tacan 63Y\nU290.40 (19)\nZone EST", linked="T4-Shell-2 escort"},  
		-- {sort=6, name="T5-Petrolsky", description="900 (IL-78M, RED)", information="U267", linked="T5-Petrolsky escort"},  
		-- {sort=7, name="CVN-74 Stennis S3B-Tanker", description="Texaco-7 (S3-B)", information="Tacan 75X\nU290.90\nZone PA"},  
		-- {sort=7, name="CVN-71 Roosevelt S3B-Tanker", description="Texaco-8 (S3-B)", information="Tacan 76X\nU290.80\nZone PA"},  
		-- {sort=8, name="Bizmuth", description="Colt-1 AFAC Bizmuth (MQ-9)", information="L1688 V118.80 (18)", jtac=1688, freq=118.80, mod="am"},
		-- {sort=9, name="Agate", description="Dodge-1 AFAC Agate (MQ-9)", information="L1687 V118.90 (19)", jtac=1687, freq=118.90, mod="am"},  
		-- {sort=10, name="A1-Magic", description="Magic (E-2D)", information="Datalink 315.3 Mhz\nU282.20 (13)", linked="A1-Magic escort"},  
		-- {sort=11, name="A2-Overlordsky", description="Overlordsky (A-50, RED)", information="V112.12"},  
    }

    veaf.loggers.get(veaf.Id):info("init - veafAssets")
    veafAssets.initialize()
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure MOVE
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafMove then
    -- uncomment (and adapt) the following lines to enable the MOVE module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("Setting move tanker radio menus")
    -- keeping the veafMove.Tankers table empty will force veafMove.initialize() to browse the units, and find the tankers automatically
    veaf.loggers.get(veaf.Id):info("init - veafMove")
    veafMove.initialize()
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure COMBAT MISSION
-------------------------------------------------------------------------------------------------------------------------------------------------------------

if veafCombatMission then 
    -- uncomment (and adapt) the following lines to enable the COMBAT MISSION module (air to air fights), its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("Loading configuration")

    veaf.loggers.get(veaf.Id):info("init - veafCombatMission")
    veafCombatMission.initialize()
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure COMBAT ZONE
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafCombatZone then 
    -- uncomment (and adapt) the following lines to enable the COMBAT MISSION module (air to ground combat), its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("Loading configuration")

    veaf.loggers.get(veaf.Id):info("init - veafCombatZone")
    veafCombatZone.initialize()
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure WW2 settings based on loaded theatre
-------------------------------------------------------------------------------------------------------------------------------------------------------------
local theatre = string.lower(env.mission.theatre)
veaf.loggers.get(veaf.Id):info(string.format("theatre is %s", theatre))
veaf.config.ww2 = false
if theatre == "thechannel" then
    veaf.config.ww2 = true
elseif theatre == "normandy" then
    veaf.config.ww2 = true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure NAMEDPOINTS
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafNamedPoints then
    -- the NAMED POINTS module is mandatory as it is used by many other modules

    veaf.loggers.get(veaf.Id):info("Loading configuration")

    
    -- here you can add points of interest, that will be added to the default points
    local customPoints = {
    --     {name="RANGE KhalKhalah",point=coord.LLtoLO("33.036180", "37.196608")},
    }
    veaf.loggers.get(veaf.Id):info("init - veafNamedPoints")
    veafNamedPoints.initialize(customPoints)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure WEATHER
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafWeather then
    veaf.loggers.get(veaf.Id):info("init - veafWeather")
    veafWeather.initialize()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure SECURITY
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafSecurity then
    -- the SECURITY module is mandatory as it is used by many other modules

    --let's not set a password
    veaf.SecurityDisabled = true
    --veafSecurity.password_L9["SHA1 hash of the password"] = true -- set the L9 password (the lowest possible security)
    veaf.loggers.get(veaf.Id):info("Loading configuration")
    veaf.loggers.get(veaf.Id):info("init - veafSecurity")
    veafSecurity.initialize()

    -- force security in order to test it when dynamic loading is in place (change to TRUE)
    if (false) then
        veaf.SecurityDisabled = false
        veafSecurity.authenticated = false
    end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure CARRIER OPERATIONS 
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafCarrierOperations then
    -- uncomment (and adapt) the following lines to enable the CARRIER OPERATIONS module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafCarrierOperations")
    veafCarrierOperations.initialize(true)
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure CTLD 
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if ctld then
    ctld.alreadyInitialized = true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- configure CSAR
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if csar then
    csar.alreadyInitialized = true
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize the remote interface
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafRemote then
    -- uncomment (and adapt) the following lines to enable the REMOTE module (call functions from a remote interface, such as the server), its commands and its radio menu
    veaf.loggers.get(veaf.Id):info("init - veafRemote")
    veafRemote.initialize()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize Skynet-IADS
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafSkynet then
    -- uncomment (and adapt) the following lines to enable Skynet-IADS
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafSkynet")
    veafSkynet.initialize(
        false, --includeRedInRadio=true
        false, --debugRed
        false, --includeBlueInRadio
        false --debugBlue
    )
    ]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize the interpreter
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafInterpreter then
    -- the INTERPRETER module is mandatory as it is used by many other modules
    veaf.loggers.get(veaf.Id):info("init - veafInterpreter")
    veafInterpreter.initialize()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize veafSanctuary
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafSanctuary then
    -- uncomment (and adapt) the following lines to enable the SANCTUARY module, its commands and its radio menu
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafSanctuary")
    veafSanctuary.initialize()
    ]]
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- initialize Hound Elint
-------------------------------------------------------------------------------------------------------------------------------------------------------------
if veafHoundElint then
    -- uncomment (and adapt) the following lines to enable Hound Elint
    --[[
    veaf.loggers.get(veaf.Id):info("init - veafHoundElint")
    veafHoundElint.initialize(
        "ELINT", -- prefix
        { -- red
            --global parameters
            sectors = {},
            markers = true,
            disableBDA = false, --disables notifications that a radar has dropped off scope
            platformPositionErrors = true,
            NATOmessages = false, --provides positions relative to the bullseye
            NATO_SectorCallsigns = false, --uses a different pool for sector callsigns
            ATISinterval = 180,
            preBriefedContacts = {
                --"Stuff",
                --"Thing",
            }, --contains the name of units placed in the ME which will be designated as pre-briefed (exact location) and who's position will be indicated exactly by Hound until the unit moved 100m away
            debug = false, --set this to true to make sure your configuration is correct and working as intended
        },
        { -- blue
            sectors = {
                --Global sector, mandatory inclusion if you want a global ATIS/controller etc., encompasses the whole map so it'll be very crowded in terms of comms
                [veafHoundElint.globalSectorName] = {
                    callsign = "Global Sector", --defines a specific callsign for the sector which will be used by the ATIS etc., if absent or nil Hound will assign it a callsign automatically, NATO format of regular Hound format. If true, callsign will be equal to the sector name
                    atis = {
                        freq = 282.175,
                        speed = 1,
                        --additional params
                        reportEWR = false
                    },
                    controller = {
                        freq = 282.225,
                        --additional params
                        voiceEnabled = true
                    },
                    notifier = {
                        freq = 282.2,
                        --additional params
                    },
                    disableAlerts = false, --disables alerts on the ATIS/Controller when a new radar is detected or destroyed
                    transmitterUnit = nil, --use the Unit/Pilot name to set who the transmitter is for the ATIS etc. This can be a static, and aircraft or a vehicule/ship
                    disableTTS = false,
                },
                --sector named "Maykop", will be geofenced to the mission editor polygon drawing (free or rectangle) called "Maykop" (case sensitive)
                ["Maykop"] = {
                    callsign = true, --defines a specific callsign for the sector which will be used by the ATIS etc., if absent or nil Hound will assign it a callsign automatically, NATO format of regular Hound format. If true, callsign will be equal to the sector name
                    atis = {
                        freq = 281.075,
                        speed = 1,
                        --additional params
                        reportEWR = false
                    },
                    controller = {
                        freq = 281.125,
                        --additional params
                        voiceEnabled = true
                    },
                    notifier = {
                        freq = 281.1,
                        --additional params
                    },
                    disableAlerts = false, --disables alerts on the ATIS/Controller when a new radar is detected or destroyed
                    transmitterUnit = nil, --use the Unit/Pilot name to set who the transmitter is for the ATIS etc. This can be a static, and aircraft or a vehicule/ship
                    disableTTS = false,
                },
            },
            --global parameters
            markers = true,
            disableBDA = false, --disables notifications that a radar has dropped off scope
            platformPositionErrors = true,
            NATOmessages= true, --provides positions relative to the bullseye
            NATO_SectorCallsigns = true, --uses a different pool for sector callsigns
            ATISinterval = 180,
            preBriefedContacts = {
                --"Stuff",
                --"Thing",
            }, --contains the name of units or groups placed in the ME which will be designated as pre-briefed (exact location) and who's position will be indicated exactly by Hound until the unit moved 100m away. If multiple radars are within a specified group, they'll all be added as pre-briefed targets
            debug = false, --set this to true to make sure your configuration is correct and working as intended
        }
        -- args = {
        --     freq = 250.000,
        --     modulation = "AM",
        --     volume = "1.0",
        --     speed = <speed> -- number default is 0/1 for controller/atis. range is -10 to +10 on windows TTS. for google it's 0.25 to 4.0
        --     gender = "male"|"female",
        --     culture = "en-US"|"en-UK" -- (any installed on your system)
        --     isGoogle = true/false -- use google TTS (requires additional STTS config)
        --     voiceEnabled = true/false (for the controller only) -- to set if the controllers uses text or TTS
        --     reportEWR = true/false (for ATIS only) -- set to tell the ATIS to report EWRs as threats
        -- }
    )
    ]]
end

-- uncomment the following lines to silence the default ATC on all the airdromes
--veaf.silenceAtcOnAllAirbases()
