SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance, force
DetectHiddenWindows, On
Menu Tray, tip, %A_ScriptName% ; Custom traytip

ALPHA_MIN := 1 ; absolute transparency factor
SourceConstantAlpha := 255 ; opaque (WinSet, Transparent, Off is better,)
hexCol := 0xFFFFFF ;white
hexColUnder := hexCol
hexColOver := -1
hexColTransCol := -1
hexColLayer := -1
myRedUnder := -1
myGreenUnder := -1
myBlueUnder := -1
myRedOver := -1
myGreenOver := -1
myBlueOver := -1
myRedLayer := -1
myGreenLayer := -1
myBlueLayer := -1
myRedTransCol := -1
myGreenTransCol := -1
myBlueTransCol := -1
myTranspUnder := 0
myTranspOver := -1
myTransIntensityUnder := -1
myTransIntensityOver := -1
myTransIntensityUnderTransCol := -1
myTransIntensityUnderLayer := -1
myTransIntensityOverTransCol := -1
myTransIntensityOverLayer := -1
formShowing := 0
mouseSlide := 0
mouseDelay := 0
dragForm := 0
scriptLoaded := 0
useLayering := 0
overlayWindow := 0
SetlayerFn := 0
WS_BORDER := 0x800000
WS_SYSMENU := 0x80000
WS_CAPTION := 0xC00000
WS_MINIMIZEBOX := 0x20000
WS_OVERLAPPED := 0x00000000
WS_VISIBLE := 0x10000000


hdc_bmp := 0
screenDC := 0
;DC's for these window styles are handled by the system
CS_CLASSDC := 0x0040
CS_OWNDC := 0x0020
red := 255
green := 255
blue := 255

tmp := 0
tmp1 := 0


Class Obj
	{
	static GWL_STYLE := -16
	;0XFFFFFFFFFFFFFFF0
	static GWL_EXSTYLE := -20
	;0XFFFFFFFFFFFFFFEC
	ObjStyle()
	{
	GetWindowLongPtrA := DllCall("GetProcAddress", "PTR", DllCall("GetModuleHandleA", "AStr", "user32.dll", "PTR"), "AStr", "GetWindowLong" (A_PtrSize=8 ? "Ptr" : "") "A", "PTR")
	Return DllCall(GetWindowLongPtrA, "Ptr", this._hWnd, "Int", this.GWL_STYLE, "PTR")
	}
	ObjExStyle()
	{
	GetWindowLongPtrA := DllCall("GetProcAddress", "PTR", DllCall("GetModuleHandleA", "AStr", "user32.dll", "PTR"), "AStr", "GetWindowLong" (A_PtrSize=8 ? "Ptr" : "") "A", "PTR")
	Return DllCall(GetWindowLongPtrA, "Ptr", this._hWnd, "Int", this.GWL_EXSTYLE, "PTR")
	}
	hWnd
	{
		set
		{
		this._hWnd := value
		}
	}
}


;WS_EX_NOREDIRECTIONBITMAP := 0x00200000 ;The window does not render to a redirection surface. This is for windows that do not have visible content or that use mechanisms other than surfaces to provide their visual.
; https://msdn.microsoft.com/magazine/dn745861?f=255&MSPPError=-2147217396 explains a better way of layering with DirectX & WS_EX_NOREDIRECTIONBITMAP

/*
Not requ'd
WS_EX_COMPOSITED := 0x02000000 ;Paints all descendants of a window in bottom-to-top painting order using double-buffering. (For more information, see Remarks = in msdn remarks had gone). This cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. 
With WS_EX_COMPOSITED set, all descendants of a window get bottom-to-top painting order using double-buffering. Bottom-to-top painting order allows a descendent window to have translucency (alpha) and transparency (color-key) effects, but only if the descendent window also has the WS_EX_TRANSPARENT bit set. Double-buffering allows the window and its descendents to be painted without flicker.
WS_EX_TRANSPARENT := 0x00000020 ;The window should not be painted until siblings beneath the window (that were created by the same thread) have been painted. The window appears transparent because the bits of underlying sibling windows have already been painted. To achieve transparency without these restrictions, use the SetWindowRgn function.
*/





WS_EX_LAYERED := 0x00080000
; "The window is a layered window. This style cannot be used if the window has a class style of either CS_OWNDC or CS_CLASSDC. However, Win 8 does support the WS_EX_LAYERED style for child windows, where previous Windows versions support it only for top-level windows."
GW_CHILD := 0X05

OverlayVisible := 0

; ---------------------- More Variable decls----------------------
guiWidth := 0
guiHeight := 0
htmlW := floor(A_ScreenWidth/2)
htmlH := floor(2 * (A_ScreenHeight/5))

tmp := 0
controlW := floor(A_ScreenWidth/8)
x := 0, y := 0, w := 0, h := 0

; Helps with flickering on window move
OnMessage(0x14, "WM_ERASEBKGND")

; Move the window with the following called method produces excessive flickering
;Onmessage(0x03,"WM_MOVE")


;Must be -%WS_SYSMENU% or else the WM_INITMENUPOPUP interferes with capture of mousedown on titlebar- alternatively try EnableMenuItem(wparam, SC_MOVE, MF_DISABLED) https://social.msdn.microsoft.com/Forums/en-US/2ab0cc68-91de-4aea-8ea0-b0082aee4eb2/how-to-disable-title-bar-context-menu-move?forum=winforms
Gui, +OwnDialogs +HwndTranspTesterHwnd -%WS_SYSMENU% +%WS_OVERLAPPED%




Gui, Add, Radio, section vuseImage guseImage HWNDuseImageHwnd, Use Image in Underlay
Gui, Add, Radio, vuseActiveX guseActiveX HWNDuseActiveXHwnd, Use ActiveX in Underlay
Gui, Add, Radio, vuseNone guseNone HWNDuseNoneHwnd, No controls in Underlay

GuiControl,, useImage, 1

Gui, Add, Checkbox, vuseOverlay guseOverlay HWNDuseOverlayHwnd, Use Overlay


Gui, Add, Radio, ys vuseTransColor guseTransColor HWNDuseTransColorHwnd, Use TransColor
Gui, Add, Radio, vuseLayered guseLayered HWNDuseLayeredHwnd, Use Layering
Gui, Add, Radio, vuseNeither guseNeither HWNDuseNeitherHwnd, Use Neither
GuiControl,, useNeither, 1

Gui, Add, text,


Gui, Add, Radio, Checked ys vtransColUnd gtransColUnd HWNDtransColUndHwnd, Underlay
Gui, Add, Radio, vtransColOver gtransColOver HWNDtransColOverHwnd, Overlay


Gui, Color, Gray

Gui, Add, Slider, xm- section NoTicks -theme center w%controlW% HwndprogressRed vmyRed gSlide Range0-1, % red
Gui, Add, Slider, NoTicks -theme center w%controlW% HwndprogressGreen vmyGreen gSlide Range0-1, % green
Gui, Add, Slider, NoTicks -theme center w%controlW% HwndprogressBlue vmyBlue gSlide Range0-1, % blue
controlW := controlW/2
Gui, Add, Progress, w%controlW% h%controlW% vColour x+mp%controlW% ys Background%hexCol%,
controlW := 2 * controlW
Gui, Add, text, section xm- y+m w%controlW% vmyHex, % hexCol



Gui, Add, text, ys+m w%controlW% HwndtxtIntensityHwnd, TransColor Intensity:

Gui, Add, Slider, section xp y+m Vertical -theme center Buddy2transIntensity NoTicks h%controlW% HwndtransColIntensityHwnd vtransColIntensity gtransColIntensity Range0-1, 0

Gui, Add, text, xp y+m w%controlW% vtransIntensity, % myTransIntensityUnder
enableTransColorCtrls()



Gui, Add, Checkbox, xm- ys- section vuseTransparency guseTransparency HWNDuseTransparencyHwnd, Use Transparency
Gui, Add, text, , Transparency Options:

Gui, Add, Radio, vtransUnd gtransUnd HWNDtransUndHwnd, Transparent Underlay
GuiControl,, transUnd, 1
Gui, Add, Radio, vtransOver gtransOver HWNDtransOverHwnd, Transparent Overlay

Gui, Add, Slider, NoTicks -theme center Buddy2myTransp w%controlW% HwndprogressTransp vTranspt gTranspt Range0-1, 0
Gui, Add, text, w%controlW% vmyTransp
enableTranspCtrls(myTranspUnder, myTranspOver, overlayWindow)


Gui, Add, Checkbox, Section vlistVarz glistVarz HWNDlistVarzHwnd, Output Vars
Gui, Add, Checkbox, vSOExample gSOExample HWNDSOExampleHwnd wp, SO Example
Gui, Add, Checkbox, ys vSetlayer gSetlayer HWNDSetlayerHwnd wp, Use Setlayer
Gui, Add, Button, xs gGo vGo HWNDGoHwnd wp, &Go
Gui, Add, Button, yp x+m gQuit vQuit HWNDquitHwnd wp, &Quit

Gui, Show

; Window must be visible
GuiGetSize(guiWidth, guiHeight, TranspTesterHwnd)
targWidth := floor((306/372) * guiWidth)
targHeight := floor((350/425) * guiHeight)


scriptLoaded := 1
SetTimer, DetectMouse, 50
Return

enableTranspCtrls(ByRef myTranspUnder, ByRef myTranspOver, overlayWindow, ctrlEnable := 0)
{

(ctrlEnable)? enable := "Enable": enable := "Disable"
	GuiControl, %enable%, Transparency Options:
	GuiControl, %enable%, transUnd
		if (overlayWindow)
		GuiControl, %enable%, transOver
		else
		GuiControl, Disable, transOver

	GuiControl, %enable%, Transpt
	GuiControl, %enable%, myTransp
		if (ctrlEnable)
		{
		GuiControl, +Range0-255, Transpt
			if (!overlayWindow)
			GuiControl,, transUnd, 1

		GuiControl, enable, useOverlay
		}
		else
		{
		myTranspUnder := 0
		GuiControl,, transUnd, 1		
			if (overlayWindow)
			{
			myTranspOver := -1
			GuiControl,, transOver, 0
			}

		GuiControl,, myTransp, % myTranspUnder
		GuiControl, +Range0-0, Transpt

		GuiControlGet, tmp,, useNeither
			if (tmp)
			GuiControl, Disable, useOverlay
		}
}
ctrlMast(ctrlEnable, isLayered)
{
global

	if (isLayered)
	{
		if (myRedUnder > -1)
		{
		GuiControlGet, myRedUnder,, myRed
		myRedTransCol := myRedUnder
		}
		if (myGreenUnder > -1)
		{
		GuiControlGet, myGreenUnder,, myGreen
		myGreenTransCol := myGreenUnder
		}
		if (myBlueUnder > -1)
		{
		GuiControlGet, myBlueUnder,, myBlue
		myBlueTransCol := myBlueUnder
		}
		if (hexColUnder > -1)
		{
		GuiControlGet, hexColUnder,, myHex
		hexColTransCol := hexColUnder
		}

		if (myTransIntensityUnder > -1)
		{
		GuiControlGet, myTransIntensityUnder,, transColIntensity
		myTransIntensityUnderTransCol := myTransIntensityUnder
		}


		if (!ctrlEnable)
		Return

	
	(myTransIntensityUnderLayer = -1)? (myTransIntensityUnder := 0): myTransIntensityUnder := myTransIntensityUnderLayer
	(hexColLayer = -1)? (hexColUnder := 0xFFFFFF): hexColUnder := hexColLayer
	(myRedLayer = -1)? (myRedUnder := 255): myRedUnder := myRedLayer
	(myGreenLayer = -1)? (myGreenUnder := 255): myGreenUnder := myGreenLayer
	(myBlueLayer = -1)? (myBlueUnder := 255): myBlueUnder := myBlueLayer

	GuiControl, text, %txtIntensityHwnd%, Underlay Intensity:
	}
	else
	{

		if (myRedUnder > -1)
		{
		GuiControlGet, myRedUnder,, myRed
		myRedLayer := myRedUnder
		}
		if (myGreenUnder > -1)
		{
		GuiControlGet, myGreenUnder,, myGreen
		myGreenLayer := myGreenUnder
		}
		if (myBlueUnder > -1)
		{
		GuiControlGet, myBlueUnder,, myBlue
		myBlueLayer := myBlueUnder
		}

		if (hexColUnder > -1)
		{
		GuiControlGet, hexColUnder,, myHex
		hexColLayer := hexColUnder
		}

		if (myTransIntensityUnder > -1)
		{
		GuiControlGet, myTransIntensityUnder,, transColIntensity
		myTransIntensityUnderLayer := myTransIntensityUnder
		}

		if (!ctrlEnable)
		Return

	(myTransIntensityUnderTransCol = -1)? (myTransIntensityUnder := 0): myTransIntensityUnder := myTransIntensityUnderTransCol
	(hexColTransCol = -1)? (hexColUnder := 0xFFFFFF): hexColUnder := hexColTransCol
	(myRedTransCol = -1)? (myRedUnder := 255): myRedUnder := myRedTransCol
	(myGreenTransCol = -1)? (myGreenUnder := 255): myGreenUnder := myGreenTransCol
	(myBlueTransCol = -1)? (myBlueUnder := 255): myBlueUnder := myBlueTransCol

	GuiControl, text, %txtIntensityHwnd%, TransColor Intensity:
	}

}

enableTransColorCtrls(ctrlEnable := 0, isLayered := 0)
{
global

(ctrlEnable)? enable := "Enable": enable := "Disable"

	GuiControl, Enable, Use Layering
	if (ctrlEnable != 1)
	ctrlMast(ctrlEnable, isLayered)



	

	GuiControl, %enable%, %txtIntensityHwnd%
	GuiControl, %enable%, transColUnd
		if (overlayWindow)
		GuiControl, %enable%, transColOver
		else
		GuiControl, Disable, transColOver

	GuiControl, %enable%, myRed
	GuiControl, %enable%, myGreen
	GuiControl, %enable%, myBlue
	GuiControl, %enable%, myHex
	GuiControl, %enable%, Colour
	GuiControl, %enable%, transIntensity
	GuiControl, %enable%, transColIntensity
	GuiControl, %enable%, useOverlay

		if (ctrlEnable)
		{
			if (!overlayWindow)
			{
				; Clicked from either Transcol or Layered
				if (ctrlEnable = 2)
				{
				GuiControl, +Range0-255, myRed
				GuiControl, +Range0-255, myGreen
				GuiControl, +Range0-255, myBlue
				GuiControl, +Range0-255, transColIntensity
				GuiControl, , myRed, % (myRedUnder = -1)? 255: myRedUnder
				GuiControl, , myGreen, % (myGreenUnder = -1)? 255: myGreenUnder
				GuiControl, , myBlue, % (myBlueUnder = -1)? 255: myBlueUnder
				GuiControl, , transColIntensity, % (myTransIntensityUnder = -1)? 0: myTransIntensityUnder
				GuiControl, , transIntensity, % (myTransIntensityUnder = -1)? 0: myTransIntensityUnder
				GuiControl, , myHex, % (hexColUnder = -1)? 0xFFFFFF: hexColUnder
				GuiControl, , transColUnd, 1
				}
				else
				{
				GuiControlGet, transColOver,, transColOver

					if (transColOver)
					{
					GuiControl,, transColUnd, 1
					GuiControl,, transColOver, 0
					GuiControl, , myRed, %myRedUnder%
					GuiControl, , myGreen, %myGreenUnder%
					GuiControl, , myBlue, %myBlueUnder%
					GuiControl,, transIntensity, %myTransIntensityUnder%
					GuiControl, , transColIntensity, %myTransIntensityUnder%
					GuiControl,, myHex, % hexColUnder
					}
					; else: just deselecting useOverlay
						if (GUI_Overlay_hwnd)
						{
						Gui GUI_Overlay:Destroy
						sleep 100
							; A worry- the message isn't posted until this thread exits.
							if (GUI_Overlay_hwnd)
							GUI_Overlay_hwnd := 0
						OverlayVisible := 0
						overlayWindow := 0
						}
				GuiControl, text, %goHwnd%, &Go
				}


			GuiControl, +Background%hexColUnder%, Colour
			myTransIntensityOver := -1

			hexColOver := -1
			}
		}
		else
		{
			if (overlayWindow)
			{
			myTransIntensityOver := -1
			hexColOver := -1
			}
		hexCol := 0xFFFFFF



		GuiControl,, myHex, % hexCol
		hexColUnder := -1
		
		GuiControl, +Background%hexCol%, Colour
		GuiControl, +C%hexCol%, Colour
		GuiControl, +Range0-0, myRed
		GuiControl, +Range0-0, myGreen
		GuiControl, +Range0-0, myBlue
		GuiControl,, transIntensity, 0
		GuiControl,, transColIntensity, 0
		myTransIntensityUnder := -1
		myRedUnder := -1
		myGreenUnder := -1
		myBlueUnder := -1
			if (overlayWindow)
			{
			myRedOver := -1
			myGreenOver := -1
			myBlueOver := -1
			GuiControl,, transColOver, 0
			}
		GuiControl,, transColUnd, 1
		GuiControl, +Range0-0, transColIntensity
		}


	if (myTransIntensityOver > -1)
	{
	GuiControl,, TransIntensity, % myTransIntensityOver
	GuiControl,, TransColIntensity, % myTransIntensityOver
	}

}

useOverlay:
Gui, Submit, Nohide
GuiControlGet, tmp,, useTransColor
GuiControlGet, useLayering,, useLayered
	if (!tmp && !useLayering)
	Return

GuiControlGet, overlayWindow,, useOverlay

enableTransColorCtrls(1, useLayering)


GuiControlGet, tmp,, useTransparency
enableTranspCtrls(myTranspUnder, myTranspOver, overlayWindow, tmp)

Return

useTransColor:
Gui, Submit, Nohide
overlayWindow := 0
enableTransColorCtrls(2)
GuiControl,, useOverlay, 0
Return

useLayered:
;Won't work with CS_OWNDC or CS_CLASSDC
Gui, Submit, Nohide
overlayWindow := 0
GuiControlGet, useLayering,, useLayered
GuiControl,, useOverlay, 0
enableTransColorCtrls(2, useLayering)

Return

useNeither:
Gui, Submit, Nohide
enableTransColorCtrls()
GuiControlGet, tmp,, useTransparency
	if (tmp)
	GuiControl, enable, useOverlay
Return

useTransparency:
Gui, Submit, Nohide
GuiControlGet, tmp,, useTransparency
enableTranspCtrls(myTranspUnder, myTranspOver, overlayWindow, tmp)
Return
transColIntensity:
Gui, Submit, Nohide
Return


transUnd:
Gui, Submit, Nohide
GuiControlGet, tmp,, myTransp
;save value

	if (overlayWindow && myTranspOver > -1)
	myTranspOver := tmp

	GuiControl,, Transpt, % myTranspUnder
	GuiControl,, myTransp, % myTranspUnder

Return
transOver:
Gui, Submit, Nohide
GuiControlGet, tmp,, myTransp

	myTranspUnder := tmp

	if (myTranspOver = -1)
	myTranspOver = myTranspUnder
	else
	{
	GuiControl,, Transpt, % myTranspOver
	GuiControl,, myTransp, % myTranspOver
	}
Return
transColUnd:
Gui, Submit, Nohide

GuiControlGet, tmp,, transIntensity

	if (overlayWindow)
	myTransIntensityOver := tmp

	if (myTransIntensityUnder > -1)
	{
	GuiControl,, transColIntensity, % myTransIntensityUnder
	GuiControl,, TransIntensity, % myTransIntensityUnder
	}

	GuiControlGet, tmp,, myHex
	hexColOver := tmp
		if (hexColUnder > -1)
		GuiControl,, myHex, % hexColUnder

		if (tmp)
		{
			if (myRed > -1)
			myRedOver := myRed
			if (myGreen > -1)
			myGreenOver := myGreen
			if (myBlue > -1)
			myBlueOver := myBlue
		}

		if (myRedUnder > -1)
		myRed := myRedUnder
		if (myGreenUnder > -1)
		myGreen := myGreenUnder
		if (myBlueUnder > -1)
		myBlue := myBlueUnder

	hexCol := SC_RGB( myRed, myGreen, myBlue )
	hexRed := SC_RGB( myRed, 0, 0 )
	hexGreen := SC_RGB( 0, myGreen, 0 )
	hexBlue := SC_RGB( 0, 0, myBlue )

	tmp := Format("{:i}", hexRed)
	tmp := 255 * (tmp/16711680)
	GuiControl,, myRed, %tmp%
	;ControlSend, msctls_trackbar321, {da-da-de-da-da}

	tmp := Format("{:i}", hexGreen)
	tmp := 255 * (tmp/65280)

	GuiControl,, myGreen, %tmp%,

	tmp := Format("{:i}", hexBlue)
	tmp := 255 * (tmp/255)

	GuiControl,, myBlue, %tmp%, 

	GuiControl, +Background%hexCol%, Colour
	GuiControl, +C%hexCol%, Colour

Return
transColOver:
Gui, Submit, Nohide

GuiControlGet, tmp,, transIntensity
myTransIntensityUnder := tmp

	if (myTransIntensityOver > -1)
	{
	GuiControl,, transColIntensity, % myTransIntensityOver
	GuiControl,, transIntensity, % myTransIntensityOver
	}

	GuiControlGet, tmp,, myHex
	hexColUnder := tmp
		if (hexColOver > -1)
		GuiControl,, myHex, % hexColOver

		if (myRed > -1)
		myRedUnder := myRed
		if (myGreen > -1)
		myGreenUnder := myGreen
		if (myBlue > -1)
		myBlueUnder := myBlue


		if (myRedOver > -1)
		myRed := myRedOver
		if (myGreenOver > -1)
		myGreen := myGreenOver
		if (myBlueOver > -1)
		myBlue := myBlueOver

	hexCol := SC_RGB( myRed, myGreen, myBlue )
	hexRed := SC_RGB( myRed, 0, 0 )
	hexGreen := SC_RGB( 0, myGreen, 0 )
	hexBlue := SC_RGB( 0, 0, myBlue )

	tmp := Format("{:i}", hexRed)
	tmp := 255 * (tmp/16711680)
	GuiControl,, myRed, %tmp%

	tmp := Format("{:i}", hexGreen)
	tmp := 255 * (tmp/65280)

	GuiControl,, myGreen, %tmp%,

	tmp := Format("{:i}", hexBlue)
	tmp := 255 * (tmp/255)

	GuiControl,, myBlue, %tmp%, 

	GuiControl, +Background%hexCol%, Colour
	GuiControl, +C%hexCol%, Colour


Return

useActiveX:
Gui, Submit, Nohide
Return
useImage:
Gui, Submit, Nohide
Return
useNone:
Gui, Submit, Nohide
Return
SOExample:
Gui, Submit, Nohide
	if (SOExample)
	{
	targWidth := htmlW
	targHeight := htmlH
	}
	else
	{
	targWidth := floor((306/372) * guiWidth)
	targHeight := floor((350/425) * guiHeight)
	}
Return
listVarz:
Gui, Submit, Nohide
Return
Setlayer:
Gui, Submit, Nohide
GuiControlGet, SetlayerFn,, Setlayer
Return




Go:
Gui, Submit, Nohide
GuiControl, text, %quitHwnd%, Cancel

	if (OverlayVisible)
	{
	GuiControl, disable, %goHwnd%
	formShowing := 1
	Gosub F1
	return
	}
GuiControlGet, tmp,, %useTransColorHwnd%
	if (tmp || useLayering)
	{

	GuiControlGet, tmp,, transColOver
		if (tmp)
		{

		GuiControlGet, tmp,, TransIntensity
		myTransIntensityOver := tmp

		GuiControlGet, tmp,, myHex
		hexColOver := tmp
		}
		else
		{
		GuiControlGet, tmp,, TransIntensity
		myTransIntensityUnder := tmp

		GuiControlGet, tmp,, myHex
		hexColUnder := tmp
		}
	}

GuiControlGet, tmp,, %useTransparencyHwnd%
	if (tmp)
	{
	GuiControlGet, tmp,, transOver
		if (tmp)
		{
		GuiControlGet, tmp,, myTransp
		myTranspOver := tmp
		}
		else
		{
		GuiControlGet, tmp,, myTransp
		myTranspUnder := tmp
			if (myTranspOver = -1)
			myTranspOver := myTranspUnder
		}
	}


	if (useLayering)
	Gui GUI_Underlay: New, +OwnDialogs +%WS_OVERLAPPED% +HWNDGUI_Underlay_hwnd +E%WS_EX_LAYERED%
	else
	Gui GUI_Underlay: New, +OwnDialogs +%WS_OVERLAPPED% +HWNDGUI_Underlay_hwnd

Gui GUI_Underlay: Margin, 0,0
; considered +ToolWindow +LastFound 
GuiControlGet, tmp,, %useTransparencyHwnd%
	if (tmp)
	{
		if (myTranspUnder = 255)
		WinSet, Transparent, Off, ahk_id%GUI_Underlay_hwnd%
		else
		WinSet, Transparent, %myTranspUnder%, ahk_id%GUI_Underlay_hwnd%
	}
	
GuiControlGet, tmp,, %useTransColorHwnd%

	if (tmp)
	{
		if (myTransIntensityUnder = 255)
		WinSet TransColor, Off, ahk_id%GUI_Underlay_hwnd%
		else
		WinSet TransColor, %hexColUnder% %myTransIntensityUnder%, ahk_id%GUI_Underlay_hwnd%
	}

	If (overlayWindow)
	{
		if (useLayering)
		Gui GUI_Overlay:New, +OwnDialogs -%WS_CAPTION% -%WS_SYSMENU% -%WS_MINIMIZEBOX% +HWNDGUI_Overlay_hwnd +E%WS_EX_LAYERED%
		else
		Gui GUI_Overlay:New, +OwnDialogs -%WS_CAPTION% -%WS_SYSMENU% -%WS_MINIMIZEBOX% +HWNDGUI_Overlay_hwnd

	GuiControlGet, tmp,, %useTransparencyHwnd%
		if (tmp)
		{
			if  (myTranspOver = 255)
			WinSet, Transparent, Off, ahk_id%GUI_Overlay_hwnd% ; same as Off for transColor
			else
			WinSet, Transparent, %myTranspOver%, ahk_id%GUI_Overlay_hwnd%
		}


	GuiControlGet, tmp,, %useTransColorHwnd%
		if (tmp)
		{
			if (myTransIntensityOver = 255)
			WinSet TransColor, Off, ahk_id%GUI_Overlay_hwnd%
			else
			{
			tmp := (hexColOver = -1)? 0xFFFFFF: hexColOver
			tmp := " " . (myTransIntensityOver = -1)? 0: myTransIntensityOver
			WinSet TransColor, %tmp%, ahk_id%GUI_Overlay_hwnd%
			}
		}
	}

Gui GUI_Underlay: Show, Hide
	if (GUI_Overlay_hwnd)
	Gui GUI_Overlay: Show, Hide


WinMove, ahk_id%GUI_Underlay_hwnd%, , % A_ScreenWidth/4, % A_ScreenHeight/5, %targWidth%, %targHeight%
GuiControlGet, tmp,, %useActiveXHwnd%
GuiControlGet, SOExample,, %SOExampleHwnd%

	if (tmp)
	ProcessControls(GUI_Underlay_hwnd, SOExample, targWidth, targHeight, 1)
	else
	{
	GuiControlGet, tmp,, %useImageHwnd%
		if (tmp)
		ProcessControls(GUI_Underlay_hwnd, SOExample, targWidth, targHeight)
	}

sleep, 30



	if (GUI_Overlay_hwnd)
	{
	WinGetPos, x, y, w, h, ahk_id%GUI_Underlay_hwnd%
	WinMove, ahk_id%GUI_Overlay_hwnd%, , %x%, %y%, %w%, %h%
	}
GuiControl, disable, %goHwnd%
formShowing := 1
GoSub F1

Return

WM_ERASEBKGND(wParam, lParam)
{
Global
	if (getKeyState("LButton", "P")) && formShowing && useLayering
	Return 1
}

/*
; Include following for extra flicker on move
WM_MOVE(wparam,lparam,msg)
{
Global
if (formShowing)
{
WinGetPos, x, y, w, h, ahk_id%GUI_Underlay_hwnd%
	if (GUI_Overlay_hwnd)
	WinMove, ahk_id%GUI_Overlay_hwnd%, , %x%, %y%, %w%, %h%
}
Return
}
*/

F1::
	if (!scriptLoaded)
	Return
tmp := A_DetectHiddenWindows
DetectHiddenWindows, Off

if (!WinExist("ahk_id " GUI_Underlay_hwnd) && !formShowing)
{
DetectHiddenWindows, %tmp%
Reload
}
DetectHiddenWindows, %tmp%
GuiControlGet, tmp,, %useActiveXHwnd%
	if (tmp)
	{
	GuiControlGet, tmp,, %SOExampleHwnd%
		if (tmp)
		GoSub Sub_BuildHTMLSOExample
		else
		Gosub Sub_BuildHTML
	}

	if (OverlayVisible)
	Gosub Sub_HideOverlay
	else
	Gosub Sub_ShowOverlay

	if (overlayWindow)
	OverlayVisible := !OverlayVisible
return




Sub_ShowOverlay:

DetectHiddenWindows, On


hWndArray :=[]
childhWndArray := []
grandchildhWndArray := []
hWndArray := WinEnum(GUI_Underlay_hwnd)

	if (GUI_Overlay_hwnd)
	tmp := Format("{1:i}", GUI_Overlay_hwnd)


outStr := % "Containing GUI_Underlay_hwnd`: " . Format("{1:i}", GUI_Underlay_hwnd) . ((GUI_Overlay_hwnd)? ", GUI_Overlay_hwnd`: " tmp1: "") . "`nEnumerated child windows of GUI_Underlay_hwnd & their attributes:"

	Loop
	{
	; Note for next version: The following nested structure should be put into a recursive routine for any number of descendants.

	childhWnd := hWndArray[A_Index]
		if (!childhWnd)
		{
			if (A_Index > 1)
			outStr .= "`nWindow enumeration complete!"
		Break
		}
		; Assume childhWnd is the only candidate for hdc_bmp
		if (!hdc_bmp)
		hdc_bmp := DllCall("GetDC", "uint", childhWnd)   ;get device context for picture
		if (!screenDC)
		screenDC := DllCall("GetDC", "UInt", 0)

	GuiControlGet, tmp,, %childhWnd%


	; consider WinGet, childhWndArray, ControlList, % "ahk_id" childhWnd
	outStr .= "`n`nhWndArray[" . A_Index . "]: " . childhWnd . ", its text: " . tmp
	outStr .= OutputStyles(childhWnd, hdc_bmp)

	childhWndArray := WinEnum(childhWnd)




		if (childhWndArray[1])
		{
		Loop
		{

		grandchildhWnd := childhWndArray[A_Index]

			loop
			{
				if (hWndArray[A_Index]=grandchildhWnd)
				hWndArray.RemoveAt(A_Index)
			} Until (!hWndArray[A_Index + 1])

		GuiControlGet, tmp,, %grandchildhWnd%
		
		outStr .= "`n`nchildhWndArray[" . A_Index . "]: " . grandchildhWnd . ", its text: " . tmp
		outStr .= OutputStyles(grandchildhWnd)

		grandchildhWndArray := WinEnum(grandchildhWnd)


		if (grandchildhWndArray[1])
		{
		Loop
		{
		greatgrandchildhWnd := grandchildhWndArray[A_Index]

			loop
			{
				if (hWndArray[A_Index] = greatgrandchildhWnd)
				hWndArray.RemoveAt(A_Index)
			} Until (!hWndArray[A_Index + 1])

			loop
			{
				if (childhWndArray[A_Index] = greatgrandchildhWnd)
				childhWndArray.RemoveAt(A_Index)
			} Until (!childhWndArray[A_Index + 1])

		GuiControlGet, tmp,, %greatgrandchildhWnd%

		outStr .= "`n`ngrandchildhWndArray[" . A_Index . "]: " . grandchildhWndArray[A_Index] . ", its text: " . tmp
		outStr .= OutputStyles(greatgrandchildhWnd)

		} Until (!grandchildhWndArray[A_Index + 1])

		}


		} Until (!childhWndArray[A_Index + 1])
		}

	} Until (!hWndArray[A_Index + 1])

GuiControlGet, tmp,, %listVarzHwnd%
	if (outStr && tmp)
	msgbox % outStr

	if (WinExist("ahk_id " GUI_Overlay_hwnd))
	{
		if (useLayering && hdc_bmp)
		ProcessLayers(GUI_Underlay_hwnd, hdc_bmp, screenDC, WS_EX_LAYERED, myTransIntensityUnder, hexColUnder, -1)
	Gui GUI_Underlay: Show
	WinGetPos, x, y, w, h, ahk_id %GUI_Underlay_hwnd%
	WinMove, ahk_id %GUI_Overlay_hwnd%, , %x%, %y%, %w%, %h%
		if (useLayering && hdc_bmp)
		ProcessLayers(GUI_Overlay_hwnd, hdc_bmp, screenDC, WS_EX_LAYERED, myTransIntensityOver, hexColOver, -2)
	Gui GUI_Overlay:Show, NoActivate
	}
	else
	{
		if (useLayering && hdc_bmp)
		ProcessLayers(GUI_Underlay_hwnd, hdc_bmp, screenDC, WS_EX_LAYERED, myTransIntensityUnder, hexColUnder, -1)
	Gui GUI_Underlay: Show
	}



DetectHiddenWindows, Off


return

OutputStyles(inhWnd, hdc_bmp := 0)
{
	WS_EX_LTRREADING = 0X0
	SS_BITMAP=0xE
	outStr := ""
	Obj._hWnd := inhWnd
	dw_Style := Obj.ObjStyle()
	dw_ExStyle := Obj.ObjExStyle()

	;Text
	isText := dw_ExStyle & WS_EX_LTRREADING ;   = text/css

	ControlGet, WindowControlStyle, Style,,, % "ahk_id" inhWnd
	; check bitmap style
	isBmp := % dw_Style & SS_BITMAP
	if (hdc_bmp)
	outStr .= "`ndw_Style: " . dw_Style . " SS_BITMAP: " . SS_BITMAP . " isBmp: " . isBmp . " hdc_bmp: " . hdc_bmp . " WindowControlStyle: " . WindowControlStyle
	else
	outStr .= "`ndw_Style: " . dw_Style . " WindowControlStyle: " . WindowControlStyle
	isBmp := % dw_ExStyle & SS_BITMAP
	ControlGet, WindowControlStyle, ExStyle,,, % "ahk_id" inhWnd
	if (hdc_bmp)
	outStr .= "`ndw_ExStyle: " . dw_ExStyle . " SS_BITMAP: " . SS_BITMAP . " isBmp: " . isBmp . " hdc_bmp: " . hdc_bmp . " WindowControlStyle: " . WindowControlStyle
	else
	outStr .= "`ndw_ExStyle: " . dw_ExStyle . " WindowControlStyle: " . WindowControlStyle
	return outStr 
}


Sub_HideOverlay:

	if (GUI_Overlay_hwnd)
	Gui GUI_Overlay:Destroy

WinSet, ExStyle, -%WS_EX_LAYERED%, ahk_id%GUI_Underlay_hwnd%

RedrawHwnd(GUI_Underlay_hwnd)

Gui GUI_Underlay: Show

; Same as...
; WinGet, dw_ExStyle, ExStyle, ahk_id%GUI_Underlay_hwnd%
;SetWindowLong(GUI_Underlay_hwnd, GWL_EXSTYLE, dw_ExStyle & ~WS_EX_LAYERED);
return


ProcessControls(GUI_Underlay_hwnd, SOExample, targWidth, targHeight, HTML := 0)
{
Static WB


	if (HTML)
	{
	Gui GUI_Underlay: Add, ActiveX, w%targWidth% h%targHeight% vWB, Shell.Explorer





	URL := A_ScriptDir . "\overlay.html"
	; prefix with "file:///" to launch URL in browser

	sleep 120
		if (!FileExist(URL))
		Return


	FileRead, html, % URL

	; considered...
	;WB := ComObjCreate("InternetExplorer.Application")
	;if (WB.Navigate(URL) != S_OK)
	;Document.Open(URL)


	Enabled := ComObjError(0)

	;WB := WBGet()


	sink := ComObjConnect(WB, "wb_")
	; wb_ is user defined prefix for events -e.g. see WB_BeforeNavigate2

	; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=77#p398
	FixIE("0")

	Document := ComObjCreate("HTMLfile")

	;https://www.autohotkey.com/boards/viewtopic.php?p=33485#p33485
	WB.Visible := false
	; DocumentComplete does not fire when the Visible property of the WebBrowser Control is set to false
	WB_BeforeNavigate2(URL, WB)

	Document.Open(html)

	Document.Write(html)

	Document.Close(html)

		if WB.ReadyState != 4
		MsgBox Document not ready  ; May happen if we call WBGet() above- but it can happen without it!
	;MsgBox % Document.body.innerText " " Document.body.innerHTML

	WB.Visible := true
	; https://docs.microsoft.com/en-us/previous-versions/office/developer/office-2003/aa219328(v%3Doffice.11)
	H1S := Document.getElementById("header1") ;get a collection of H1 elements
	H1S := Document.getElementsByTagName("div") ;get a collection of H1 elements
	;MsgBox % "H1S.innerText  " H1S.innerText " H1S.length " H1S.length
		if (!H1S)
		MsgBox Could not get headers or divs!

		Loop % H1S.length
		{
			H1 := H1S[A_Index-1] ; zero based collection
		;	MsgBox % "InnerText of H1: " H1.Innertext
		}
	sink := ComObjConnect(WB)
	WB.Quit()
	}
	else
	{
		if (SOExample)
		{
		tmp = http://i.stack.imgur.com/FBZq5.png
		tmp1 = FBZq5.png
		}
		else
		{
		tmp = https://raw.githubusercontent.com/lmstearn/TranspTester/master/TranspTester.bmp
		tmp1 = TranspTester.bmp
		}

		try
		{
			UrlDownloadToFile, %tmp%, %tmp1%
		}
		catch e
		{
		msgbox, 8208, FileDownload, Error with the bitmap download!`nSpecifically: %e%
		}

	FileGetSize, tmp , % A_ScriptDir . "`\" . tmp1
		if tmp < 1000
		msgbox, 8208, FileDownload, File size is incorrect!
		sleep 300
		tmp1 := A_ScriptDir . "`\" . tmp1

		if Fileexist(tmp1)
		tmp := LoadPicture(tmp1, GDI+ w%targWidth% h%targHeight%)
		else
		{
		sleep 300
		tmp := LoadPicture(tmp1, GDI+ w%targWidth% h%targHeight%)
		}
 
	Gui GUI_Underlay: Add, Picture, , % "HBITMAP:*" tmp
	DllCall("DeleteObject", "ptr", tmp)

	}


}
WB_BeforeNavigate2(URL, WB)
{
S_OK := 0
WB.Navigate(URL)

	if (WB.Navigate(URL) == s_OK)
	{
	; alterbative: while try !(pdoc := WB.document)
		while WB.ReadyState != 4 || WB.document.readyState!="complete" || WB.busy
		sleep 100
	}
}
Sub_BuildHTMLSOExample:
FileDelete, overlay.html
;Original URL of image: http://i.stack.imgur.com/FBZq5.png
FileAppend,
(
	<!DOCTYPE html>
	<html>
	<meta charset="utf-8" http-equiv="X-UA-Compatible" content="IE=edge"/>
	<head>
	<style type="text/css">
	body {
	background-color: transparent;
	overflow:hidden;
	}
	#header1 {
	color:blue;
    opacity: 0.5;
	}
	</style>
	</head>
	<body>
	<div id="header1">TEST</div>
	<img src="FBZq5.png" />
	</body>
	</html>
), overlay.html
Return
Sub_BuildHTML:
FileDelete, overlay.html

FileAppend,
(
	<!DOCTYPE html>


<html>

	<head>
	
		<!--
			Metadata : Produced 17:02 2014-05-26 EST by joedf 
			Last Revision date : 21:03 2017-02-04
			This document is property of the AutoHotkey Foundation LLC
			(R) All Rights Reversed - AutoHotkey Foundation LLC
			
			Revised by BigVent, now undrafted.
		-->
		
		<title>The AutoHotkey Foundation</title>
	
		<meta charset="utf-8">
		<meta name="google-site-verification" content="fr3ji3GiYpzhLJkRkVDBS-gJoxhmoVFZnNMd8iZnE3Q" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1">
		
		<script src="/cdn-cgi/apps/head/21XiSFXBdVHXl7A_izEkLSn9ayc.js"></script><link rel="icon" type="image/ico" href="/favicon.ico">
		<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">

		<link rel="stylesheet" href="assets/default.bkp.css">
		<link rel="stylesheet" href="assets/style.css">
		
		<!--
		<style type="text/css"></style>
		<script type="text/javascript"></script>
		-->
		
	</head>
	
	<body>
		<a href="https://autohotkey.com"><img src="assets/ahk_logo-llc.png" border="0" alt="AutoHotkey"></a>
		<br><br>
		
		<p>This document may be downloaded in PDF format <a href="https://autohotkey.com/foundation/The_AutoHotkey_Foundation.pdf">here</a>.</p>
		
		<h1>The AutoHotkey Foundation</h1>
		
		<h2>The Name</h2>
		<p>
			The name <q>AutoHotkey Foundation LLC</q> comes directly from the name of the software <q>AutoHotkey</q>. It is a non-profit LLC (Limited Liability Company) founded for this software.<br>Here is the <a href="https://autohotkey.com/certificate_of_organization.pdf">Certificate of Organization</a>.
		</p>
		
		<h2>Our Purpose</h2>
		<p>
			The <q>AutoHotkey Foundation LLC</q> was founded on April 24<sup>th</sup> 2014 in Indiana, USA. It was created in order to prevent monetization, ensure the continuing existence of the software <q>AutoHotkey</q> and naturally, continue the support for it. This foundation provides organizational, legal, and financial support for this software. It is a volunteer organization created <q>by the community, for the community</q>.
		</p>
		
		<h2>Who manages it?</h2>
		<p>
			The foundation's managers are Charlie Simmons (tank), Steve Gray (Lexikos) and Joachim de Fourestier (joedf) with guidance from Chris Mallett (the creator of the software <q>AutoHotkey</q>).
		</p>

		<h2>Our Mission</h2>
		<p>
			The tenets of this project will not change. We have and will continue to filter obvious wrongdoing. That said, we are not to be held responsible for any misuse. We shall not be financially liable for any misdeed. An LLC also serves to separate person from entity. Consider the following example: violating a license is not a criminal matter but there could be legal concerns if we appeared to have supported it. As such, the AutoHotkey Foundation LLC is not to be held responsible for any misuse of this product.
			<br><br>
			Many users were unhappy with the forum software changes and site administration policies, and when these opinions were voiced, entire threads were deleted as well as moderators were getting stripped of their privileges. Finally, we came here (ahkscript.org) and contacted Chris for his approval of creating a foundation. Here is a quote:
			
			<div class="quote">
				Having a real organization, especially a legal entity, would be quite an achievement. I'm glad you've done some preliminary research into it because it's far beyond anything I have any knowledge of. My response to your proposal is that as long as I wouldn't be responsible for the legal aspects or any other part of maintaining the organization (keeping it going), I wouldn't mind having some kind of guiding/suggesting position just the way you described, with some emergency authority in case things ever departed radically from the original spirit of the project (such as moving toward commercialization or bundling third-party, disreputable software with AutoHotkey).
			</div>
			<br>
			We want a free and open, unaffiliated community that is transparent and respectful to all fellow users and developers. Here is our mission statement:
			
			<ul>
				<li>Provide highly useful Open Source Software (OSS) free of charge at the foundation owned domain.</li>
				<li>Support the Software</li>
				<li>Keep it Open Source</li>
				<li>Not monetize the software or support site.</li>
				<li>Have more than one person that can make changes to the site</li>
				<li>Offer a web site to support the scripting software for windows
					<ul>
						<li>A support forum suitable to the sharing of knowledge for a scripting community.</li>
						<li>Administration without monopoly</li>
						<li>Solicits content improvements from the community</li>
						<li>Hosts documentation that is freely available</li>
						<li>Protects the community from SPAM, violent, derogatory, or any other	abusive content.</li>
						<li>Transparently identifies Moderators and Site Administrators</li>
						<li>Supports users of multiple preferred languages when the user base is large enough to support it and adequate moderators are available.</li>
					</ul>
				</li>
			</ul>
		</p>
			
		<h2>Our History</h2>
		<p>
			You may read about it in detail here: <a href="https://autohotkey.com/foundation/history.html">https://autohotkey.com/foundation/history.html</a>
		</p>
				
		<h2>Contributions</h2>
		<p>
			We are and will always be a volunteer organization. No one that is part of this will collect salary or fee. In the interest of staying with Chris's wish to not monetize <q>AutoHotkey</q>, from time to time we may need to open up and allow donations. Please note contributions are not only monetary. You may also contribute by developing code, submitting a bug fix, improving the documentation, helping other members, or even just filling a bug report. All funds or donations collected should and will be given to support this foundation and not to elicit any favour or rank.
			<br><br>
			You may donate through PayPal <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FXC8HB7XBTQJ6">here</a>.
		</p>
		
		<h2>Contact information</h2>
		<p>
			For any concerns, issues or any other problems, it is suggested to try the support forum first. If the subject matter is specifically about the foundation or its resources, you may also contact support (support[at]ahkscript.org).
		</p>
		
		<script src="assets/autoheaderlinks.js"></script>
	</body>

</html>
), overlay.html
Return

Esc::
Quit:
GuiClose:
GUI_OverlayGuiClose:
GUI_UnderlayGuiClose:

formShowing := 0
SetTimer, DetectMouse, 50

	if (hdc_bmp && !(CS_OWNDC & Obj.ObjStyle()) && !(CS_CLASSDC & Obj.ObjStyle()))
	{
		if (!DllCall("ReleaseDC", "UInt", childhWnd, "UInt", hdc_bmp))
		msgbox hdc_bmp not Released!
	Sleep 10
	hdc_bmp := 0
	}

GuiControlGet, tmp,, %quitHwnd%
	if (tmp = "Cancel")
	{
		if (OverlayVisible && overlayWindow)
		{
		GuiControl, text, %goHwnd%, &Underlay
		Gui GUI_Underlay: Show, Hide
		Gui GUI_Overlay:Destroy
		OverlayVisible := 1
		}
		else
		{
		GuiControl, text, %goHwnd%, &Go
		Gui GUI_Underlay:Destroy
		OverlayVisible := 0
		}
	ProcessLayers(tmp, tmp, tmp, tmp, tmp, tmp)
	GuiControl, enable, %goHwnd%
	GuiControl, text, %quitHwnd%, &Quit
	Return
	}
	else
	{
	Gui GUI_Overlay:Destroy
	Gui GUI_Underlay:Destroy
	}

	if (screenDC && !DllCall("ReleaseDC", "UInt", 0, "UInt", screenDC))
	msgbox screenDC not Released!



if (FileExist(A_ScriptDir "`\overlay.html"))
FileDelete, % A_ScriptDir "`\overlay.html"
if (FileExist(A_ScriptDir "`\FBZq5.png"))
FileDelete, % A_ScriptDir "`\FBZq5.png"
if (FileExist(A_ScriptDir "`\TranspTester.bmp"))
FileDelete, % A_ScriptDir "`\TranspTester.bmp"
ExitApp

ProcessLayers(hwnd, hdc_bmp, screenDC, WS_EX_LAYERED, SourceConstantAlpha, hexColour, UpdateLayer := 0, x := 0, y := 0, w := 0, h := 0)
{

Static AC_SRC_ALPHA, AC_SRC_OVER, CHROMA_KEY, ULW_COLORKEY, ULW_ALPHA, hdcLayered, pt, bl, Ptr

;UpdateLayer: 0 cleanup. -1 (underlay), -2 (overlay) initialise, 1 (underlay) 2 (overlay) update
	if (!UpdateLayer)
	{
	;Cleanup
	VarSetCapacity(CHROMA_KEYU, 0)
	VarSetCapacity(CHROMA_KEYO, 0)
	AC_SRC_ALPHA := 0x0, AC_SRC_OVER := 0
	ULW_COLORKEY := 0x0, ULW_ALPHA := 0x0
	Ptr := 0
	Return
	}

	if (UpdateLayer < 0)
	{
	AC_SRC_ALPHA := 0x01, AC_SRC_OVER := 0 ; 32bpp
	ULW_COLORKEY := 0x00000001, ULW_ALPHA := 0x00000002
	hdcLayered := 0
	;Chroma_KeyU is a colorref structure: https://docs.microsoft.com/en-us/windows/desktop/gdi/colorref
	;When specifying an explicit RGB color, the COLORREF value has the following hexadecimal form: 0x00bbggrr
	(UpdateLayer = 1)? (VarSetCapacity(CHROMA_KEYU, 4 + A_PtrSize, 0)): (VarSetCapacity(CHROMA_KEYO, 4 + A_PtrSize, 0))
	COLORREF := hexColour
	lpCOLORREF := &COLORREF
	; get the pointer
	lpCOLORREF := strget(lpCOLORREF)
	NumPut(COLORREF, (UpdateLayer = 1)? (CHROMA_KEYU): (CHROMA_KEYO), 0, "Uint") 
	NumPut(lpCOLORREF,(UpdateLayer = 1)? (CHROMA_KEYU): (CHROMA_KEYO), A_PtrSize, "UPtr")
	Ptr := 0
	; not requ'd...
	;hdc_dib := DllCall("CreateCompatibleDC", "Uint", screenDC) 
	;DllCall("CreateCompatibleBitmap", UInt,screenDC, Int,w, Int,h)


	; "Note that once SetLayeredWindowAttributes has been called for a layered window, subsequent UpdateLayeredWindow calls will fail until the layering style bit is cleared and set again."
		Try
		{
		DllCall("SetLayeredWindowAttributes", "Ptr", hWnd, "Ptr", (UpdateLayer = 1)? (CHROMA_KEYU): (CHROMA_KEYO), "Char", SourceConstantAlpha, "UInt", ULW_COLORKEY|ULW_ALPHA)
		}
		Catch e
		{
		msgbox % "SetLayeredWindowAttributes Failed: error " e " or " DllCall("GetLastError") " hWnd " hWnd " &CHROMA_KEY " &CHROMA_KEY " SourceConstantAlpha " SourceConstantAlpha " ULW_COLORKEY|ULW_ALPHA " ULW_COLORKEY|ULW_ALPHA
		}
	;Note: It's possible to remove ULW_COLORKEY so that CHROMA_KEY is ignored
	}
	else
	{

	if (!Ptr)
	{
	; Calls fail unless "the layering style bit is cleared and set again"
	WinSet, ExStyle, -%WS_EX_LAYERED%,  % "ahk_id" hwnd
	RedrawHwnd(hwnd)
	WinSet, ExStyle, +%WS_EX_LAYERED%,  % "ahk_id" hwnd
	VarSetCapacity(bl, 8), NumPut(AC_SRC_OVER, bl, 0, "Char"), NumPut(0, bl, 1, "Char"), NumPut(SourceConstantAlpha, bl, 2, "Char"), NumPut(w, bl, 3, "Char") ;Blendfunction
	Ptr := (A_PtrSize == 8) ? "UPtr" : "UInt"
	VarSetCapacity(pt, 8)
	}




	NumPut(x, pt, 0, "UInt"), NumPut(y, pt, 4, "UInt")
		if (!w || !h)
		WinGetPos, , , w, h, % "ahk_id" hwnd
	VarSetCapacity(sz, 8), NumPut(w, sz, 0, "UInt"), NumPut(h, sz, 4, "UInt")


		if (!DllCall("UpdateLayeredWindow", "Ptr", hwnd
		, "Ptr", screenDC
		, "Ptr", (!x && !y) ? 0 : &pt
		, "Ptr", (!w || !h) ? 0 : &sz
		, "Ptr", hdc_bmp
		, "Ptr", hdcLayered
		, "Ptr", (UpdateLayer = 1)? &CHROMA_KEYU: &CHROMA_KEYO
		, "Ptr", &bl
		, "UInt", ULW_ALPHA))
		msgbox % "UpdateLayeredWindow Failed!`nUpdateLayer is : " UpdateLayer ", SourceConstantAlpha is : " SourceConstantAlpha ", hexColour is: " hexColour,

	}
}

RedrawHwnd(hwnd)
{
RDW_ERASE := 0x0004
RDW_INVALIDATE := 0x0001
RDW_FRAME := 0x0400
RDW_ALLCHILDREN := 0x0080
   
	if (!dllcall("RedrawWindow", Ptr, hwnd, Ptr, 0, Ptr, 0, uint, RDW_ERASE | RDW_INVALIDATE | RDW_FRAME | RDW_ALLCHILDREN))
	msgbox Redraw failed
}
/*
 * Function: WinEnum
 *     Wrapper for Enum(Child)Windows [http://goo.gl/5eCy9 | http://goo.gl/FMXit]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Syntax:
 *     windows := WinEnum( [ hwnd ] )
 * Parameter(s) / Return Value:
 *     windows   [retval] - an array of window handles
 *     hwnd     [in, opt] - parent window. If specified, EnumChildWindows is
 *                          called. Accepts a window handle or any string that
 *                          match the WinTitle[http://goo.gl/NdhybZ] parameter.
 * Example:
 *     win := WinEnum() ; calls EnumWindows
 *     children := WinEnum("A") ; enumerate child windows of the active window

EnumChildWindowsCallback(Hwnd, lParam)
{
  return true
}
WinEnum1(hwnd, lParam:=0) ;// lParam (internal, used by callback)
{
EnumChildWindowsAddress := RegisterCallback("EnumChildWindowsCallback", "Fast")
Result := DllCall("EnumChildWindows", UInt, Hwnd, UInt, EnumChildWindowsAddress, UInt, &out)
return out
}
 */
; https://www.autohotkey.com/boards/viewtopic.php?f=7&t=37871&p=282861#p282861
WinEnum(hwnd:=0, lParam:=0) ;// lParam (internal, used by callback)
{
	static pWinEnum := "X" ; pWinEnum will be pointer to WinEnum
	
	; Eventinfo parameter is omitted in the RegisterCallback function below, so A_EventInfo defaults to Address of WinEnum
	if (A_EventInfo != pWinEnum)
	{
			if (pWinEnum == "X")
			pWinEnum := RegisterCallback(A_ThisFunc, "F", 2)
			; A_ThisFunc: name of function this is called from (i.e. WinEnum).
			; "F" is fast. The "2 "is number of params in WinEnum decl above

		if hwnd
		{
			;// not a window handle, could be a WinTitle parameter
			if !DllCall("IsWindow", "Ptr", hwnd)
			{
				prev_DHW := A_DetectHiddenWindows
				prev_TMM := A_TitleMatchMode
				DetectHiddenWindows On
				SetTitleMatchMode 2
				hwnd := WinExist(hwnd)
				DetectHiddenWindows %prev_DHW%
				SetTitleMatchMode %prev_TMM%
			}
		}
		out := []
		; The function calls...
		if hwnd
			DllCall("EnumChildWindows", "Ptr", hwnd, "Ptr", pWinEnum, "Ptr", &out)
			; &out: An application-defined value to be passed to the callback function.
		else
			DllCall("EnumWindows", "Ptr", pWinEnum, "Ptr", &out)
		return out ; now pass the info over to the callback function...
	}

	; Callback returns with lParam initialised as address(?) of out. lParam is the door to our window loot!
	; The Callback - either EnumWindowsProc or EnumChildProc e.g.: 
	; BOOL CALLBACK EnumChildProc( _In_ HWND   hwnd, _In_ LPARAM lParam) is not required to be explicitly declared in the script
	; EnumChildProc is a placeholder for the application-defined function name, WinEnum

	static ObjPush := Func(A_AhkVersion < "2" ? "ObjInsert" : "ObjPush")
	; In the next line it's object := Object(address) with + 0 to force evaluation
	; Same as Push- https://www.autohotkey.com/docs/objects/Object.htm#Push
	%ObjPush%(Object(lParam + 0), hwnd)
	; If desired, check the contents of the array with something like msgbox % " First window " Object(lParam + 0)[1] " Second window " Object(lParam + 0)[2]  ...etc...
	; (aside note: address := Object(object) is another usage of Object())

	return true
}


/* Function: BrowserEmulationL
* based on https://autohotkey.com/board/topic/93660-embedded-ie-shellexplorer-render-issues-fix-force-it-to-use-a-newer-render-engine/
 *     FEATURE_BROWSER_EMULATION -> http://goo.gl/V01Frx
 * Syntax:
 *     BrowserEmulation( [ version ] )
 * Parameter(s):
 *     version  [in, opt] - IE version(7+). Integer between 7 - 11, value can be
 *                          negative. If omitted, current setting is returned.
 *                          If 'version' is the word "edge", installed IE version
 *                          is used. See table below for possible values:
 * Parameter "version" values table:
 * (values that are negative ignore !DOCTYPE directives, see http://goo.gl/V01Frx)
 *     7:  7000               ; 0x1B58           - IE7 Standards mode.
 *     8:  8000,  -8:  8888   ; 0x1F40  | 0x22B8 - IE8 mode, IE8 Standards mode
 *     9:  9000,  -9:  9999   ; 0x2328  | 0x270F - IE9 mode, IE9 Standards mode
 *     10: 10000, -10: 10001  ; 0x02710 | 0x2711 - IE10 Standards mode
 *     11: 11000, -11: 11001  ; 0x2AF8  | 0x2AF9 - IE11 edge mode
 * Remarks:
 *     This function modifes the registry.
 */
FixIE(version:="*") ;// FEATURE_BROWSER_EMULATION -> http://goo.gl/V01Frx
{
	static key := "HKCU\Software\"
	. "Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION\"
	. ( A_IsCompiled ? A_ScriptName : StrGet(DllCall("Shlwapi\PathFindFileName", "Str", A_AhkPath)) )

	static WshShell := ComObjCreate("WScript.Shell")
	
	static prev := "*"
	if (prev == "*") ;// init
		try prev := WshShell.RegRead(key)
		catch ;// value does not exist
			prev := ""

	;// __Get()
	if (version == "*")
	{
		try val := WshShell.RegRead(key)
		catch ;// value does not exist
		{
			val := "" ;// throw Exception()??
		}
			return val
	}

	;// __Set()
	ie_version := Round(WshShell.RegRead("HKLM\SOFTWARE\Microsoft\Internet Explorer\svcVersion"))
	if (ie_version < 8) ;// unsure of this but I read it somewhere...
		throw Exception("FEATURE_BROWSER_EMULATION is only available for IE8 and later.")

	if version
	{
		if !(version ~= "i)^7|-?(8|9|1[01])|edge$")
			throw Exception(Format("Invalid argument: '{1}'", version))
		if (version = "edge")
			version := ie_version
		version := Round(version * (version>0 ? 1000 : -(version>=-9 ? 1111 : 1000.1)))
	}

	try version? WshShell.RegWrite(key, version, "REG_DWORD")
	           : (prev != "" ? WshShell.RegWrite(key, prev, "REG_DWORD") : WshShell.RegDelete(key))
	catch error
	{
		throw error
	}
		return FixIE() ;// OR return the value itself
}
; https://www.autohotkey.com/boards/viewtopic.php?t=39869
WBGet(WinTitle="ahk_class IEFrame", Svr#=1) {               ;// based on ComObjQuery docs
   static msg := DllCall("RegisterWindowMessage", "str", "WM_HTML_GETOBJECT")
        , IID := "{0002DF05-0000-0000-C000-000000000046}"   ;// IID_IWebBrowserApp
;//     , IID := "{332C4427-26CB-11D0-B483-00C04FD90119}"   ;// IID_IHTMLWindow2
   SendMessage msg, 0, 0, Internet Explorer_Server%Svr#%, %WinTitle%
   if (ErrorLevel != "FAIL") {
      lResult:=ErrorLevel, VarSetCapacity(GUID,16,0)
      if DllCall("ole32\CLSIDFromString", "wstr","{332C4425-26CB-11D0-B483-00C04FD90119}", "ptr",&GUID) >= 0 {
         DllCall("oleacc\ObjectFromLresult", "ptr",lResult, "ptr",&GUID, "ptr",0, "ptr*",pdoc)
         return ComObj(9,ComObjQuery(pdoc,IID,IID),1), ObjRelease(pdoc)
      }
   }
}



; Adapted from sjc1000  @ https://www.autohotkey.com/boards/viewtopic.php?t=65 
SC_RGB( red, green, blue)
{
	oldFormat := A_FormatInteger

	SetFormat, Integer, Hex
	myOutput := ( red << 16 ) + ( green << 8 ) + blue
	SetFormat, Integer, % oldFormat
	Return myOutput
}

Transpt:
	;Operating slider with ctrl or shift somehow  binds this event to another control, so myTransp is not updated
	GuiControlGet, tmp, Name, % mControl
	If (inStr(tmp, "Transpt"))
	{
	Gui, Submit, NoHide
	GuiControlGet, Transpt,, Transpt
	GuiControl,, myTransp, % Transpt
	}
	else
	{
		if (inStr(tmp, "transColIntensity"))
		{
		Gui, Submit, NoHide
		GuiControlGet, transColIntensity,, transColIntensity
		GuiControl,, TransIntensity, % transColIntensity
		}
	}
Return
Slide:
	GuiControlGet, tmp, Name, % mControl
		If (!(inStr(tmp, "myRed") || inStr( tmp, "myGreen") || inStr( tmp, "myBlue")))
		Return
	Gui, Submit, NoHide
	GuiControlGet, myRed,, myRed
	GuiControlGet, myGreen,, myGreen
	GuiControlGet, myBlue,, myBlue
	hexCol := SC_RGB(myRed, myGreen, myBlue)
	
	hexRed := SC_RGB(myRed, 0, 0)
	hexGreen := SC_RGB(0, myGreen, 0)
	hexBlue := SC_RGB(0, 0, myBlue)
	
	GuiControl, +Background%hexCol%, Colour
	GuiControl, +C%hexCol%, Colour
	
	GuiControl,, myHex, % hexCol
Return
~LButton::
	if (formShowing)
	return

	While( getKeyState("LButton", "P") )
	{
		MouseGetPos, mX, mY, mWin, mControl ; mX relative to FORM
		ControlGetPos, cX, cY, cWidth, cHeight, % mControl, A
		;cX relative to FORM
		GuiControlGet, tmp, Name, % mControl
			If ( !inStr( mControl, "trackbar" ) )
			Return
		if (inStr(tmp, "transColIntensity"))
		{
			if (!useLayering)
			{
			GuiControlGet, tmp, Enabled, myHex
				If (!tmp)
				Return
			}
		currentPos := ((mY -cY)/cHeight) * 255
			if currentPos < 3
			currentPos := 0
			else
			{
				if (currentPos > 255 - 8)
				currentPos := 255
			}
		SetTimer, Transpt, -1
		}
		else
		{
		currentPos := ((mX -cX)/cWidth) * 255
			if currentPos < 3
			currentPos := 0
			else
			{
				if (currentPos > 255 - 8)
				currentPos := 255
			}
		If (inStr(tmp, "Transpt"))
		SetTimer, Transpt, -1
		else
		{
		GuiControlGet, tmp, Enabled, myHex
			If (!tmp)
			Return
		SetTimer, Slide, -1
		}
		}
		; Supposed to handle "jerky" mouse on slider
		if (!mouseSlide)
		{
		mouseSlide := A_DefaultMouseSpeed
		SetDefaultMouseSpeed, % mouseSlide/2
		mouseDelay := A_MouseDelay
		SetMouseDelay, % 2 * mouseDelay
		}
		GuiControl,, % mControl, % currentPos
	}
Return
DetectMouse:
if MouseIsOverTitlebar()
	{
		if (getKeyState("LButton", "P"))
		{
			if (formShowing)
			{
				if (formShowing = 1)
				SetTimer, DetectMouse, 10
				if (useLayering && hdc_bmp && !SetlayerFn)
				{
				WinGetPos, x, y, w, h, ahk_id %GUI_Underlay_hwnd%
					if (GUI_Overlay_hwnd)
					ProcessLayers(GUI_Overlay_hwnd, 0, 0, WS_EX_LAYERED, myTransIntensityOver, hexColOver, 2, x, y, w, h)
					else
					ProcessLayers(GUI_Underlay_hwnd, hdc_bmp, screenDC, WS_EX_LAYERED, myTransIntensityUnder, hexColUnder, 1, x, y, w, h)
				}
				else
				{
					if (!SetlayerFn && GUI_Overlay_hwnd)
					{
					Gui GUI_Overlay: Show, Hide
					dragForm := 1
					}
				}
			formShowing := 2
			}
		}
	}
	else
	{
		if (dragForm && !useLayering)
		{
		WinGetPos, x, y, w, h, ahk_id%GUI_Underlay_hwnd%
			if (GUI_Overlay_hwnd && OverlayVisible)
			{
			WinMove, ahk_id%GUI_Overlay_hwnd%, , %x%, %y%, %w%, %h%
			Gui GUI_Overlay: Show, NoActivate
			}
		dragForm := 0
		}
		else
		{
			if (mouseSlide && !getKeyState("LButton", "P"))
			{
			SetDefaultMouseSpeed, % mouseSlide
			SetMouseDelay, % mouseDelay
			mouseSlide := 0
			mouseDelay := 0
			}
		
		}
	}

Return
MouseIsOverTitlebar()
{
;https://autohotkey.com/board/topic/82066-minimize-by-right-click-titlebar-close-by-middle-click/
    static WM_NCHITTEST := 0x84, HTCAPTION := 2
	tmp := A_CoordModeMouse
    CoordMode Mouse, Screen
    MouseGetPos x, y, w
	CoordMode, Mouse, % tmp
    if WinExist("ahk_class Shell_TrayWnd ahk_id " w)  ; Exclude taskbar.
        return false

    SendMessage WM_NCHITTEST,, x | (y << 16),, ahk_id %w%
    WinExist("ahk_id " w)  ; Set Last Found Window for convenience.
    return ErrorLevel = HTCAPTION
}
GuiGetSize(ByRef W, ByRef H, TranspTesterHwnd)
{
	If WinExist("ahk_id " TranspTesterHwnd)
	{
		VarSetCapacity(rect, 16, 0)
		DllCall("GetClientRect", uint, TranspTesterHwnd, uint, &rect)
		W := NumGet(rect, 8, "int")
		H := NumGet(rect, 12, "int")
	}
}
