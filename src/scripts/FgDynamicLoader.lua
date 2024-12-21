--FgMissionDevPath = [[D:\Projects\DcsMissions\FlogasMissions\Training Supercarrier\]]
--assert(loadfile(MissionDevPath .. "DynamicLoader.lua"))()

local scriptsToLoad =
{
    "Moose.lua",
    "FgTools.lua",
    --"FgWeather.lua",
    "FgRfgDb.lua",
    "FgRfg.lua",
    "FgTn.lua",
    "Mission.lua"
}

local sMissionScriptsPath = nil
if (VEAF_DYNAMIC_MISSIONPATH) then
    sMissionScriptsPath=VEAF_DYNAMIC_MISSIONPATH .. [[src\scripts\]]
elseif (FgMissionDevPath) then
    sMissionScriptsPath = FgMissionDevPath .. [[scripts\]]
    -- if (sMissionScriptsPath:sub(-1) ~= [[\]]) then
    --     sMissionScriptsPath = sMissionScriptsPath .. [[\]]
    -- end
end

if (sMissionScriptsPath) then
    for _, script in pairs(scriptsToLoad) do
        local sPathToExec = sMissionScriptsPath .. script
        env.info("FG DYN LOADER >> Loading " .. sPathToExec)
        assert(loadfile(sPathToExec))()

        if (Fg) then
            Fg.LogLevel = Fg.LogLevels.Debug
        end
    end
end