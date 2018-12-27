#NoTrayIcon
#include <Misc.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <ColorConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <SliderConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <Math.au3>
#include "StuffCopiedFromWeb.au3"

If _Singleton("Pointer Speed Setter", 1) == 0 Then
    WinActivate("Pointer Speed Setter")
    WinActivate("Customize Windows Accel Curve")
    Exit
EndIf


Global $Speed = 0xa
Global $Accel[3]; = [0x0,0x0,0x0]
Global $gCycle = 0
Global $gPoll = 1
Global Const $pSpeed = DllStructCreate("uint speed")
Global Const $pAccel = DllStructCreate("uint thresh1;uint thresh2;uint accel")
Global Const $appletVersion  = "v1.1.0.0"




GetMouseSpeed()
GetMouseAccel()
MakeGUI()





Func MakeGUI()

  Local Const $workAreaWidth  = 131
  Local Const $workAreaHeight = 202
  Local Const $margin         = 16
  Local Const $mainWidth      = $workAreaWidth  + $margin + $margin
  Local Const $mainHeight     = $workAreaHeight + $margin + $margin
  Local Const $modeXcoord     = $margin + 105
  Local Const $modeYcoord     = $margin - 1
  Local Const $sliderYcoord   = $margin + 20
  Local Const $sliderXcoord   = $margin - 6

  Local $idGUI       = GUICreate("Pointer Speed Setter", $mainWidth   , $mainHeight,-1,-1,BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
  Local $idInfo      = GUICtrlCreateButton(" i"        , 0            , 0                     ,  13, 13, $BS_LEFT)
  Local $sMode       = GUICtrlCreateLabel(CalculateMultiplier() , $margin      , $modeYcoord, $mainWidth-$margin)
                       GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)                       
  Local $idApply     = GUICtrlCreateButton("Apply"     , $margin-5    , $mainHeight-20-$margin,  70, 25, $BS_DEFPUSHBUTTON)
                       GUICtrlSetState($idApply,$GUI_DISABLE)
  Local $idCustomize = GUICtrlCreateButton("Custom..." , $margin+66   , $mainHeight-20-$margin,  70, 25)

  Local $lSlider     = MakeMouseSpeedSlider(             $sliderXcoord, $sliderYcoord)  

  GUICtrlCreateLabel("Pointer Accel:"                  , $margin      , $margin+60)
  Local $idRadio0    = GUICtrlCreateRadio("Off"        , $margin      , $margin+75            ,  30, 20)
  Local $idRadio1    = GUICtrlCreateRadio("On"         , $margin      , $margin+95            ,  30, 20)
  Local $idRadio2    = GUICtrlCreateRadio("On (Legacy)", $margin      , $margin+115           , 120, 20)

  GUICtrlCreateLabel("Threshold 1 (2x)"                , $margin+45   , $margin+139)
  GUICtrlCreateLabel("Threshold 2 (4x)"                , $margin+45   , $margin+159)
  Local $sThresh1    = GUICtrlCreateInput($Accel[0]    , $margin+15   , $margin+137           ,  25, 20)
                       GUICtrlSendMsg($sThresh1,$EM_SETREADONLY,NOT($Accel[2]=2),0)
  Local $sThresh2    = GUICtrlCreateInput($Accel[1]    , $margin+15   , $margin+157           ,  25, 20)
                       GUICtrlSendMsg($sThresh2,$EM_SETREADONLY,NOT($Accel[2]=2),0)



  AccessAccelRadio($idRadio0,$idRadio1,$idRadio2,"set")
  HotKeySet( IniRead("hotkey.ini","Hotkeys","IncrementSens","!{=}") , "IncrementSens" )
  HotKeySet( IniRead("hotkey.ini","Hotkeys","DecrementSens","!{-}") , "DecrementSens" )
  HotKeySet( IniRead("hotkey.ini","Hotkeys","CenterSens"   ,"!{0}") , "CenterSens"    )
  HotKeySet( IniRead("hotkey.ini","Hotkeys","EnableAccel"  ,"!+{\}"), "EnableAccel"   )
  HotKeySet( IniRead("hotkey.ini","Hotkeys","DisableAccel" ,"!{\}") , "DisableAccel"  )
 
  Local $lastSliderSpeed=GUICtrlRead($lSlider)
  Local $lastAccelRadio=AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)
  Local $idMsg
  GUISetState(@SW_SHOW,$idGUI)
  While 1
    Sleep(10)
       $gCycle+=1
    If $gCycle>=25 Then       
       $gCycle=0
       If $gPoll Then
          GetMouseSpeed()
          GetMouseAccel()
          If ($lastSliderSpeed <> $Speed)+($lastAccelRadio <> $Accel[2]) Then
              GUICtrlSetData($sMode,CalculateMultiplier())
              GUICtrlSetData($sThresh1   ,$Accel[0])
              GUICtrlSetData($sThresh2   ,$Accel[1])
              AccessAccelRadio($idRadio0,$idRadio1,$idRadio2,"set")
              GUICtrlSetData($lSlider,$Speed)
              $lastSliderSpeed = $Speed
              $lastAccelRadio  = $Accel[2]
              GUICtrlSetState($idApply,$GUI_DISABLE)
              GUICtrlSendMsg($sThresh1,$EM_SETREADONLY,NOT($Accel[2]=2),0)
              GUICtrlSendMsg($sThresh2,$EM_SETREADONLY,NOT($Accel[2]=2),0)
          EndIf
       EndIf
    EndIf
    If $lastSliderSpeed - GUICtrlRead($lSlider) Then
       $lastSliderSpeed = GUICtrlRead($lSlider)
       If $lastSliderSpeed == 0 Then
          $lastSliderSpeed = 1
          GUICtrlSetData($lSlider, $lastSliderSpeed)
       EndIf
       GUICtrlSetData($sMode,CalculateMultiplier(GUICtrlRead($lSlider),AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)))
       $gPoll=0
    EndIf

    $idMsg = GUIGetMsg()
    Switch $idMsg
      Case $GUI_EVENT_CLOSE
           Exit
      
      Case $lSlider, $idRadio0, $idRadio1, $idRadio2, $sThresh1, $sThresh2
           GUICtrlSetState($idApply,$GUI_ENABLE)
           $gPoll=0
        If ($idMsg=$idRadio0) OR ($idMsg=$idRadio1) OR ($idMsg=$idRadio2) Then
           $lastAccelRadio = AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)
           GUICtrlSetData($sMode,CalculateMultiplier(GUICtrlRead($lSlider),AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)))
           If $lastAccelRadio Then
              GUICtrlSetData($sThresh1, 6)
              GUICtrlSetData($sThresh2, 10)
           Else
              GUICtrlSetData($sThresh1, 0)
              GUICtrlSetData($sThresh2, 0)
           EndIf
           GUICtrlSendMsg($sThresh1,$EM_SETREADONLY,NOT($lastAccelRadio=2),0)
           GUICtrlSendMsg($sThresh2,$EM_SETREADONLY,NOT($lastAccelRadio=2),0)
        EndIf
           GetMouseSpeed()
           GetMouseAccel()
        If     (                          GUICtrlRead($lSlider)=$Speed   ) _
           AND (AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)=$Accel[2]) _
           AND (   _GetNumberFromString(GuiCtrlRead($sThresh2))=$Accel[1]) _
           AND (   _GetNumberFromString(GuiCtrlRead($sThresh1))=$Accel[0]) Then
           GUICtrlSetState($idApply,$GUI_DISABLE)
           $gPoll=1
        EndIf

      Case $idApply
        if ( _StringIsNumber(GuiCtrlRead($sThresh1)) + _StringIsNumber(GuiCtrlRead($sThresh2)) ) == 2 Then
           $gPoll    =  1
           $Speed    =  GUICtrlRead($lSlider)
           $Accel[0] = _GetNumberFromString(GuiCtrlRead($sThresh1))
           $Accel[1] = _GetNumberFromString(GuiCtrlRead($sThresh2))
           $Accel[2] =  AccessAccelRadio($idRadio0,$idRadio1,$idRadio2)
           SetMouseSpeed()
           SetMouseAccel()
           GetMouseSpeed()
           GetMouseAccel()
           SetMouseSpeed()
           SetMouseAccel()
           CalculateMultiplier()
           GUICtrlSetData($sMode      ,CalculateMultiplier())
           GUICtrlSetData($lSlider    ,$Speed   )
           GUICtrlSetData($sThresh1   ,$Accel[0])
           GUICtrlSetData($sThresh2   ,$Accel[1])
           GUICtrlSendMsg($sThresh1,$EM_SETREADONLY,NOT($Accel[2]=2),0)
           GUICtrlSendMsg($sThresh2,$EM_SETREADONLY,NOT($Accel[2]=2),0)
           AccessAccelRadio($idRadio0,$idRadio1,$idRadio2,"set")
           GUICtrlSetState($idApply,$GUI_DISABLE)
         Else
           MsgBox(0, "Error", "Must be a number")
         EndIf

      Case $idCustomize
           AutoItSetOption ( "GUICoordMode", 0 )
           $idGUICustomize = GUICreate("Customize Windows Accel Curve", 513, 234,-1,-1,BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
           AutoItSetOption ( "GUICoordMode", 1 )
           GUISetState(@SW_SHOW   ,$idGUICustomize)
           GUISetState(@SW_DISABLE,$idGUI)
           GUISetState(@SW_HIDE   ,$idGUI)
           CustomizeAccel($idGUICustomize, 513, 234)
           GUISetState(@SW_SHOW   ,$idGUI)
           GUISetState(@SW_ENABLE ,$idGUI)
           GUISetState(@SW_RESTORE,$idGUI)
           GUIDelete(              $idGUICustomize)

      Case $idInfo
           MsgBox(0,"About",$appletVersion)
    EndSwitch
  WEnd
EndFunc


Func CustomizeAccel(ByRef $idGUICustomize, $windowWidth, $windowHeight)
  Local Const $AccelCurveXdefault    = ["0.4300079345703125", "1.25"              ,  "3.8600006103515625", "40"    ]
  Local Const $AccelCurveYdefaultW7  = ["1.3699951171875"   , "5.3000030517578125", "24.3000030517578125", "568"   ]
  Local Const $AccelCurveYdefaultW10 = ["1.0702667236328125", "4.140625"          , "18.984375"          , "443.75"]
  Local Const $AccelCurveXprime      = [16,   32,  48,  64]
  Local Const $AccelCurveYprime      = [56,  112, 168, 224]
  Local $AccelCurveX[4], $AccelCurveY[4], $idX[4], $idY[4], $percent
  Local $dpi = 96
  Local $nominalHz = 120
  Local $PointsToDraw = 4
  Local $graphMode = 1

  ; initializing variables
  Local $regCurveX = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse","SmoothMouseXCurve")
  Local $regCurveY = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse","SmoothMouseYCurve")
  Local $line
  For $i = 0 to 3 Step 1
    $line = $i + 1
    $AccelCurveX[$i] = SmoothMouseBinaryToFloat($regCurveX, $line)
    $AccelCurveY[$i] = SmoothMouseBinaryToFloat($regCurveY, $line)
  Next

  ; start drawing the GUI
  GUISwitch($idGUICustomize)
  Local Const $inputWidth = 120
  Local Const $margin     = 12
  Local Const $graphPosX  = $windowWidth-$margin-202
  Local Const $graphPosY  = $margin+2  
  Local Const $graphElements = DllStructCreate("ptr idGraph; ptr idXlabel; ptr idYlabel")



  Local $idHelp = GUICtrlCreateButton("?", 0, 0, 15, 15)
  for $i = 0 to 3 step 1
    $idX[$i] = GUICtrlCreateInput(StringFormat("%.20g",$AccelCurveX[$i]), $margin               , $margin+15+(20*$i)      , $inputWidth    , 20)
    $idY[$i] = GUICtrlCreateInput(StringFormat("%.20g",$AccelCurveY[$i]), $margin+$inputWidth   , $margin+15+(20*$i)      , $inputWidth    , 20)
  next
  Local $idMouseSpeed   = GUICtrlCreateLabel("Nominal Mouse Speed"      , $margin               , $margin                 , $inputWidth    , 15, $SS_CENTER)
                          GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
  Local $idPointerSpeed = GUICtrlCreateLabel("Nominal Pointer Speed"    , $margin+$inputWidth   , $margin                 , $inputWidth    , 15, $SS_CENTER)
                          GUICtrlCreateLabel("Configure Presets for:"   , $margin               , $margin+100             , $inputWidth*2  , 15, $SS_CENTER)
  Local $idScaling      = GUICtrlCreateLabel("100% (96 dpi)"            , $margin               , $margin+120             , $inputWidth    , 15, $SS_CENTER)
                          GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
  Local $idDPI          = GUICtrlCreateSlider(                            $margin               , $margin+135             , $inputWidth    , 20, $TBS_NOTICKS)
                          GUICtrlSetLimit($idDPI,8,0)
                          GUICtrlSetData( $idDPI,$dpi/96-1)
  Local $idWin10        = GUICtrlCreateRadio("Windows 10"               , $margin+$inputWidth+23, $margin+119             , 75             , 15)
                          GUICtrlSetState($idWin10,$GUI_CHECKED)
  Local $idWin7         = GUICtrlCreateRadio("Windows 7"                , $margin+$inputWidth+23, $margin+137             , 75             , 15)
  Local $idLinearize    = GUICtrlCreateButton("Linearize (MarkC Fix)"   , $margin               , $margin+160             , $inputWidth    , 25)
  Local $idDefault      = GUICtrlCreateButton("Default Curve (Win10)"   , $margin+$inputWidth   , $margin+160             , $inputWidth    , 25)
  Local $idApply        = GUICtrlCreateButton("Write to Registry"       , $margin               , $windowHeight-$margin-25, $inputWidth*2  , 25)
                          GUICtrlSetState($idApply, $GUI_DISABLE)

  ; draw the Graph and its labels
  GUICtrlCreateLabel("0"     ,$windowWidth-$margin-214,$margin+204,10 ,-1,$SS_RIGHT)
  GUICtrlCreateLabel("counts",$windowWidth-$margin-202,$margin+204,202,-1,$SS_CENTER)
  DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY) 
  Local $idZoomOut      = GUICtrlCreateButton("+",$windowWidth-$margin-201   ,$margin+3    ,15,15,$BS_CENTER)
  Local $idZoomIn       = GUICtrlCreateButton("-",$windowWidth-$margin-201   ,$margin+17   ,15,15,$BS_CENTER)
  Local $idGraphMode    = GUICtrlCreateButton("pixel",$graphPosX-40,$graphPosY+90,33,20,$BS_CENTER) 
  Local $idValid
  While 1
    $percent = GUICtrlRead($idDPI) * 25 + 100
    If $dpi*100/96 - $percent Then
       $dpi = $percent * 96 / 100
       GUICtrlSetData($idScaling,$percent&"% ("&$dpi&" dpi)")
    EndIf  
    Switch  GUIGetMsg()
      Case $GUI_EVENT_CLOSE
        exitloop
        
      Case $idDPI, $idWin10, $idWin7
        if     GUICtrlRead($idWin10) == $GUI_CHECKED then
          $nominalHz = 120
          GUICtrlSetData($idDefault,"Default Curve (Win10)")
        elseif GUICtrlRead($idWin7)  == $GUI_CHECKED then
          $nominalHz = 150
          GUICtrlSetData($idDefault,"Default Curve (Win7)")
        endif
        DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        
      Case $idX[0],$idX[1],$idX[2],$idX[3], $idY[0],$idY[1],$idY[2],$idY[3]
        For $i = 0 to 3 step 1
          $AccelCurveX[$i] = GUICtrlRead($idX[$i])
          $AccelCurveY[$i] = GUICtrlRead($idY[$i])
        Next
        DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        GUICtrlSetState($idApply,$GUI_ENABLE)

      Case $idZoomIn
        if $PointsToDraw > 1 then
          $PointsToDraw -= 1
          DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        endif

      Case $idZoomOut
        if $PointsToDraw < 4 then
          $PointsToDraw += 1    
          DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        endif

      Case $idGraphMode
        Switch $graphMode
          Case 1
            $graphMode = 2
            GUICtrlSetData($idGraphMode,"gain") 
          Case 2
            $graphMode = 3
            GUICtrlSetData($idGraphMode,"scale") 
          Case 3
            $graphMode = 1
            GUICtrlSetData($idGraphMode,"pixel") 
        EndSwitch
        DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)

      Case $idLinearize
        for $i = 0 to 3 step 1
          $AccelCurveY[$i] = $AccelCurveYprime[$i]
          $AccelCurveX[$i] = int($dpi * 65536 / $nominalHz ) * $AccelCurveYprime[$i] / 65536 / 3.5
          GUICtrlSetData($idX[$i],$AccelCurveX[$i])
          GUICtrlSetData($idY[$i],$AccelCurveY[$i])
        next
        DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        GUICtrlSetState($idApply,$GUI_ENABLE)
        ; future complete implementation should be SomeFunctionName($AccelCurveY,$AccelCurveX) byref in the loop then setdata

      Case $idDefault
        for $i = 0 to 3 step 1
            $AccelCurveX[$i] = $AccelCurveXdefault[$i]
          if     $nominalHz == 120 then
            $AccelCurveY[$i] = $AccelCurveYdefaultW10[$i]
          elseif $nominalHz == 150 then
            $AccelCurveY[$i] = $AccelCurveYdefaultW7[$i]
          endif
          GUICtrlSetData($idX[$i],$AccelCurveX[$i])
          GUICtrlSetData($idY[$i],$AccelCurveY[$i])
        next
        DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $graphElements, $graphPosX, $graphPosY)
        GUICtrlSetState($idApply,$GUI_ENABLE)

      Case $idApply
        $regCurveX = BinaryMid(0,1,4) + BinaryMid(0,1,4)
        $regCurveY = BinaryMid(0,1,4) + BinaryMid(0,1,4)
        $idValid   = 1
        For $i = 0 to 3 step 1
          $AccelCurveX[$i] = GUICtrlRead($idX[$i])
          $AccelCurveY[$i] = GUICtrlRead($idY[$i])
          If ( _StringIsNumber($AccelCurveX[$i]) + _StringIsNumber($AccelCurveY[$i]) + IsNumber($AccelCurveX[$i]) + IsNumber($AccelCurveY[$i]) ) == 2 Then
            $regCurveX += CoordinateToSmoothMouseBinary( number( $AccelCurveX[$i] ) )
            $regCurveY += CoordinateToSmoothMouseBinary( number( $AccelCurveY[$i] ) )
          Else
            $idValid = 0
          EndIf
        Next
        if $idValid then
          RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseXCurve", "REG_BINARY", $regCurveX)
          RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseYCurve", "REG_BINARY", $regCurveY)
          $regCurveX = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseXCurve")
          $regCurveY = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseYCurve")
          For $i = 0 to 3 Step 1
            $line = $i + 1
            if SmoothMouseBinaryToFloat($regCurveX, $line) - Number($AccelCurveX[$i]) then
              $AccelCurveX[$i] = SmoothMouseBinaryToFloat($regCurveX, $line)
              GUICtrlSetData($idX[$i], $AccelCurveX[$i])
            EndIf
            if SmoothMouseBinaryToFloat($regCurveY, $line) - Number($AccelCurveY[$i]) then
              $AccelCurveY[$i] = SmoothMouseBinaryToFloat($regCurveY, $line)
              GUICtrlSetData($idY[$i], $AccelCurveY[$i]) 
            EndIf
          Next   
          MsgBox(0,"Success","Successfully written the following data to the Registry:" & @crlf & @crlf & "HKCU\Control Panel\Mouse\SmoothMouseXCurve: " & $regCurveX & @crlf & @crlf & "HKCU\Control Panel\Mouse\SmoothMouseYCurve: " & $regCurveY & @crlf & @crlf & "Customization will take effect on next logon.")
          GUICtrlSetState($idApply,$GUI_DISABLE)
        Else
          $regCurveX = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseXCurve")
          $regCurveY = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseYCurve")
          MsgBox(0,"Error","Must be a number")
        EndIf

      Case $idHelp
        MsgBox( -1, "Help", "The grey line on the plot indicates the identity line (along which your mouse input to pixel movement is 1-to-1.)" _
         & @crlf & @crlf  & "Nominal mouse/pointer speeds are in units of IPS (inches per second) where Microsoft assumes a 400 CPI @ 125 Hz mouse is being used on a certain DPI monitor. In actuality, only the raw counts are considered when the acceleration algorithm is applied." _
         & @crlf & @crlf  & "MarkC's fix essentially modifies (linearizes) the Windows mouse accel function such that it inverts the calculations in the mouse accel algorithm and compensates for binary truncation errors (hence the messy decimals), resulting in unmodified pointer counts." _
         & @crlf & @crlf  & "The appropriate MarkC fix applied depends on your display scaling due to the aforementioned truncation error, as well as your Windows Version due to Microsoft changing the algorithm going from Win7 to Win8 & onwards." _
         & @crlf & @crlf  & "Technically, if you have your pointer speed slider set to anything other than the central notch (5/10 in Control Panel), the truncation compensation would need to be be different once again. The fix applied here assumes that you're leaving it at the centre notch." _
         & @crlf & @crlf  & "For a more complete customization feature set, check out MarkC's Fix Builder which lets you do things like using the accel algorithm to set arbitrary pointer multiplier to downscale your effective cursor CPI on the desktop only, instead of using Povohat's driver which affects raw input programs too. Povohat's driver is still pretty kick-ass though, I highly recommend checking that out too." _
         & @crlf & @crlf  & "Trivia: the Pointer Options Control Panel applet is physically located at C:\WINDOWS\System32\main.cpl, which includes both the Mouse settings applet as well as the key repeat applet." _
         & @crlf & @crlf  & "Check out FilterKeysSetter for natively making your key repeat/delay more responsive. I personally use a delay of 150ms whereas Windows doesn't typically let you go below 250ms even at the lowest setting in the Control Panel applet." _
         & @crlf & @crlf  & "Important notice: Windows Precision Trackpad uses the Accel curve here regardless of whether Enhance Pointer Precision is enabled or not. This means that changing the curve here, even if you're not using the accel with your mouse, will affect how the trackpad feels if it's using the Precision driver.") 
    EndSwitch
  WEnd
EndFunc 



; Where did 1.28 come from? Why does it keep popping up everywhere?
;win10 Y = win7 Y * 1.28
;        = win7 Y * 153.6 / 120
;        = win7 Y * 96    / 75
;        = win7 Y * (200 * 96 / 125) / 120
;        = win7 Y * (100 * 96 / 125) / 60
;        = (X*56/16*1.25) * (100 * 96 / 125) / 60
; 1.28 = MarkC win10 linearize first X / 10
; 1.28 = 153.6 / 120 = smoothmouse y of w7 over w10
; 1.28 = 3.2 / 2.5 = 2 * 400/125 / 5




Func DrawMousePlot($graphMode, $AccelCurveX, $AccelCurveY, $dpi, $win, $PointsToDraw, $graphElements, $xPos, $yPos)

  Local $valueX[4], $valueY[4], $gain[4]
  Local $xScale, $yScale
  Local $mouseSpeedBound   = 0
  Local $pointerSpeedBound = 0
  Local $pointerGainBound  = 0
  Local $maxGain = $pointerGainBound
  Local Const $countScale  = 400/125

  for $i = 0 to $PointsToDraw-1 step 1
    $valueX[$i] = number($AccelCurveX[$i])
    $valueY[$i] = number($AccelCurveY[$i])
    if $valueX[$i] > $mouseSpeedBound then
      $mouseSpeedBound = $valueX[$i]
    endif
    if $valueY[$i] > $pointerSpeedBound then
      $pointerSpeedBound = $valueY[$i]
    endif
  Next

  for $i = 0 to $PointsToDraw-1 step 1
    if $i > 0 then
      $gain[$i] = ($valueY[$i] - $valueY[$i-1])/($valueX[$i] - $valueX[$i-1])
    elseif $i = 0 then
      $gain[$i] =  $valueY[$i] / $valueX[$i]
    endif
    if $gain[$i] > $pointerGainBound then
      $pointerGainBound = $gain[$i]
      $maxGain = $pointerGainBound
    endif
  next

  Local $slopeScale = $mouseSpeedBound / $pointerSpeedBound / $dpi * 3.5 * $win  
  Local $gainScale  = 65536 * 3.5 / int($dpi * 65536 / $win )
  if $pointerGainBound < 2*$gainScale then
     $pointerGainBound = 2*$gainScale
  endif

  Local $idGraph  = DllStructGetData($graphElements, "idGraph" )
  Local $idXlabel = DllStructGetData($graphElements, "idXlabel")
  Local $idYlabel = DllStructGetData($graphElements, "idYlabel")
  GUICtrlDelete( $idGraph  )
  GUICtrlDelete( $idXlabel )
  GUICtrlDelete( $idYlabel )
  $idGraph = GUICtrlCreateGraphic($xPos,$yPos,202,202,0x07)
  $xScale  = 200/$mouseSpeedBound

  Switch $graphMode
    Case 1
      $yScale = 200/$pointerSpeedBound
      AutoItSetOption ( "GUICoordMode", 0 )
        GUICtrlSetBkColor($idGraph, 0xffffff)
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0xdddddd)
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE , 1,200)
        GUICtrlSetGraphic($idGraph, $GUI_GR_LINE , _min(200,200/$slopeScale), 201 - _min(200,200/$slopeScale)*$slopeScale)
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0x000000)
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE , 1,200)
        GUICtrlSetGraphic($idGraph, $GUI_GR_DOT  , 1,200)
        For $i = 0 to $PointsToDraw-1 step 1
          GUICtrlSetGraphic($idGraph, $GUI_GR_DOT , $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
          GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
          GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
        Next
        GUICtrlSetGraphic($idGraph, $GUI_GR_REFRESH, 100, 50)
      AutoItSetOption ( "GUICoordMode", 1 )
      $idXlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale,2)            , $xPos+202-40, $yPos+202, 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
      $idYlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale/$slopeScale,2), $xPos-42    , $yPos-2  , 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    Case 2
      $yScale = 200/$pointerGainBound
      AutoItSetOption ( "GUICoordMode", 0 )
        GUICtrlSetBkColor($idGraph, 0xffffff)
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0xdddddd)
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1  , 201-$yScale*$gainScale)
        GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, 200, 201-$yScale*$gainScale)
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0x000000)
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE , 1                 , 201-$yScale*$gain[0])
        GUICtrlSetGraphic($idGraph, $GUI_GR_LINE , 1+$xScale*$valueX[0], 201-$yScale*$gain[0])
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE , 1+$xScale*$valueX[0], 201-$yScale*$gain[0])
        For $i = 1 to $PointsToDraw-1 step 1
          GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, 1+$xScale*$valueX[$i-1], 201-$yScale*$gain[$i])
          GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1+$xScale*$valueX[$i-1], 201-$yScale*$gain[$i])
          GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, 1+$xScale*$valueX[$i]  , 201-$yScale*$gain[$i])
          GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1+$xScale*$valueX[$i]  , 201-$yScale*$gain[$i])
        Next
        For $i = 1 to 3 step 1
          GUICtrlSetGraphic($idGraph, $GUI_GR_PIXEL, $i, 201-$yScale*$maxGain)
        Next
        GUICtrlSetGraphic($idGraph, $GUI_GR_REFRESH, 100, 50)
      AutoItSetOption ( "GUICoordMode", 1 )
      $idXlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale, 2), $xPos+202-40, $yPos+202                   , 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
      $idYlabel = GUICtrlCreatelabel( round($maxGain/$gainScale, 2)         , $xPos-42    , $yPos+198-($yScale*$maxGain), 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    Case 3
      $yScale = 200/$pointerGainBound
      Local $effSens, $transferFunction
      Local $interval = 0
      AutoitSetOption ( "GUICoordMode", 0 )
        GUICtrlSetBkColor($idGraph, 0xffffff)        
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0xdddddd)
        GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1  , 201-$yScale*$gainScale)
        GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, 200, 201-$yScale*$gainScale)
        GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0x000000)
        For $j = 1 to 200 step 1        
          if $j/$xScale > $valueX[$interval] then
            $interval += 1
          endif
          $transferFunction = $valueY[$interval] - ( $gain[$interval] * ($valueX[$interval] - $j/$xScale) )
          $effSens = $transferFunction / $j * $xScale
          if $j == 1 then
            GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1, round(201-$yScale*$effSens,1))
          endif
          GUICtrlSetGraphic($idGraph, $GUI_GR_LINE , $j, round(201-$yScale*$effSens,1))
          GUICtrlSetGraphic($idGraph, $GUI_GR_PIXEL, $j, round(201-$yScale*$effSens,1))
          GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE , $j, round(201-$yScale*$effSens,1))
        Next
        For $i = 1 to 200 step 1
          if $i/2 - int($i/2) then
            GUICtrlSetGraphic($idGraph, $GUI_GR_PIXEL, $i, 201-$yScale*$maxGain)
          endif
        Next
        GUICtrlSetGraphic($idGraph, $GUI_GR_REFRESH, 100, 50)
      AutoitSetOption ( "GUICoordMode", 1 )
      $idXlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale, 2), $xPos+202-40, $yPos+202                   , 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
      $idYlabel = GUICtrlCreatelabel( round($maxGain/$gainScale, 2)         , $xPos-42    , $yPos+198-($yScale*$maxGain), 40, -1, $SS_RIGHT)
                  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
  EndSwitch

  DllStructSetData($graphElements, "idGraph" , $idGraph )
  DllStructSetData($graphElements, "idXlabel", $idXlabel)
  DllStructSetData($graphElements, "idYlabel", $idYlabel)
EndFunc

Func MakeMouseSpeedSlider($inputX, $inputY)
   Local Const $tickCoordY = $inputY+10
   Local Const $numbCoordY = $inputY+23
   GUICtrlCreateLabel("!" ,  $inputX+16 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+22 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+34 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+46 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+58 , $tickCoordY)
   GUICtrlCreateLabel("." ,  $inputX+70 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+82 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+94 , $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+106, $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+118, $tickCoordY)
   GUICtrlCreateLabel("!" ,  $inputX+130, $tickCoordY)
   GUICtrlCreateLabel("1" ,  $inputX+14 , $numbCoordY)
   GUICtrlCreateLabel("10",  $inputX+65 , $numbCoordY)
   GUICtrlCreateLabel("20",  $inputX+125, $numbCoordY)
   Local  $pSlider = GUICtrlCreateSlider($inputX, $inputY-5, 143, 24)
   GUICtrlSetLimit($pSlider, 20, 0)
   GUICtrlSetData( $pSlider, $Speed)
   Return $pSlider
EndFunc

Func IncrementSens()
     GetMouseSpeed()
  If $Speed < 20 Then
     $Speed+= 1
     SetMouseSpeed()
     $gCycle=50
     $gPoll=1
  EndIf
EndFunc

Func DecrementSens()
     GetMouseSpeed()
  If $Speed > 1 Then
     $Speed-= 1
     SetMouseSpeed()
     $gCycle=50
     $gPoll=1
  EndIf
EndFunc

Func CenterSens()
     $Speed=10
     SetMouseSpeed()
     $gCycle=50
     $gPoll=1
EndFunc

Func DisableAccel()
     $Accel[2]=0
     SetMouseAccel()
     $gCycle=50
     $gPoll=1
EndFunc

Func EnableAccel()
     $Accel[2]=1
     SetMouseAccel()
     $gCycle=50
     $gPoll=1
EndFunc

Func GetMouseSpeed()
        Local $Action = 0x0070      
    DllCall("user32.dll", "none", "SystemParametersInfo", _
            "uint",  $Action, _
            "uint",  0, _
             "ptr",  DllStructGetPtr($pSpeed), _
            "uint",  0)
    $Speed = DllStructGetData($pSpeed, "speed")
EndFunc

Func GetMouseAccel()
        Local $Action = 0x0003
    DllCall("user32.dll", "none", "SystemParametersInfo", _
            "uint",  $Action, _
            "uint",  0, _
             "ptr",  DllStructGetPtr($pAccel), _
            "uint",  0)
    $Accel[0] = DllStructGetData($pAccel, "thresh1")
    $Accel[1] = DllStructGetData($pAccel, "thresh2")
    $Accel[2] = DllStructGetData($pAccel, "accel")
EndFunc

Func SetMouseSpeed()
        Local $Action = 0x0071
    DllCall("user32.dll", "none", "SystemParametersInfo", _
            "uint",  $Action, _
            "uint",  0, _
            "uint",  $Speed, _
            "uint",  0)
    RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "MouseSensitivity", "REG_SZ", string($Speed))
EndFunc

Func SetMouseAccel()
        Local $Action = 0x0004
    DllStructSetData($pAccel, "thresh1", $Accel[0])
    DllStructSetData($pAccel, "thresh2", $Accel[1])
    DllStructSetData($pAccel, "accel",   $Accel[2])
    DllCall("user32.dll", "none", "SystemParametersInfo", _
            "uint",  $Action, _
            "uint",  0, _
            "ptr",  DllStructGetPtr($pAccel), _
            "uint",  0)
    RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "MouseThreshold1", "REG_SZ", string($Accel[0]))
    RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "MouseThreshold2", "REG_SZ", string($Accel[1]))
    RegWrite("HKEY_CURRENT_USER\Control Panel\Mouse", "MouseSpeed"     , "REG_SZ", string($Accel[2]))
EndFunc

Func SmoothMouseBinaryToFloat($input,$line)
  Local $float
  $float += Dec(Hex(BinaryMid($input,($line*8)+1,1))) / 65536
  $float += Dec(Hex(BinaryMid($input,($line*8)+2,1))) / 256
  $float += Dec(Hex(BinaryMid($input,($line*8)+3,1)))      
  $float += Dec(Hex(BinaryMid($input,($line*8)+4,1))) * 256
  return $float
EndFunc

Func CoordinateToSmoothMouseBinary($input)
  Local $byte1, $byte2, $byte3, $byte4
  $byte4 =   int(   $input                                          / 256   )
  $byte3 =   int(   $input - ($byte4*256)                                   )
  $byte2 =   int( ( $input - ($byte4*256) - $byte3 )                * 256   )
  $byte1 = round( ( $input - ($byte4*256) - $byte3 - ($byte2/256) ) * 65536 ) ; needs to be round since this is our last bit of precision
  if $byte4 > 255 then
     $byte4 = 255                                                             ; make sure int is one byte
  EndIf
  Local $output = BinaryMid(binary($byte1),1,1) + BinaryMid(binary($byte2),1,1) + BinaryMid(binary($byte3),1,1) + BinaryMid(binary($byte4),1,1)
  For $i = 1 to 4 step 1
    $output += BinaryMid(0,1,1)
  Next  
  Return $output
EndFunc

Func AccessAccelRadio($idRadio0,$idRadio1,$idRadio2,$accessMode="read")
  If $accessMode = "set" then
    Switch $Accel[2]
      Case 2
        GUICtrlSetState($idRadio2, $GUI_CHECKED)
      Case 1
        GUICtrlSetState($idRadio1, $GUI_CHECKED)
      Case 0
        GUICtrlSetState($idRadio0, $GUI_CHECKED)
    EndSwitch
  Else
    If      GUICtrlRead($idRadio0)=$GUI_CHECKED Then
      return 0
    ElseIf  GUICtrlRead($idRadio1)=$GUI_CHECKED Then
      return 1
    ElseIf  GUICtrlRead($idRadio2)=$GUI_CHECKED Then
      return 2
    EndIf
  Endif
EndFunc

Func CalculateMultiplier($lMouseSpeed=$Speed,$lAccelMode=$Accel[2])
    Local $multiplier = "?"
    Local $mode = "Pointer Speed:"
    if $lAccelMode  Then
        $mode = "Pointer Acc Multiplier:"
        $multiplier = StringFormat("%.1f",$lMouseSpeed/10)
    Else
        $mode = "Pointer Speed Factor:"
        Switch $lMouseSpeed
           Case 0 to 1
                 $multiplier = "1/32"
           Case 2
                 $multiplier = "1/16"
           Case 3 to 9
                 $multiplier = String($lMouseSpeed-2)&"/8"
           Case 10, 14, 18
                 $multiplier = String($lMouseSpeed/4-1.5)
           Case 11 to 13
                 $multiplier = "1 "&String($lMouseSpeed-10)&"/4"
           Case 15 to 17
                 $multiplier = "2 "&String($lMouseSpeed-14)&"/4"
           Case 19 to 20
                 $multiplier = "3 "&String($lMouseSpeed-18)&"/4"
        EndSwitch
    EndIf
    return $mode&" "&$multiplier
EndFunc
