#SingleInstance force
; Globals
global desknum
global targetnum
;~ #NoTrayIcon
mapDesktopsFromRegistry() {
 global CurrentDesktop, DesktopCount
 ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
 IdLength := 32
 SessionId := getSessionId()
 if (SessionId) {
 RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
 if (CurrentDesktopId) {
 IdLength := StrLen(CurrentDesktopId)
 }
 }
 ; Get a list of the UUIDs for all virtual desktops on the system
 RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
 if (DesktopList) {
 DesktopListLength := StrLen(DesktopList)
 ; Figure out how many virtual desktops there are
 DesktopCount := DesktopListLength / IdLength
 }
 else {
 DesktopCount := 1
 }
A_LastDesktopCount := DesktopCount ; remember how many desktops there are
guiCreateByDesktopCount() ;create the gui

 ; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
 i := 0
 while (CurrentDesktopId and i < DesktopCount) {
 StartPos := (i * IdLength) + 1
 DesktopIter := SubStr(DesktopList, StartPos, IdLength)
 OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.
 ; Break out if we find a match in the list. If we didn't find anything, keep the
 ; old guess and pray we're still correct :-D.
 if (DesktopIter = CurrentDesktopId) {
 CurrentDesktop := i + 1
 OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
 break
 }
 i++
 }
}
;
; This functions finds out ID of current session.
;
getSessionId()
{
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
}
; This function redraws the gui if new desktops are created or removed 
guiCreateByDesktopCount()
{
 WinGetPos, taskx, tasky, taskwidth, taskheight, ahk_class Shell_TrayWnd ;find out where the taskbar is
 If (A_screenwidth < A_screenheight) ;if the tablet has a longer width than height
 {
  A_useableWidth:= A_screenheight
  A_useableheight:= A_ScreenWidth
  }  
 else
 {
  A_useableWidth:= A_ScreenWidth
  A_useableheight:= A_screenheight
 }
 otherbuttons:= ((A_useableWidth/30)*1.5) ;define the width of the three buttons X, GRAB, & FOLLOW
 guiwidth:= (A_useableWidth) ;define the gui width as the width
 guiheight:= (A_useableheight/50) ;define the gui height as 1/50 of A_Screenheight
 if (tasky = 0) ;if the taskbar is positioned at the top of the screen
  guidepth:= (A_useableheight-guiheight) ;gui will be positioned  at the bottom
 else
  guidepth:= 0 ;if the taskbar is at the bottom of the screen, position the gui at the top of the screen
 if (taskwidth < A_useableWidth/3) ;if the taskbar is in vertical position
  guiwidth:= (guiwidth-taskwidth) ;shrink the gui to accomodate a smaller width
 global DesktopCount
 if (A_LastDesktopCount != DesktopCount) || (taskx_prev != taskx) || (tasky_prev != tasky) ;remake the gui if the destop count changes, or if the taskbar location changes
 {
  gui destroy
  gui, -dpiscale ;make sure the gui is not scaled to 96 DPI
  buttonwidth:=((guiwidth-otherbuttons*4)/DesktopCount-2) ;each desktop button should be the remaining screen width divided by the total number of desktops, munus 4 buttons of a different size
  Gui, +LastFound +AlwaysOnTop +ToolWindow -Caption +Border +E0x08000000 ;style the gui
  buttonlocation:= 0
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h24 , X ;add non-desktop button (close button) 
  buttonlocation := (otherbuttons) ;increment the button location with the width of the last button created
  buttoncount += 1 ;increment the button count
  loop, %DesktopCount% ;create a new button for each desktop
  {
   Gui, Add, Button, x%buttonlocation% y2 w%buttonwidth% h%guiheight% gDesktopButtons, DESKTOP%A_Index% ;each desktop button has the same dimensions
   buttonlocation := (buttonlocation+buttonwidth+2) ;with a little space between each button
   buttoncount += 1 ;increment the button count after each desktop button
  }
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h%guiheight% , + ;create a button to add a new desktop
  buttonlocation := (buttonlocation+otherbuttons) ;start the next button at the end of this one
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h%guiheight% , GRAB ;create a button to grab a window and take it to another desktop
  buttonlocation := (buttonlocation+otherbuttons) ;start the next button at the end of this one
  Gui, Add, Button, x%buttonlocation% y2 w%otherbuttons% h24 , FOLLOW ;create a button to add a new desktop
  buttoncount += 3 ;increment these buttons to the button count
  ;position the gui depending on task bar location
  if (taskwidth < A_useableWidth/2) && (taskx > 0) ;if the taskbar is vertical on the right side of the screen
   gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  if (taskwidth < A_useableWidth/2) && (taskx < 5) ;if the taskbar is vertical on the left side of the screen
   gui, show, x%taskwidth% y%guidepth% w%guiwidth% h%guiheight%
  if (taskwidth > A_useableWidth/2) && (tasky < 5) ;if the taskbar is horzontal at the top of the screen
   gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  if (taskwidth > A_useableWidth/2) && (tasky > 5) ;if the taskbar is horzontal at the bottom of the screen
   gui, show, x0 y%guidepth% w%guiwidth% h%guiheight%
  WinGetActiveTitle, guistats ;variable name for the gui
  WinGetPos, guix, guiy, guiwidth, guiheight, %guistats% ;get the position of the gui window to reference it later
  taskx_prev:= %taskx% ;save the taskbar x and y coordinates to check later if they change
  tasky_prev:= %tasky%
 }
}
; This function switches to the desktop number provided.
;this came with the original script
switchDesktopByNumber(targetDesktop)
{
 global CurrentDesktop, DesktopCount
 ; Re-generate the list of desktops and where we fit in that. We do this because
 ; the user may have switched desktops via some other means than the script.
 mapDesktopsFromRegistry()
 ; Don't attempt to switch to an invalid desktop
 if (targetDesktop > DesktopCount || targetDesktop < 1) {
 OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
 return
 }
 ; Go right until we reach the desktop we want
 while(CurrentDesktop < targetDesktop) {
 Send ^#{Right}
 CurrentDesktop++
 OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
 }
 ; Go left until we reach the desktop we want
 while(CurrentDesktop > targetDesktop) {
 Send ^#{Left}
 CurrentDesktop--
 OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
 }
 DetectHiddenWindows, off
}

createVirtualDesktop()
{
 global CurrentDesktop, DesktopCount
 Send, #^d
 DesktopCount++
 A_LastDesktopCount++
 CurrentDesktop = %DesktopCount%
 OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
 guiCreateByDesktopCount()
}

deleteVirtualDesktop()
{
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
; User config!
; This section binds the key combo to the switch/create/delete actions
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
^#f4::deleteVirtualDesktop()

~f18::movewin = 1 ;this is a stylus pen button, used to toggle %movwin% and bring a window to a different desktop

ButtonGRAB:
if movewin = 1
{
 ToolTip, Window movement off, %grabx%-300, %graby%-100
 movewin = 0
SetTimer, RemoveToolTip, 5000
return
}
 ToolTip, Window movement on`r(Tap a window`rand select a desktop), %grabx%-300, %graby%-100
{
  movewin = 1
SetTimer, RemoveToolTip, 5000
return
}


ButtonFOLLOW:
WinWaitNotActive, desktop switcher
WinGetActiveTitle, bring
if bringwin = 1
{
 bringwin = 0
SetTimer, RemoveToolTip, 5000
return
}
 ToolTip, Active window will follow`ryou to each desktop, %grabx%-300, %graby%-100
{
  bringwin = 1
SetTimer, RemoveToolTip, 5000
return
}

Bringwin:
if bringwin = 1
{
 WinHide, %bring%
 sleep, 50
 winshow, %bring%
}

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

DesktopButtons: ;if any of the DESKTOP buttons are pressed...
global CurrentDesktop, DesktopCount
desknum:= A_GuiControl ;save the button's name to a variable
desknum:=RegExReplace(desknum, "DESKTOP", "") ;keep only the number to do math with it
targetDesktop := %desknum%
WinGetActiveTitle, title ;save the active window's name to potentially move it later
if (movewin = 1) || (grabwin) && (CurrentDesktop != targetDesktop) ;if we want to move a window to anothe desktop and any window (besides the gui) is active ...
{
 IfWinActive, ahk_class ApplicationFrameWindow
 {
  mapDesktopsFromRegistry()
  finish_task_view()
 }
 else
 {
  sleep, 100
  winhide, %title%
 }
}
switchDesktopByNumber(desknum)
if  (movewin) || (grabwin)
{
 sleep, 200
 winshow, %title%
 WinActivate, %title%
 movewin = 0
 return
}
else
{
 sleep, 200
 switchDesktopByNumber(desknum)
}
Sleep, 100
winshow, %title%
goto, Bringwin
return

finish_task_view() ;this function moves modern apps that won't respond to winshow or winhide commands
{
  global CurrentDesktop, targetnum
  MsgBox, CurrentDesktop: %CurrentDesktop%`rtargetnumber: %desknum%
  if (CurrentDesktop != desknum)
  {
   if (desknum = 1)
    {
     targetnum:= (0)
     MsgBox, 302
    }
   else if (desknum > CurrentDesktop) 
    {
     targetnum:= (targetnum-1) ;subtract 1 if the target desktop is larger
     MsgBox, 293 
    }
   else if (desknum < CurrentDesktop) 
    {
     targetnum:= (desknum-2) ;subtract 2 if the target desktop is smaller
     MsgBox, 298 %targetnum%
    }

   Sleep, 200
 send, #{tab}
 WinWaitActive, Task View
 movewin = 0
 send, {home down}{home up}{appskey down}{appskey up}
 Sleep, 50
 send, {down down}{down up}{down down}{down up}
 sleep, 300
 send, {Right down}{Right up}
 sleep, 300
 loop, %targetnum%
 {
  send, {down down}
  sleep, 50
  send, {down up}
 }
 send, {Space 2}
 WinWaitNotActive, Task View
 WinActivate, %title%
 SetKeyDelay, 0
 Sleep, 100
 winshow, %title%
 return
 }
}

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
^!LWin::
WinShow, %title%
winshow, %move%
return
