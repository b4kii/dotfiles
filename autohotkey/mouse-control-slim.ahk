#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

F18::
Click, Down
return

F19::
Click, Up
return

F20::
Click
return

F21::
Send {MButton}
return

F22::
Click, Right
return
 
$F23::
Send {WheelUp}
return

$F24::
Send {WheelDown}
return