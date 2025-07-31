import nimgl/[opengl]
import std/[unicode]
import glm
import binfont, shaders
type
  TextInstance* = object
    vao, vbo, ebo, ibo: GLuint
    length*,cap*: int
    width*:int
  Align* = enum
    alignLeft,alignRight,alignMiddle
var
  widthes*: seq[byte]
  data: seq[byte]
  texbuf: Gluint
  texture: Gluint
  uMVP, uPos, uSize, uColor: GLint
proc initFont*() =
  (widthes,data)=readBinFont()
  # echo widthes["A".runeAt(0).int]
  # for i in 0..255:
  #   let c=data["A".runeAt(0).int*256+i]
  #   stdout.write if c>0:'#' else:'.'
  #   if (i and 15)==15:
  #     stdout.write '\n'
  glGenBuffers(1, texbuf.addr)
  glBindBuffer(GL_TEXTURE_BUFFER, texbuf)
  glBufferData(GL_TEXTURE_BUFFER,256*65536,data[0].addr,GL_STATIC_DRAW)
  glGenTextures(1,texture.addr)
  glBindTexture(GL_TEXTURE_BUFFER,texture)
  glTexBuffer(GL_TEXTURE_BUFFER,GL_R8UI,texbuf)
  uMVP = glGetUniformLocation(textShader, "uMVP")
  uPos = glGetUniformLocation(textShader, "uPos")
  uSize = glGetUniformLocation(textShader, "uSize")
  uColor = glGetUniformLocation(textShader, "uColor")
proc quitFont*() =
  glDeleteTextures(1, texture.addr)
proc initTextInstance*(ti: var TextInstance, str: string) =
  var
    text:seq[byte]
    offset:uint16=0
  for r in str.toRunes():
    let c=r.uint16
    text.add byte(c and 255)
    text.add byte(c shr 8)
    text.add byte(offset and 255)
    text.add byte(offset shr 8)
    offset+=widthes[c]
  # echo text,offset
  ti.length=(text.len) shr 2
  ti.width=offset.int
  glGenVertexArrays(1, ti.vao.addr)
  glBindVertexArray(ti.vao)
  glGenBuffers(3, ti.vbo.addr)
  var
    verts: array[16, GLfloat] = [-1, -1, 0, 0, -1, 1, 0, 1, 1, 1, 1, 1, 1, -1, 1, 0]
    inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ti.ebo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(inds), inds[0].addr, GL_STATIC_DRAW)
  glBindBuffer(GL_ARRAY_BUFFER, ti.vbo)
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts[0].addr, GL_STATIC_DRAW)
  glVertexAttribPointer(0, 4, EGL_FLOAT, false, 4*sizeof(GLfloat), nil)
  glEnableVertexAttribArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, ti.ibo)
  if text.len>0:
    glBufferData(GL_ARRAY_BUFFER, len(text), text[0].addr, GL_STATIC_DRAW)
  else:
    glBufferData(GL_ARRAY_BUFFER, len(text), nil, GL_STATIC_DRAW)
  glVertexAttribIPointer(1, 2, GL_UNSIGNED_SHORT, 4, nil)
  glEnableVertexAttribArray(1)
  glVertexAttribDivisor(1, 1)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindVertexArray(0)
proc destroyTextInstance*(ti: var TextInstance) =
  glDeleteBuffers(3, ti.vbo.addr)
  glDeleteVertexArrays(1, ti.vao.addr)
proc update*(ti:var TextInstance, str:string) =
  glBindBuffer(GL_ARRAY_BUFFER, ti.ibo)
  defer:glBindBuffer(GL_ARRAY_BUFFER,0)
  var
    text:seq[byte]
    offset:uint16=0
  for r in str.toRunes():
    let c=r.uint16
    text.add byte(c and 255)
    text.add byte(c shr 8)
    text.add byte(offset and 255)
    text.add byte(offset shr 8)
    offset+=widthes[c]
  ti.length=(text.len) shr 2
  ti.width=offset.int
  if text.len>ti.cap:
    glBufferData(GL_ARRAY_BUFFER, text.len, text[0].addr, GL_STATIC_DRAW)
    ti.cap=text.len
  elif text.len==0:
    discard
  else:
    glBufferSubData(GL_ARRAY_BUFFER, 0, text.len, text[0].addr)
proc render*(ti: var TextInstance, x, y: float32,align:Align=alignLeft, size: float32 = 0.04,color:(uint8,uint8,uint8,uint8)=(255,255,255,255)) =
  glBindTexture(GL_TEXTURE_BUFFER, texture)
  glUseProgram(textShader)
  var
    mvp = ortho[GLfloat](-1, 1, -1, 1, -1, 1)
  let
    (r,g,b,a)=color
  glUniformMatrix4fv(uMVP, 1, false, mvp.caddr)
  let
    offset:float32=case align
      of alignLeft:0
      of alignRight:ti.width.float32*size/8
      of alignMiddle:ti.width.float32*size/16
  glUniform2f(uPos, x-offset, y)
  glUniform1f(uSize, size)
  glUniform4f(uColor,r.float32/255,g.float32/255,b.float32/255,a.float32/255)
  glBindVertexArray(ti.vao)
  glDrawElementsInstanced(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil,
      ti.length.Glsizei)
