#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
; Big pointer + turns into a hand while HOLD_KEY is held.
SIZE := 64          ; pointer size in pixels (32 = default, 48, 64, 96, 128...)
HOLD_KEY := "Ctrl"  ; key to hold (e.g. "Shift", "Alt", "CapsLock", "F8")

ARROW := A_WinDir "\Cursors\aero_arrow_xl.cur"
HAND  := A_WinDir "\Cursors\aero_link_xl.cur"
IDS := [32512, 32513, 32515, 32646, 32649, 32650, 32514, 32642, 32643, 32644, 32645]
handOn := false

SetAll(HAND)  ; brief flash proves it works
Sleep 300
SetAll(ARROW)
OnExit (*) => DllCall("SystemParametersInfo", "UInt", 0x57, "UInt", 0, "Ptr", 0, "UInt", 0)

Hotkey "~*" HOLD_KEY, KeyDown
Hotkey "~*" HOLD_KEY " up", KeyUp

KeyDown(*) {
    global handOn
    if !handOn {
        handOn := true
        SetAll(HAND)
    }
}
KeyUp(*) {
    global handOn
    handOn := false
    SetAll(ARROW)
}
SetAll(file) {
    global SIZE, IDS
    for id in IDS {
        h := DllCall("LoadImage", "Ptr", 0, "Str", file, "UInt", 2, "Int", SIZE, "Int", SIZE, "UInt", 0x10, "Ptr")
        if h
            DllCall("SetSystemCursor", "Ptr", h, "UInt", id)
    }
}
