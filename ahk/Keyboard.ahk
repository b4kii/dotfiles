#Requires AutoHotkey v2.0
#SingleInstance Force

; ===========================
; HYPER KEYS
; ===========================
*F13:: {
    SendInput "{Shift Down}{Alt Down}"
    KeyWait "F13"
    SendInput "{Alt Up}{Shift Up}"

    if A_PriorKey = "F13"
        SendInput "{Esc}"
}

*F14:: {
    SendInput "{Ctrl Down}{Shift Down}{Alt Down}"
    KeyWait "F14"
    SendInput "{Alt Up}{Shift Up}{Ctrl Up}"

    if A_PriorKey = "F14"
        SendInput "{Esc}"
}

; ===========================
; WIN + CTRL + [LEFT/RIGHT ARROW]
; ===========================
F23::Send "^#{Left}"
F24::Send "^#{Right}"

; =========================================
; Set the initial speed for mouse movement
speed := 1.5

; Function to reset speed
ResetSpeed() {
    global speed
    speed := 1.5
}

; Function to handle mouse movement with acceleration
MoveMouse(x, y) {
    global speed
    DllCall("mouse_event", "UInt", 1, "Int", x * speed, "Int", y * speed, "UInt", 0, "UInt", 0)
    speed := Min(speed + 3, 100)
}

; Timer to handle continuous movement
MoveMouseLoop() {
    ; Get the state of each Numpad key
    up := GetKeyState("Numpad8", "P")
    down := GetKeyState("Numpad5", "P")
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
}

SetTimer MoveMouseLoop, 30

#HotIf GetKeyState("Numpad8", "P") || GetKeyState("Numpad5", "P") || GetKeyState("Numpad4", "P") || GetKeyState("Numpad6", "P")
Numpad8::return
Numpad5::return
Numpad4::return
Numpad6::return
#HotIf

Numpad7::Send("{WheelUp 1}")
Numpad9::Send("{WheelDown 1}")
NumpadAdd::XButton1
NumpadEnter::XButton2
Numpad1::MButton     
Numpad2::LButton    
Numpad3::RButton  
