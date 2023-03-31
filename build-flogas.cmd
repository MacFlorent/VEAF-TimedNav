@echo off
set NOPAUSE=true
set VERBOSE_LOG_FLAG=true

::set LUA_SCRIPTS_DEBUG_PARAMETER=-trace
::set SECURITY_DISABLED_FLAG=false
::set DYNAMIC_SCRIPTS_PATH="d:\dev\_VEAF\VEAF-Mission-Creation-Tools"
call build.cmd
copy build\*.miz .
copy build\*.miz "C:\Users\flore\Saved Games\DCS Missions\VeafMissions"
pause