#Requires AutoHotkey v2.0
#SingleInstance Force
; Apple Magic Keyboard on Windows - a replacement for PowerToys Keyboard Manager.
; Also merges the former macos_screenshot_hotkey and macos_Spotlight scripts.
;
; Physically: control = LCtrl, option = LAlt, command = LWin
; The Cmd <-> Ctrl swap is done by Windows itself through the registry
; (Scancode Map in HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout),
; which is more reliable than a hook in AHK/PowerToys.
; So after the swap: command sends Ctrl, control sends Win.
; NOTE: PowerToys Keyboard Manager must stay disabled, otherwise the keys get
; swapped twice and you are back where you started.

A_MenuMaskKey := "vkE8"   ; keep a lone Win/Alt after a hotkey from opening Start/menu

; --- Hotkeys (written in keys AFTER the swap) ------------------------------
; <^ = command,  <# = control,  <! = option
; Digits are written as scan codes (sc003=2, sc004=3, sc005=4) so they do not
; depend on the active layout. On a Czech keyboard the character "2" requires
; Shift, so AHK would register the hotkey "<!2" as Option+Shift+2 and it would
; never fire on a plain Option+2.

<^+sc004::Send "{PrintScreen}"          ; Cmd+Shift+3  -> full screenshot
<^+sc005::Run "ms-screenclip:"          ; Cmd+Shift+4  -> snip
<^Space::Send "#s"                  ; Cmd+Space    -> Windows Search (Spotlight)
<#Space::Send "!{Space}"            ; Ctrl+Space   -> Alt+Space (PowerToys Run)
<!sc003::SendText "@"                   ; Option+2     -> @
<!c::Send "^!+c"                    ; Option+C     -> Ctrl+Alt+Shift+C


; --- macOS-style text navigation -------------------------------------------
<^Left::Send "{Home}"               ; Cmd+Left     -> start of line
<^Right::Send "{End}"               ; Cmd+Right    -> end of line
<^Up::Send "^{Home}"                ; Cmd+Up       -> start of document
<^Down::Send "^{End}"               ; Cmd+Down     -> end of document
<^+Left::Send "+{Home}"             ; same with Shift = select
<^+Right::Send "+{End}"
<^+Up::Send "^+{Home}"
<^+Down::Send "^+{End}"
<!Left::Send "^{Left}"              ; Option+Left  -> one word back
<!Right::Send "^{Right}"            ; Option+Right -> one word forward
<!+Left::Send "^+{Left}"
<!+Right::Send "^+{Right}"

; --- macOS-style deleting --------------------------------------------------
<^BackSpace::Send "+{Home}{BackSpace}"   ; Cmd+Backspace    -> delete to start of line
<!BackSpace::Send "^{BackSpace}"         ; Option+Backspace -> delete previous word

; --- Quit application ------------------------------------------------------
<^q::Send "!{F4}"                   ; Cmd+Q        -> close window / application

; --- Close document (Cmd+W) ------------------------------------------------
; CorelDRAW uses Ctrl+W for Refresh Window; Ctrl+F4 closes the document.
#HotIf WinActive("ahk_exe CorelDRW.exe")
<^w::Send "^{F4}"                   ; Cmd+W        -> close document
#HotIf

; --- Tab switching (replaces Ctrl+Tab, which Cmd+Tab took over) ------------
<^<!Right::Send "^{Tab}"            ; Cmd+Option+Right -> next tab
<^<!Left::Send "^+{Tab}"            ; Cmd+Option+Left  -> previous tab

; --- Cmd+Tab = application switching ---------------------------------------
; Alt has to stay held down as long as you hold command, otherwise the
; switcher disappears immediately.
#HotIf GetKeyState("LControl", "P")   ; LControl = the physical command key
Tab::AltTab("{Tab}")
+Tab::AltTab("+{Tab}")
#HotIf
~LControl Up::AltTab("release")

AltTab(action) {
    static held := false
    if (action = "release") {
        if held {
            Send "{Alt up}"
            held := false
        }
        return
    }
    if !held {
        Send "{Alt down}"
        held := true
    }
    Send action
}
; --- Tray ------------------------------------------------------------------
A_IconTip := "Mac keyboard"
if ProcessExist("PowerToys.KeyboardManagerEngine.exe")
    TrayTip "PowerToys Keyboard Manager is running - disable it, otherwise Cmd/Ctrl get swapped twice.", "Mac keyboard", "Icon!"
