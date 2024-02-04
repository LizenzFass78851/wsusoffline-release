@echo off
rem *** Author: T. Wittrock, Kiel ***
rem ***   - Community Edition -   ***

verify other 2>nul
setlocal enableextensions
if errorlevel 1 goto NoExtensions

if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set AUT2EXE_EXE=Aut2exe_x64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set AUT2EXE_EXE=Aut2exe_x64.exe) else (set AUT2EXE_EXE=Aut2Exe.exe)
)

echo Compiling AutoIt-Scripts...
for %%i in (UpdateGenerator.au3 client\UpdateInstaller.au3) do "%~dps0bin\%AUT2EXE_EXE%" /in "%%i" /icon "%~dps0ico\okshield.ico" /x86 /comp 0 /nopack
goto EoF

:NoExtensions
echo.
echo ERROR: No command extensions available.
echo.
goto EoF

:EoF
endlocal
