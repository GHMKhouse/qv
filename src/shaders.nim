import nimgl/[opengl]
import macros

proc initShaderSrc(shader: var GLuint, sources: openArray[(GLenum, string)]) =
  shader = glCreateProgram()
  for (kind, src) in sources:
    var
      csrc = src.cstring
      shd = glCreateShader(kind)
    glShaderSource(shd, 1, csrc.addr, nil)
    glCompileShader(shd)
    glAttachShader(shader, shd)
    var status: int32
    glGetShaderiv(shd, GL_COMPILE_STATUS, status.addr);
    if status != GL_TRUE.ord:
      var
        log_length: int32
        message = newSeq[char](1024)
      glGetShaderInfoLog(shd, 1024, log_length.addr, cast[cstring](message[0].addr))
      echo cast[cstring](message[0].addr)
    glDeleteShader(shd)
  glLinkProgram(shader)
  var
    log_length: int32
    message = newSeq[char](1024)
    pLinked: int32
  glGetProgramiv(shader, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(shader, 1024, log_length.addr, cast[cstring](message[
        0].addr));
    echo cast[cstring](message[0].addr)
proc initShaderBin(shader: var GLuint, binaries: openArray[(GLenum, seq[byte])]) =
  # maybe used one day
  shader = glCreateProgram()
  for (kind, bin) in binaries:
    var
      shd = glCreateShader(kind)
    glShaderBinary(1, shd.addr, GL_SPIR_V_BINARY, bin[0].addr, bin.len.GLsizei)
    glSpecializeShader(shd, "main", 0, nil, nil)
    glCompileShader(shd)
    glAttachShader(shader, shd)
    var status: int32
    glGetShaderiv(shd, GL_COMPILE_STATUS, status.addr);
    if status != GL_TRUE.ord:
      var
        log_length: int32
        message = newSeq[char](1024)
      glGetShaderInfoLog(shd, 1024, log_length.addr, cast[cstring](message[0].addr))
      echo cast[cstring](message[0].addr)
    glDeleteShader(shd)
  glLinkProgram(shader)
  var
    log_length: int32
    message = newSeq[char](1024)
    pLinked: int32
  glGetProgramiv(shader, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(shader, 1024, log_length.addr, cast[cstring](message[0].addr))
    echo cast[cstring](message[0].addr)
var
  noteShader*: GLuint
  lineShader*: GLuint
  textShader*: GLuint
  particleShader*:GLuint
  maskShader*:GLuint
  bgShader*:GLuint
  rectShader*:GLuint
macro initShader(idn:untyped)=
  idn.expectKind nnkIdent
  var
    s=idn.strVal
    sl=newLit(s)
    sh=ident(s&"Shader")
  # bindSym(sh)
  quote do:
    block:
      var
        vf=open("shaders/"&`sl`&".vs")
      defer:vf.close()
      var
        ff=open("shaders/"&`sl`&".fs")
      defer:ff.close()
      initShaderSrc(`sh`,[(GL_VERTEX_SHADER,vf.readAll()),(GL_FRAGMENT_SHADER,ff.readAll())])
proc initShaders*() =
  initShader note
  initShader line
  initShader text
  initShader particle
  initShader mask
  initShader bg
  initShader rect
macro delShader(idn:untyped)=
  idn.expectKind nnkIdent
  var
    s=idn.strVal
    sh=ident(s&"Shader")
  quote do:
    glDeleteProgram(`sh`)
proc quitShaders*() =
  delShader note
  delShader line
  delShader text
  delShader particle
  delShader mask
  delShader bg
  delShader rect