#NoTrayIcon
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <ColorConstants.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <SliderConstants.au3>
#include <Array.au3>
#include <Math.au3>


Global $Speed = 0xa
Global $Accel[3]; = [0x0,0x0,0x0]
Global $multiplier = ""
Global $mode = "Pointer Speed:"
Global Const $pSpeed = DllStructCreate("uint speed")
Global Const $pAccel = DllStructCreate("uint thresh1;uint thresh2;uint accel")
Global Const $appletVersion  = "v1.0.0.1"

GetMouseSpeed()
GetMouseAccel()
CalculateMultiplier()
MakeGUI()





Func MakeGUI()

  Local Const $workAreaWidth  = 131
  Local Const $workAreaHeight = 202
  Local Const $margin         = 20
  Local Const $mainWidth      = $workAreaWidth  + $margin + $margin
  Local Const $mainHeight     = $workAreaHeight + $margin + $margin
  Local Const $modeXcoord     = $margin + 105
  Local Const $modeYcoord     = $margin - 1
  Local Const $sliderYcoord   = $margin + 20
  Local Const $sliderXcoord   = $margin - 6

  Local $idGUI       = GUICreate("Pointer Speed Setter", $mainWidth   , $mainHeight)
  Local $sMode       = GUICtrlCreateLabel($mode                 , $margin      , $modeYcoord)
                       GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
  Local $sMultiplier = GUICtrlCreateLabel($multiplier           , $modeXcoord  , $modeYcoord)
                       GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
                       
  Local $idInfo      = GUICtrlCreateButton("i"         , 0            , 0                     ,  10, 12, $BS_CENTER)
  Local $idStart     = GUICtrlCreateButton("Apply"     , $margin-5    , $mainHeight-20-$margin,  70, 25, $BS_DEFPUSHBUTTON)
  Local $idCustomize = GUICtrlCreateButton("Custom..." , $margin+65   , $mainHeight-20-$margin,  70, 25)

  Local $testSlider  = MakeMouseSpeedSlider(             $sliderXcoord, $sliderYcoord)  

  GUICtrlCreateLabel("Pointer Accel:"                  , $margin      , $margin+60)
  Local $idRadio0    = GUICtrlCreateRadio("Off"        , $margin      , $margin+75            ,  30, 20)
  Local $idRadio1    = GUICtrlCreateRadio("On"         , $margin      , $margin+95            ,  30, 20)
  Local $idRadio2    = GUICtrlCreateRadio("On (Legacy)", $margin      , $margin+115           , 120, 20)

  GUICtrlCreateLabel("Threshold 1 (2x)"                , $margin+45   , $margin+139)
  GUICtrlCreateLabel("Threshold 2 (4x)"                , $margin+45   , $margin+159)
  Local $sThresh1    = GUICtrlCreateInput($Accel[0]    , $margin+15   , $margin+137           ,  25, 20)
  Local $sThresh2    = GUICtrlCreateInput($Accel[1]    , $margin+15   , $margin+157           ,  25, 20)




  if $Accel[2] Then
    if $Accel[2] == 2 Then
      GUICtrlSetState($idRadio2, $GUI_CHECKED)
    Else
      GUICtrlSetState($idRadio1, $GUI_CHECKED)
    EndIf
  Else
    GUICtrlSetState($idRadio0, $GUI_CHECKED)
  EndIf
 
  GUISetState(@SW_SHOW,$idGUI)

  Local $idMsg
  Local $lastSpeed = $Speed
  Local $lastAccel = $Accel[2]

  While 1

    ;live read of speed and accel
    $Speed = GUICtrlRead($testSlider)
    if $Speed == 0 Then
      $Speed = 1
      GUICtrlSetData($testSlider, $Speed)
    EndIf
    if     GUICtrlRead($idRadio0) == $GUI_CHECKED Then
      $Accel[2] = 0
    ElseIf GUICtrlRead($idRadio1) == $GUI_CHECKED Then
      $Accel[2] = 1
    ElseIf GUICtrlRead($idRadio2) == $GUI_CHECKED Then
      $Accel[2] = 2
    EndIf

    ;live update based on change
    if ($Speed == $lastSpeed) And ($Accel[2] == $lastAccel) Then
    Else
      CalculateMultiplier()
      if $Accel[2] == $lastAccel Then
      Else
        GUICtrlDelete($sMode)
        $sMode = GUICtrlCreateLabel($mode, $margin, $modeYcoord)
                 GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
        if $Accel[2] Then
          GUICtrlSetData($sThresh1, 6)
          GUICtrlSetData($sThresh2, 10)
        Else
          GUICtrlSetData($sThresh1, 0)
          GUICtrlSetData($sThresh2, 0)
        EndIf
      EndIf
      GUICtrlDelete($sMultiplier)
      $sMultiplier = GUICtrlCreateLabel($multiplier, $modeXcoord, $modeYcoord)
                     GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
      $lastSpeed = $Speed
      $lastAccel = $Accel[2]
    EndIf

    ;read button command 
    $idMsg = GUIGetMsg()
    Select
      Case $idMsg = $GUI_EVENT_CLOSE
        Exit

      Case $idMsg = $idStart
        if ( _StringIsNumber(GuiCtrlRead($sThresh1)) + _StringIsNumber(GuiCtrlRead($sThresh2)) ) == 2 Then
            $Accel[0] = _GetNumberFromString(GuiCtrlRead($sThresh1))
            $Accel[1] = _GetNumberFromString(GuiCtrlRead($sThresh2))
          if     GUICtrlRead($idRadio0) == $GUI_CHECKED Then
            $Accel[2] = 0
          ElseIf GUICtrlRead($idRadio1) == $GUI_CHECKED Then
            $Accel[2] = 1
          ElseIf GUICtrlRead($idRadio2) == $GUI_CHECKED Then
            $Accel[2] = 2
          EndIf

          $Speed = GUICtrlRead($testSlider)
          if  $Speed == 0 Then
              $Speed =  1
              GUICtrlSetData($testSlider, $Speed)
          EndIf
          SetMouseSpeed()
          SetMouseAccel()
          GetMouseSpeed()
          GetMouseAccel()
          SetMouseSpeed()
          SetMouseAccel()
          CalculateMultiplier()

          ;refresh the labels
          GUICtrlDelete($sMode)
          GUICtrlDelete($sMultiplier)
          $sMode       = GUICtrlCreateLabel($mode      , $margin    , $modeYcoord)
                         GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
          $sMultiplier = GUICtrlCreateLabel($multiplier, $modeXcoord, $modeYcoord)
                         GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

          GUICtrlSetData($testSlider, $Speed)
          GUICtrlSetData($sThresh1  , $Accel[0])
          GUICtrlSetData($sThresh2  , $Accel[1])
            if $Accel[2] Then
              if     $Accel[2] == 2 Then
                GUICtrlSetState($idRadio2, $GUI_CHECKED)
              ElseIf $Accel[2] == 1 Then
                GUICtrlSetState($idRadio1, $GUI_CHECKED)
              EndIf
            Else
              GUICtrlSetState($idRadio0, $GUI_CHECKED)
            EndIf
        Else
          MsgBox(0, "Error", "Must be a number")
        EndIf

      Case $idMsg = $idCustomize
        AutoItSetOption ( "GUICoordMode", 0 )
        $idGUICustomize = GUICreate("Customize Windows Accel Curve", 513, 242)
        AutoItSetOption ( "GUICoordMode", 1 )
        GUISetState(@SW_SHOW   ,$idGUICustomize)
        GUISetState(@SW_DISABLE,$idGUI)
        GUISetState(@SW_HIDE   ,$idGUI)
        CustomizeAccel($idGUICustomize, 513, 242)
        GUISetState(@SW_SHOW   ,$idGUI)
        GUISetState(@SW_ENABLE ,$idGUI)
        GUISetState(@SW_RESTORE,$idGUI)
        GUIDelete(              $idGUICustomize)

      Case $idMsg = $idInfo
        MsgBox(0,"About",$appletVersion)
    EndSelect
  WEnd
EndFunc


Func CustomizeAccel(ByRef $idGUICustomize, $windowWidth, $windowHeight)
  Local Const $AccelCurveXdefault    = ["0.4300079345703125", "1.25"              ,  "3.8600006103515625", "40"    ]
  Local Const $AccelCurveYdefaultW7  = ["1.3699951171875"   , "5.3000030517578125", "24.3000030517578125", "568"   ]
  Local Const $AccelCurveYdefaultW10 = ["1.0702667236328125", "4.140625"          , "18.984375"          , "443.75"]
  Local Const $AccelCurveXprime      = [16,   32,  48,  64]
  Local Const $AccelCurveYprime      = [56,  112, 168, 224]
  Local $AccelCurveX[4], $AccelCurveY[4], $idX[4], $idY[4], $lastAccelCurveX[4], $lastAccelCurveY[4], $percent
  Local $dpi = 96
  Local $nominalHz = 120
  Local $PointsToDraw = 4
  Local $lastDPI = $dpi
  Local $lastNominalHz = $nominalHz
  Local $lastPointsToDraw = $PointsToDraw

  ; initializing variables
  Local $regCurveX = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse","SmoothMouseXCurve")
  Local $regCurveY = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse","SmoothMouseYCurve")
  Local $line
  For $i = 0 to 3 Step 1
    $line = $i + 1
    $AccelCurveX[$i] = SmoothMouseBinaryToFloat($regCurveX, $line)
    $AccelCurveY[$i] = SmoothMouseBinaryToFloat($regCurveY, $line)
    $lastAccelCurveX[$i] = $AccelCurveX[$i]
    $lastAccelCurveY[$i] = $AccelCurveY[$i]
  Next

  ; start drawing the GUI
  GUISwitch($idGUICustomize)
  Local Const $inputWidth = 120
  Local Const $margin     = 13

  for $i = 0 to 3 step 1
    $idX[$i] = GUICtrlCreateInput(StringFormat("%.20g",$AccelCurveX[$i]), $margin               , $margin+15+(20*$i)      , $inputWidth    , 20)
    $idY[$i] = GUICtrlCreateInput(StringFormat("%.20g",$AccelCurveY[$i]), $margin+$inputWidth   , $margin+15+(20*$i)      , $inputWidth    , 20)
  next
  Local $idMouseSpeed   = GUICtrlCreateLabel("Nominal Mouse Speed"      , $margin               , $margin                 , $inputWidth    , 15, $SS_CENTER)
  Local $idPointerSpeed = GUICtrlCreateLabel("Nominal Pointer Speed"    , $margin+$inputWidth   , $margin                 , $inputWidth    , 15, $SS_CENTER)
                          GUICtrlCreateLabel("Configure Presets for:"   , $margin               , $margin+100             , $inputWidth*2  , 15, $SS_CENTER)
  Local $idScaling      = GUICtrlCreateLabel("100% (96 dpi)"            , $margin               , $margin+120             , $inputWidth    , 15, $SS_CENTER)
                          GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
                          GUICtrlSetState(@SW_DISABLE,$idScaling)
  Local $idDPI          = GUICtrlCreateSlider(                            $margin               , $margin+135             , $inputWidth    , 20, $TBS_NOTICKS)
                          GUICtrlSetLimit($idDPI,8,0)
                          GUICtrlSetData( $idDPI,$dpi/96-1)
  Local $idWin10        = GUICtrlCreateRadio("Windows 10"               , $margin+$inputWidth+23, $margin+119             , 75             , 15)
                          GUICtrlSetState($idWin10,$GUI_CHECKED)
  Local $idWin7         = GUICtrlCreateRadio("Windows 7"                , $margin+$inputWidth+23, $margin+137             , 75             , 15)
  Local $idLinearize    = GUICtrlCreateButton("Linearize (MarkC Fix)"   , $margin               , $margin+160             , $inputWidth    , 25)
  Local $idDefault      = GUICtrlCreateButton("Default Curve (Win10)"   , $margin+$inputWidth   , $margin+160             , $inputWidth    , 25)
  Local $idApply        = GUICtrlCreateButton("Write to Registry"       , $margin               , $windowHeight-$margin-25, $inputWidth*2  , 25)
  Local $idHelp         = GUICtrlCreateButton("?"                       , 0                     , 0                       , 15             , 15)




  ; draw the Graph and its labels
  Local $idXlabel, $idYlabel
  GUICtrlCreateLabel("0"     ,$windowWidth-$margin-214,$margin+204,10 ,-1,$SS_RIGHT)
  GUICtrlCreateLabel("counts",$windowWidth-$margin-202,$margin+204,202,-1,$SS_CENTER)
  GUICtrlCreatelabel("pixels",$windowWidth-$margin-230,$margin+101,25)
  Local $idGraph = DrawMousePlot($AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $idXlabel, $idYlabel, $windowWidth-$margin-202, $margin+2)
  Local $idZoomOut  = GUICtrlCreateButton("+",$windowWidth-$margin-201,$margin+3 ,15,15,$BS_CENTER)
  Local $idZoomIn   = GUICtrlCreateButton("-",$windowWidth-$margin-201,$margin+17,15,15,$BS_CENTER)


  ;GUISetState(@SW_SHOW,$idGUICustomize)
  ; loop until user exits
  Local $idMsg
  Local $run = 1
  While $run

    if     GUICtrlRead($idWin10) == $GUI_CHECKED then
      $nominalHz = 120
    elseif GUICtrlRead($idWin7)  == $GUI_CHECKED then
      $nominalHz = 150
    endif

    $percent = GUICtrlRead($idDPI) * 25 + 100

    If $dpi*100/96 - $percent Then
      $dpi = $percent * 96 / 100
      GUICtrlDelete($idScaling)
      $idScaling = GUICtrlCreateLabel($percent&"% ("&$dpi&" dpi)",$margin,$margin+120,$inputWidth,-1,$SS_CENTER)
      GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
      GUICtrlSetState(@SW_DISABLE,$idScaling)
    EndIf

    $idMsg = 0

    For $i = 0 to 3 step 1
      $AccelCurveX[$i] = GUICtrlRead($idX[$i])
      $AccelCurveY[$i] = GUICtrlRead($idY[$i])

      If $lastAccelCurveX[$i]-$AccelCurveX[$i] or $lastAccelCurveY[$i]-$AccelCurveY[$i] or $lastNominalHz-$nominalHz or $lastDPI-$dpi or $lastPointsToDraw-$PointsToDraw Then
         $lastAccelCurveX[$i] = $AccelCurveX[$i]
         $lastAccelCurveY[$i] = $AccelCurveY[$i]
         $lastDPI             = $dpi
         $lastPointsToDraw    = $PointsToDraw

         $idMsg += 1
      EndIf      
    Next

    If $idMsg Then
      GUICtrlDelete($idGraph)
      GUICtrlDelete($idXlabel)
      GUICtrlDelete($idYlabel)      
      $idGraph = DrawMousePlot($AccelCurveX, $AccelCurveY, $dpi, $nominalHz, $PointsToDraw, $idXlabel, $idYlabel, $windowWidth-$margin-202,$margin+2)
      if $lastNominalHz - $nominalHz then
         $lastNominalHz = $nominalHz
         GUICtrlDelete($idDefault)
        if     $nominalHz == 120 then
          $idDefault = GUICtrlCreateButton("Default Curve (Win10)", $margin+$inputWidth, $margin+160, $inputWidth, 25)
        elseif $nominalHz == 150 then
          $idDefault = GUICtrlCreateButton("Default Curve (Win7)" , $margin+$inputWidth, $margin+160, $inputWidth, 25)
        endif
      endif
    EndIf

    $idMsg = GUIGetMsg()

    Select
      Case $idMsg == $GUI_EVENT_CLOSE
        $run = 0

      Case $idMsg == $idHelp
        MsgBox( -1, "Help", "The grey line on the plot indicates the identity line (along which your mouse input to pixel movement is 1-to-1.)" & @crlf & @crlf & "Nominal mouse/pointer speeds are in units of IPS (inches per second) where Microsoft assumes a 400 CPI @ 125 Hz mouse is being used on a certain DPI monitor. In actuality, only the raw counts are considered when the acceleration algorithm is applied." & @crlf & @crlf & "MarkC's fix essentially modifies (linearizes) the Windows mouse accel function such that it inverts the calculations in the mouse accel algorithm and compensates for binary truncation errors (hence the messy decimals), resulting in unmodified pointer counts." & @crlf & @crlf & "The appropriate MarkC fix applied depends on your display scaling due to the aforementioned truncation error, as well as your Windows Version due to Microsoft changing the algorithm going from Win7 to Win8 & onwards." & @crlf & @crlf & "Technically, if you have your pointer speed slider set to anything other than the central notch (5/10 in Control Panel), the truncation compensation would need to be be different once again. The fix applied here assumes that you're leaving it at the centre notch." & @crlf & @crlf & "For a more complete customization feature set, check out MarkC's Fix Builder which lets you do things like using the accel algorithm to set arbitrary pointer multiplier to downscale your effective cursor CPI on the desktop only, instead of using Povohat's driver which affects raw input programs too. Povohat's driver is still pretty kick-ass though, I highly recommend checking that out too." & @crlf & @crlf & "Trivia: the Pointer Options Control Panel applet is physically located at C:\WINDOWS\System32\main.cpl")

      Case $idMsg == $idZoomIn
        if $PointsToDraw > 1 then
          $PointsToDraw -= 1
        endif

      Case $idMsg == $idZoomOut
        if $PointsToDraw < 4 then
          $PointsToDraw += 1
        endif

      Case $idMsg == $idLinearize
        for $i = 0 to 3 step 1
          $AccelCurveY[$i] = $AccelCurveYprime[$i]
          $AccelCurveX[$i] = int($dpi * 65536 / $nominalHz ) * $AccelCurveYprime[$i] / 65536 / 3.5
          GUICtrlSetData($idX[$i],$AccelCurveX[$i])
          GUICtrlSetData($idY[$i],$AccelCurveY[$i])
        next
        ; future complete implementation should be SomeFunctionName($AccelCurveY,$AccelCurveX) byref in the loop then setdata

      Case $idMsg == $idDefault
        for $i = 0 to 3 step 1
          $AccelCurveX[$i] = $AccelCurveXdefault[$i]
          if $nominalHz == 120 then
            $AccelCurveY[$i] = $AccelCurveYdefaultW10[$i]
          elseif $nominalHz == 150 then
            $AccelCurveY[$i] = $AccelCurveYdefaultW7[$i]
          endif
          GUICtrlSetData($idX[$i],$AccelCurveX[$i])
          GUICtrlSetData($idY[$i],$AccelCurveY[$i])
        next

      Case $idMsg == $idApply
        $regCurveX = BinaryMid(0,1,4) + BinaryMid(0,1,4)
        $regCurveY = BinaryMid(0,1,4) + BinaryMid(0,1,4)

        for $i = 0 to 3 step 1
          $AccelCurveX[$i] = GUICtrlRead($idX[$i])
          $AccelCurveY[$i] = GUICtrlRead($idY[$i])

          If ( _StringIsNumber($AccelCurveX[$i]) + _StringIsNumber($AccelCurveY[$i]) + IsNumber($AccelCurveX[$i]) + IsNumber($AccelCurveY[$i]) ) == 2 Then
            $regCurveX += CoordinateToSmoothMouseBinary( number( $AccelCurveX[$i] ) )
            $regCurveY += CoordinateToSmoothMouseBinary( number( $AccelCurveY[$i] ) )

          Else
            $idMsg = 0

          EndIf
        Next

        if $idMsg == $idApply then
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

        Else
          $regCurveX = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseXCurve")
          $regCurveY = RegRead("HKEY_CURRENT_USER\Control Panel\Mouse", "SmoothMouseYCurve")
          MsgBox(0,"Error","Must be a number")
        EndIf

    EndSelect
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









Func DrawMousePlot($AccelCurveX, $AccelCurveY, $dpi, $win, $PointsToDraw, ByRef $idXlabel, ByRef $idYlabel, $xPos, $yPos)

  Local $valueX[4], $valueY[4]
  Local $mouseSpeedBound = 0
  Local $pointerSpeedBound = 0
  Local Const $countScale = 400/125

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

  Local $xScale = 200/$mouseSpeedBound
  Local $yScale = 200/$pointerSpeedBound
  Local $slopeScale = $mouseSpeedBound / $pointerSpeedBound / $dpi * 3.5 * $win
  Local $idGraph = GUICtrlCreateGraphic($xPos,$yPos,202,202,0x07)

  AutoItSetOption ( "GUICoordMode", 0 )
  GUICtrlSetBkColor($idGraph, 0xffffff)
  GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1,200)
  GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0xdddddd)
  GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, _min(200,200/$slopeScale), 201 - _min(200,200/$slopeScale)*$slopeScale)
  GUICtrlSetGraphic($idGraph, $GUI_GR_COLOR, 0x000000)
  GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, 1,200)
  GUICtrlSetGraphic($idGraph, $GUI_GR_DOT , 1,200)
  For $i = 0 to $PointsToDraw-1 step 1
    GUICtrlSetGraphic($idGraph, $GUI_GR_DOT , $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
    GUICtrlSetGraphic($idGraph, $GUI_GR_LINE, $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
    GUICtrlSetGraphic($idGraph, $GUI_GR_MOVE, $valueX[$i]*$xScale, 201-$valueY[$i]*$yScale)
  Next
  GUICtrlSetGraphic($idGraph, $GUI_GR_REFRESH, 100, 50)
  AutoItSetOption ( "GUICoordMode", 1 )

  $idXlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale,1)             , $xPos+202-40, $yPos+202, 40, -1, $SS_RIGHT)
  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
  $idYlabel = GUICtrlCreatelabel( round($mouseSpeedBound*$countScale/$slopeScale,1) , $xPos-42    , $yPos-2  , 40, -1, $SS_RIGHT)
  GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

  Return $idGraph

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


Func CalculateMultiplier()

        $multiplier = "?"
        $mode = "Pointer Speed:"

    if $Accel[2] Then

        $mode = "Pointer Acc Multiplier:"

        Switch $Speed
           Case 0 to 1
                 $multiplier = "0.1"
           Case 2
                 $multiplier = "0.2"
           Case 3
                 $multiplier = "0.3"
           Case 4
                 $multiplier = "0.4"
           Case 5
                 $multiplier = "0.5"
           Case 6
                 $multiplier = "0.6"
           Case 7
                 $multiplier = "0.7"
           Case 8
                 $multiplier = "0.8"
           Case 9
                 $multiplier = "0.9"
           Case 10
                 $multiplier = "1.0"
           Case 11
                 $multiplier = "1.1"
           Case 12
                 $multiplier = "1.2"
           Case 13
                 $multiplier = "1.3"
           Case 14
                 $multiplier = "1.4"
           Case 15
                 $multiplier = "1.5"
           Case 16
                 $multiplier = "1.6"
           Case 17
                 $multiplier = "1.7"
           Case 18
                 $multiplier = "1.8"
           Case 19
                 $multiplier = "1.9"
           Case 20
                 $multiplier = "2.0"
        EndSwitch

    Else

        $mode = "Pointer Speed Factor:"

        Switch $Speed
           Case 0 to 1
                 $multiplier = "1/32"
           Case 2
                 $multiplier = "1/16"
           Case 3
                 $multiplier = "1/8"
           Case 4
                 $multiplier = "2/8"
           Case 5
                 $multiplier = "3/8"
           Case 6
                 $multiplier = "4/8"
           Case 7
                 $multiplier = "5/8"
           Case 8
                 $multiplier = "6/8"
           Case 9
                 $multiplier = "7/8"
           Case 10
                 $multiplier = "1"
           Case 11
                 $multiplier = "1 1/4"
           Case 12
                 $multiplier = "1 2/4"
           Case 13
                 $multiplier = "1 3/4"
           Case 14
                 $multiplier = "2"
           Case 15
                 $multiplier = "2 1/4"
           Case 16
                 $multiplier = "2 2/4"
           Case 17
                 $multiplier = "2 3/4"
           Case 18
                 $multiplier = "3"
           Case 19
                 $multiplier = "3 1/4"
           Case 20
                 $multiplier = "3 2/4"
        EndSwitch

    EndIf

EndFunc

 
Func _StringIsNumber($input) ; Checks if an input string is a number.
;   The default StringIsDigit() function doesn't recognize negatives or decimals.
;   "If $input == String(Number($input))" doesn't recognize ".1" since Number(".1") returns 0.1
;   So, here's a regex I pulled from http://www.regular-expressions.info/floatingpoint.html
   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3)
   if UBound($array) > 0 Then
      Return True
   EndIf
   Return False
EndFunc

 
Func _GetNumberFromString($input) ; uses the above regular expression to pull a proper number
;   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3) ; this didn't return negatives
   $array = StringRegExp($input, '^([-+])?(\d*\.\d+|\d+)$', 3)
   if UBound($array) > 1 Then
      Return Number($array[0] & $array[1]) ; $array[0] is "" or "-", $array[1] is the number.
   EndIf
   Return "error"
EndFunc