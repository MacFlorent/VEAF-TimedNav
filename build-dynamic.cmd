@echo off
set NOPAUSE=true
set VERBOSE_LOG_FLAG=true
set LUA_SCRIPTS_DEBUG_PARAMETER=-trace
set SECURITY_DISABLED_FLAG=true
set DYNAMIC_SCRIPTS_PATH=D:\Projects\DcsLua\VEAF-Mission-Creation-Tools\
set DYNAMIC_LOAD_SCRIPTS=true
set MISSION_FILE_SUFFIX1=dynamic
call build.cmd
copy build\*.miz .
pause