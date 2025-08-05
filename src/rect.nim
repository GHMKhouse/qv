import nimgl/[opengl]
import glm
# import std/[strutils,macros]
import unirender,shaders,types
var
  verts: array[8, GLfloat] = [0, 0, 0, 1, 1, 1, 1, 0]
  inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
  
proc initRect*(ri:var Rect,colors:array[4,(uint8,uint8,uint8,uint8)])=
  initRenderInstance(ri,inds,[(@[(rFloat,2,0)],2*sizeof(float32))],0,rectShader,["uColors","uPnS"])
  ri.updateBuffer(0,8*sizeof(float32),verts[0].addr)
  for x in 0..3:
    ri.colors[x,0]=colors[x][0].float32/255
    ri.colors[x,1]=colors[x][1].float32/255
    ri.colors[x,2]=colors[x][2].float32/255
    ri.colors[x,3]=colors[x][3].float32/255
proc drawRect*(ri:var Rect,x,y,w,h:float32,xAlign,yAlign:float32)=
  ri.render(1,0):
    glUniformMatrix4fv(ri.uColors,1,false,ri.colors.caddr)
    glUniform4f(ri.uPnS,x-xAlign*w,y-yAlign*h,w,h)