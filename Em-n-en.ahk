SetWorkingDir %A_ScriptDir%
SendMode Input
#SingleInstance, force
#NoEnv


settings_file = Em-n-en_Settings.ini
startup_shortcut := A_Startup . "\Em-n-en.lnk"
settings := Object()

; Initialize Settings in the following way:
; array[key]   := ["Section", "Key", "Value"]
settings["mod"] := ["Methods", "modifiers", false]
settings["inl"] := ["Methods", "inline", true]
settings["hrd"] := ["Methods", "hard_replace", false]
settings["sww"] := ["General", "startup_run", false]

if !FileExist(settings_file) {
    write_settings(settings)
    settingsGui()
}
read_settings(settings)

; Set up the right click menu
Menu, Tray, NoStandard

; Menu, Tray, Add, About, about
Menu, Tray, Add, Settings, settingsGui
Menu, Tray, Default, Settings
Menu, Tray, Add,
Menu, Tray, Add, Reset, reset
Menu, Tray, Add, Restart, restart
Menu, Tray, Add, Exit, exit
Menu, Tray, Tip, Em-n-en - Type En and Em dashes

; Define the settings GUI
settingsGui() {
    global

    ; Initialization
    Gui, Settings: New
    Gui, Settings: -Resize -MaximizeBox +OwnDialogs

    ; Title and Copyright
    Gui, Settings:font, s18, Arial
    Gui, Settings:Add, Text, Center W475, Em-n-en Settings
    Gui, Settings:font, s8 c808080, Trebuchet MS
    Gui, Settings:Add, Text, Center W475 yp+26, Copyright (c) 2016 Jason Cemra

    ; Standard Settings
    Gui, Settings:font, s8 c505050, Trebuchet MS
    Gui, Settings:Add, GroupBox, w455 h283, Standard Settings
    Gui, Settings:font, s10 c10101f, Trebuchet MS
    Gui, Settings:Add, Text, Left w210 xp+12 yp+22, Method for Dash Insertion:

    Gui, Add, Checkbox, yp+25 vcheck_modifier_method, Modifier Keys
    Gui, Settings:font, s8 c808080, Trebuchet MS
    Gui, Settings:Add, Text, W400 yp+20, En Dash: Ctrl + Shift + "-" and Em Dash: En Dash: Ctrl + Shift + Alt + "-"
    Gui, Settings:font, s10 c10101f, Trebuchet MS

    Gui, Add, Checkbox, yp+25 vcheck_inline_method, Inline Replace
    Gui, Settings:font, s8 c808080, Trebuchet MS
    Gui, Settings:Add, Text, W400 yp+20, En Dash, type: "--=" and Em Dash, type: "==-"
    Gui, Settings:font, s10 c10101f, Trebuchet MS

    Gui, Add, Checkbox, yp+25 vcheck_hard_replace_method, Hard Replace
    Gui, Settings:font, s8 c808080, Trebuchet MS
    Gui, Settings:Add, Text, W400 yp+20, Not Recommended. Will replace "-" with En Dash if not directly next to a letter.
    Gui, Settings:font, s10 c10101f, Trebuchet MS

    Gui, Settings:Add, Text, Left w210 yp+35, Other Settings:
    Gui, Add, Checkbox, yp+25 vcheck_start_with_windows, Start on Windows Startup
    Gui, Settings:font, s10 c810000, Arial
    Gui, Settings:Add, Button, yp+25 w180 gSettingsButtonReset, Reset everything to default

    ; Buttons
    Gui, Settings:Add, Button, Default xp+158 yp+50 w85, Ok
    Gui, Settings:Add, Button, xp+100 w85, Apply
    Gui, Settings:Add, Button, xp+100 w85, Cancel

    loadSettingsToGui()
    Gui, show, W500 H400 center, Em-n-en Settings
}
; GUI Actions
settingsButtonOk() {
    if (pullSettingsFromGui()) {
        Gui, Settings:Destroy
    } else {
        MsgBox, Errer!
    }
}
settingsButtonApply(){
    pullSettingsFromGui()
}
loadSettingsToGui(){
    global
    GuiControl, Settings:, check_modifier_method, % settings["mod"][3]
    GuiControl, Settings:, check_inline_method, % settings["inl"][3]
    GuiControl, Settings:, check_hard_replace_method, % settings["hrd"][3]
    GuiControl, Settings:, check_start_with_windows, % settings["sww"][3]
}
pullSettingsFromGui(){
    global
    Gui, Settings:Submit, NoHide
    settings["mod"][3] := check_modifier_method
    settings["inl"][3] := check_inline_method
    settings["hrd"][3] := check_hard_replace_method
    settings["sww"][3] := check_start_with_windows
    save()
    update_sww_state(settings["sww"][3])
    return true
}
settingsButtonCancel(){
    Gui, Settings:Destroy
}
settingsButtonReset() {
    Gui, Settings: +OwnDialogs
    reset()
}


;  On-startup logic
sww() {
    global
    settings["sww"][3] := !settings["sww"][3]
    save()
    update_sww_state(settings["sww"][3])
    loadSettingsToGui()
}

update_sww_state(state){
    global startup_shortcut
    if (state) {
        FileGetShortcut, %startup_shortcut%, shortcut_path
        if (!FileExist(startup_shortcut) || shortcut_path != A_ScriptFullPath) {
            startup_shortcut_create()
        }
    } else {
        startup_shortcut_destroy()
    }
}

startup_shortcut_create() {
    global startup_shortcut
    FileCreateShortcut, %A_ScriptFullPath%, %startup_shortcut%, %A_WorkingDir%
}

startup_shortcut_destroy() {
    global startup_shortcut
    FileDelete, %startup_shortcut%
}

; Settings logic
save() {
    global settings
    write_settings(settings)
}

write_settings(settings) {
    global settings_file
    for index, var in settings {
        IniWrite, % var[3], %settings_file%, % var[1], % var[2]
    }
}

read_settings(ByRef settings) {
    global settings_file
    for index, var in settings {
        IniRead, buffer, %settings_file%, % var[1], % var[2]
        var[3] := buffer
    }
}

; Exit logic
restart() {
    save()
    Reload
    ExitApp
}

exit() {
    save()
    ExitApp
}

reset(){
    global
    MsgBox, 0x34, Are you sure?, This will completely wipe all settings and exit the program.
    IfMsgBox, No
        return
    FileDelete, %settings_file%
    startup_shortcut_destroy()
    ExitApp
}


; "En Dash" code point is {U+2013} and "Em Dash" code point is {U+2014}

#If, settings["mod"][3]
^+-::
Send {U+2013}
return

#If, settings["mod"][3]
^!+-::
Send {U+2014}
return

#If, settings["inl"][3]
:*?:--=::
Send {U+2013}
return

#If, settings["inl"][3]
:*?:==-::
Send {U+2014}
return

#If, settings["hrd"][3]
:*:-::
Send {U+2013}
return