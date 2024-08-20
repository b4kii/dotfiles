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
}

SetTimer MoveMouseLoop, 30

#HotIf GetKeyState("Numpad8", "P") || GetKeyState("Numpad2", "P") || GetKeyState("Numpad4", "P") || GetKeyState("Numpad6", "P")
Numpad8::return
Numpad2::return
Numpad4::return
Numpad6::return
#HotIf

NumpadAdd::LButton
NumpadSub::RButton
NumpadMult::Send("{WheelUp 1}")
NumpadDiv::MButton
NumpadDot::Send("{WheelDown 1}")
Numpad0::XButton1
Numpad1::XButton2
