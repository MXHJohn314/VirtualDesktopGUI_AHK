#SingleInstance, force

goto, mapRectangles

mapRectangles:
{
    splitModes := {}
    splitModes["ThreeTall"] := [{"x": 0, "y": 0, "w": 1 / 3, "h": 1}, {"x": 1 / 3, "y": 0, "w": 1 / 3, "h": 1}, {"x": 2 / 3, "y": 0, "w": 1 / 3, "h": 1}]
    splitModes["SplitTopBottom"] := [{"x": 0, "y": 0, "w": 1, "h": 1 / 2}, {"x": 0, "y": 1 / 2, "w": 1, "h": 1 / 2}]
    numArrangements := 0 ;number of 'RectangleArrangement's
    rectangles := [ ] ; holds a single 'RectangleArrangement'
    arrangements := {} ; holds all the 'RectangleArrangement's
    offset := 0 ; accumulates an offset of where to place the next arrangement's elements in the gui
    scaleY := A_ScreenHeight / 16 ; scale for Rectangle.x fields
    scaleX := A_ScreenWidth / ( 2 * (numArrangements > 6 ? numArrangements : 6)) ; scale for Rectangle.y fields
    buttonWidth := A_ScreenWidth / 20 ; width for 'gTop' buttons
    topButtonH := A_ScreenHeight / ( buttonWidth / A_ScreenWidth ) ; height for 'gTop buttons
    default_color := 0xffffff
    guiWidth := 0 ;start new buttons at 0
    padding := buttonWidth / 20
    gui, gBottom: +AlwaysOnTop +Caption -ToolWindow
    numArrangements := 0
    for arrangementName, measurements in splitModes { ; look into each arrangement in the associative array
        for i, rect in measurements { ; look at all the rectangles inside each arrangement
            if(i == 1) {
                soloButtonPos := guiWidth ; The x position of any arrangement when it is in "solo mode" is the same as the first arrangement's x position
            }
            r := new Rectangle({"x": rect.x, "y": rect.y, "w": rect.w, "h": rect.h, "name": arrangementName  "_" A_Index
            , "homePos": {"x": rect.x * scaleX + guiWidth, "y": rect.y * scaleY, "w": rect.w * scaleX, "h":  rect.h * scaleY}
            , "soloPos": {"x": rect.x * scaleX, "y": rect.y * scaleY, "w": " w" rect.w * scaleX, "h":  rect.h * scaleY}})
            rectangles.push(r)
            h := r.homePos
            gui, gBottom: add, button,% "hwnd" r.hwnd " v" r.name " gmini x" h.x " y" h.y " w" h.w " h"  h.h , % r.name
            r.hwnd := rhwnd
            r.homePos := recPos
            r.soloPos := r.x * scaleX
        }

        a := new RectangleArrangement({"rectangles": rectangles, "len": i, "factor": scaleX, "name": arrangementName, "buttonPos": {"x": guiWidth, "y": padding, "w": scaleX, "h": topButtonH}, "soloButtonPos": {"x": soloButtonPos, "y": padding, "w": scaleX, "h": topButtonH}})
        h := a.buttonPos
        f := func("setSoloPosition").bind(a, arrangements)
        gui, gTop: add, Button,% " v" a.name " x" h.x " y" h.x " w" h.w " h" h.h " hwnd" a.hwnd  " gsetSoloPosition",% a.name
        ;~ gui, gTop: add, button,% "hwnd" a.hwnd " v" a.name " gfirstTop x" h.x " y" h.x " w" h.w " h" h.h, % a.name
        guiWidth += scaleX + padding
        rectangles := [ ] ;empty the rectangles array for the next set, then push to array
        arrangements[arrangementName] := a
        numArrangements += 1
    }
    guiWidth += padding ;

    gui, gBottom: +AlwaysOnTop +Caption -ToolWindow -Border
    gui, gTop: +AlwaysOnTop +Caption -ToolWindow -Border
    Gui, gBottom: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - scaleY " w" guiWidth " h" scaleY, gBottom
    Gui, gTop: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - scaleY " w" guiWidth " h" scaleY, gTop
    WinSet, Transparent, 1, gTop
    Gui, gBottom: hide
    Gui, gTop: Hide
    return
}
setSoloPosition:
currentArrangement := arrangements[A_GuiControl]
for arangementName, arrangement in arrangements {
    isSelectedArranment := arrangement.name = A_GuiControl
    arrangement.setSoloPosition(isSelectedArranment)
    arrangement.setVisible(isSelectedArranment)
}
goto soloPositionLabel
return

mini:
Gui, gBottom: hide ; selected a button, so hide both
Gui, gTop: Hide

return

mini(controlName, offsetX) {
    MsgBox % A_GuiControl
    GuiControlGet, miniposition, Pos, %controlName%
    minipositionX -= offsetX
    return minipositionX
}

moveWindows(arrangement) {

   global gBottom ; Declare global variables to be used within the function
    global gTop

    SetTitleMatchMode, 2 ; Set the title match mode to match any part of the window title

   for _, r in  % arrangement.rectangles { ; loop through the rectangles in the selected arrangement
       send, ^!{Tab} ; Send a Ctrl+Alt+Tab keystroke to activate task switching
       sleep, 300 ; wait for 300ms to ensure the window switcher has appeared
       WinWaitNotActive, Task Switching ; Wait for the task switcher to disappear
       WinGetActiveTitle, t ; Get the title of the currently active window
       r.window := t ; Assign the title to the "window" property of the rectangle object
   }

   for _, r in arrangement.rectangles { ; loop through all the rectangles in the arrangement (including those that weren't selected)
       r.moveWindow() ; Call the "moveWindow" method on each rectangle to move its associated window
   }

   Hotkey, ^!Tab, on ; Turn on the hotkey for Ctrl+Alt+Tab
   Gui, gBottom: hide ; Hide the bottom panel (which contains the buttons to select the arrangements)
   Gui, gTop: Hide ; Hide the top panel (which contains the buttons to toggle the hotkeys)

   return ; End the function
}
soloPositionLabel:
GuiControlGet, %A_GUIControl%position, Pos, %A_GuiControl%
newX := %A_GUIControl%positionW
for key, val in arrangements {
    if !(InStr(  A_GuiControl,val.name ) ) { ; Find out if the RectangleArrangement goes with the pressed button
        controlName := val.name ; If not, hide the translucent button that goes with that RectangleArrangement
        GuiControl, gTop: Hide, %controlName%
        for k, v in val.rectangles {
            GuiControl, gBottom: Hide, % v.name ; hide all the Rectangles inside that Rectangle Arrangement
        }
    }
    else { ; The only one that will remain goes with the clicked Rectangle Arrangement
        controlName := val.name
        GuiControlGet, gTopposition, Pos, %controlName% ; move it over to x0
        gToppositionX -= newX
        GuiControl, Move, %controlName%, x%gToppositionX% y%gToppositionY% w%gToppositionW% h%gToppositionH%
        WinActivate, gBottom ; do the same for its Rectangles
        ;*** This loop has all the trouble!!
        for k, v in val.rectangles {
            controlName := v.name
            GuiControlGet, OutputVar, Pos , % v.name
            GuiControl, Move, %controlName%, x
        }
    }
}
GuiControl, MoveDraw, %A_GuiControl%, % "-x"  %newX%
;~ Gui, gTop: Show, xCenter y%scaleY% w%buttonWidth% h%scaleY%
Gui, gTop: hide
;~ Gui, gBottom: Show, xCenter y%scaleY% w%buttonWidth% h%scaleY%
Gui, gBottom: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - scaleY " w" gToppositionW " h" scaleY, gBottom
moveWindows(arrangement)
return
Escape::ExitApp

Class RectangleArrangement {
    __New(params)
    {
        for key, value in params{
            this[key] := value
        }
        this.hwnd := "h_" this.name
    }

    setSoloPosition(isSelectedArrangement) {
        if(isSelectedArrangement) {
            for k, r in this.rectangles {
                GuiControl, Move, r.name,% "x" r.soloPos " y" r.y " w" r.w " h" r.h
            }
        } else {
            for k, r in this.rectangles {
                GuiControl, Move, r.name,% "x" r.x " y" r.y " w" r.w " h" r.h
            }
        }
    }

    setVisible(bool) {
        if(bool) {
            for k, v in this.rectangles {
                GuiControl, gBottom: Show,% v.name
            }
            GuiControl, gTop: Show,% this.name
        } else {
            for k, v in this.rectangles {
                GuiControl, gBottom: Hide,% v.name
            }
            GuiControl, gTop: Hide,% this.name
        }
    }
}

Class Rectangle {
    __New(params)
    {
        for key, value in params{
            this[key] := value
        }
        this.hwnd := "h_" this.name
    }
    moveWindow() {
        x :=  this.x * A_ScreenWidth
        y := this.y * A_ScreenHeight
        w := this.w * A_ScreenWidth
        h := this.h * A_ScreenHeight
        WinMove,% this.window,,%x%,%y%, %w% ,%h%
        this.window := ""
    }
}
^!Tab::
Gui, gBottom: Show,% "xCenter y0 w" guiWidth " h" scaleY, gBottom
Gui, gTop: Show,% "xCenter y0 w" guiWidth " h" scaleY, gTop
WinActivate, gTop
Hotkey, ^!Tab, off
return
