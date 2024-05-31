#Persistent
#NoEnv
#SingleInstance force

; Set the initial speed for mouse movement
speed := 1

; Function to reset speed
ResetSpeed() {
    global speed
    speed := 1
}

; Function to handle mouse movement with acceleration
MoveMouse(x, y) {
    global speed
    DllCall("mouse_event", "UInt", 1, "Int", x * speed, "Int", y * speed, "UInt", 0, "UInt", 0)
    speed := Min(speed + 2, 50)
}

; Timer to handle continuous movement
SetTimer, MoveMouseLoop, 30

MoveMouseLoop:
    ; Get the state of each Numpad key
    up := GetKeyState("Numpad8", "P")
    down := GetKeyState("Numpad2", "P")
    left := GetKeyState("Numpad4", "P")
    right := GetKeyState("Numpad6", "P")
    
    ; Determine the direction based on key states
    x := (right ? 1 : 0) - (left ? 1 : 0)
    y := (down ? 1 : 0) - (up ? 1 : 0)
    
    ; If any key is pressed, move the mouse
    if (x != 0 or y != 0)
        MoveMouse(x, y)
    else
        ResetSpeed()
Return

#If (GetKeyState("Numpad8", "P") or GetKeyState("Numpad2", "P") or GetKeyState("Numpad4", "P") or GetKeyState("Numpad6", "P"))
Numpad8::return
Numpad2::return
Numpad4::return
Numpad6::return
#If

NumpadAdd::LButton
return

NumpadSub::RButton
return

NumpadMult::
send {WheelUp 1}
return

NumpadDiv::MButton
return

NumpadDot::
send {WheelDown 1}
return

Numpad0::XButton1
return

Numpad1::XButton2
return


; first
;#Persistent
;#NoEnv
;#SingleInstance force
;
;; Set the initial speed for mouse movement
;speed := 1
;
;; Function to reset speed
;ResetSpeed() {
;    global speed
;    speed := 1
;}
;
;; Function to handle mouse movement with acceleration
;MoveMouse(x, y) {
;    global speed
;    DllCall("mouse_event", "UInt", 1, "Int", x * speed, "Int", y * speed, "UInt", 0, "UInt", 0)
;    speed := Min(speed + 1, 20)
;}
;
;; Timer to handle continuous movement
;SetTimer, MoveMouseLoop, 30
;
;MoveMouseLoop:
;    ; Get the state of each Numpad key
;    up := GetKeyState("Numpad8", "P")
;    down := GetKeyState("Numpad2", "P")
;    left := GetKeyState("Numpad4", "P")
;    right := GetKeyState("Numpad6", "P")
;    
;    ; Determine the direction based on key states
;    x := (right ? 1 : 0) - (left ? 1 : 0)
;    y := (down ? 1 : 0) - (up ? 1 : 0)
;    
;    ; If any key is pressed, move the mouse
;    if (x != 0 or y != 0)
;        MoveMouse(x, y)
;    else
;        ResetSpeed()
;Return
;
;NumpadAdd::LButton
;return
;
;NumpadSub::RButton
;return
;
;NumpadMult::
;send {WheelUp 1}
;return
;
;NumpadDiv::MButton
;return
;
;NumpadDot::
;send {WheelDown 1}
;return
;
;Numpad0::XButton1
;return
;
;Numpad1::XButton2
;return
