import nimgl/[opengl,glfw]
import std/[strformat]
import globals,font,load
var dest=0
proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  case action
  of GLFWPress:
    case key
    of GLFWKey.Enter:
      dest=1
    of GLFWKey.Backspace:
      dest=2
    else:
      discard
  of GLFWRelease:
    case key
    of GLFWKey.Escape:
      dest=1
    else:
      discard
  else:
    discard

var
  scoreText:TextInstance
proc render()=
  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)
  scoreText.render(-0.8,0.8,alignLeft,0.16)

proc results*():State=
  discard window.setKeyCallback(keyProc)
  dest=0
  initTextInstance(scoreText, fmt"{score:07}")
  defer: destroyTextInstance(scoreText)
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
    return sSongs
  of 2:
    return sGamePlay
  else:
    return sEndGame