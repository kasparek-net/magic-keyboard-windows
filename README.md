# Apple Magic Keyboard on Windows

Configuration that turns an Apple Magic Keyboard into something usable on
Windows for people with macOS muscle memory. Replaces PowerToys Keyboard
Manager.

Tested on Windows 10 22H2, AutoHotkey v2.0.19, Czech QWERTZ layout.

## What it solves

| Problem | Solution |
|---|---|
| Cmd and Ctrl are swapped compared to macOS | driver-level swap via `Scancode Map` |
| Cmd+C occasionally launches Cortana | same — a driver-level mapping never leaks a physical Win |
| Cmd+arrows jumps by word instead of to the end of the line | hotkeys in AHK |
| Hotkeys do not work in windows running as administrator | scheduled task with `RunLevel Highest` |

## Installation

1. **Swap the keys** — run `prohodit-cmd-ctrl.reg` and **reboot**.
   It writes `Scancode Map` into `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout`.

2. **Disable PowerToys Keyboard Manager** if you use it.
   Otherwise the keys get swapped twice and you are back where you started.

3. **Install [AutoHotkey v2](https://www.autohotkey.com/)**.

4. **Register the scheduled task** — in PowerShell **as administrator**:

   ```powershell
   powershell -ExecutionPolicy Bypass -File instalace.ps1
   ```

   The task runs `mac-klavesnice.ahk` at logon with elevated privileges.
   If you also have the script in your *Startup* folder, remove it from there —
   it would run twice.

Uninstall: run `prohodit-cmd-ctrl-ZRUSIT.reg`, reboot, and delete the
*Mac klavesnice (AHK)* task from Task Scheduler.

## Hotkeys

Written in keys **after the swap**: `<^` = command, `<#` = control, `<!` = option.

| Hotkey | Action |
|---|---|
| Cmd+Shift+3 | full screenshot |
| Cmd+Shift+4 | snip (`ms-screenclip:`) |
| Cmd+Space | Windows Search (Spotlight replacement) |
| Ctrl+Space | Alt+Space (PowerToys Run) |
| Option+2 | `@` |
| Option+C | Ctrl+Alt+Shift+C |
| Cmd+←/→ | start / end of line |
| Cmd+↑/↓ | start / end of document |
| Option+←/→ | jump by word |
| + Shift with any of the above | same, with selection |
| Cmd+Backspace | delete to start of line |
| Option+Backspace | delete previous word |
| Cmd+Q | close window (Alt+F4) |
| Cmd+Tab / Cmd+Shift+Tab | switch applications |
| Cmd+Option+←/→ | switch browser tabs |

## Two traps we ran into

### 1. Digits in a hotkey must be scan codes

AutoHotkey resolves a key name in a hotkey through the **active keyboard
layout**. On Czech QWERTZ the character `2` requires Shift —
`VkKeyScanExW('2')` returns `VK=0x32 + SHIFT`. So a hotkey written as:

```autohotkey
<!2::SendText "@"          ; WRONG on a Czech keyboard
```

gets registered as **Option+Shift+2** and never fires on a plain Option+2 —
instead of an at sign you get "ě". The correct form:

```autohotkey
<!sc003::SendText "@"      ; sc003 = the physical "2" key
```

Scan codes of the number row: `sc002`=1, `sc003`=2, `sc004`=3, `sc005`=4 …
Letters (`c`, `q`) do not require Shift, so those can be written as characters.

This applies to any layout where digits are shifted — Czech, Slovak, French
AZERTY and others.

### 2. Do not do the swap with a hook

Both PowerToys Keyboard Manager and an AHK `LWin::LCtrl` work through a
low-level hook, which occasionally leaks the physical Win — and Cmd+C then
launches Cortana (Win+C). `Scancode Map` sits at the driver level and does
not have this problem.

The price is that it applies **globally to every keyboard**. If you use
another keyboard next to the Apple one, it will have Ctrl/Win swapped too.

## Notes

* Check the script syntax with `AutoHotkey64.exe /ErrorStdOut mac-klavesnice.ahk`
  — errors go to stderr instead of a modal dialog.
  The `/validate` switch **does not exist** in AHK 2.0.19 and returns exit code 2
  even for a valid file, so it cannot be relied on.
* The `.reg` files are stored as **UTF-16LE**, otherwise regedit garbles the
  accented characters in the comments. As a side effect Git treats them as
  binary and shows no diffs for them.
