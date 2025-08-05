import nimgl/opengl
import stb_image/read as stbi
type
  Tex* = object
    glTex*:GLuint
    w*,h*,c*:int
template withTex*(tex:var Tex,body:untyped)=
  block:
    glBindTexture(GL_TEXTURE_2D,tex.glTex)
    defer:
      glBindTexture(GL_TEXTURE_2D,0)
    body
proc initTexture*(tex:var Tex,file:string)=
  var buf=load(file,tex.w,tex.h,tex.c,4)
  glGenTextures(1,tex.glTex.addr)
  glBindTexture(GL_TEXTURE_2D,tex.glTex)
  defer:
    glBindTexture(GL_TEXTURE_2D,0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR.GLint)
  glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA.GLint,tex.w.GLsizei,tex.h.GLsizei,0,GL_RGBA,GL_UNSIGNED_BYTE,buf[0].addr)
proc destroyTexture*(tex:var Tex)=
  glDeleteTextures(1,tex.glTex.addr)