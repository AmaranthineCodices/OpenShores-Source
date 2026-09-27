@echo off
setlocal

set "SEiDEV=C:\HazeronDev"
set "AUARCH=soh-win64"
set "QTDIR=C:\HazeronDev\Qt5.7.0\5.7\msvc2015_64"

echo Configuring Visual Studio 2026 x64 build environment.
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64 10.0.19041.0
if errorlevel 1 exit /b 1

set "PATH=%QTDIR%\bin;C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64;%PATH%"

echo Checking Qt.
qmake -v
if errorlevel 1 exit /b 1

cd /d "%SEiDEV%\au"
if errorlevel 1 exit /b 1

call nmakeall.bat
exit /b %errorlevel%