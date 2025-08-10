import nimgl/[opengl,glfw]
import std/[os,tables,streams]
import globals,font,load,rect,types,unirender,res,shaders,message
when defined(windows):
  import filewindow,binchart

var
  songList:seq[(string,TextInstance,Rect)]
  chosen:int
  dest=0
  bg:RenderInstance
proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  case action
  of GLFWPress:
    case key
    of GLFWKey.Up:
      chosen=(chosen+songList.len-1) mod songList.len
    of GLFWKey.Down:
      chosen=(chosen+1) mod songList.len
    of GLFWKey.Enter:
      chartPath=songList[chosen][0]
      dest=1
    of GLFWKey.Backspace:
      chartPath=songList[chosen][0]
      dest=2
    of GLFWKey.GraveAccent: # `
      autoPlay = not autoPlay
    else:
      discard
  of GLFWRelease:
    case key
    of GLFWKey.Escape:
      quit(QuitSuccess)
    of GLFWKey.Equal:
      when defined(windows):
        let
          musicPath=openFileDialog()
        if musicPath.len>0:
          let
            (path,name,ext)=musicPath.splitFile()
          createDir(getAppDir()/"maps"/name)
          copyFile(musicPath,getAppDir()/"maps"/name/"music.ogg")
          var s=openFileStream(getAppDir()/"maps"/name/"chart.qv",fmWrite)
          var c:Chart
          c.events.add Event(t1:0,t2:0,bpm:120,speed:1,jump:0,xsEasing:1,xs1:0,xs2:0)
          c.writeChart(s)
          s.close()
          while not fileExists(getAppDir()/"maps"/name/"chart.qv"):
            sleep(200)
          dest=2
          chartPath=name
      else:
        discard
    else:
      discard
  else:
    discard
proc render()=
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)
  bg.render(1):
    discard
  let sl=songList.addr
  for i in 0..<sl[].len:
    let
      color:(uint8,uint8,uint8,uint8)=
        if i==chosen:(
          if autoPlay:(255,0,0,255) else:(0,255,255,255))
        else:(255,255,255,255)
    sl[][i][2].drawRect(-0.95,0.85-0.16*(i-chosen).float32,sl[][i][1].width/16*0.04*2,0.04*2,0,0.5)
    sl[][i][1].render(-0.95,0.85-0.16*(i-chosen).float32,color=color)
  renderMessages()
      
  
proc songs*():State=
  discard window.setKeyCallback(keyProc)
  discard window.setScrollCallback(nil)
  discard window.setCursorPosCallback(nil)
  discard window.setMouseButtonCallback(nil)
  songList.setLen(0)
  chosen=0
  dest=0
  for kind,song in walkDir(getAppDir()/"maps",relative=true):
    case kind
    of pcDir,pcLinkToDir:
      var
        ti:TextInstance
        ri:Rect
      initTextInstance(ti,song)
      initRect(ri,[(0'u8,0'u8,0'u8,128'u8),(0'u8,0'u8,0'u8,128'u8),(0'u8,0'u8,0'u8,128'u8),(0'u8,0'u8,0'u8,128'u8)])
      songList.add (song,ti,ri)
    else:
      discard
  defer:
    for _,ti,ri in songList.mitems():
      destroyTextInstance(ti)
      destroyRenderInstance(ri)
  initRenderInstance(bg,[0'u32,1,2,2,3,0],[(@[(rFloat,2,0)],2*sizeof(float32))],textures["songsbg"].glTex,bgShader,[])
  defer:destroyRenderInstance(bg)
  var
    verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
  bg.updateBuffer(0,8*sizeof(float32),verts[0].addr)

  var outro=false
  while not window.windowShouldClose():
    if not outro:
      loadOutro(render)
      outro=true
    else:
      render()
      window.swapBuffers()
      glfwWaitEvents()
    if dest!=0:
      break
  if window.windowShouldClose():quit(QuitSuccess)
  loadIntro(render)
  case dest
  of 1:
    return sGamePlay
  of 2:
    return sGameEdit
  else:
    discard