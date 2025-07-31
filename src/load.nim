import std/[monotimes,math]
import nimgl/[opengl,glfw]
import globals,unirender,types,shaders
const duration=1_000_000_000
var
  verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
  inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
  st,t:int64
  mask,bg:RenderInstance
  tex:GLuint
proc initLoads*()=
  initRenderInstance(mask,inds,[(@[(rFloat,2,0)],2*sizeof(float32))],0,maskShader,["uProgress"])
  mask.updateBuffer(0,8*sizeof(float32),verts[0].addr)
  initRenderInstance(bg,inds,[(@[(rFloat,2,0)],2*sizeof(float32))],tex,bgShader,[])
  bg.updateBuffer(0,8*sizeof(float32),verts[0].addr)
proc quitLoads*()=
  destroyRenderInstance(mask)
  destroyRenderInstance(bg)
proc loadIntro*()=
  st=getMonoTime().ticks()
  t=st
  glGenTextures(1, tex.addr)
  glBindTexture(GL_TEXTURE_2D, tex)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, scrnW.GLint, scrnH.GLint, 0)
  while t-st<duration and not window.windowShouldClose():
    let progress=log10(9*(t-st)/duration+1)
    bg.render(1):
      discard
    mask.render(1):
      glUniform1f(mask.uProgress,progress)
    window.swapBuffers()
    glfwPollEvents()
    t=getMonoTime().ticks()
  if window.windowShouldClose():quit(QuitSuccess)

proc loadOutro*()=
  st=getMonoTime().ticks()
  t=st
  glGenTextures(1, tex.addr)
  glBindTexture(GL_TEXTURE_2D, tex)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, scrnW.GLint, scrnH.GLint, 0)
  while t-st<duration and not window.windowShouldClose():
    let progress=1-log10(9*(t-st)/duration+1)
    bg.render(1):
      discard
    mask.render(1):
      glUniform1f(mask.uProgress,progress)
    window.swapBuffers()
    glfwPollEvents()
    t=getMonoTime().ticks()
  if window.windowShouldClose():quit(QuitSuccess)
