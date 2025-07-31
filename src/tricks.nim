import std/[math, strutils]
proc myParseFloat*(x: string): float32 =
  var
    r = 0
    i = 0
    neg = if x[i] == '-':
        inc i
        -1'f32
      elif x[i] == '+':
        inc i
        1'f32
      else:
        1'f32
    e = 0'i32
  while i < x.len and x[i].isDigit():
    r = r*10+x[i].ord-'0'.ord
    inc i
  if i >= x.len: return r.float32*neg
  if x[i] == '.':
    inc i
    while i < x.len and x[i].isDigit():
      r = r*10+x[i].ord-'0'.ord
      inc i
      dec e
  if i >= x.len: return r.float32*neg*pow(10'f32, e.float32)
  if x[i] == 'e':
    inc i
    var e2 = 0
    let
      eneg = if x[i] == '-':
          inc i
          -1
        elif x[i] == '+':
          inc i
          1
        else:
          1
    while i < x.len:
      e2 = e2*10+x[i].ord-'0'.ord
      inc i
    return r.float32*neg*pow(10'f32, (e+e2).float32)
# {.define:testMyParseFloat.}
when defined(testMyParseFloat):
  {.hint: $myParseFloat("1").}
  {.hint: $myParseFloat("-11.4514e4").}