#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

AppsKey::
{
    Send("{Ctrl DownTemp}{Alt DownTemp}{Shift DownTemp}")
    KeyWait("AppsKey")
    Send("{Shift Up}{Alt Up}{Ctrl Up}")

	if (A_PriorKey = "AppsKey")
		Send("{Esc}")
}

ScrollLock:: {
    ; Press Shift + Alt + LWin down
    Send("{Shift down}{Alt down}{LWin down}")

    ; Wait for ScrollLock to be released
    KeyWait("ScrollLock")

    ; Release the keys
    Send("{LWin up}{Alt up}{Shift up}")

    ; If ScrollLock was the previous key, send Esc
    if (A_PriorKey = "ScrollLock")
        Send("{Esc}")
}

;; Deactivate CapsLock completely
;SetCapsLockState("AlwaysOff")
;
;; Remap CapsLock to Hyper (Ctrl+Shift+Alt+Win)
;; If CapsLock is tapped, send Esc
;~CapsLock::
;{
;	; Press down Hyper keys temporarily
;	Send("{Shift DownTemp}{Alt DownTemp}{LWin DownTemp}")
;
;	; Wait until CapsLock is released
;	KeyWait("CapsLock")
;
;	; Release Hyper keys
;	Send("{LWin Up}{Alt Up}{Shift Up}")
;
;	; If CapsLock was tapped without other key, send Esc
;	if (A_PriorKey = "CapsLock")
;		Send("{Esc}")
;}
