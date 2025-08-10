import std/[streams,endians]
import types
proc readLE[T](s:Stream):T=
  var data:array[sizeof(T),byte]
  doAssert s.readData(data[0].addr,sizeof(T))==sizeof(T)
  littleEndian32(result.addr,data[0].addr)
proc writeLE[T](s:Stream,x:T)=
  var data:array[sizeof(T),byte]
  littleEndian32(data[0].addr,x.addr)
  s.writeData(data[0].addr,sizeof(T))
proc readChartFrombinary*(chart:var Chart,stream:Stream)=
  chart.offset=stream.readLE[:float32]()
  chart.notes=newSeqUninit[Note](stream.readLE[:uint32]().int)
  for i in 0..<chart.notes.len:
    chart.notes[i].t1=stream.readLE[:float32]()
    chart.notes[i].t2=stream.readLE[:float32]()
    chart.notes[i].f1=stream.readLE[:float32]()
    chart.notes[i].f2=stream.readLE[:float32]()
    chart.notes[i].x1=stream.readLE[:float32]()
    chart.notes[i].x2=stream.readLE[:float32]()
    chart.notes[i].width=stream.readLE[:uint8]()
    chart.notes[i].r=stream.readLE[:uint8]()
    chart.notes[i].g=stream.readLE[:uint8]()
    chart.notes[i].b=stream.readLE[:uint8]()
    chart.notes[i].kind=stream.readLE[:uint8]()
    chart.notes[i].judged=0
  chart.events=newSeqUninit[Event](stream.readLE[:uint32]().int)
  for i in 0..<chart.events.len:
    chart.events[i].t1=stream.readLE[:float32]()
    chart.events[i].t2=stream.readLE[:float32]()
    chart.events[i].bpm=stream.readLE[:float32]()
    chart.events[i].speed=stream.readLE[:float32]()
    chart.events[i].jump=stream.readLE[:float32]()
    chart.events[i].xsEasing=stream.readLE[:float32]()
    chart.events[i].xs1=stream.readLE[:float32]()
    chart.events[i].xs2=stream.readLE[:float32]()
proc writeChart*(chart:var Chart,stream:Stream)=
  stream.writeLE chart.offset
  stream.writeLE chart.notes.len.uint32
  for note in chart.notes:
    stream.writeLE note.t1
    stream.writeLE note.t2
    stream.writeLE note.f1
    stream.writeLE note.f2
    stream.writeLE note.x1
    stream.writeLE note.x2
    stream.writeLE note.width
    stream.writeLE note.r
    stream.writeLE note.g
    stream.writeLE note.b
    stream.writeLE note.kind
  stream.writeLE chart.events.len.uint32
  for event in chart.events:
    stream.writeLE event.t1
    stream.writeLE event.t2
    stream.writeLE event.bpm
    stream.writeLE event.speed
    stream.writeLE event.jump
    stream.writeLE event.xsEasing
    stream.writeLE event.xs1
    stream.writeLE event.xs2