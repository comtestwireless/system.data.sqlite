@ECHO OFF

SETLOCAL

SET MYDIR=%~dp0
SET REGROOT=SOFTWARE\Microsoft\VisualStudio\8.0
SET XMLPATH=%MYDIR%

:ParseCmdLine

IF "%1"=="" GOTO Main
IF "%1"=="/regroot" IF NOT "%~2"=="" SET REGROOT=%~2& SHIFT & GOTO NextCmdLine
IF "%1"=="/xmlpath" IF NOT "%~2"=="" SET XMLPATH=%~f2& SHIFT & GOTO NextCmdLine
IF "%1"=="/?" GOTO Help
GOTO Help

:NextCmdLine

SHIFT
GOTO ParseCmdLine

:Main

ECHO Installing DDEX Data Provider for SQLite
ECHO   VS Registry Root: %REGROOT%
ECHO   XML File Path:    %XMLPATH%
ECHO   SQLite.DLL Path:  %MYDIR%..\

IF NOT EXIST "%XMLPATH%\SQLiteDataViewSupport.xml" ECHO The data view support XML file was not found.& GOTO End
IF NOT EXIST "%XMLPATH%\SQLiteDataObjectSupport.xml" ECHO The data object support XML file was not found.& GOTO End
IF NOT EXIST "..\System.Data.SQLite.DLL" ECHO The ..\System.Data.SQLite.DLL could not be found.& GOTO End

CScript //D "%MYDIR%\Install.vbs" //NoLogo "%REGROOT%" "%XMLPATH%"

GOTO End

:Help

ECHO DDEX Data Provider for SQLite Installation
ECHO   Usage: install [/?] [/regroot ^<regroot^>] [/xmlpath ^<xmlpath^>]

:End

ECHO Done!

ENDLOCAL
