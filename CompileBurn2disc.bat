@echo off
cls
echo Compiling
if exist burn2disc.exe del burn2disc.exe
"c:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe" /in burn2disc.au3 /console
if exist burn2disc.exe echo Done
