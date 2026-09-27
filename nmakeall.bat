@echo off
echo Au nmakeall.bat Started
time /t

rem Configure environment variables.
if not defined SEIDEV (
    echo Error: SEIDEV must identify the development folder.
    exit /b 1
)
if not "%AUARCH%" == "soh-win64" if not "%AUARCH%" == "soh-win32" (
    echo Error: AUARCH must be soh-win64 or soh-win32.
    exit /b 1
)
cd /d "%~dp0" || goto :build_failed
call auenv.bat || goto :build_failed

rem Build base level libraries.
echo ==================== auutil ====================
cd auutil || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumath ====================
cd ..\aumath || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== augl ====================
cd ..\augl || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auglobal ====================
cd ..\auglobal || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== audata ====================
cd ..\audata || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auloginclient ====================
cd ..\auloginclient || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumail ====================
cd ..\aumail || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatom ====================
cd ..\auatom || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auclient ====================
cd ..\auclient || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== audesigner ====================
cd ..\audesigner || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

echo ==================== austoryres ====================
cd ..\austoryres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build client resources libraries, which is a bunch of libs linked into a big dll.
echo ==================== auclientmailres ====================
cd ..\auclientmailres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auclientres1 ====================
cd ..\auclientres1 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auclientres ====================
cd ..\auclientres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build atom resources library, which is a bunch of libs linked into a big dll.
echo ==================== auatomr1 ====================
cd ..\auatomr1 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomr2 ====================
cd ..\auatomr2 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomr3 ====================
cd ..\auatomr3 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomr4 ====================
cd ..\auatomr4 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomr5 ====================
cd ..\auatomr5 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomr6 ====================
cd ..\auatomr6 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auatomres ====================
cd ..\auatomres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build body parts resources library, which is a bunch of libs linked into a big dll.
echo ==================== aubodyparts0 ====================
cd ..\aubodyparts0 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts1 ====================
cd ..\aubodyparts1 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts2 ====================
cd ..\aubodyparts2 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts3 ====================
cd ..\aubodyparts3 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts4 ====================
cd ..\aubodyparts4 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts5 ====================
cd ..\aubodyparts5 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts6 ====================
cd ..\aubodyparts6 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodyparts7 ====================
cd ..\aubodyparts7 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aupowerarmor ====================
cd ..\aupowerarmor || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aubodypartsres ====================
cd ..\aubodypartsres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build model resources library, which is a bunch of libs linked into a big dll.
echo ==================== aumodel1 ====================
cd ..\aumodel1 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel2 ====================
cd ..\aumodel2 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel3 ====================
cd ..\aumodel3 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel4 ====================
cd ..\aumodel4 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel5 ====================
cd ..\aumodel5 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel6 ====================
cd ..\aumodel6 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel7 ====================
cd ..\aumodel7 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel8 ====================
cd ..\aumodel8 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel9 ====================
cd ..\aumodel9 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodel10 ====================
cd ..\aumodel10 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumodelres ====================
cd ..\aumodelres || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build texture resources library, which is a bunch of libs linked into a big dll.
echo ==================== ausctex1 ====================
cd ..\ausctex1 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== ausctex2 ====================
cd ..\ausctex2 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== ausctex3 ====================
cd ..\ausctex3 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== ausctex4 ====================
cd ..\ausctex4 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== ausctex5 ====================
cd ..\ausctex5 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aushiptex0 ====================
cd ..\aushiptex0 || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== autexture ====================
cd ..\autexture || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed

rem Build client programs.
echo ==================== ausceneclient ====================
cd ..\ausceneclient || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== auchatclient ====================
cd ..\auchatclient || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aulauncher ====================
cd ..\aulauncher || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
echo ==================== aumailclient ====================
cd ..\aumailclient || goto :build_failed
call reqtr.bat || goto :build_failed
nmake /NOLOGO /f Makefile.Release || goto :build_failed
rem echo ==================== auscript ====================
rem cd ..\auscript
rem call reqtr.bat
rem nmake /NOLOGO /f Makefile.Release
cd .. || goto :build_failed

rem Build launcher distribution.
echo Copying launcher output to ShoresOfHazeron folder.
if not exist "..\ShoresOfHazeron\" (mkdir "..\ShoresOfHazeron" || goto :build_failed)
echo aulauncher.exe
copy /B /Y release\aulauncher.exe "..\ShoresOfHazeron\Hazeron Launcher.exe" || goto :build_failed
echo %AUARCH% > ..\ShoresOfHazeron\data.bin || goto :build_failed
cd ..\ShoresOfHazeron || goto :build_failed
windeployqt "Hazeron Launcher.exe" || goto :build_failed

rem Build game package files for download by launcher.
cd ..\au || goto :build_failed
echo Copying package output to %AUARCH% folder.
if not exist "..\%AUARCH%\" (mkdir "..\%AUARCH%" || goto :build_failed)
if not exist "..\%AUARCH%\tex\" (mkdir "..\%AUARCH%\tex" || goto :build_failed)
if not exist "..\%AUARCH%\Blueprints\" (mkdir "..\%AUARCH%\Blueprints" || goto :build_failed)
if not exist "..\%AUARCH%\Blueprints\Buildings\" (mkdir "..\%AUARCH%\Blueprints\Buildings" || goto :build_failed)
if not exist "..\%AUARCH%\Blueprints\Spacecraft\" (mkdir "..\%AUARCH%\Blueprints\Spacecraft" || goto :build_failed)
echo Building Blueprints
copy /B /Y Blueprints\Buildings\*.SoH ..\%AUARCH%\Blueprints\Buildings || goto :build_failed
echo Spacecraft Blueprints
copy /B /Y Blueprints\Spacecraft\*.SoH ..\%AUARCH%\Blueprints\Spacecraft || goto :build_failed
echo sfx
copy /B /Y auglobal\sfx\sfx.har ..\%AUARCH% || goto :build_failed
echo tex
copy /B /Y autexture\data\*.png ..\%AUARCH%\tex || goto :build_failed
echo SDL2.dll
copy /B /Y "%SEIDEV%\SDL2-2.0.3\VisualC\SDL\%AUDEVSDL%\Release\SDL2.dll" ..\%AUARCH% || goto :build_failed
echo GD
copy /B /Y GD ..\%AUARCH% || goto :build_failed
echo aumailclient.exe
copy /B /Y release\aumailclient.exe "..\%AUARCH%\Hazeron Mail.exe" || goto :build_failed
echo ausceneclient.exe
copy /B /Y release\ausceneclient.exe "..\%AUARCH%\Shores of Hazeron.exe" || goto :build_failed
echo auchatclient.exe
copy /B /Y release\auchatclient.exe "..\%AUARCH%\Hazeron Commander.exe" || goto :build_failed
rem copy /B /Y release\auscript.exe ..\%AUARCH%\AuScript.exe
rem copy /B /Y auscript\AuScript.bin ..\%AUARCH%\AuScript.bin
rem copy /B /Y auscript\AuScript.txt ..\%AUARCH%\AuScript.txt
echo auatomres7.dll
copy /B /Y release\auatomres7.dll ..\%AUARCH%\AuAtomRes7.dll || goto :build_failed
echo aubodypartsres7.dll
copy /B /Y release\aubodypartsres7.dll ..\%AUARCH%\AuBodyPartsRes7.dll || goto :build_failed
echo auclientmailres7.dll
copy /B /Y release\auclientmailres7.dll ..\%AUARCH%\AuClientMailRes7.dll || goto :build_failed
echo auclientres7.dll
copy /B /Y release\auclientres7.dll ..\%AUARCH%\AuClientRes7.dll || goto :build_failed
echo aumodelres7.dll
copy /B /Y release\aumodelres7.dll ..\%AUARCH%\AuModelRes7.dll || goto :build_failed
echo austoryres7.dll
copy /B /Y release\austoryres7.dll ..\%AUARCH%\AuStoryRes7.dll || goto :build_failed
echo autexture7.dll
copy /B /Y release\autexture7.dll ..\%AUARCH%\AuTexture7.dll || goto :build_failed
cd ..\%AUARCH% || goto :build_failed
windeployqt --sql "Shores of Hazeron.exe" || goto :build_failed
windeployqt "Hazeron Mail.exe" || goto :build_failed
windeployqt --sql "Hazeron Commander.exe" || goto :build_failed

rem Wave goodbye.
cd ..\au || goto :build_failed
echo Au nmakeall.bat Done
time /t
exit /b 0

:build_failed
set "AU_BUILD_ERROR=%errorlevel%"
if "%AU_BUILD_ERROR%" == "0" set "AU_BUILD_ERROR=1"
echo Au nmakeall.bat FAILED in "%CD%" with exit code %AU_BUILD_ERROR%.
exit /b %AU_BUILD_ERROR%
