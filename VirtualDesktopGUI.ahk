#SingleInstance force
; Globals
global desknum
global targetnum
;~ #NoTrayIcon

; Modern Apps need this prefix to their titles in order to move them
MODERN_APP_AHK_CLASS := "ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe"

; This function looks at the registry to determine the list of virtual desktops
mapDesktopsFromRegistry() {
  global CurrentDesktop, DesktopCount
  ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
  IdLength := 32
  SessionId := getSessionId()
  if (SessionId) {

    registryString 
    := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\"
      . "Windows\CurrentVersion\Explorer\"
      . "SessionInfo\" SessionId "\VirtualDesktops"
    RegRead, CurrentDesktopId,% registryString, CurrentVirtualDesktop
                        
    if (CurrentDesktopId) {
      IdLength := StrLen(CurrentDesktopId)
    }
  }

  ; Get a list of the UUIDs for all virtual desktops on the system
  registryString 
  := "SOFTWARE\Microsoft\Windows\CurrentVersion"
      . "\Explorer\VirtualDesktops"
  RegRead, DesktopList, HKEY_CURRENT_USER,% registryString, VirtualDesktopIDs
  
  ; Figure out how many virtual desktops there are
  DesktopCount := DesktopList ? StrLen(DesktopList) / IdLength : 1

  ; Remember how many desktops there are
  A_LastDesktopCount := DesktopCount
  guiCreateByDesktopCount() ;create the gui

  ; Parse the REG_DATA string that stores the array of UUID's 
  ; for virtual desktops in the registry.
  i := 0
  while (CurrentDesktopId and i < DesktopCount) {
    StartPos := (i * IdLength) + 1
    DesktopIter := SubStr(DesktopList, StartPos, IdLength)
    OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.  
    
    ; Break out if we find a match in the list. If we didn't find anything,
    ; keep the old guess and pray we're still correct.
    if (DesktopIter = CurrentDesktopId) {
      CurrentDesktop := i + 1
      OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
      break
    }
    i++
  }
}

; This functions finds out ID of current session.
getSessionId() {
  ProcessId := DllCall("GetCurrentProcessId", "UInt")
  if ErrorLevel {
    OutputDebug, Error getting current process id: %ErrorLevel%
    return
  }
  OutputDebug, Current Process Id: %ProcessId%
  DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
  if ErrorLevel {
    OutputDebug, Error getting session id: %ErrorLevel%
    return
  }
  OutputDebug, Current Session Id: %SessionId%
  return SessionId
} ; End getSessionId

getElementMeasurements() {
  ; Todo, figure out if the position of the gui should be vertical or horizonatal, and on whitch edge.
  WinGetPos, taskX, taskY, taskW, taskH, ahk_class Shell_TrayWnd
  if(taskX > 0) { ; right edge
    return {"right"
      : {"wholeSpace": {"x": A_ScreenWidth * 29 / 30, "y": 0, "w":  A_ScreenWidth  / 30, "h": A_ScreenHeight}
      , "removeButton":{"x": A_ScreenWidth * 29 / 30, "y": 0, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "addButton":{"x": A_ScreenWidth * 29 / 30, "y": A_ScreenHeight * 11 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "grabButton":{"x": A_ScreenWidth * 29 / 30, "y": A_ScreenHeight * 12 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "followButton":{"x": A_ScreenWidth * 29 / 30, "y": A_ScreenHeight * 13 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "desktopButtons":{"x": A_ScreenWidth * 29 / 30, "y": A_ScreenHeight / 14, "w": A_ScreenWidth / 30, "h": "undefined"}}}
  } else if(taskY > 0) { ; bottom edge
    return {"bottom"
      : {"wholeSpace": {"x": 0, "y": A_ScreenHeight * 29 /30, "w":   A_ScreenWidth, "h": A_ScreenHeight/30}
      , "removeButton":{"x": 0, "y": A_ScreenHeight * 29 / 30, "w": A_ScreenWidth * .05 , "h": A_ScreenHeight / 30}
      , "addButton":{"x": A_ScreenWidth / 16 * 1.5, "y": A_ScreenHeight * 29 / 30, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "grabButton":{"x": A_ScreenWidth * 14 / 16 * 1.5, "y": A_ScreenHeight * 29 / 30, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "followButton":{"x": A_ScreenWidth * 15 / 16 * 1.5, "y": A_ScreenHeight * 29 / 30, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "desktopButtons":{"x": A_ScreenWidth * 2 / 16 * 1.5, "y": A_ScreenHeight * 29 / 30, "w": "undefined", "h": A_ScreenHeight / 30}}}
  } else if(taskW > taskH) { ;top edge
    return {"top"
      : {"wholeSpace": {"x": 0, "y": 0, "w":   A_ScreenWidth, "h": A_ScreenHeight/30}
      , "removeButton":{"x": 0, "y": 0, "w": A_ScreenWidth * .05 , "h": A_ScreenHeight / 30}
      , "addButton":{"x": A_ScreenWidth / 16 * 1.5, "y": 30, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "grabButton":{"x": A_ScreenWidth * 14 / 16 * 1.5, "y": 0, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "followButton":{"x": A_ScreenWidth * 15 / 16 * 1.5, "y": 0, "w": A_ScreenWidth * .05, "h": A_ScreenHeight / 30}
      , "desktopButtons":{"x": A_ScreenWidth * 2 / 16 * 1.5, "y": 0, "w": "undefined", "h": A_ScreenHeight / 30}}}
  } else { ; left edge
    return {"left"
      : {"wholeSpace": {"x": 0, "y": 0, "w":  A_ScreenWidth  / 30, "h": A_ScreenHeight}
      , "removeButton":{"x": 0, "y": 0, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "addButton":{"x": 0, "y": A_ScreenHeight * 11 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "grabButton":{"x": 0, "y": A_ScreenHeight * 12 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "followButton":{"x": 0, "y": A_ScreenHeight * 13 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "desktopButtons":{"x": 0, "y": A_ScreenHeight / 14, "w": A_ScreenWidth / 30, "h": "undefined"}}}
  }
}

; This function redraws the gui if desktops are created or removed 
guiCreateByDesktopCount() {
  global A_LastDesktopCount
  ; Assign A_useableHeight and A_usableWidth opposite to the taskbar
  WinGetPos, taskx, tasky, taskwidth, taskheight, ahk_class Shell_TrayWnd
  isTall := A_screenwidth < A_screenheight
  A_useableWidth := isTall ? A_screenheight : A_ScreenWidth
  A_useableHeight := isTall ? A_ScreenWidth : A_screenheight

  ; Defines the width of the three buttons X, GRAB, & FOLLOW
  otherbuttons := (A_useableWidth/30) * 1.5
  ; Defines the gui width as the width
  guiwidth := (A_useableWidth)
  ; Defines the gui height as 1/50 of A_Screenheight
  guiheight := (A_useableHeight/50)
  ; Gui will be positioned  along the edge opposite of the task bar
  guidepth := (tasky = 0) ? (A_useableHeight-guiheight) : 0 
  ; If the tablet is vertical, shrink the gui width
  guiwidth -= taskwidth < A_useableWidth / 3 ? guiwidth-taskwidth : 0

  global DesktopCount
  ; Remake the gui if the destop count changes, or if the taskbar location changes
  if ((A_LastDesktopCount != DesktopCount) 
  || (taskx_prev != taskx) 
  || (tasky_prev != tasky)) {
  gui destroy

  ; Make sure the gui is not scaled to 96 DPI
  gui, -dpiscale

  ; Each desktop button should be the remaining screen width 
  ; (after subtracting the width of the 4 special buttons)
  ; divided by the total number of desktops, 
  buttonwidth:= (guiwidth-otherbuttons*4)/DesktopCount - 2

  ; Style the gui and add the close button
/*  Gui,% " +LastFound "
      . " +AlwaysOnTop "
      . " +ToolWindow "
      . " -Caption "
      . " +Border "
      . " +E0x08000000"
*/
  Gui, +LastFound +AlwaysOnTop +ToolWindow -Caption +Border +E0x08000000 ;style the gui
  buttonlocation := 0
  Gui, Add, Button,% ""
  . " x" buttonlocation
  . " y" 2
  . " w" otherbuttons
  . " h" 24
  ,% "X" 

  buttonlocation := (otherbuttons)
  buttoncount += 1

  ; Create a new button for each desktop
  loop,% DesktopCount {
    ;each desktop button has the same dimensions
    Gui, Add, Button, x%buttonlocation% y2 w%buttonwidth% h%guiheight% gDesktopButtons, DESKTOP%A_Index% 
    
    ; Margin between buttons
    buttonlocation := (buttonlocation+buttonwidth+2) 
    buttoncount += 1
  }

  ; Create a button to add a new desktop
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h%guiheight% , + 
  
  ; Start the next button at the end of this one
  buttonlocation := (buttonlocation+otherbuttons) 
  
  ; Create a button to grab a window and take it to another desktop
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h%guiheight% , GRAB 
  
  ; Start the next button at the end of this one
  buttonlocation := (buttonlocation+otherbuttons) 
  ; Create a button to add a new desktop
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h24 , FOLLOW 
  
  ; Increment these buttons to the button count
  buttoncount += 3 
  
  ; Position the gui opposite of the taskbar

  ; Position the gui opposite of the taskbar
  barIsNarrow := taskwidth < A_useableWidth/2
  barIsAtTop := !(taskx > 0)

  if (barIsNarrow && barIsAtTop) {
    gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  } else if (barIsNarrow && !barIsAtTop) {
    gui, show, x%taskwidth% y%guidepth% w%guiwidth% h%guiheight%
  } else if (!barIsNarrow && barIsAtTop) {
    gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  } else {
    gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  }

  ; Name the gui and get its position, and save the taskbar 
  ; x and y coordinates to check if the gui should move later
  WinGetActiveTitle, guistats
  WinGetPos, guix, guiy, guiwidth, guiheight, %guistats% 
  taskx_prev:= %taskx%
  tasky_prev:= %tasky%
  }
}


; This function takes a number to a corresponding deskotp
; and switches the screen to that desktop
switchDesktopByNumber(targetDesktop) {
  global CurrentDesktop, DesktopCount
  ; Re-generate informatino on the number of desktops and where 
  ; the current desktop is. We do this because the user may have
  ; switched desktops via some other means than the script.
  mapDesktopsFromRegistry()

  ; Don't attempt to switch to an invalid desktop
  if (targetDesktop > DesktopCount || targetDesktop < 1) {
    OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
    return
  }

  ; Scan right until we reach the desktop we want
  while(CurrentDesktop < targetDesktop) {
    Send ^#{Right}
    CurrentDesktop++
    OutputDebug, [Right] target: %targetDesktop% current: %CurrentDesktop%
  }

  ; Scan left until we reach the desktop we want
  while(CurrentDesktop > targetDesktop) {
    Send ^#{Left}
    CurrentDesktop--
    OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
  }
  DetectHiddenWindows, off
}

createVirtualDesktop() {
  global CurrentDesktop, DesktopCount
  Send, #^d
  DesktopCount++
  A_LastDesktopCount++
  CurrentDesktop = %DesktopCount%
  OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
  guiCreateByDesktopCount()
}

deleteVirtualDesktop() {
  global CurrentDesktop, DesktopCount
  Send, #^{F4}
  DesktopCount--
  A_LastDesktopCount--
  CurrentDesktop--
  OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
  guiCreateByDesktopCount()
}

; Main
SetKeyDelay, 75
mapDesktopsFromRegistry()
OutputDebug, [loading] desktops: %DesktopCount% current: %CurrentDesktop%

/*
User config!
This section binds the key combo to the switch/create/delete actions
Uncomment the hotkeys you want to use, or just handle everything through
the gui :)
*/
^#f4::deleteVirtualDesktop()
; ^#1::switchDesktopByNumber(1)
; ^#2::switchDesktopByNumber(2)
; ^#3::switchDesktopByNumber(3)
; ^#4::switchDesktopByNumber(4)
; ^#5::switchDesktopByNumber(5)
; ^#6::switchDesktopByNumber(6)
; ^#7::switchDesktopByNumber(7)
; ^#8::switchDesktopByNumber(8)
; ^#9::switchDesktopByNumber(9)
; ^#0::switchDesktopByNumber(10)


; Hotkey F18 is a stylus pen button, used to detect gui presses,
; toggle the boolean 'movwin'
~F18::windowWasGrabbed = true

; Button for moving a window to a different desktop
ButtonGRAB:
if (windowWasGrabbed) {
  ToolTip, Window movement off, %grabx%-300, %graby%-100
  windowWasGrabbed := false
  SetTimer, RemoveToolTip, 5000
  return
}
ToolTip, Window movement on`r(Tap a window`rand select a desktop), %grabx%-300, %graby%-100
windowWasGrabbed := true
SetTimer, RemoveToolTip, 5000
return


; Button for selecting a window to always follow the user to the active desktop
ButtonFOLLOW:
WinWaitNotActive, desktop switcher
WinGetActiveTitle, bring
if (bringwin) {
  bringwin := false
  SetTimer, RemoveToolTip, 5000
  return
}
ToolTip, Active window will follow`ryou to each desktop, %grabx%-300, %graby%-100
bringwin := true
SetTimer, RemoveToolTip, 5000
return


; Label for removing tooltip
RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

; Runs this goto when any of the DESKTOP buttons are pressed
DesktopButtons:
global CurrentDesktop, DesktopCount

; Keep only the number of the desktop to do math with it
targetDesktop := RegExReplace(A_GuiControl, "DESKTOP", "")
; Save the acti ve window's name to potentially move it later
WinGetActiveTitle, title 
; Runs if we want to move a window to another desktop
; and any window except besides the gui is active
if (CurrentDesktop != targetDesktop) {
  if(WinActive, "ahk_class ApplicationFrameWindow") {
    title := title " " MODERN_APP_AHK_CLASS
  }
  winhide, % title
  switchDesktopByNumber(targetDesktop)
  winshow,% title
  windowWasGrabbed := false
}
return
SetTimer, ShowGui, 500

ShowGui:	
WinWait, ahk_class Shell_TrayWnd
guiCreateByDesktopCount()
SetTimer, ShowGui, 500
return

Button+:
createVirtualDesktop()
return
ButtonX:
deleteVirtualDesktop()
return
