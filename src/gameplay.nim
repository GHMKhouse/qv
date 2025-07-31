
import nimgl/[opengl, glfw]
import glm
import std/[streams, monotimes, strformat,os]
import readcht, initchart, shaders, types, globals, font, unirender,audio,judge,aff2cht,load
var dest=0
proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  case action
  of GLFWPress:
    case key
    of GLFWKey.Home:
      dest=1
    else:
      if not autoPlay:
        dealKey()
      inc keyn
  of GLFWRelease:
    if key!=GLFWKey.Escape:
      dec keyn
      if keyn<0:keyn=0
    else:
      dest=2
  else:
    discard


var
  verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
  inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
const
  linePos = -0.667
proc gameplay*(): State =
  discard window.setKeyCallback(keyProc)
  dest=0
  var lineRI:RenderInstance
  initRenderInstance(lineRI,inds,[(@[(rFloat,2,0)],2*sizeof(GLfloat))],0,lineShader,["uMVP","uLinePos"])
  defer:
    destroyRenderInstance(lineRI)
  lineRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  var particleRI:RenderInstance
  initRenderInstance(particleRI,inds,[
    (@[(rFloat,2,0)],2*sizeof(GLfloat)),
    (@[(rFloat,3,1),(rUByte,3,1)],sizeof(Particle))],0,particleShader,["uMVP","uLinePos","uTime"])
  defer:destroyRenderInstance(particleRI)
  particleRI.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  particles=cast[ptr array[256, Particle]](alloc(256*sizeof(Particle)))
  defer:dealloc(particles)
  for p in particles[].mitems():
    p = Particle.default
  particleRI.updateBuffer(1,256*sizeof(Particle),particles)

  (judgedNotes, combo, maxCombo, xExact, exact, fine, good, lost) = (0,0,0,0,0,0,0,0)
  notes.setLen(0)
  catches.setLen(0)
  postJudges.setLen(0)
  (jNotes,jCatches,postJudged,judged)=(0,0,0,0)
  lastCaught = -Inf.float32
  acc=1
  score=0
  block readChart:
    if fileExists("maps"/chartPath/"chart.cht"):
      var s = openFileStream("maps"/chartPath/"chart.cht", fmRead)
      defer: s.close()
      readCht(chart, s)
    else:
      var s = openFileStream("maps"/chartPath/"chart.aff", fmRead)
      defer: s.close()
      readAff(s,chart)
  initChart(chart)
  defer:
    destroyRenderInstance(chart.ri)
    chart=Chart.default
  if fileExists("maps"/chartPath/"music.ogg"):
    loadMusic("maps"/chartPath/"music.ogg")
  else:
    loadMusic("maps"/chartPath/"music.wav")
  
  var
    titleText, levelText: TextInstance
  initTextInstance(titleText, chart.title)
  defer: destroyTextInstance(titleText)
  initTextInstance(levelText, chart.level)
  defer: destroyTextInstance(levelText)
  var
    accText,comboText,judgeText,scoreText: TextInstance
  initTextInstance(accText, "100.00%")
  defer: destroyTextInstance(accText)
  initTextInstance(comboText, "0/0")
  defer: destroyTextInstance(comboText)
  initTextInstance(judgeText, "0(0)/0/0/0")
  defer: destroyTextInstance(judgeText)
  initTextInstance(scoreText, "0000000")
  defer: destroyTextInstance(judgeText)
  var
    mvp = ortho[GLfloat](-1, 1, -1, 1, -1, 1)
  
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)
  titleText.render(-0.95, -0.85)
  judgeText.render(-0.95, 0.85)
  levelText.render(0.95, -0.85, alignRight)
  scoreText.render(0.95, 0.85, alignRight)
  accText.render(0, -0.85, alignMiddle)
  comboText.render(0, 0.75, alignMiddle)
  
  lineRI.render(1):
    glUniformMatrix4fv(lineRI.uMVP, 1, false, mvp.caddr)
    glUniform1f(lineRI.uLinePos, linePos)
  loadOutro()
  lastTime = getMonoTime().ticks()
  startTime = lastTime
  time = lastTime
  playMusic()
  defer:stopMusic()
  while (time-startTime)/1_000_000_000<musicLength()+1 and not window.windowShouldClose():
    time = getMonoTime().ticks()
    igt = (time-startTime)/1_000_000_000-chart.offset
    if time-lastTime >= 16_000_000:
      let
        floor = convertFloor(igt, chart.events)
      if autoPlay:
        dealAutoPlay()
      else:
        recentlyCaught=false
        dealUpdate()
      score=int(ceil(1000000*acc*(judged/numOfNotes)))+int(ceil(48576*xExact/numOfNotes))
      accText.update(fmt"{acc*100:.2f}%")
      comboText.update(fmt"{combo}/{maxCombo}/{numOfNotes}")
      judgeText.update(fmt"{exact+xExact}({xExact})/{fine}/{good}/{lost}")
      scoreText.update(fmt"{score:07}")
    
      particleRI.updateBuffer(1,256*sizeof(Particle),particles)

      glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT or GL_BUFFER_UPDATE_BARRIER_BIT)
      glClearColor(0, 0, 0, 1)
      glClear(GL_COLOR_BUFFER_BIT)
      titleText.render(-0.95, -0.85)
      judgeText.render(-0.95, 0.85)
      levelText.render(0.95, -0.85, alignRight)
      scoreText.render(0.95, 0.85, alignRight)
      accText.render(0, -0.85, alignMiddle)
      comboText.render(0, 0.75, alignMiddle)
      chart.ri.render(len(chart.notes)):
        glUniformMatrix4fv(chart.ri.uMVP, 1, false, mvp.caddr)
        glUniform1f(chart.ri.uSpeed, speed)
        glUniform1f(chart.ri.uXSF, 0.1)
        glUniform1f(chart.ri.uFloor, floor)
        glUniform1f(chart.ri.uLinePos, linePos)
      
      lineRI.render(1):
        glUniformMatrix4fv(lineRI.uMVP, 1, false, mvp.caddr)
        glUniform1f(lineRI.uLinePos, linePos)

      particleRI.render(256):
        glUniformMatrix4fv(particleRI.uMVP, 1, false, mvp.caddr)
        glUniform1f(particleRI.uLinePos, linePos)
        glUniform1f(particleRI.uTime, igt)

      window.swapBuffers()
      lastTime = time

    glfwPollEvents()
    case dest
    of 0:
      discard
    of 1:
      loadIntro()
      return sGamePlay
    of 2:
      loadIntro()
      return sSongs
    else:
      discard
    time = getMonoTime().ticks()
  if window.windowShouldClose():quit(QuitSuccess)
  loadIntro()
  return sResults
