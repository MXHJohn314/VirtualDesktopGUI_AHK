#SingleInstance force
#Persistent
;~ #NoTrayIcon

main() {
  ; Globals
  global desknum
  global targetnum
  
  ; Modern Apps need this prefix to their titles in order to move them
  MODERN_APP_AHK_CLASS 
  := "ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe"

  SetKeyDelay, 75
  taskBarLocation := mapDesktopsFromRegistry()
  setTimer, guiCheck, 5
}
main()

; This function looks at the registry to determine the list of virtual desktops
mapDesktopsFromRegistry(rebuildGui := true) {
  global CurrentDesktop, DesktopCount
  
  ; Get the current desktop UUID. Length should be 32 always, but there's 
  ; no guarantee this couldn't change in a later Windows release so we check.
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
  if(rebuildGui) {
    guiCreateByDesktopCount(taskBarHasMoved().taskCoords) ;create the gui
  }

  ; Parse the REG_DATA string that stores the array of UUID's 
  ; for virtual desktops in the registry.
  i := 0
  while (CurrentDesktopId and i < DesktopCount) {
    StartPos := (i * IdLength) + 1
    DesktopIter := SubStr(DesktopList, StartPos, IdLength)
    
    ; Break out if we find a match in the list. If we didn't find anything,
    ; keep the old guess and pray we're still correct.
    if (DesktopIter = CurrentDesktopId) {
      CurrentDesktop := i + 1
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
getElementMeasurements(taskCoords) {
  screen := {"w": A_ScreenWidth, "h": A_ScreenHeight}
  
  ; task bar to the right, gui to the left
  if(taskCoords.x > 0) { 
    return {"edge": "left"
            ,"orientation": "vertical"
            ,"taskbar": taskCoords
            ,"positions"
              : {"guiSpace"
                  : {"x": 0, "y": 0
                  , "w":  screen.w  / 30, "h": screen.h}
            ,"specialButtons"
              :{"X"
                  :{"x": 0, "y": 0
                  , "w": screen.w / 30, "h": screen.h / 14}
              ,"+"
                  :{"x": 0, "y": screen.h * 11 / 14
                  , "w": screen.w / 30, "h": screen.h / 14}
              ,"GRAB"
                  :{"x": 0, "y": screen.h * 12 / 14
                  , "w": screen.w / 30, "h": screen.h / 14}
              ,"FOLLOW"
                    :{"x": 0, "y": screen.h * 13 / 14
                    , "w": screen.w / 30, "h": screen.h / 14}}
              ,"desktopButtons"
                  :{"x": 0, "y": screen.h / 14
                  , "w": screen.w / 30, "h": screen.h * 10 / 14}}}
                  
  ; task bar at the bottom, gui at the top
  } else if(taskCoords.y > 0) { ; bottom edge is opposite
    return {"edge": "top"
            ,"orientation": "horizontal"
            ,"taskbar": taskCoords
            ,"positions"
              : {"guiSpace"
                    :{"x": 0, "y": 0
                    , "w":   screen.w, "h": screen.h/32}
              ,"specialButtons"
                    : {"X": {"x": 0, "y": 0
                    , "w": screen.w /32 , "h": screen.h / 32}
              ,"+"
                    :{"x": screen.w  * 29 /32, "y": 0
                    , "w": screen.w / 32, "h": screen.h / 32}
              ,"GRAB"
                    :{"x": screen.w * 30 /32, "y": 0
                    , "w": screen.w / 32, "h": screen.h / 32}
              ,"FOLLOW"
                    :{"x": screen.w * 31 /32, "y": 0
                    , "w": screen.w / 32, "h": screen.h / 32}}
              , "desktopButtons"
                    :{"x": screen.w /32, "y": 0
                    , "w": screen.w * 28 / 32 , "h": screen.h / 32}}}
                    
  ; task bar to the at the top, gui at the bottom
  } else if(taskCoords.w > taskCoords.h) {
    return {"edge": "bottom"
            ,"orientation": "horizontal"
            ,"taskbar": taskCoords
            ,"positions"
              :{"guiSpace"
                :{"x": 0, "y": screen.h * 31 / 32
                ,"w":   screen.w, "h": screen.h/32}
              ,"specialButtons"
              :{"X"
                  :{"x": 0, "y": 0
                  ,"w": screen.w /32 , "h": screen.h / 32}
              ,"+"
                  :{"x": screen.w  * 29 /32, "y": 0
                  ,"w": screen.w / 32, "h": screen.h / 32}
              ,"GRAB"
                  :{"x": screen.w * 30 /32, "y": 0
                  ,"w": screen.w / 32, "h": screen.h / 32}
              ,"FOLLOW"
                  :{"x": screen.w * 31 /32, "y": 0
                  , "w": screen.w / 32, "h": screen.h / 32}}
              ,"desktopButtons"
                  :{"x": screen.w /32, "y": 0
                  , "w": screen.w * 28 / 32 , "h": screen.h / 32}}}
                  
  ; task bar to the left, gui to the right
  } else {
    return {"edge": "right"
            ,"orientation": "vertical"
            , "taskbar": taskCoords
            , "positions"
              : {"guiSpace"
                  :{"x": screen.w  * 29 / 30, "y": 0
                  , "w":  screen.w  / 30, "h": screen.h}
              ,"specialButtons"
                  :{"X": {"x": 0, "y": 0
                  , "w": screen.w / 30, "h": screen.h / 14}
              ,"+"
                  :{"x": 0, "y": screen.h * 11 / 14
                  ,"w": screen.w / 30, "h": screen.h / 14}
              ,"GRAB"
                  :{"x": 0, "y": screen.h * 12 / 14
                  ,"w": screen.w / 30, "h": screen.h / 14}
              ,"FOLLOW"
                  :{"x": 0, "y": screen.h * 13 / 14
                  , "w": screen.w / 30, "h": screen.h / 14}}
              ,"desktopButtons"
                  :{"x": 0, "y": screen.h / 14
                  , "w": screen.w / 30, "h": screen.h * 11 / 14}}}
  }
}

; This function checks if the task bar has moved
taskBarHasMoved() {
  global DesktopCount
  static A_LastDesktopCount
  static oldCoords := ""
  WinGetPos, taskX, taskY, taskW, taskH, ahk_class Shell_TrayWnd
  taskCoords := {"x": taskX, "y": taskY, "w": taskW, "h": taskH}
  hasMoved
  := A_LastDesktopCount != DesktopCount
    || oldCoords.x != taskCoords.x
    || oldCoords.y != taskCoords.y
    || oldCoords.w != taskCoords.w
    || oldCoords.h != taskCoords.h
    
    oldCoords := taskCoords
    A_LastDesktopCount := DesktopCount
    return {"hasMoved": hasMoved, "taskCoords": taskCoords}
}

; This function redraws the gui if desktops are created or removed 
guiCreateByDesktopCount(taskCoords) {
    global A_LastDesktopCount, taskBarLocation, DesktopCount

    static badTitles := ["virtual_desktop_gui"
                        , "VirtualDesktopGUI.ahk"
                        , ""
                        , "Task Manager"
                        , "Program Manager"]

    measurements := getElementMeasurements(taskCoords)
    
    guiSpace := measurements.positions.guiSpace
    gui destroy
    gui,% "-dpiscale"
        . " +LastFound"
        . " +AlwaysOnTop"
        . " +ToolWindow"
        . " -Caption"
        . " +Border"
        . " +E0x08000000"

    ; Create a new button for each desktop
    isVertical := measurements.orientation = "vertical"
    posButtons := measurements.positions.desktopButtons

    loop,% DesktopCount {
        buttonIncrement := (!isVertical) 
        ? posButtons.w / DesktopCount
        : posButtons.h / DesktopCount
        
      ;each desktop button has the same dimensions
      Gui, Add, Button, % ""
      . " x" posButtons.x + ( isVertical ? 0 
                            : posButtons.w /  DesktopCount * (A_Index - 1))
      . " y" posButtons.y + ( isVertical 
                            ? posButtons.h /  DesktopCount * (A_Index - 1) : 0)
      . " w" posButtons.w / ( isVertical ? 1: DesktopCount)
      . " h" posButtons.h / ( isVertical ? DesktopCount: 1)
      . " gDesktopButtons"
      ,% "DESKTOP" A_Index
      
      p := "DESKTOP " A_Index " { "
      . "`n`tx = " (posButtons.x + ( isVertical 0
                                    ? 0 : buttonIncrement * A_Index))
      . "`n`ty = " (posButtons.y +( isVertical 
                                    ? buttonIncrement * A_Index : 0))
      . "`n`tw = " posButtons.w
      . "`n`th = " posButtons.h
      . "`n}`n"
      s .= p
    }
    
    specialButtons := measurements.positions.specialButtons
    ; Create each of the special function buttons
    for buttonName, specialButton in specialButtons {
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
  mapDesktopsFromRegistry(false)

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
  guiCreateByDesktopCount(taskBarHasMoved().taskCoords)
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
  guiCreateByDesktopCount(taskBarHasMoved().taskCoords)
}

; Hotkey F18 is a stylus pen button, used to detect gui presses,
; and toggles the boolean value 'movewin'
~F18::windowWasGrabbed = true

; This is the button for selecting a one-time movement of
; a window to whichever virtual desktop is chosen next
ButtonGRAB:
if (windowWasGrabbed) {
  ToolTip, Window movement off, %grabx%-300, %graby%-100
  windowWasGrabbed := false
  SetTimer, RemoveToolTip, 5000
  return
}
ToolTip,% "Window movement on`r(Tap a window"
        . "`rand select a desktop)", %grabx%-300, %graby%-100

windowWasGrabbed := true
SetTimer, RemoveToolTip, 5000
return

; This is the button for selecting a window to always 
; follow the user to the active desktop
ButtonFOLLOW:
WinWaitNotActive, desktop switcher
WinGetActiveTitle, bring
if (bringwin) {
  bringwin := false
  SetTimer, RemoveToolTip, 5000
  return
}
ToolTip,% "Active window will follow"
          . "`ryou to each desktop", %grabx%-300, %graby%-100

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

; Save the active window's name to potentially move it later
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
; It invokes the guiCheck function below
guiCheck: 
guiCheck()
SetTimer, guiCheck, -500
return

; This function checks if the gui needs to move.
; It is invoked from the guiCheck label above
guiCheck() {
  taskBarCheck := taskBarHasMoved()
  if(taskBarCheck.hasMoved) {
    guiCreateByDesktopCount(taskBarCheck.taskCoords)
  }
}

; This is the add button label
Button+:
createVirtualDesktop()
return

; This is the remove button label
ButtonX:
deleteVirtualDesktop()
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*
User config!
This section binds a key combo to the switch/create/delete actions.
Each combo is one of the following:
  Windows Key + <number> --> switch to that numebr desktop (0 = desktop 10)
  Windows Key + <f4> --> delete the current desktop
Uncomment the hotkeys you want to use, or just leave it alone and
handle everything through the gui :)
*/
;~ ^#f4::deleteVirtualDesktop()
;~ ^#1::switchDesktopByNumber(1)
;~ ^#2::switchDesktopByNumber(2)
;~ ^#3::switchDesktopByNumber(3)
;~ ^#4::switchDesktopByNumber(4)
;~ ^#5::switchDesktopByNumber(5)
;~ ^#6::switchDesktopByNumber(6)
;~ ^#7::switchDesktopByNumber(7)
;~ ^#8::switchDesktopByNumber(8)
;~ ^#9::switchDesktopByNumber(9)
;~ ^#0::switchDesktopByNumber(10)
