@echo off
rem *** Author: T. Wittrock, Kiel ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

if %1~==~ goto NoParam
set TARGET_DIR="%~f1"
if not exist %TARGET_DIR% goto InvalidParam

rem *** Copy scripts and binaries ***
echo Copying scripts and binaries...
pushd "%~dps0"
xcopy *.* %TARGET_DIR% /E /Q /Y /EXCLUDE:exclude\ExcludeList-ReleaseTree.txt
popd

rem *** Compile AutoIt-Scripts ***
pushd %TARGET_DIR%
call "%~dps0CompileAutoItScripts.cmd"
popd
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
goto EoF

:NoParam
echo.
echo ERROR: Missing parameter %1
echo Usage: %~n0 ^<TargetDirectory^>
echo.
goto EoF

:InvalidParam
echo.
echo ERROR: Target directory %TARGET_DIR% not found.
echo Usage: %~n0 ^<TargetDirectory^>
echo.
goto EoF

:EoF
endlocal
