#SingleInstance force
#Persistent
;~ #NoTrayIcon

main() {
  ; Globals
  global desknum
  global targetnum
  
  ; Modern Apps need this prefix to their titles in order to move them
  MODERN_APP_AHK_CLASS := "ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe"

  SetKeyDelay, 75
  taskBarLocation := mapDesktopsFromRegistry()
  setTimer, guiCheck, 5
}
main()

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
    ;~ OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.  
    
    ; Break out if we find a match in the list. If we didn't find anything,
    ; keep the old guess and pray we're still correct.
    if (DesktopIter = CurrentDesktopId) {
      CurrentDesktop := i + 1
      ;~ OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
      break
    }
    i++
  }
  return taskBarLocation
}

; This function finds out ID of current session.
getSessionId() {
  ProcessId := DllCall("GetCurrentProcessId", "UInt")
  if ErrorLevel {
    OutputDebug, Error getting current process id: %ErrorLevel%
    return
  }
  ;~ OutputDebug, Current Process Id: %ProcessId%
  DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
  if ErrorLevel {
    OutputDebug, Error getting session id: %ErrorLevel%
    return
  }
  ;~ OutputDebug, Current Session Id: %SessionId%
  return SessionId
} ; End getSessionId

; This function calculates the area to be given to different buttons on 
; the gui, and the coordinates to display the gui at.
getElementMeasurements() {
  ; Todo, figure out if the position of the gui should be vertical or horizonatal, and on whitch edge.
  WinGetPos, taskX, taskY, taskW, taskH, ahk_class Shell_TrayWnd
  taskBarDimensions := {"x": taskX, "y": taskY, "w": taskW, "h": taskH}
  if(taskX > 0) { ; right edge is opposite
    return {"edge": "left", "orientation": "vertical", "taskbar": taskBarDimensions, "positions"
      : {"guiSpace": {"x": 0, "y": 0, "w":  A_ScreenWidth  / 30, "h": A_ScreenHeight}
      , "specialButtons"
      : {"X": {"x": 0, "y": 0, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "+":{"x": 0, "y": A_ScreenHeight * 11 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "GRAB":{"x": 0, "y": A_ScreenHeight * 12 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "FOLLOW":{"x": 0, "y": A_ScreenHeight * 13 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}}
      , "desktopButtons":{"x": 0, "y": A_ScreenHeight / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight * 10 / 14}}}
  } else if(taskY > 0) { ; bottom edge is opposite
    return {"edge": "top",  "orientation": "horizontal", "taskbar": taskBarDimensions, "positions"
      : {"guiSpace": {"x": 0, "y": 0, "w":   A_ScreenWidth, "h": A_ScreenHeight/32}
      , "specialButtons"
      : {"X": {"x": 0, "y": 0, "w": A_ScreenWidth /32 , "h": A_ScreenHeight / 32}
      , "+":{"x": A_ScreenWidth  * 29 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}
      , "GRAB":{"x": A_ScreenWidth * 30 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}
      , "FOLLOW":{"x": A_ScreenWidth * 31 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}}
      , "desktopButtons":{"x": A_ScreenWidth /32, "y": 0, "w": A_ScreenWidth * 28 / 32 , "h": A_ScreenHeight / 32}}}
  } else if(taskW > taskH) { ;top edge is opposite
    return {"edge": "bottom", "orientation": "horizontal", "taskbar": taskBarDimensions, "positions"
      : {"guiSpace": {"x": 0, "y": A_ScreenHeight * 31 / 32, "w":   A_ScreenWidth, "h": A_ScreenHeight/32}
      , "specialButtons"
      : {"X": {"x": 0, "y": 0, "w": A_ScreenWidth /32 , "h": A_ScreenHeight / 32}
      , "+":{"x": A_ScreenWidth  * 29 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}
      , "GRAB":{"x": A_ScreenWidth * 30 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}
      , "FOLLOW":{"x": A_ScreenWidth * 31 /32, "y": 0, "w": A_ScreenWidth / 32, "h": A_ScreenHeight / 32}}
      , "desktopButtons":{"x": A_ScreenWidth /32, "y": 0, "w": A_ScreenWidth * 28 / 32 , "h": A_ScreenHeight / 32}}}
  } else { ; left edge is opposite
    return {"edge": "right",  "orientation": "vertical", "taskbar": taskBarDimensions, "positions"
      : {"guiSpace": {"x": A_ScreenWidth  * 29 / 30, "y": 0, "w":  A_ScreenWidth  / 30, "h": A_ScreenHeight}
      , "specialButtons"
      : {"X": {"x": 0, "y": 0, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "+":{"x": 0, "y": A_ScreenHeight * 11 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "GRAB":{"x": 0, "y": A_ScreenHeight * 12 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}
      , "FOLLOW":{"x": 0, "y": A_ScreenHeight * 13 / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight / 14}}
      , "desktopButtons":{"x": 0, "y": A_ScreenHeight / 14, "w": A_ScreenWidth / 30, "h": A_ScreenHeight * 11 / 14}}}
  }
}

; This function redraws the gui if desktops are created or removed 
guiCreateByDesktopCount() {
    global A_LastDesktopCount, taskBarLocation
    static task
    static badTitles := ["virtual_desktop_gui", "VirtualDesktopGUI.ahk", "", "Task Manager", "Program Manager"]
    measurements := getElementMeasurements()

/*     ;  Debug/Pretty Print the measurements object
      s .= "measurements:`n`tedge:"  measurements.edge
    . "`n`torientation: " measurements.orientation
    . "`n`ttaskbar dimensions {"
    . "`n`t`tx = " measurements.taskbar.x
    . "`n`t`ty = " measurements.taskbar.y
    . "`n`t`tw = " measurements.taskbar.w
    . "`n`t`th = " measurements.taskbar.h
    . "`n`t}"
    . "`n`torientation: " measurements.orientation
    . "`n`tpositions {"
    . "`n`t`tguiSpace { "
    . "`n`t`t`tx = " measurements.positions.guiSpace.x
    . "`n`t`t`ty = " measurements.positions.guiSpace.y
    . "`n`t`t`tw = " measurements.positions.guiSpace.w
    . "`n`t`t`th = " measurements.positions.guiSpace.h
    . "`n`t`t}"
    . "`n`t`tremoveButton { "
    . "`n`t`t`tx = " measurements.positions.removeButton.x
    . "`n`t`t`ty = " measurements.positions.removeButton.y
    . "`n`t`t`tw = " measurements.positions.removeButton.w
    . "`n`t`t`th = " measurements.positions.removeButton.h
    . "`n`t`t}"
    . "`n`t`taddButton { "
    . "`n`t`t`tx = " measurements.positions.addButton.x
    . "`n`t`t`ty = " measurements.positions.addButton.y
    . "`n`t`t`tw = " measurements.positions.addButton.w
    . "`n`t`t`th = " measurements.positions.addButton.h
    . "`n`t`t}"
    . "`n`t`tgrabButton { "
    . "`n`t`t`tx = " measurements.positions.grabButton.x
    . "`n`t`t`ty = " measurements.positions.grabButton.y
    . "`n`t`t`tw = " measurements.positions.grabButton.w
    . "`n`t`t`th = " measurements.positions.grabButton.h
    . "`n`t`t}"
    . "`n`t`tfollowButton { "
    . "`n`t`t`tx = " measurements.positions.followButton.x
    . "`n`t`t`ty = " measurements.positions.followButton.y
    . "`n`t`t`tw = " measurements.positions.followButton.w
    . "`n`t`t`th = " measurements.positions.followButton.h
    . "`n`t`t}"
    . "`n`t`tdesktopButtons { "
    . "`n`t`t`tx = " measurements.positions.desktopButtons.x
    . "`n`t`t`ty = " measurements.positions.desktopButtons.y
    . "`n`t`t`tw = " measurements.positions.desktopButtons.w
    . "`n`t`t`th = " measurements.positions.desktopButtons.h
    . "`n`t`t}"
    . "`n`t}"
    . "`n}`n`n" 
    */

    global DesktopCount
    ; Only remake the gui if the destop count changes, or if the taskbar location changes
    if (taskBarLocation 
    && A_LastDesktopCount = DesktopCount
    && task.x = measurements.taskbar.x
    && task.y = measurements.taskbar.y
    && task.w = measurements.taskbar.w
    && task.h = measurements.taskbar.h) {
      return taskBarLocation
    }
    
    guiSpace := measurements.positions.guiSpace
    gui destroy
    gui, -dpiscale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border +E0x08000000

    ; Create a new button for each desktop
    isVertical := measurements.orientation = "vertical"
    loop,% DesktopCount {
        buttonIncrement := (!isVertical) 
        ? measurements.positions.desktopButtons.w / DesktopCount
        : measurements.positions.desktopButtons.h / DesktopCount
        
      ;each desktop button has the same dimensions
      Gui, Add, Button, % ""
      . " x" measurements.positions.desktopButtons.x + ( isVertical ? 0 : measurements.positions.desktopButtons.w /  DesktopCount * (A_Index - 1))
      . " y" measurements.positions.desktopButtons.y + ( isVertical ? measurements.positions.desktopButtons.h /  DesktopCount * (A_Index - 1) : 0)
      . " w" measurements.positions.desktopButtons.w / ( isVertical ? 1: DesktopCount)
      . " h" measurements.positions.desktopButtons.h / ( isVertical ? DesktopCount: 1)
      . " gDesktopButtons"
      ,% "DESKTOP" A_Index
      
      p := "DESKTOP " A_Index " { "
      . "`n`tx = " (measurements.positions.desktopButtons.x + ( isVertical ? 0 : buttonIncrement * A_Index))
      . "`n`ty = " (measurements.positions.desktopButtons.y +( isVertical ? buttonIncrement * A_Index : 0))
      . "`n`tw = " measurements.positions.desktopButtons.w
      . "`n`th = " measurements.positions.desktopButtons.h
      . "`n}`n"
      s .= p
    }
    
    ; Create each of the special function buttons
    for buttonName, specialButton in measurements.positions.specialButtons {
      ; Debug to see where special buttons wil be placed
      ;~ MsgBox % "buttonName is "  """" buttonName """" ":`nx = " specialButton.x ", y = " specialButton.y ", w = " specialButton.w ", h = " specialButton.h
      
      Gui, Add, Button, % ""
    . " x" specialButton.x
    . " y" specialButton.y
    . " w" specialButton.w
    . " h" specialButton.h
    ,% buttonName
    }
    
    ; Name the gui and get its position, and save the taskbar 
    ; x and y coordinates to check if the gui should move later
    gui, show,% ""
    . " x" guiSpace.x
    . " y" guiSpace.y
    . " w" guiSpace.w
    . " h" guiSpace.h
    ,% "virtual_desktop_gui"
    
    WinGetActiveTitle, guistats
    WinGetPos, guix, guiy, guiwidth, guiheight, %guistats% 

    ; For debugging
    ;~ MsgBox % s
    
    WinGet, Z_Order_List, List
    edge := measurements.edge
    Loop % Z_Order_List {
        WinGetTitle, ID2Title, % "ahk_id " Z_Order_List%A_Index%
        if (!DllCall("IsWindowVisible",uint,Z_Order_List%A_Index%)){
          continue
        }
        if(contains(badTitles, ID2Title)) {
          continue
        }
        
        WinGetPos, x, y, w, h,% ID2Title
        
        ; too far left, scoot right and subtract from width
        if(x < guiSpace.w && edge = "left"){
          x := guiSpace.w
          w -= (guiSpace.w - x)
        }
        ; too far up, scoot down and subtract from width
        if(y < guiSpace.h && edge = "top"){
          y := guiSpace.h
          h -= (guiSpace.h - y)
        }
        ; too far down, subtract from height
        if(y > guiSpace.y && edge = "bottom"){
          h -= (y + h - guiSpace.y)
        }
        ; too far right, subtract from width
        if(x + w > guiSpace.x && edge = "right"){
          w -= (x + w - guiSpace.x)
        }
        
        title := "ahk_id " Z_Order_List%A_Index%
        WinMove,% title,, x, y, w, h
    }
    taskBarLocation := edge
}

; Helper method to make sure we don't try to move 
; certain windows that should not or cannot be moved.
contains(badTitles, title) {
  for key, val in badTitles {
    if(val = title) {
      return true
    }
  }
  return false
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

; This function creates a new virtual desktop and associated button
createVirtualDesktop() {
  global CurrentDesktop, DesktopCount
  Send, #^d
  DesktopCount++
  A_LastDesktopCount++
  CurrentDesktop = %DesktopCount%
  OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
  guiCreateByDesktopCount()
}

; This function deletes the current virtual desktop and associated button
deleteVirtualDesktop() {
  global CurrentDesktop, DesktopCount
  if(DesktopCount == 1){
    return
  }
  Send, #^{F4}
  DesktopCount--
  A_LastDesktopCount--
  CurrentDesktop--
  OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
  guiCreateByDesktopCount()
}

/*
User config!
This section binds the key combo to the switch/create/delete actions
Uncomment the hotkeys you want to use, or just handle everything through
the gui :)
*/
^#f4::deleteVirtualDesktop()
^#1::switchDesktopByNumber(1)
^#2::switchDesktopByNumber(2)
^#3::switchDesktopByNumber(3)
^#4::switchDesktopByNumber(4)
^#5::switchDesktopByNumber(5)
^#6::switchDesktopByNumber(6)
^#7::switchDesktopByNumber(7)
^#8::switchDesktopByNumber(8)
^#9::switchDesktopByNumber(9)
^#0::switchDesktopByNumber(10)


; Hotkey F18 is a stylus pen button, used to detect gui presses,
; and toggles the boolean value 'movewin'
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

; This label checks if the gui needs to be redrawn
guiCheck: 
guiCheck()
SetTimer, guiCheck, -500
return

guiCheck() {
  global taskBarLocation
  static registryLocations 
  := {"00": ["Left",  "right"]
  ,"01": ["Top", "bottom"]
  ,"02": ["Right", "left"]
  ,"03": ["Bottom", "top"]}
  registry := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
  RegRead,location,% registry,Settings
  location := registryLocations["" SubStr(location, 25, 2)]
  newTaskBarLocation := location[1]
  guiLocation := location[2]
  If(newTaskBarLocation != taskBarLocation) {
    guiCreateByDesktopCount()
    taskBarLocation := newTaskBarLocation
  }
}

Button+:
createVirtualDesktop()
return
ButtonX:
deleteVirtualDesktop()
return
