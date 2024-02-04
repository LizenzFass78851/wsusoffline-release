@echo off
rem *** Author: H. Buhrmester & aker ***

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

rem *** Determine superseded updates ***
echo %TIME% - Determining superseded updates...

rem *** Revised part for determination of superseded updates starts here ***

rem *** Step 0: Files used multiple times ***

echo Extracting revision-and-update-ids.txt...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-revision-and-update-ids.xsl "%TEMP%\revision-and-update-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids.txt"
.\bin\gsort.exe -T "%TEMP%" -t "," -k 2 "%TEMP%\revision-and-update-ids-unsorted.txt" > "%TEMP%\revision-and-update-ids-inverted-unclean.txt"
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractUniqueFromSorted.vbs "%TEMP%\revision-and-update-ids-inverted-unclean.txt" "%TEMP%\revision-and-update-ids-inverted.txt"
rem del "%TEMP%\revision-and-update-ids-unsorted.txt"
rem del "%TEMP%\revision-and-update-ids-inverted-unclean.txt"

echo Extracting BundledUpdateRevisionAndFileIds.txt...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-update-revision-and-file-ids.xsl "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt" > "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
rem del "%TEMP%\BundledUpdateRevisionAndFileIds-unsorted.txt"

echo Extracting UpdateCabExeIdsAndLocations.txt...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-update-cab-exe-ids-and-locations.xsl "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt" > "%TEMP%\UpdateCabExeIdsAndLocations.txt"
rem del "%TEMP%\UpdateCabExeIdsAndLocations-unsorted.txt"

echo Extracting existing-bundle-revision-ids.txt...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-existing-bundle-revision-ids.xsl "%TEMP%\existing-bundle-revision-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\existing-bundle-revision-ids-unsorted.txt" >"%TEMP%\existing-bundle-revision-ids.txt"
rem del "%TEMP%\existing-bundle-revision-ids-unsorted.txt"

rem *** Step 1: extract RevisionIds from HideList-seconly.txt [target: revision-ids-HideList-seconly.txt] ***

if not exist .\client\exclude\HideList-seconly.txt (
  echo Creating blank revision-ids-HideList-seconly.txt...
  echo. > "%TEMP%\revision-ids-HideList-seconly.txt"
  goto SkipHideList
)

echo Creating file-and-update-ids.txt...
.\bin\join.exe -t "," -o "2.3,1.2" "%TEMP%\revision-and-update-ids.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" > "%TEMP%\file-and-update-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\file-and-update-ids-unsorted.txt" > "%TEMP%\file-and-update-ids.txt"
rem del "%TEMP%\file-and-update-ids-unsorted.txt"

echo Creating update-ids-and-locations.txt...
.\bin\join.exe -t "," -o "1.2,2.2" "%TEMP%\file-and-update-ids.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" > "%TEMP%\update-ids-and-locations-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-and-locations-unsorted.txt" > "%TEMP%\update-ids-and-locations.txt"
rem del "%TEMP%\update-ids-and-locations-unsorted.txt"

echo Creating UpdateTable-all.csv...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\ExtractIdsAndFileNames.vbs "%TEMP%\update-ids-and-locations.txt" "%TEMP%\UpdateTable-all.csv"

echo Extracting HideList-seconly-KBNumbers.txt...
.\bin\cut.exe -d "," -f "1" .\client\exclude\HideList-seconly.txt > "%TEMP%\HideList-seconly-KBNumbers.txt"

echo Creating UpdateTable-HideList-seconly.csv...
%SystemRoot%\System32\findstr.exe /L /I /G:"%TEMP%\HideList-seconly-KBNumbers.txt" "%TEMP%\UpdateTable-all.csv" > "%TEMP%\UpdateTable-HideList-seconly.csv"

echo Creating update-ids-HideList-seconly.txt...
.\bin\cut.exe -d "," -f "1" "%TEMP%\UpdateTable-HideList-seconly.csv" > "%TEMP%\update-ids-HideList-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\update-ids-HideList-seconly-unsorted.txt" > "%TEMP%\update-ids-HideList-seconly.txt"
rem del "%TEMP%\update-ids-HideList-seconly-unsorted.txt"

echo Creating revision-ids-HideList-seconly.txt...
.\bin\join.exe -t "," -1 2 -o "1.1" "%TEMP%\revision-and-update-ids-inverted.txt" "%TEMP%\update-ids-HideList-seconly.txt" > "%TEMP%\revision-ids-HideList-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\revision-ids-HideList-seconly-unsorted.txt" > "%TEMP%\revision-ids-HideList-seconly.txt"
rem del "%TEMP%\revision-ids-HideList-seconly-unsorted.txt"

rem del "%TEMP%\file-and-update-ids.txt"
rem del "%TEMP%\update-ids-and-locations.txt"
rem del "%TEMP%\HideList-seconly-KBNumbers.txt"
rem del "%TEMP%\UpdateTable-all.csv"
rem del "%TEMP%\UpdateTable-HideList-seconly.csv"
rem del "%TEMP%\update-ids-HideList-seconly.txt"

:SkipHideList

rem *** Step 2: Calculate the relations of the updates [target: ValidSupersededRevisionIds(-seconly).txt & ValidNonSupersededRevisionIds(-seconly).txt] ***

echo Extracting superseding-and-superseded-revision-ids.txt...
%SystemRoot%\System32\cscript.exe //Nologo //B //E:vbs .\cmd\XSLT.vbs "%TEMP%\package.xml" .\xslt\extract-superseding-and-superseded-revision-ids.xsl "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt" >"%TEMP%\superseding-and-superseded-revision-ids.txt"
rem del "%TEMP%\superseding-and-superseded-revision-ids-unsorted.txt"

echo Joining superseding-and-superseded-revision-ids.txt and revision-ids-HideList-seconly.txt to superseding-and-superseded-revision-ids-Rollups.txt...
.\bin\join.exe -1 1 -2 1 -t "," -o "1.1,1.2" "%TEMP%\superseding-and-superseded-revision-ids.txt" "%TEMP%\revision-ids-HideList-seconly.txt" > "%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt"

echo Creating superseding-and-superseded-revision-ids-seconly.txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt" "%TEMP%\superseding-and-superseded-revision-ids.txt" > "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt"

echo Joining existing-bundle-revision-ids.txt and superseding-and-superseded-revision-ids(-seconly).txt to ValidSupersededRevisionIds(-seconly).txt...
.\bin\join.exe -t "," -o "2.2" "%TEMP%\existing-bundle-revision-ids.txt" "%TEMP%\superseding-and-superseded-revision-ids.txt" >"%TEMP%\ValidSupersededRevisionIds-unsorted.txt"
.\bin\join.exe -t "," -o "2.2" "%TEMP%\existing-bundle-revision-ids.txt" "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt" >"%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidSupersededRevisionIds-unsorted.txt" >"%TEMP%\ValidSupersededRevisionIds.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt" >"%TEMP%\ValidSupersededRevisionIds-seconly.txt"
rem del "%TEMP%\ValidSupersededRevisionIds-unsorted.txt"
rem del "%TEMP%\ValidSupersededRevisionIds-seconly-unsorted.txt"

echo Creating ValidNonSupersededRevisionIds(-seconly).txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ValidSupersededRevisionIds.txt" "%TEMP%\existing-bundle-revision-ids.txt" > "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt"
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ValidSupersededRevisionIds-seconly.txt" "%TEMP%\existing-bundle-revision-ids.txt" > "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt" >"%TEMP%\ValidNonSupersededRevisionIds.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt" >"%TEMP%\ValidNonSupersededRevisionIds-seconly.txt"
rem del "%TEMP%\ValidNonSupersededRevisionIds-unsorted.txt"
rem del "%TEMP%\ValidNonSupersededRevisionIds-seconly-unsorted.txt"

rem del "%TEMP%\revision-ids-HideList-seconly.txt"
rem del "%TEMP%\superseding-and-superseded-revision-ids-Rollups.txt"
rem del "%TEMP%\superseding-and-superseded-revision-ids.txt"
rem del "%TEMP%\superseding-and-superseded-revision-ids-seconly.txt"

rem *** Step 3: Get the FileIds for the RevisionIds [target: OnlySupersededFileIds(-seconly).txt] ***

echo Joining ValidSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to SupersededFileIds(-seconly).txt...
.\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidSupersededRevisionIds.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\SupersededFileIds-unsorted.txt"
.\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidSupersededRevisionIds-seconly.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\SupersededFileIds-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\SupersededFileIds-unsorted.txt" >"%TEMP%\SupersededFileIds.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\SupersededFileIds-seconly-unsorted.txt" >"%TEMP%\SupersededFileIds-seconly.txt"
rem del "%TEMP%\SupersededFileIds-unsorted.txt"
rem del "%TEMP%\SupersededFileIds-seconly-unsorted.txt"

echo Joining ValidNonSupersededRevisionIds(-seconly).txt and BundledUpdateRevisionAndFileIds.txt to NonSupersededFileIds(-seconly).txt...
.\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidNonSupersededRevisionIds.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\NonSupersededFileIds-unsorted.txt"
.\bin\join.exe -t "," -o "2.3" "%TEMP%\ValidNonSupersededRevisionIds-seconly.txt" "%TEMP%\BundledUpdateRevisionAndFileIds.txt" >"%TEMP%\NonSupersededFileIds-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\NonSupersededFileIds-unsorted.txt" >"%TEMP%\NonSupersededFileIds.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\NonSupersededFileIds-seconly-unsorted.txt" >"%TEMP%\NonSupersededFileIds-seconly.txt"
rem del "%TEMP%\NonSupersededFileIds-unsorted.txt"
rem del "%TEMP%\NonSupersededFileIds-seconly-unsorted.txt"

echo Creating OnlySupersededFileIds(-seconly).txt...
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\NonSupersededFileIds.txt" "%TEMP%\SupersededFileIds.txt" >"%TEMP%\OnlySupersededFileIds-unsorted.txt"
%SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\NonSupersededFileIds-seconly.txt" "%TEMP%\SupersededFileIds-seconly.txt" >"%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\OnlySupersededFileIds-unsorted.txt" >"%TEMP%\OnlySupersededFileIds.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt" >"%TEMP%\OnlySupersededFileIds-seconly.txt"
rem del "%TEMP%\OnlySupersededFileIds-unsorted.txt"
rem del "%TEMP%\OnlySupersededFileIds-seconly-unsorted.txt"

rem del "%TEMP%\ValidSupersededRevisionIds.txt"
rem del "%TEMP%\ValidSupersededRevisionIds-seconly.txt"
rem del "%TEMP%\ValidNonSupersededRevisionIds.txt"
rem del "%TEMP%\ValidNonSupersededRevisionIds-seconly.txt"
rem del "%TEMP%\NonSupersededFileIds.txt"
rem del "%TEMP%\NonSupersededFileIds-seconly.txt"
rem del "%TEMP%\SupersededFileIds.txt"
rem del "%TEMP%\SupersededFileIds-seconly.txt"

rem *** Step 4: Get the URLs for the FileIds [target: ExcludeList-superseded-all(-seconly).txt] ***

echo Joining OnlySupersededFileIds(-seconly).txt and UpdateCabExeIdsAndLocations.txt to ExcludeList-superseded-all(-seconly).txt...
.\bin\join.exe -t "," -o "2.2" "%TEMP%\OnlySupersededFileIds.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" >"%TEMP%\ExcludeList-superseded-all-unsorted.txt"
.\bin\join.exe -t "," -o "2.2" "%TEMP%\OnlySupersededFileIds-seconly.txt" "%TEMP%\UpdateCabExeIdsAndLocations.txt" >"%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ExcludeList-superseded-all-unsorted.txt" >"%TEMP%\ExcludeList-superseded-all.txt"
.\bin\gsort.exe -u -T "%TEMP%" "%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt" >"%TEMP%\ExcludeList-superseded-all-seconly.txt"
rem del "%TEMP%\ExcludeList-superseded-all-unsorted.txt"
rem del "%TEMP%\ExcludeList-superseded-all-seconly-unsorted.txt"

rem del "%TEMP%\OnlySupersededFileIds.txt"
rem del "%TEMP%\OnlySupersededFileIds-seconly.txt"

rem *** Cleanup ***

rem del "%TEMP%\revision-and-update-ids.txt"
rem del "%TEMP%\revision-and-update-ids-inverted.txt"
rem del "%TEMP%\BundledUpdateRevisionAndFileIds.txt"
rem del "%TEMP%\UpdateCabExeIdsAndLocations.txt"
rem del "%TEMP%\existing-bundle-revision-ids.txt"

rem *** Step 5: Apply ExcludeList-superseded-exclude(-seconly).txt [target: ExcludeList-superseded(-seconly).txt] ***

if exist .\exclude\ExcludeList-superseded-exclude.txt copy /Y .\exclude\ExcludeList-superseded-exclude.txt "%TEMP%\ExcludeList-superseded-exclude.txt" >nul
if exist .\exclude\ExcludeList-superseded-exclude.txt copy /Y .\exclude\ExcludeList-superseded-exclude.txt "%TEMP%\ExcludeList-superseded-exclude-seconly.txt" >nul
if exist .\exclude\custom\ExcludeList-superseded-exclude.txt (
  type .\exclude\custom\ExcludeList-superseded-exclude.txt >>"%TEMP%\ExcludeList-superseded-exclude.txt"
  type .\exclude\custom\ExcludeList-superseded-exclude.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
for %%i in (upd1 upd2) do (
  for /F %%j in ('type .\client\static\StaticUpdateIds-w63-%%i.txt ^| find /i "kb"') do (
    echo windows8.1-%%j>>"%TEMP%\ExcludeList-superseded-exclude.txt"
    echo windows8.1-%%j>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
  )
)
if exist .\exclude\ExcludeList-superseded-exclude-seconly.txt (
  type .\exclude\ExcludeList-superseded-exclude-seconly.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
if exist .\exclude\custom\ExcludeList-superseded-exclude-seconly.txt (
  type .\exclude\custom\ExcludeList-superseded-exclude-seconly.txt >>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
)
for %%i in (w62 w63) do (
  for /F %%j in ('dir /B .\client\static\StaticUpdateIds-%%i*-seconly.txt 2^>nul') do (
    for /F "tokens=1* delims=,;" %%k in (.\client\static\%%j) do (
      echo %%k>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
    )
  )
  for /F %%j in ('dir /B .\client\static\custom\StaticUpdateIds-%%i*-seconly.txt 2^>nul') do (
    for /F "tokens=1* delims=,;" %%k in (.\client\static\custom\%%j) do (
      echo %%k>>"%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
    )
  )
)
for %%i in ("%TEMP%\ExcludeList-superseded-exclude.txt") do if %%~zi==0 del %%i
for %%i in ("%TEMP%\ExcludeList-superseded-exclude-seconly.txt") do if %%~zi==0 del %%i
if exist "%TEMP%\ExcludeList-superseded-exclude.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeList-superseded-exclude.txt" "%TEMP%\ExcludeList-superseded-all.txt" >"%TEMP%\ExcludeList-superseded.txt"
  rem del "%TEMP%\ExcludeList-superseded-exclude.txt"
) else (
  copy /Y "%TEMP%\ExcludeList-superseded-all.txt" "%TEMP%\ExcludeList-superseded.txt" >nul
)
if exist "%TEMP%\ExcludeList-superseded-exclude-seconly.txt" (
  %SystemRoot%\System32\findstr.exe /L /I /V /G:"%TEMP%\ExcludeList-superseded-exclude-seconly.txt" "%TEMP%\ExcludeList-superseded-all-seconly.txt" >"%TEMP%\ExcludeList-superseded-seconly.txt"
  rem del "%TEMP%\ExcludeList-superseded-exclude-seconly.txt"
) else (
  copy /Y "%TEMP%\ExcludeList-superseded-all-seconly.txt" "%TEMP%\ExcludeList-superseded-seconly.txt" >nul
)

rem del "%TEMP%\ExcludeList-superseded-all.txt"
rem del "%TEMP%\ExcludeList-superseded-all-seconly.txt"

rem *** Completed ***

echo %TIME% - Done.
if "%PREEXISTING_PACKAGE_XML%"=="0" if exist "%TEMP%\package.xml" del "%TEMP%\package.xml"
goto EoF

if "%PREEXISTING_WSUSSCN2_CAB%"=="0" if exist "%TEMP%\wsusscn2.cab" del "%TEMP%\wsusscn2.cab"
:EoF
endlocal
