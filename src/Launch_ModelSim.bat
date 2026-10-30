@echo off
where vsim.exe >nul 2>&1
if errorlevel 1 (
    echo Start ModelSim manually, or add the folder containing vsim.exe to PATH.
    echo In the ModelSim Transcript, run: do src/runlab.do
    pause
    exit /b 1
)
start "" /D "%~dp0.." vsim.exe
