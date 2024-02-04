@echo off
rem *** Author: aker ***

setlocal enabledelayedexpansion

if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set WGET_PATH=.\bin\wget64.exe) else (
  if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (set WGET_PATH=.\bin\wget64.exe) else (set WGET_PATH=.\bin\wget.exe)
)
if not exist %WGET_PATH% goto EoF

if not exist "%TEMP%\package.xml" (
  set PREEXISTING_PACKAGE_XML=0
  if not exist "%TEMP%\wsusscn2.cab" (
    set PREEXISTING_WSUSSCN2_CAB=0
    %WGET_PATH% -N -i .\static\StaticDownloadLinks-wsus.txt -P "%TEMP%"
  ) else (
    set PREEXISTING_WSUSSCN2_CAB=1
  )
  if exist "%TEMP%\package.cab" del "%TEMP%\package.cab"
  %SystemRoot%\System32\expand.exe "%TEMP%\wsusscn2.cab" -F:package.cab "%TEMP%"
  %SystemRoot%\System32\expand.exe "%TEMP%\package.cab" "%TEMP%\package.xml"
  del "%TEMP%\package.cab"
) else (
  set PREEXISTING_WSUSSCN2_CAB=1
  set PREEXISTING_PACKAGE_XML=1
)

echo Extracting revision-and-update-ids.txt ...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-revision-and-update-ids.xsl "%TEMP%\revision-and-update-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids.txt"
rem del "%TEMP%\revision-and-update-ids-unsorted.txt"

echo Extracting BundledUpdateRevisionAndFileIds.txt ...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-update-revision-and-file-ids.xsl "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt" > "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
rem del "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"

echo Extracting UpdateCabExeIdsAndLocations.txt ...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-update-cab-exe-ids-and-locations.xsl "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt" > "%TEMP%\UpdateCabExeIdsAndLocations.txt"
rem del "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"

echo Creating file-and-update-ids.txt ...
.\bin\join.exe -t "," -o "2.3,1.2" "%TEMP%\revision-and-update-ids.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" > "%TEMP%\file-and-update-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\file-and-update-ids-unsorted.txt" > "%TEMP%\file-and-update-ids.txt"
rem del "%TEMP%\revision-and-update-ids.txt"
rem del "%TEMP%\file-and-update-ids-unsorted.txt"

echo Creating update-ids-and-locations.txt ...
.\bin\join.exe -t "," -o "1.2,2.2" "%TEMP%\file-and-update-ids.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" > "%TEMP%\update-ids-and-locations-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-and-locations-unsorted.txt" > "%TEMP%\update-ids-and-locations.txt"
rem del "%TEMP%\file-and-update-ids.txt"
rem del "%TEMP%\update-ids-and-locations-unsorted.txt"

echo Creating update-ids-and-locations-all.txt ...
type "%TEMP%\update-ids-and-locations.txt" > "%TEMP%\update-ids-and-locations-all.txt"

echo Creating UpdateTable-all.csv ...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractIdsAndFileNames.vbs "%TEMP%\update-ids-and-locations-all.txt" "%TEMP%\UpdateTable-all.csv"

echo Creating DynamicDownloadLinks-all.txt ...
.\bin\cut.exe -d "," -f "2" "%TEMP%\update-ids-and-locations-all.txt" > "%TEMP%\DynamicDownloadLinks-all-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\DynamicDownloadLinks-all-unsorted.txt" > "%TEMP%\DynamicDownloadLinks-all.txt"
rem del "%TEMP%\update-ids-and-locations-all.txt"
rem del "%TEMP%\DynamicDownloadLinks-all-unsorted.txt"

echo Creating DownloadLinks-all.txt ...
move /Y "%TEMP%\DynamicDownloadLinks-all.txt" "%TEMP%\DownloadLinks-all.txt" >nul

if "%PREEXISTING_PACKAGE_XML%"=="0" if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"
if "%PREEXISTING_WSUSSCN2_CAB%"=="0" if exist "%TEMP%\wsusscn2.cab" del "%TEMP%\wsusscn2.cab"

:EoF
endlocal
