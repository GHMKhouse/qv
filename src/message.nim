import std/[monotimes,macros]
import font,types,rect,unirender
type
  MessageKind* = enum
    nkDebug,mkInfo,mkWarning,mkError
  Message* = object
    msg:string
    time:int64
    kind:MessageKind
    ti:TextInstance
    ri:Rect
let c:array[MessageKind,(uint8,uint8,uint8,uint8)]=[(0x88'u8,0x88'u8,0x88'u8,0xbb'u8),(0x00,0x88,0x88,0xbb),(0x88,0x88,0x00,0xbb),(0x88,0x00,0x00,0xbb),]
var
  msgs:array[64,Message]
  head,tail:int
proc renderMessages*()=
  var i=head
  while i!=tail:
    if getMonoTime().ticks()-msgs[i].time>5_000_000_000:
      destroyTextInstance(msgs[i].ti)
      destroyRenderInstance(msgs[i].ri)
      head=(head+1) and 63
    else:
      let
        y=0.95-0.08*((i-head+64) and 63).float32
      msgs[i].ri.drawRect(0.95,y,msgs[i].ti.width.float32/16*0.04*2,0.08,1,0.5)
      msgs[i].ti.render(0.95,y,alignRight)
    i=(i+1) and 63
proc addMessage*(kind:MessageKind,text:string)=
  msgs[tail]=Message(msg:text,time:getMonoTime().ticks(),kind:kind)
  initRect(msgs[tail].ri,[c[kind],c[kind],c[kind],c[kind]])
  initTextInstance(msgs[tail].ti,text)
  tail=(tail+1) and 63
template safeDo*(body)=
  try:
    body
  except Exception as e:
    stderr.write e.getStackTrace()
    stderr.write e.msg
    stderr.write "\n"
    addMessage(mkError,e.msg)
macro safe*(def:untyped)=
  def.expectKind nnkProcDef
  result=def
  result.body=newCall(ident("safeDo"),result.body)