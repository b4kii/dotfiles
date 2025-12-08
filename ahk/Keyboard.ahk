#Requires AutoHotkey v2.0
F23::Send "^#{Left}"
F24::Send "^#{Right}"

c::
{
    Send "{LWin down}{LCtrl down}{LAlt down}{LShift down}"
}
