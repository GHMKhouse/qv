import nimgl/[glfw, opengl]
import std/[strutils,os]
import shaders, globals, gameplay,songs,results, audio, font,load,res,gameedit

proc parseOpenGLVersion(versionStr: string): (int, int) =
  let versionPart = 
    if versionStr.startsWith("OpenGL ES"):
      versionStr.split(' ')[2]
    else:
      versionStr.split(' ')[0]
  
  let parts = versionPart.split('.')
  if parts.len < 2:
    raise newException(ValueError, "Invalid OpenGL version format: " & versionStr)
  
  let major = parts[0].parseInt()
  let minor = parts[1].parseInt()
  
  return (major, minor)
proc main(): int =
  # GLFW
  doAssert glfwInit():
    var err: cstringArray
    discard glfwGetError(err)
    $err.cstringArrayToSeq().join("\n")
  defer:
    glfwTerminate()
  glfwWindowHint(GLFWVisible,GLFWFalse)
  var tmpWin=glfwCreateWindow(800,600,"",icon=false)
  doAssert not tmpWin.isNil(), "failed to create window"
  tmpWin.makeContextCurrent()
  doAssert glInit(), "failed to init openGL"
  compatibilityMode=block:
    var c=glGetString(GL_VERSION)
    var s = $(cast[cstring](c))
    let (a,b)=parseOpenGLVersion(s)
    a<4 or (a==4 and b<2)
  tmpWin.destroyWindow()
  if compatibilityMode:
    stderr.write "You are in compatibilityMode! Notice that performance may be degraded.\n"
  if compatibilityMode:
    glfwWindowHint(GLFWContextVersionMajor, 3)
    glfwWindowHint(GLFWContextVersionMinor, 3)
  else:
    glfwWindowHint(GLFWContextVersionMajor, 4)
    glfwWindowHint(GLFWContextVersionMinor, 2)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFWTrue)
  glfwWindowHint(GLFWOpenglProfile, GLFWOpenglCoreProfile)
  glfwWindowHint(GLFWVisible,GLFWTrue)
  glfwWindowHint(GLFWResizable, GLFWFalse)
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
    of sGameEdit:
      state = gameedit()
    of sEndGame:
      break
    else:
      discard
  return QuitSuccess

when isMainModule:
  setCurrentDir(getAppDir())
  quit(main())
