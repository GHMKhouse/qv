import nimgl/[glfw, opengl]
import std/[strutils]
import shaders, globals, gameplay,songs,results, audio, font,load,res

proc main(): int =
  # GLFW
  doAssert glfwInit():
    var err: cstringArray
    discard glfwGetError(err)
    $err.cstringArrayToSeq().join("\n")
  defer:
    glfwTerminate()

  glfwWindowHint(GLFWContextVersionMajor, 4)
  glfwWindowHint(GLFWContextVersionMinor, 4)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)
  glfwWindowHint(GLFWRepeat, GLFWFalse)


  window = glfwCreateWindow(scrnW.int32, scrnH.int32, "QuartzViolet",icon=false)
  doAssert not window.isNil(), "failed to create window"
  defer: window.destroyWindow()
  # window.setWindowIcon(1,nil)

  window.makeContextCurrent()
  doAssert glInit(), "failed to init openGL"

  glClearColor(0, 0, 0, 1)
  glClear(GL_COLOR_BUFFER_BIT)
  window.swapBuffers()
  glfwPollEvents()
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  initAudio()
  defer: quitAudio()
  initShaders()
  defer: quitShaders()
  initFont()
  defer: quitFont()
  initRes()
  defer:quitRes()
  initLoads()
  defer:quitLoads()
  while state != sEndGame:
    case state
    of sGamePlay:
      state = gameplay()
    of sSongs:
      state = songs()
    of sResults:
      state = results()
    of sEndGame:
      break
    else:
      discard
  return QuitSuccess

when isMainModule:
  quit(main())
