import std/[streams, strutils]
import types,tricks


proc convertTime*(beat: float32, bpms: seq[Event]): float32 =
  if bpms.len == 0: return 0
  var
    bt = beat
    lbpm = bpms[0].bpm
    lt = 0'f32
  for event in bpms:
    if bt < (event.t1-lt)*lbpm/60:
      result+=bt*60/lbpm
      return
    else:
      bt-=(event.t1-lt)*lbpm/60
      result+=event.t1-lt
      lbpm = event.bpm
      lt = event.t1
  result+=bt*60/lbpm
proc convertFloor*(time: float32, speeds: seq[Event]): float32 =
  if speeds.len == 0: return 0
  var
    t = time
    ls = speeds[0].speed
    lt = 0'f32
  for event in speeds:
    if t < event.t1-lt:
      result+=ls*t
      return
    else:
      t-=event.t1-lt
      result+=ls*(event.t1-lt)+event.jump
      ls = event.speed
      lt = event.t1
  result+=ls*t

# {.define:testConvertTime.}
when defined(testConvertTime):
  {.hint: $convertTime(8, @[Event(t1: 0, bpm: 120), Event(t1: 2, bpm: 240)]).}
  # == 3.0
  {.hint: $convertFloor(6, @[Event(t1: 0.0, t2: 0.0, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 0.0, t2: 0.0, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 0.0, t2: 0.0, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 0.0, t2: 0.0, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 0.673, t2: 0.673, bpm: 1424.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 0.674, t2: 0.674, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 2.696, t2: 2.696, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 8.089, 
t2: 8.089, bpm: 89.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 11.46, t2: 11.46, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 12.134, t2: 12.134, bpm: 178.0, speed: 
1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 69.606, t2: 69.606, bpm: 89.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 70.112, t2: 70.112, bpm: 89.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 71.46, t2: 71.46, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 75.168, t2: 75.168, bpm: 89.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 75.505, t2: 75.505, bpm: 89.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 76.853, t2: 76.853, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 130.785, t2: 130.785, bpm: 9999998.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 130.786, t2: 130.786, bpm: 44.5, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 131.122, t2: 131.122, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 132.133, t2: 132.133, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 170.0, t2: 170.0, bpm: -17800000.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 170.001, t2: 170.001, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), Event(t1: 171.235, t2: 171.235, bpm: 1335.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0), 
Event(t1: 171.236, t2: 171.236, bpm: 178.0, speed: 1.0, jump: 0.0, xsEasing: 0.0, xs1: 0.0, xs2: 0.0)]).}


proc readCht*(chart: var Chart, stream: Stream) =
  while true:
    var line = newStringOfCap(64)
    if not stream.readLine(line): break
    if line.isEmptyOrWhitespace(): continue
    let
      i = line.find(' ')
      j = line.find(' ', i+1)
      k = line.find(' ', j+1)
    if i == -1: break
    case line[0..<i].toUpper()
    of "OFFSET": chart.offset = line[i+1..^1].myParseFloat()
    of "BPM":
      let
        t1 = line[i+1..<j].myParseFloat().convertTime(chart.events)
        bpm = line[j+1..^1].myParseFloat()
      chart.events.add Event(t1: t1, t2: t1, bpm: bpm, speed: 1, xsEasing: 1,
          xs1: 0, xs2: 0)
    of "TITLE": chart.title = line[i+1..^1]
    of "LEVEL": chart.level = line[i+1..^1]
    of "COMPOSER": chart.composer = line[i+1..^1]
    of "CHARTER": chart.charter = line[i+1..^1]
    of "ILLUSTRATOR": chart.illustrator = line[i+1..^1]
    of "NOTE":
      let
        t = line[i+1..<j].myParseFloat().convertTime(chart.events)
        f = t.convertFloor(chart.events)
        x = line[j+1..<(k+line.len) mod line.len].myParseFloat()/1600
      chart.notes.add(Note(t1: t, t2: t, x1: x, x2: x, f1: f, f2: f, width: 16,
          r: 255, g: 255, b: 255, kind: 0))
    of "CATCH":
      let
        t = line[i+1..<j].myParseFloat().convertTime(chart.events)
        f = t.convertFloor(chart.events)
        x = line[j+1..<(k+line.len) mod line.len].myParseFloat()/1600
      chart.notes.add(Note(t1: t, t2: t, x1: x, x2: x, f1: f, f2: f, width: 16,
          r: 255, g: 255, b: 255, kind: 1))

