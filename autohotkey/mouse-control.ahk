#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Speed = 0
Offset = 20

NumpadDiv::
Click
return

NumpadAdd::
Click, 2
return

NumpadSub::
Click, Right
return

$F23::
Send {WheelUp}
Sleep, 75
return

$F24::
Send {WheelDown}
Sleep, 75
return

Numpad8::
MouseMove, 0, (Offset * -1), Speed, R
return

Numpad7::
MouseMove, (Offset * -1), (Offset * -1), Speed, R
return

Numpad9::
MouseMove, Offset, (Offset * -1), Speed, R
return

Numpad2::
MouseMove, 0, Offset, Speed, R
return

Numpad1::
MouseMove, (Offset * -1), Offset, Speed, R
return

Numpad3::
MouseMove, Offset, Offset, Speed, R
return

Numpad4::
MouseMove, (Offset * -1), 0, Speed, R
return

Numpad6::
MouseMove, Offset, 0, Speed, R
return

Numpad5::
Click, Down
return

Numpad0::
Click, Up
return

NumpadMult::
Send {MButton}
return
