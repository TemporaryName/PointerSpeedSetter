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
