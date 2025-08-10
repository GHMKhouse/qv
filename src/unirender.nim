import nimgl/opengl
import std/[macros,tables]
import types
{.experimental:"dotOperators".}
macro `.`*(ri:RenderInstance,name:untyped):GLint=
  name.expectKind nnkIdent
  let s=newLit(name.strVal)
  quote do:
    `ri`.shader.glGetUniformLocation(`s`)
proc destroyRenderInstance*(ri:RenderInstance)=
  var vbos:seq[GLuint]
  for vbo,_,_ in ri.vbos.items:
    vbos.add vbo
  glDeleteBuffers(ri.vbos.len.GLsizei,vbos[0].addr)
  glDeleteBuffers(1,ri.ebo.addr)
  glDeleteVertexArrays(1,ri.vao.addr)
let
  sizes:array[RType,GLint]=[4,4,8,4,4,2,2,1,1]
  typs:array[RType,GLenum]=[EGL_FLOAT,EGL_FLOAT,EGL_DOUBLE,EGL_INT,GL_UNSIGNED_INT,EGL_SHORT,GL_UNSIGNED_SHORT,EGL_BYTE,GL_UNSIGNED_BYTE]
proc initRenderInstance*(ri:var RenderInstance,idx:openArray[uint32],rules:openArray[Rule],texture,shader:GLuint,uniforms:openArray[string])=
  glGenVertexArrays(1,ri.vao.addr)
  glGenBuffers(1,ri.ebo.addr)
  glBindVertexArray(ri.vao)
  defer:glBindVertexArray(0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,ri.ebo)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER,len(idx)*sizeof(uint32),idx[0].addr,GL_STATIC_DRAW)
  ri.elements=idx.len.GLsizei
  ri.vbos = newSeq[(GLuint,int,Rule)](len(rules))
  var vbos = newSeq[GLuint](len(rules))
  glGenBuffers(len(rules).GLsizei,vbos[0].addr)
  var idx:GLuint=0
  for i,rule in rules.pairs():
    ri.vbos[i]=(vbos[i],0,rule)
    glBindBuffer(GL_ARRAY_BUFFER,vbos[i])
    var
      offset=0
    for typ,num,dvs in rule[0].items():
      # echo idx," ", num, " ",typ, " ", rule[1], " ", offset
      if typ==rFloat: 
        glVertexAttribPointer(idx,num.GLsizei,typs[typ],false,rule[1].GLsizei,cast[pointer](offset))
      elif typ==rNFloat: 
        glVertexAttribPointer(idx,num.GLsizei,typs[typ],true,rule[1].GLsizei,cast[pointer](offset))
      elif typ==rDouble:
        glVertexAttribLPointer(idx,num.GLsizei,typs[typ],rule[1].GLsizei,cast[pointer](offset))
      else:
        glVertexAttribIPointer(idx,num.GLsizei,typs[typ],rule[1].GLsizei,cast[pointer](offset))
      
      glVertexAttribDivisor(idx,dvs.GLuint)
      glEnableVertexAttribArray(idx)
      offset+=sizes[typ]*num.GLsizei
      inc idx
    
  glBindBuffer(GL_ARRAY_BUFFER,0)
  ri.texture=texture
  ri.shader=shader
  for u in uniforms:
    ri.uniforms[u]=glGetUniformLocation(shader,u.cstring)
proc initBuffer*(ri:var RenderInstance,idx,size:int,flags:GLbitfield)=
  glBindBuffer(GL_ARRAY_BUFFER,ri.vbos[idx][0])
  defer:
    glBindBuffer(GL_ARRAY_BUFFER,0)
  glBufferStorage(GL_ARRAY_BUFFER,size.GLsizeiptr,nil,flags)
proc updateBuffer*(ri:var RenderInstance,idx,size:int,data:pointer)=
  glBindBuffer(GL_ARRAY_BUFFER,ri.vbos[idx][0])
  defer:
    glBindBuffer(GL_ARRAY_BUFFER,0)
  if size>ri.vbos[idx][1]:
    glBufferData(GL_ARRAY_BUFFER,size.GLsizeiptr,data,GL_DYNAMIC_DRAW)
    ri.vbos[idx][1]=size
  else:
    glBufferSubData(GL_ARRAY_BUFFER,0,size.GLsizeiptr,data)
template withBuffer*(ri:var RenderInstance,idx:int,body:untyped)=
  block:
    glBindBuffer(GL_ARRAY_BUFFER,ri.vbos[idx][0])
    defer:
      glBindBuffer(GL_ARRAY_BUFFER,0)
    body
template render*(ri:var RenderInstance,instanceCount:int=1,assignments:untyped)=
  block:
    glBindTexture(GL_TEXTURE2D,ri.texture)
    defer:glBindTexture(GL_TEXTURE2D,0)
    glUseProgram(ri.shader)
    defer:
      glUseProgram(0)
    assignments
    glBindVertexArray(ri.vao)
    defer:
      glBindVertexArray(0)
    glDrawElementsInstanced(GL_TRIANGLES,ri.elements,GL_UNSIGNED_INT,nil,instanceCount.GLsizei)