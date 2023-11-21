-- THIS IS THE MAIN TABLE OF FLIGHT PLAN WAYPOINTS. 
-- DEFINE THE WAYPOINTS HERE AND REFER TO THEN LATER IN THE FILE
--
-- THIS SHOULD BE THE ONLY PART OF THIS FILE YOU'LL NEED TO CHANGE IF YOU ONLY CHANGE THE WAYPOINTS
-- TO ADD OR CHANGE AIRCRAFT AND COALITION TEMPLATES, SEE FURTHER BELOW
waypoints =
{
    ["BULLSEYE"] = {
        ["type"] = "Turning Point",
        ["action"] = "Turning Point",
        ["alt"] = 6096, -- 20000 ft
        ["alt_type"] = "BARO",
        ["ETA"] = 364.89432745775,
        ["ETA_locked"] = false,
        ["speed"] = 999,
        ["speed_locked"] = true,
        ["name"] = "BULLSEYE",
        ["x"] = 75869,
        ["y"] = 48674,
    }, -- end of [BULLSEYE]
    ["START"] = {
        ["type"] = "Turning Point",
        ["action"] = "Turning Point",
        ["alt"] = 2430, -- 8000 ft
        ["alt_type"] = "BARO",
        ["ETA"] = 364.89432745775,
        ["ETA_locked"] = false,
        ["speed"] = 999,
        ["speed_locked"] = true,
        ["name"] = "START",
        ["x"] = 211038,
        ["y"] = 41192,
    }, -- end of [START]
    ["REFUEL"] = {
        ["type"] = "Turning Point",
        ["action"] = "Turning Point",
        ["alt"] = 2430, -- 8000 ft
        ["alt_type"] = "BARO",
        ["ETA"] = 364.89432745775,
        ["ETA_locked"] = false,
        ["speed"] = 999,
        ["speed_locked"] = true,
        ["name"] = "REFUEL",
        ["x"] = -114740,
        ["y"] = 86388,
    }, -- end of [REFUEL]
}

-- THIS IS THE TABLE OF flightPlan settings. 
-- MAKE USE OF THE WAYPOINTS  DEFINED EARLIER IF YOU WANT
-- BY SETTING THE VALUE OF THE type, coalition, AND country PARAMETERS, YOU CAN TARGET A TEMPLATE TO A SPECIFIC GROUP OF AIRCRAFTS
settings =
{
    ["all blue planes"] =
    {
        category = "plane",
        coalition = "blue",
        type = nil,
        country = nil,

        ["waypoints"] =
        {
            ["START"] = "START",
            ["REFUEL"] = "REFUEL",
        }, -- end of ["waypoints"]
    },

    ["all blue helicopters"] =
    {
        category = "helicopter",
        coalition = "blue",
        type = nil,
        country = nil,

        ["waypoints"] =
        {
            --["BULLSEYE"] = "BULLSEYE",
        }, -- end of ["waypoints"]
    },
}
