
import nimgl/[opengl, glfw]
import glm
import std/[streams, monotimes, strformat,os,tables]
import readcht, initchart, shaders, types, globals, font, unirender,audio,judge,aff2cht,load,res,binchart,message,rect

var
  dest=0
proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl,safe.} =
  case action
  of GLFWPress:
    case key
    of GLFWKey.GraveAccent:
      dest=1
    of GLFWKey.Enter:
      if not musicPlaying():
        setMusicPosF(max(0,getMusicPosF()-3))
        resumeMusic()
    else:
      if musicPlaying() and not autoPlay:
        dealKey()
      inc keyn
  of GLFWRelease:
    if key!=GLFWKey.Escape:
      dec keyn
      if keyn<0:keyn=0
    else:
      if musicPlaying():
        pauseMusic()
        for p in particles[].mitems():
          p = Particle.default
      else:
        dest=2
  else:
    discard


var
  verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
  inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
const
  linePos = -0.667
  xSF = 0.2
  persF = 0.4

var
  lineRI, particleRI, gameBg:RenderInstance
  titleText, levelText: TextInstance
  accText,comboText,judgeText,scoreText: TextInstance
  mvp:Mat4[GLfloat]
  floor:float32
  progressBar:Rect
proc render()=
  accText.update(fmt"{acc*100:.2f}%")
  comboText.update(fmt"{combo}/{maxCombo}/{judged}")
  judgeText.update(fmt"{exact+xExact}({xExact})/{fine}/{good}/{lost}")
  scoreText.update(fmt"{score:07}")
  particleRI.updateBuffer(1,256*sizeof(Particle),particles)
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)
  gameBg.render(1):discard
  titleText.render(-0.95, -0.85)
  judgeText.render(-0.95, 0.85)
  levelText.render(0.95, -0.85, alignRight)
  scoreText.render(0.95, 0.85, alignRight)
  accText.render(0, -0.85, alignMiddle)
  comboText.render(0, 0.75, alignMiddle)
  chart.ri.render(len(chart.notes)):
    glUniformMatrix4fv(chart.ri.uMVP, 1, false, mvp.caddr)
    glUniform1f(chart.ri.uSpeed, speed)
    glUniform1f(chart.ri.uXSF, xSF)
    glUniform1f(chart.ri.uFloor, floor)
    glUniform1f(chart.ri.uLinePos, linePos)
    glUniform1f(chart.ri.uPersF, persF)
  lineRI.render(1):
    glUniformMatrix4fv(lineRI.uMVP, 1, false, mvp.caddr)
    glUniform1f(lineRI.uLinePos, linePos)
  particleRI.render(256):
    glUniformMatrix4fv(particleRI.uMVP, 1, false, mvp.caddr)
    glUniform1f(particleRI.uLinePos, linePos)
    glUniform1f(particleRI.uTime, igt)
    glUniform1f(particleRI.uPersF, persF)
  drawRect(progressBar,-1,1,getMusicPosF()/musicLength()*2,0.025,0,1)
  renderMessages()
proc gameplay*(): State =
  discard window.setKeyCallback(keyProc)
  discard window.setScrollCallback(nil)
  discard window.setCursorPosCallback(nil)
  discard window.setMouseButtonCallback(nil)
  dest=0
  initRenderInstance(lineRI,inds,[(@[(rFloat,2,0)],2*sizeof(GLfloat))],0,lineShader,["uMVP","uLinePos"])
  defer:
    destroyRenderInstance(lineRI)
  lineRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  initRenderInstance(particleRI,inds,[
    (@[(rFloat,2,0)],2*sizeof(GLfloat)),
    (@[(rFloat,3,1),(rUByte,3,1)],sizeof(Particle))],0,particleShader,["uMVP","uLinePos","uTime","uPersF"])
  defer:destroyRenderInstance(particleRI)
  particleRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  initRenderInstance(gameBg,[0'u32,1,2,2,3,0],[(@[(rFloat,2,0)],2*sizeof(float32))],textures["gamebg"].glTex,bgShader,[])
  defer:destroyRenderInstance(gameBg)
  gameBg.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  particles=cast[ptr array[256, Particle]](alloc(256*sizeof(Particle)))
  defer:dealloc(particles)
  for p in particles[].mitems():
    p = Particle.default
  particleRI.updateBuffer(1,256*sizeof(Particle),particles)
  initRect(progressBar,[(0xff'u8,0xff'u8,0xff'u8,0xff'u8),(0xff,0xff,0xff,0xff),(0xff,0xff,0xff,0xff),(0xff,0xff,0xff,0xff)])
  (judgedNotes, combo, maxCombo, xExact, exact, fine, good, lost) = (0,0,0,0,0,0,0,0)
  defer:
    destroyRenderInstance(progressBar)
  notes.setLen(0)
  catches.setLen(0)
  postJudges.setLen(0)
  (jNotes,jCatches,postJudged,judged)=(0,0,0,0)
  lastCaught = -Inf.float32
  lastCaughtI = 0
  for i in 0..255:
    lastCaughts[i] = Inf.float32
  lastNote = 0
  acc=1
  score=0
  igt=0
  floor=0
  block readChart:
    if fileExists(getAppDir()/"maps"/chartPath/"chart.qv"):
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.qv", fmRead)
      defer: s.close()
      readChartFromBinary(chart, s)
    elif fileExists(getAppDir()/"maps"/chartPath/"chart.cht"):
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.cht", fmRead)
      defer: s.close()
      readCht(chart, s)
      var ws = openFileStream(getAppDir()/"maps"/chartPath/"chart.qv", fmWrite)
      defer: ws.close()
      writeChart(chart,ws)
    else:
      var s = openFileStream(getAppDir()/"maps"/chartPath/"chart.aff", fmRead)
      defer: s.close()
      readAff(s,chart)
      var ws = openFileStream(getAppDir()/"maps"/chartPath/"chart.qv", fmWrite)
      defer: ws.close()
      writeChart(chart,ws)
  initChart(chart)
  defer:
    destroyRenderInstance(chart.ri)
    chart=Chart.default
  if fileExists(getAppDir()/"maps"/chartPath/"music.ogg"):
    loadMusic(getAppDir()/"maps"/chartPath/"music.ogg")
  else:
    raiseAssert "only OGG supported"
  initTextInstance(titleText, chart.title)
  defer: destroyTextInstance(titleText)
  initTextInstance(levelText, chart.level)
  defer: destroyTextInstance(levelText)
  initTextInstance(accText, "100.00%")
  defer: destroyTextInstance(accText)
  initTextInstance(comboText, "0/0")
  defer: destroyTextInstance(comboText)
  initTextInstance(judgeText, "0(0)/0/0/0")
  defer: destroyTextInstance(judgeText)
  initTextInstance(scoreText, "0000000")
  defer: destroyTextInstance(judgeText)
  mvp = ortho[GLfloat](-1, 1, -1, 1, -1, 1)
  loadOutro(render)
  lastTime = getMonoTime().ticks()
  startTime = lastTime
  time = lastTime
  playMusic()
  defer:stopMusic()
  while getMusicPosF()<musicLength() and not window.windowShouldClose():
    time = getMonoTime().ticks()
    igt = getMusicPosF()-chart.offset
    if time-lastTime >= 16_000_000:
      floor = convertFloor(igt, chart.events)
      if autoPlay:
        dealAutoPlay()
      else:
        recentlyCaught=false
        dealUpdate()
      score=int(ceil(1000000*acc*(judged/numOfNotes)))+int(ceil(48576*xExact/numOfNotes))
      if compatibilityMode:
        glFinish()
      else:
        glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT or GL_BUFFER_UPDATE_BARRIER_BIT)
      render()
      window.swapBuffers()
      lastTime = time
    glfwPollEvents()
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
  return sResults
