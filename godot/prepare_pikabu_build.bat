@echo off
setlocal
set SRC=%~dp0web\cloud.php
set DST=%~dp0..\build\pikabu\cloud.php
if not exist "%~dp0..\build\pikabu" mkdir "%~dp0..\build\pikabu"
copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 (
  echo Failed to copy cloud.php
  exit /b 1
)
echo Pikabu build prepared: %~dp0..\build\pikabu
endlocal
