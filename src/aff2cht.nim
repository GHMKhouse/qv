import streams,strutils,algorithm
import types,tricks
proc readAff*(s:Stream,chart:var Chart)=
  var offset=s.readLine().split(':')[^1].myParseFloat()/1000
  while s.readLine().strip()!="-":
    discard
  template readAtom():string=
    var res:string
    while true:
      let c=s.readChar()
      if c in {',',')'}:
        break
      else:
        res.add c
    res

  while not s.atEnd():
    var cmd:string
    while s.peekChar().isSpaceAscii():
      discard s.readChar()
    if s.peekChar==';':
      discard s.readChar()
      continue
    if s.peekChar=='}':
      doAssert s.readStr(2)=="};"
      if s.atEnd():
        break
      else:
        discard s.readChar()
        continue
    while true:
      let c=s.readChar()
      if c=='(':
        break
      else:
        cmd.add c
    if s.peekChar()==';':
      discard s.readChar()
    case cmd
    of "timing":
      #echo "t"
      let
        t=readAtom().myParseFloat()/1000
        bpm=readAtom().myParseFloat()
        dsc=readAtom()
      chart.events.add Event(t1:t,t2:t,bpm:bpm,speed:1) # no use now
    of "arc":
      #echo "a"
      let
        t1=readAtom().myParseFloat()/1000
        t2=readAtom().myParseFloat()/1000
        x1=readAtom().myParseFloat()/3+0.33
        x2=readAtom().myParseFloat()/3+0.33
        es=readAtom()
        y1=readAtom()
        y2=readAtom()
        c=readAtom().parseInt().uint8
        dsc=readAtom()
        trace=readAtom()=="true"
      if not trace:
        chart.notes.add Note(t1:t1,t2:t2,f1:t1,f2:t2,x1:x1,x2:x2,width:10,r:255*c,g:0,b:255*(1-c),kind:1)
      if s.peekChar()=='[':
        discard s.readChar()
        while true:
          # echo "at"
          doAssert s.readStr(7)=="arctap("
          var t=readAtom().myParseFloat()/1000
          let
            x=x1+(x2-x1)*(t-t1)/(t2-t1)
          chart.notes.add Note(t1:t,t2:t,f1:t,f2:t,x1:x,x2:x,width:20,r:160,g:160,b:160,kind:0)
          if s.readChar()==']':break
    of "hold":
      #echo "h"
      let
        t1=readAtom().myParseFloat()/1000
        t2=readAtom().myParseFloat()/1000
        x=(readAtom().myParseFloat()/2-1.25)/3+0.5
      chart.notes.add Note(t1:t1,t2:t2,f1:t1,f2:t2,x1:x,x2:x,width:16,r:255,g:255,b:255,kind:0)
    of "":
      #echo "n"
      let
        t=readAtom().myParseFloat()/1000
        x=(readAtom().myParseFloat()/2-1.25)/3+0.5
      chart.notes.add Note(t1:t,t2:t,f1:t,f2:t,x1:x,x2:x,width:16,r:255,g:255,b:255,kind:0)
    of "scenecontrol":
      let
        a=readAtom()
        b=readAtom()
        c=readAtom()
        d=readAtom()
      discard s.readStr(2)
      # echo s.getPosition()
    else:
      discard s.readLine()
  chart.events.sort(proc (x,y:Event):int=cmp(x.t1,y.t1))
  chart.notes.sort(proc (x,y:Note):int=cmp(x.t1,y.t1))