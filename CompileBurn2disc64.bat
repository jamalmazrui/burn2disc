@echo off
cls
echo Compiling
if exist burn2disc64.exe del burn2disc64.exe
"c:\Program Files (x86)\AutoIt3\Aut2Exe\aut2exe_x64.exe" /in burn2disc.au3 /out burn2disc64.exe /console
if exist burn2disc64.exe echo Done
	