
import nimgl/[opengl, glfw]
import glm
import std/[streams, monotimes, os, strformat, unicode, math, options]
import readcht, initchart, shaders, types, globals, font, unirender,audio,aff2cht,load,binchart,tricks,message,rect
var
  dest=0
  mouseX,mouseY:float32
var
  lineRI, gameBg, vLineRI:RenderInstance
  mvp:Mat4[GLfloat]
  floor:float32
  view:bool
  chosenNotes:seq[int]
  copiedNotes:seq[Note]
  hDivisor:int=16
  vDivisor:int=4
  vLines:seq[(float32,uint8,uint8)]
  vColors:array[81,Vec4[float32]]=[
    vec4(1'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(1'f32,0'f32,0'f32,1'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(0'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,0'f32,1'f32),vec4(0'f32,0'f32,1'f32,1),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(1'f32,1'f32,0'f32,1'f32),vec4(1'f32,1'f32,0'f32,1'f32),vec4(1'f32,1'f32,0'f32,1'f32),vec4(1'f32,1'f32,0'f32,1'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(1'f32,0.5'f32,0'f32,1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(1'f32,0'f32,0'f32,1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(1'f32,0.5'f32,0'f32,1'f32),vec4(0'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(1'f32,0'f32,1'f32,1'f32),vec4(0'f32),vec4(0'f32),
    vec4(1'f32),vec4(0'f32,1'f32,1'f32,1'f32),vec4(0'f32,0'f32,1'f32,1'f32),vec4(0'f32,1'f32,1'f32,1'f32),vec4(1'f32,0'f32,0'f32,1'f32),vec4(0'f32,1'f32,1'f32,1'f32),vec4(0'f32,0'f32,1'f32,1'f32),vec4(0'f32,1'f32,1'f32,1'f32),vec4(0'f32),
    vec4(1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),vec4(0'f32,1'f32,0'f32,1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),vec4(1'f32,0'f32,0.5'f32,1'f32),
  ]
  t1,f1,x1:float32
  eventI:int=0
  eventText:TextInstance
template hAdjust(f:float32):float32=
  round(f*hDivisor.float32)/hDivisor.float32
template hAdjust2(f:float32):float32=
  round(f*hDivisor.float32*2)/hDivisor.float32/2
proc reDrawVLines=
  vLines.setLen(0)
  var
    t:float32=chart.events[0].t1
    le=0
    a:uint8=0
  while t<musicLength():
    while le+1<chart.events.len and t>chart.events[le+1].t1:
      inc le
      t=chart.events[le].t1
      a=0
    let f=convertFloor(t,chart.events)
    vLines.add (f,vDivisor.uint8,a)
    a = (a+1) mod vDivisor.uint8
    t+=60/vDivisor/chart.events[le].bpm
  vlineRI.updateBuffer(1,vLines.len*(sizeof((GLfloat,GLubyte,GLubyte))),vLines[0].addr)
const
  linePos = -0.667
  xSF = 0.2
  persF = 0.4
proc convertY(chart:Chart,y:float32,divisor:int):float32=
  let
    f=(y-linePos)/speed+floor
  var le=0
  for i,e in chart.events:
    if e.t1<=igt:
      le=i
    else:
      break
  result=chart.events[le].t1
  var
    t=result
    lf=convertFloor(result,chart.events)
  while le+1<chart.events.len:
    while le+1<chart.events.len and chart.events[le+1].t1<=t:
      inc le
    while le+1<chart.events.len and chart.events[le+1].t1>t:
      let f1=convertFloor(t,chart.events)
      if abs(f1-f)<abs(lf-f):
        result=t
        lf=f1
      t+=60/divisor/chart.events[le].bpm
  while true:
    let f1=convertFloor(t,chart.events)
    if abs(f1-f)<=abs(lf-f):
      result=t
      lf=f1
    else:
      break
    t+=60/divisor/chart.events[le].bpm
var
  shift,control,alt:bool
  enableInputMode:bool
  inputMode:bool
  input:string
  inputCallBack:proc(s:string)
  inputText:TextInstance
proc startInput(cb:proc(s:string))=
  enableInputMode=true
  input.setLen(0)
  inputText.update(input)
  inputCallBack=cb
proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl,safe.} =
  if inputMode:
    case action
    of GLFWPress:
      case key
      of GLFWKey.Enter:
        inputMode=false
        inputCallBack(input)
      else:
        discard
    else:
      discard
    return
  case action
  of GLFWPress:
    case key
    of GLFWKey.A:
      if control:
        chosenNotes.setLen(chart.notes.len)
        for i in 0..chart.notes.high:
          chosenNotes[i]=i
          chart.notes[i].chosen=1
        updateChart(chart)
    of GLFWKey.J:
      if control:
        for i in chosenNotes:
          chart.notes[i].x1=hAdjust(chart.notes[i].x1)
          chart.notes[i].x2=hAdjust(chart.notes[i].x2)
        updateChart(chart)
    of GLFWKey.GraveAccent:
      dest=1
    of GLFWKey.Q:
      t1=convertY(chart,mouseY,vDivisor)
      f1=convertFloor(t1,chart.events)
      x1=hAdjust(mouseX/2+0.5)
    of GLFWKey.W:
      t1=convertY(chart,mouseY,vDivisor)
      f1=convertFloor(t1,chart.events)
      x1=hAdjust(mouseX/2+0.5)
    of GLFWKey.E:
      for i in chosenNotes:
        chart.notes[i].kind=1-chart.notes[i].kind
      updateChart(chart)
    of GLFWKey.D:
      var j=0
      for i in chosenNotes:
        chart.notes.delete(i-j)
        inc j
      chosenNotes.setLen(0)
      chart.updateChart()
    of GLFWKey.R:
      startInput do(s:string):
        let c= toColor(s)
        if c.isSome():
          for i in chosenNotes:
            (chart.notes[i].r,chart.notes[i].g,chart.notes[i].b)=c.get()
          updateChart(chart)
    of GLFWKey.T:
      inc eventI
      chart.events.insert(chart.events[eventI-1],eventI)
    of GLFWKey.Y:
      startInput do(s:string):
        let bpm=myParseFloat(s)
        if not bpm.isNaN():
          chart.events[eventI].bpm=bpm
        reDrawVLines()
    of GLFWKey.U:
      chart.events[eventI].t1=convertY(chart,mouseY,vDivisor)
      updateNotes(chart)
      reDrawVLines()
    of GLFWKey.I:
      chart.events[eventI].t2=convertY(chart,mouseY,vDivisor)
      updateNotes(chart)
      reDrawVLines()
    of GLFWKey.O:
      startInput do(s:string):
        let t=myParseFloat(s)
        if not t.isNaN():
          chart.events[eventI].speed=t
          updateNotes(chart)
          reDrawVLines()
    of GLFWKey.P:
      startInput do(s:string):
        let t=myParseFloat(s)
        if not t.isNaN():
          chart.events[eventI].jump=t
          updateNotes(chart)
          reDrawVLines()
    of GLFWKey.C:
      if control and chosenNotes.len>0:
        copiedNotes.setLen(0)
        let t=chart.notes[chosenNotes[0]].t1
        for i in chosenNotes:
          var n=chart.notes[i]
          n.t1-=t
          n.t2-=t
          copiedNotes.add n
    of GLFWKey.V:
      if control and copiedNotes.len>0:
        for i in chosenNotes:
          chart.notes[i].chosen=0
        chosenNotes.setLen(0)
        let t=convertY(chart,mouseY,vDivisor)
        for n in copiedNotes:
          var n2=n
          n2.t1+=t
          n2.t2+=t
          n2.f1=convertFloor(n2.t1,chart.events)
          n2.f2=convertFloor(n2.t2,chart.events)
          chosenNotes.add chart.addNote(n2)
        chart.updateChart()
    of GLFWKey.S:
      if control:
        var s = openFileStream("maps"/chartPath/"chart.qv", fmWrite)
        defer: s.close()
        chart.writeChart(s)
        addMessage mkInfo,"file saved"
    of GLFWKey.Equal:
      for i in chosenNotes:
        inc chart.notes[i].width
      chart.updateChart()
    of GLFWKey.Minus:
      for i in chosenNotes:
        dec chart.notes[i].width
      chart.updateChart()
    of GLFWKey.L:
      startInput do(s:string):
        let t=myParseFloat(s)
        if not t.isNaN():
          chart.offset=t
          updateNotes(chart)
    of GLFWKey.LeftShift,GLFWKey.RightShift:
      shift=true
    of GLFWKey.LeftControl,GLFWKey.RightControl:
      control=true
    of GLFWKey.LeftAlt,GLFWKey.RightAlt:
      alt=true
    of GLFWKey.LeftBracket:
      vDivisor=max(1,vDivisor-1)
      reDrawVLines()
    of GLFWKey.RightBracket:
      inc vDivisor
      reDrawVLines()
    of GLFWKey.Comma:
      eventI=(eventI+chart.events.len-1) mod chart.events.len
    of GLFWKey.Period:
      eventI=(eventI+1) mod chart.events.len
    of GLFWKey.Backslash:
      raise newException(Exception,"You pressed '\\'!")
    else:
      inc keyn
  of GLFWRelease:
    case key
    of GLFWKey.Space:
      if musicPlaying():
        pauseMusic()
      else:
        resumeMusic()
    of GLFWKey.Escape:
      dest=2
    of GLFWKey.Q:
      let
        t=convertY(chart,mouseY,vDivisor)
        f=convertFloor(t,chart.events)
        x=hAdjust(mouseX/2+0.5)
      if t>=t1:
        chart.addNote(Note(t1:t1,t2:t,f1:f1,f2:f,x1:x1,x2:x,width:16,r:255,g:255,b:255,kind:0))
      else:
        chart.addNote(Note(t1:t,t2:t1,f1:f,f2:f1,x1:x,x2:x1,width:16,r:255,g:255,b:255,kind:0))
      chart.updateChart()
    of GLFWKey.W:
      let
        t=convertY(chart,mouseY,vDivisor)
        f=convertFloor(t,chart.events)
        x=hAdjust(mouseX/2+0.5)
      if t>=t1:
        chart.addNote(Note(t1:t1,t2:t,f1:f1,f2:f,x1:x1,x2:x,width:16,r:255,g:255,b:255,kind:1))
      else:
        chart.addNote(Note(t1:t,t2:t1,f1:f,f2:f1,x1:x,x2:x1,width:16,r:255,g:255,b:255,kind:1))
      chart.updateChart()
    of GLFWKey.LeftShift,GLFWKey.RightShift:
      shift=false
    of GLFWKey.LeftControl,GLFWKey.RightControl:
      control=false
    of GLFWKey.LeftAlt,GLFWKey.RightAlt:
      alt=false
    else:
      dec keyn
      if keyn<0:keyn=0
  else:
    discard
proc scrollProc(window: GLFWWindow, xoffset: float64, yoffset: float64): void {.cdecl,safe.}=
  setMusicPosF(max(0,getMusicPosF()+yoffset.float32/16))
proc mouseMotionProc(window: GLFWWindow, xpos: float64, ypos: float64): void {.cdecl,safe.}=
  mouseX=xpos.float32*2/scrnW.float32-1
  mouseY=1-ypos.float32*2/scrnH.float32
var
  ct1,ct2,cx1,cx2:float32
proc mouseButtonProc(window: GLFWWindow, button: int32, action: int32, mods: int32): void {.cdecl,safe.}=
  if mouseY>=0.975:
    setMusicPosF(musicLength()*(mouseX+1)/2)
    return
  case action
  of GLFWPress:
    ct1=convertY(chart,mouseY,vDivisor*2)
    cx1=hAdjust2(mouseX/2+0.5)
  of GLFWRelease:
    if not control:
      chosenNotes.setLen(0)
    ct2=convertY(chart,mouseY,vDivisor*2)
    cx2=hAdjust2(mouseX/2+0.5)
    for i,n in chart.notes.mpairs():
      if (n.t2>=min(ct1,ct2) and n.t1<=max(ct1,ct2)) and (max(n.x1,n.x2)>=min(cx1,cx2) and min(n.x1,n.x2)<=max(cx1,cx2)):
        n.chosen=1
        chosenNotes.add i
      else:
        if not control:
          n.chosen=0
    chart.updateChart()
  else:
    discard
proc inputProc(window: GLFWWindow, codepoint: uint32): void {.cdecl,safe.}=
  if inputMode:
    if codepoint==ord('\n'):
      inputMode=false
      inputCallBack(input)
    else:
      input &= $Rune(codepoint)
      inputText.update(input)
var progressBar:Rect
var
  verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
  inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]

proc render()=
  safeDo:
    floor = convertFloor(igt, chart.events)
    glClearColor(0, 0, 0, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    # gameBg.render(1,0):discard
    chart.ri.render(len(chart.notes)):
      glUniformMatrix4fv(chart.ri.uMVP, 1, false, mvp.caddr)
      glUniform1f(chart.ri.uSpeed, speed)
      glUniform1f(chart.ri.uXSF, if view:xSF else:0)
      glUniform1f(chart.ri.uFloor, floor)
      glUniform1f(chart.ri.uLinePos, linePos)
      glUniform1f(chart.ri.uPersF, if view:persF else:0)
    lineRI.render(1):
      glUniformMatrix4fv(lineRI.uMVP, 1, false, mvp.caddr)
      glUniform1f(lineRI.uLinePos, linePos)
    vlineRI.render(vLines.len):
      glUniformMatrix4fv(vlineRI.uMVP, 1, false, mvp.caddr)
      glUniform1f(vlineRI.uSpeed, speed)
      glUniform1f(vlineRI.uFloor, floor)
      glUniform1f(vlineRI.uLinePos, linePos)
      glUniform4fv(vlineRI.uColors, 81*4, cast[ptr GLfloat](vColors[0].addr))
    eventText.update(&"[{eventI}/{chart.events.len}]\n" & $chart.events[eventI])
    eventText.render(-0.95,0.95)
    if inputMode:
      inputText.render(-0.95,-0.95)
    drawRect(progressBar,-1,1,getMusicPosF()/musicLength()*2,0.025,0,1)
  renderMessages()
proc gameedit*(): State =
  safeDo:
    discard window.setKeyCallback(keyProc)
    discard window.setScrollCallback(scrollProc)
    discard window.setCursorPosCallback(mouseMotionProc)
    discard window.setMouseButtonCallback(mouseButtonProc)
    discard window.setCharCallback(inputProc)
  safeDo:
    dest=0
    initRenderInstance(lineRI,inds,[(@[(rFloat,2,0)],2*sizeof(GLfloat))],0,lineShader,["uMVP","uLinePos"])
    lineRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
    initRenderInstance(vlineRI,inds,[(@[(rFloat,2,0)],2*sizeof(GLfloat)),(@[(rFloat,1,1),(rUByte,2,1)],sizeof((GLfloat,GLubyte,GLubyte)))],0,vlineShader,["uMVP","uLinePos","uFloor","uSpeed"])
    initRect(progressBar,[(0xff'u8,0xff'u8,0xff'u8,0xff'u8),(0xff,0xff,0xff,0xff),(0xff,0xff,0xff,0xff),(0xff,0xff,0xff,0xff)])
  defer:
    destroyRenderInstance(vlineRI)
    destroyRenderInstance(lineRI)
    destroyRenderInstance(progressBar)

  safeDo:
    vlineRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
    chosenNotes.setLen(0)
    vDivisor=4
    eventI=0
    igt=0
    floor=0
    inputMode=false
  safeDo:
    if fileExists(getAppDir()/"maps"/chartPath/"chart.qv"):
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.qv", fmRead)
      defer: s.close()
      readChartFromBinary(chart, s)
    elif fileExists(getAppDir()/"maps"/chartPath/"chart.cht"):
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.cht", fmRead)
      defer: s.close()
      readCht(chart, s)
      var ws = openFileStream("getAppDir()/maps"/chartPath/"chart.qv", fmWrite)
      defer: ws.close()
      writeChart(chart,ws)
    else:
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.aff", fmRead)
      defer: s.close()
      readAff(s,chart)
      var ws = openFileStream(getAppDir()/"maps"/chartPath/"chart.qv", fmWrite)
      defer: ws.close()
      writeChart(chart,ws)
  safeDo:
    initChart(chart,false)
    initTextInstance(eventText,&"[0/{chart.events.len}]\n" & $chart.events[0])
    initTextInstance(inputText,"")
  defer:
    destroyRenderInstance(chart.ri)
    chart=Chart.default
  safeDo:
    if fileExists(getAppDir()/"maps"/chartPath/"music.ogg"):
      loadMusic(getAppDir()/"maps"/chartPath/"music.ogg")
    else:
      raiseAssert "only OGG supported"
  safeDo:
    reDrawVLines()
    mvp = ortho[GLfloat](-1, 1, -1, 1, -1, 1)
  loadOutro(render)
  lastTime = getMonoTime().ticks()
  startTime = lastTime
  time = lastTime
  safeDo:
    playMusic()
  defer:stopMusic()
  while not window.windowShouldClose():
    time = getMonoTime().ticks()
    if getMusicPosF()>=musicLength():
      setMusicPosF(0)
    igt = getMusicPosF()-chart.offset
    if time-lastTime >= 16_000_000:
      if compatibilityMode:
        glFinish()
      else:
        glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT or GL_BUFFER_UPDATE_BARRIER_BIT)
      render()
      window.swapBuffers()
      lastTime = time
    glfwPollEvents()
    if enableInputMode:
      enableInputMode=false
      inputMode=true
    case dest
    of 0:
      discard
    of 1:
      loadIntro(render)
      return sGamePlay
    of 2:
      loadIntro(render)
      return sSongs
    else:
      discard
    time = getMonoTime().ticks()
  if window.windowShouldClose():quit(QuitSuccess)
  loadIntro(render)
  return sSongs
