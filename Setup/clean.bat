@ECHO OFF

::
:: clean.bat --
::
:: Build Cleaning Tool
::
:: Written by Joe Mistachkin.
:: Released to the public domain, use at your own risk!
::

SETLOCAL

REM SET __ECHO=ECHO
REM SET __ECHO2=ECHO
REM SET __ECHO3=ECHO
IF NOT DEFINED _AECHO (SET _AECHO=REM)
IF NOT DEFINED _CECHO (SET _CECHO=REM)
IF NOT DEFINED _CECHO3 (SET _CECHO3=REM)
IF NOT DEFINED _VECHO (SET _VECHO=REM)

CALL :fn_UnsetVariable BREAK

%_AECHO% Running %0 %*

SET DUMMY2=%1

IF DEFINED DUMMY2 (
  GOTO usage
)

SET SOURCE=%~dp0\..
SET SOURCE=%SOURCE:\\=\%

%_VECHO% Source = '%SOURCE%'

IF NOT DEFINED TEMP (
  ECHO The TEMP environment variable must be set first.
  GOTO usage
)

%_VECHO% Temp = '%TEMP%'

IF NOT EXIST "%TEMP%" (
  ECHO The TEMP directory, "%TEMP%", does not exist.
  GOTO usage
)

IF DEFINED CLEANDIRS GOTO skip_cleanDirs

SET CLEANDIRS=.vs bin obj Doc\Output Setup\Output
SET CLEANDIRS=%CLEANDIRS% SQLite.Designer\bin SQLite.Designer\obj
SET CLEANDIRS=%CLEANDIRS% SQLite.Interop\bin SQLite.Interop\obj
SET CLEANDIRS=%CLEANDIRS% System.Data.SQLite\bin System.Data.SQLite\obj
SET CLEANDIRS=%CLEANDIRS% System.Data.SQLite.Linq\bin System.Data.SQLite.Linq\obj
SET CLEANDIRS=%CLEANDIRS% test\bin test\obj testce\bin testce\obj testlinq\bin
SET CLEANDIRS=%CLEANDIRS% testlinq\obj tools\install\bin tools\install\obj

:skip_cleanDirs

%_VECHO% CleanDirs = '%CLEANDIRS%'

CALL :fn_ResetErrorLevel

%_AECHO%.

FOR %%D IN (%CLEANDIRS%) DO (
  IF EXIST "%SOURCE%\%%D" (
    %__ECHO% RMDIR /S /Q "%SOURCE%\%%D"

    IF ERRORLEVEL 1 (
      ECHO Could not remove directory "%SOURCE%\%%D".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Removed directory "%SOURCE%\%%D".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% Directory "%SOURCE%\%%D" does not exist.
    %_AECHO%.
  )
)

IF EXIST "%SOURCE%\*.cache" (
  REM
  REM NOTE: *WARNING* Deleting from the entire source tree.
  REM
  %__ECHO% DEL /S /Q "%SOURCE%\*.cache"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.cache".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.cache".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.cache" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.ncb" (
  REM
  REM NOTE: *WARNING* Deleting from the entire source tree.
  REM
  %__ECHO% DEL /S /Q "%SOURCE%\*.ncb"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.ncb".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.ncb".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.ncb" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.psess" (
  %__ECHO% DEL /Q "%SOURCE%\*.psess"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.psess".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.psess".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.psess" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.sdf" (
  %__ECHO% DEL /Q "%SOURCE%\*.sdf"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.sdf".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.sdf".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.sdf" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.suo" (
  REM
  REM NOTE: *WARNING* Unhiding in the entire source tree.
  REM
  %__ECHO% ATTRIB -H "%SOURCE%\*.suo" /S

  IF ERRORLEVEL 1 (
    ECHO Could not make "%SOURCE%\*.suo" visible.
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Made "%SOURCE%\*.suo" visible.
    %_AECHO%.
  )

  REM
  REM NOTE: *WARNING* Deleting from the entire source tree.
  REM
  %__ECHO% DEL /S /Q "%SOURCE%\*.suo"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.suo".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.suo".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.suo" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.vsp" (
  %__ECHO% DEL /Q "%SOURCE%\*.vsp"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.vsp".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.vsp".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.vsp" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.vsps" (
  %__ECHO% DEL /Q "%SOURCE%\*.vsps"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.vsps".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.vsps".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.vsps" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\*.nupkg" (
  %__ECHO% DEL /Q "%SOURCE%\*.nupkg"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\*.nupkg".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\*.nupkg".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\*.nupkg" exist.
  %_AECHO%.
)

IF EXIST "%SOURCE%\Doc\SQLite.NET.chw" (
  %__ECHO% DEL /Q "%SOURCE%\Doc\SQLite.NET.chw"

  IF ERRORLEVEL 1 (
    ECHO Could not delete "%SOURCE%\Doc\SQLite.NET.chw".
    ECHO.
    GOTO errors
  ) ELSE (
    %_AECHO% Deleted "%SOURCE%\Doc\SQLite.NET.chw".
    %_AECHO%.
  )
) ELSE (
  %_AECHO% No files matching "%SOURCE%\Doc\SQLite.NET.chw" exist.
  %_AECHO%.
)

FOR %%D IN (net5 net6 netCore20 netCore30 netFramework40) DO (
  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\EntityFramework.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\EntityFramework.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\EntityFramework.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\EntityFramework.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\EntityFramework.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\sqlite3.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\sqlite3.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\sqlite3.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\sqlite3.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\sqlite3.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\Win32\sqlite3.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\Win32\sqlite3.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\Win32\sqlite3.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\Win32\sqlite3.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\Win32\sqlite3.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\x86\sqlite3.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\x86\sqlite3.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\x86\sqlite3.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\x86\sqlite3.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\x86\sqlite3.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\x64\sqlite3.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\x64\sqlite3.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\x64\sqlite3.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\x64\sqlite3.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\x64\sqlite3.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\SQLite.Interop.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\SQLite.Interop.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\SQLite.Interop.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\SQLite.Interop.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\SQLite.Interop.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\Win32\SQLite.Interop.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\Win32\SQLite.Interop.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\Win32\SQLite.Interop.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\Win32\SQLite.Interop.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\Win32\SQLite.Interop.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\x86\SQLite.Interop.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\x86\SQLite.Interop.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\x86\SQLite.Interop.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\x86\SQLite.Interop.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\x86\SQLite.Interop.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\x64\SQLite.Interop.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\x64\SQLite.Interop.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\x64\SQLite.Interop.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\x64\SQLite.Interop.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\x64\SQLite.Interop.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.Linq.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.Linq.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.Linq.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.Linq.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.Linq.*" exist.
    %_AECHO%.
  )

  IF EXIST "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.EF6.*" (
    %__ECHO% DEL /Q "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.EF6.*"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.EF6.*".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.EF6.*".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%SOURCE%\Externals\Eagle\bin\%%D\System.Data.SQLite.EF6.*" exist.
    %_AECHO%.
  )
)

IF DEFINED NOLKG GOTO clean_allTestLogs
IF NOT DEFINED LKG GOTO clean_allTestLogs

SET SRCLKGDIR=%SOURCE%\Externals\Eagle\bin\netFramework40
SET SRCLKGDIR=%SRCLKGDIR:\\=\%

%_VECHO% SrcLkgDir = '%SRCLKGDIR%'

IF NOT EXIST "%SRCLKGDIR%\EagleShell.exe" (
  ECHO The file "%SRCLKGDIR%\EagleShell.exe" does not exist.
  GOTO usage
)

%__ECHO% "%SRCLKGDIR%\EagleShell.exe" /? > NUL 2>&1

IF ERRORLEVEL 1 (
  ECHO The "%SRCLKGDIR%\EagleShell.exe" tool appears to be missing.
  GOTO usage
)

%_AECHO% Using LKG "EagleShell.exe" tool from "%SRCLKGDIR%"...

CALL :fn_AppendToPath SRCLKGDIR

%_VECHO% Path = '%PATH%'

REM
REM BUGFIX: Do not attempt to delete a log file that is currently in use by
REM         a running test suite as that can cause spurious failures of the
REM         test suite due to a missing test log start sentry.
REM
SETLOCAL EnableDelayedExpansion
FOR %%E IN (%TESTEXEFILES%) DO (
  SET PATTERN=%%E
  SET PATTERN=!PATTERN:__=*!

  FOR /F "delims=" %%F IN ('DIR /B /S "%TEMP%\!PATTERN!.test.*.log" 2^> NUL') DO (
    CALL :fn_UnsetVariable SHOULD_DELETE_FILE

    CALL :fn_CheckTestLogFile "!PATTERN!" "%%F"
    IF ERRORLEVEL 1 GOTO errors

    IF DEFINED SHOULD_DELETE_FILE (
      %__ECHO% DEL /Q "%%F"

      IF ERRORLEVEL 1 (
        ECHO Could not delete "%%F".
        ECHO.
        GOTO errors
      ) ELSE (
        %_AECHO% Deleted "%%F".
        %_AECHO%.
      )

      %__ECHO% RMDIR "%%~dpF" 2>NUL

      IF ERRORLEVEL 1 (
        ECHO WARNING: Could not remove "%%~dpF".
        ECHO.
      ) ELSE (
        %_AECHO% Removed "%%~dpF".
        %_AECHO%.
      )
    ) ELSE (
      %_AECHO% Skipping "%%F", in use by active test suite.
      %_AECHO%.
    )
  )
)
ENDLOCAL

IF EXIST "%TEMP%\logs" (
  %__ECHO% RMDIR "%TEMP%\logs" 2>NUL

  IF ERRORLEVEL 1 (
    ECHO WARNING: Could not remove "%TEMP%\logs".
    ECHO.
  ) ELSE (
    %_AECHO% Removed "%TEMP%\logs".
    %_AECHO%.
  )
)

GOTO skip_allTestLogs

:clean_allTestLogs

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\dotnet.exe.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\dotnet.exe.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\dotnet.exe.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\dotnet.exe.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\dotnet.exe.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\dotnet.exe.test.*.log".
  %_AECHO%.
)

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\EagleShell.dll.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\EagleShell.dll.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\EagleShell.dll.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\EagleShell.dll.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\EagleShell.dll.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\EagleShell.dll.test.*.log".
  %_AECHO%.
)

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\EagleShell.exe.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\EagleShell.exe.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\EagleShell.exe.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\EagleShell.exe.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\EagleShell.exe.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\EagleShell.exe.test.*.log".
  %_AECHO%.
)

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\EagleShell32.exe.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\EagleShell32.exe.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\EagleShell32.exe.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\EagleShell32.exe.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\EagleShell32.exe.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\EagleShell32.exe.test.*.log".
  %_AECHO%.
)

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\mono.exe.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\mono.exe.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\mono.exe.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\mono.exe.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\mono.exe.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\mono.exe.test.*.log".
  %_AECHO%.
)

IF NOT DEFINED NOTESTLOGS (
  IF EXIST "%TEMP%\tclsh*.exe.test.*.log" (
    %__ECHO% DEL /S /Q "%TEMP%\tclsh*.exe.test.*.log"

    IF ERRORLEVEL 1 (
      ECHO Could not delete "%TEMP%\tclsh*.exe.test.*.log".
      ECHO.
      GOTO errors
    ) ELSE (
      %_AECHO% Deleted "%TEMP%\tclsh*.exe.test.*.log".
      %_AECHO%.
    )
  ) ELSE (
    %_AECHO% No files matching "%TEMP%\tclsh*.exe.test.*.log" exist.
    %_AECHO%.
  )
) ELSE (
  %_AECHO% Skipped deleting "%TEMP%\tclsh*.exe.test.*.log".
  %_AECHO%.
)

:skip_allTestLogs

GOTO no_errors

:fn_ResetErrorLevel
  VERIFY > NUL
  GOTO :EOF

:fn_SetErrorLevel
  VERIFY MAYBE 2> NUL
  GOTO :EOF

:fn_AppendToPath
  IF NOT DEFINED %1 GOTO :EOF
  SETLOCAL
  SET __ECHO_CMD=ECHO %%%1%%
  FOR /F "delims=" %%V IN ('%__ECHO_CMD%') DO (
    SET VALUE=%%V
  )
  SET VALUE=%VALUE:"=%
  REM "
  ENDLOCAL && SET PATH=%PATH%;%VALUE%
  GOTO :EOF

:fn_UnsetVariable
  SETLOCAL
  SET VALUE=%1
  IF DEFINED VALUE (
    SET VALUE=
    ENDLOCAL
    SET %VALUE%=
  ) ELSE (
    ENDLOCAL
  )
  CALL :fn_ResetErrorLevel
  GOTO :EOF

:fn_UnquoteVariable
  IF NOT DEFINED %1 GOTO :EOF
  SETLOCAL
  SET __ECHO_CMD=ECHO %%%1%%
  FOR /F "delims=" %%V IN ('%__ECHO_CMD%') DO (
    SET VALUE=%%V
  )
  SET VALUE=%VALUE:"=%
  REM "
  ENDLOCAL && SET %1=%VALUE%
  GOTO :EOF

:fn_CheckTestLogFile
  SET EXEFILENAME=%1
  IF NOT DEFINED EXEFILENAME (
    ECHO Cannot check log file, missing EXE file name.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  SET LOGFILENAME=%2
  IF NOT DEFINED LOGFILENAME (
    ECHO Cannot check log file, missing LOG file name.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  CALL :fn_UnquoteVariable EXEFILENAME
  CALL :fn_UnquoteVariable LOGFILENAME
  SET CHECK_TESTLOGFILE_CMD=EagleShell.exe -evaluate "catch {maybeForceUseLatestTestPackage}; package require Eagle.Test; checkActiveTestLogFile {%EXEFILENAME%} {%LOGFILENAME%}"
  IF NOT DEFINED __ECHO GOTO exec_checkTestLogFileCmd
  %__ECHO% %CHECK_TESTLOGFILE_CMD%
  GOTO :EOF
  :exec_checkTestLogFileCmd
  IF EXIST fn_CheckTestLogFile.err DEL /Q fn_CheckTestLogFile.err
  %_CECHO% %CHECK_TESTLOGFILE_CMD%
  FOR /F %%T IN ('%CHECK_TESTLOGFILE_CMD% ^|^| ECHO 1 ^>^> fn_CheckTestLogFile.err') DO (
    SET SHOULD_DELETE_FILE=%%T
  )
  IF EXIST fn_CheckTestLogFile.err (
    DEL /Q fn_CheckTestLogFile.err
    ECHO Failed to check log file.
    CALL :fn_SetErrorLevel
    GOTO :EOF
  )
  GOTO :EOF

:usage
  ECHO.
  ECHO Usage: %~nx0
  ECHO.
  ECHO The TEMP environment variable must be set to the full path of the existing
  ECHO directory used to store temporary files.
  GOTO errors

:errors
  CALL :fn_SetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Clean failure, errors were encountered.
  GOTO end_of_file

:no_errors
  CALL :fn_ResetErrorLevel
  ENDLOCAL
  ECHO.
  ECHO Clean success, no errors were encountered.
  GOTO end_of_file

:end_of_file
%__ECHO% EXIT /B %ERRORLEVEL%
