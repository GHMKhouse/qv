import nimgl/[opengl,glfw]
import std/[os]
import globals,font,load

var
  songList:seq[(string,TextInstance)]
  chosen:int
  dest=0
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
    of GLFWKey.GraveAccent: # `
      autoPlay = not autoPlay
    else:
      discard
  of GLFWRelease:
    case key
    of GLFWKey.Escape:
      quit(QuitSuccess)
    else:
      discard
  else:
    discard
proc songs*():State=
  discard window.setKeyCallback(keyProc)
  songList.setLen(0)
  chosen=0
  dest=0
  for kind,song in walkDir("maps",relative=true):
    case kind
    of pcDir,pcLinkToDir:
      var ti:TextInstance
      initTextInstance(ti,song)
      songList.add (song,ti)
    else:
      discard
  defer:
    for _,ti in songList.mitems():
      destroyTextInstance(ti)
  var outro=false
  while not window.windowShouldClose():
    glClearColor(0, 0, 0, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    for i,(song,ti) in songList.mpairs():
      let
        color:(uint8,uint8,uint8,uint8)=
          if i==chosen:(
            if autoPlay:(255,0,0,255) else:(0,255,255,255))
          else:(255,255,255,255)
      ti.render(-0.95,0.85-0.16*i.float32,color=color)
    if not outro:
      loadOutro()
      outro=true
    else:
      window.swapBuffers()
      glfwPollEvents()
    if dest==1:
      break
  if window.windowShouldClose():quit(QuitSuccess)
  loadIntro()
  return sGamePlay