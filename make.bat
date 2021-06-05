@echo off
set appname=espprobe
set source=sjasmpl

if EXIST %appname%.exe (
	del %appname%.exe
)
tools\sjasmplus\sjasmplus.exe %source%.asm --lst=%appname%.lst
if errorlevel 1 goto ERR
echo Ok!
goto END

:ERR
del %appname%.exe
pause
echo Some errors occured...
pause
goto END

:END
