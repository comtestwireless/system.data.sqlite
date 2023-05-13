@ECHO OFF

::
:: set_user_mistachkin_Debug.bat --
::
:: Custom Per-User Debug Build Settings
::
:: Written by Joe Mistachkin.
:: Released to the public domain, use at your own risk!
::

REM
REM NOTE: Enables the extra debug code helpful in troubleshooting issues.
REM
SET MSBUILD_ARGS=/property:CheckState=true
SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:InteropLog=false
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:CountHandle=true
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:TraceConnection=true
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:TraceDetection=true
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:TraceHandle=true
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:TraceStatement=true
REM SET MSBUILD_ARGS=%MSBUILD_ARGS% /property:TrackMemoryBytes=true
