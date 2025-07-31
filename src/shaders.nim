import nimgl/[opengl]


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
proc initShaders*() =
  initShaderSrc(noteShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in int aHoT; // head or tail
layout (location = 2) in vec4 aTnF; // time and floor
layout (location = 3) in vec2 aPosX;
layout (location = 4) in uvec4 aMisc1;
layout (location = 5) in uvec2 aMisc2;

uniform mat4 uMVP;
uniform float uSpeed;
uniform float uFloor;
uniform float uLinePos;
uniform float uXSF;
out vec4 Color;

void main(){
  if(aMisc2.y==uint(1) || (aTnF[2]-uFloor)*uSpeed>10){ // judged note should'nt be drawn
    gl_Position=vec4(0,114,0,1);
  }
  else{
    float y=(aTnF[2+aHoT]-uFloor)*uSpeed+(aTnF.x==aTnF.y?float(aHoT)*0.1:0);
    gl_Position = uMVP*vec4(
      ((aPos.x*(float(aMisc1.x)/255)
      +aPosX[aHoT])-0.5)*pow(2,1-y*uXSF),
      y+uLinePos,
      0,1+y);
  }
  Color = vec4(
    float(aMisc1.y)/255,
    float(aMisc1.z)/255,
    float(aMisc1.w)/255,
    (aMisc2.x==uint(0) || aMisc2.y==uint(2))?1:0.5
    );
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
out vec4 FragColor;
in vec4 Color;
void main(){
  FragColor=Color;
}
""")])

  initShaderSrc(lineShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec2 aPos;

uniform mat4 uMVP;
uniform float uLinePos;

void main(){
  gl_Position=uMVP*vec4(
    aPos.x,
    aPos.y*0.01+uLinePos,
    0,1);
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
out vec4 FragColor;
void main(){
  FragColor=vec4(1,1,1,1);
}
""")])
  initShaderSrc(textShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec4 aPos;
layout (location = 1) in uvec2 aCnO;

uniform mat4 uMVP;
uniform vec2 uPos;
uniform float uSize;
uniform vec4 uColor;
out vec2 TexCoord;
out vec4 Color;
flat out uint chr;

void main(){
  gl_Position=uMVP*vec4(
    uPos.x+aCnO.y*2u*uSize/16+uSize*aPos.z*2u,
    aPos.y*uSize+uPos.y,0,1);
  TexCoord=vec2(aPos.z,1-aPos.w);
  chr=aCnO.x;
  Color=uColor;
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
in vec2 TexCoord;
in vec4 Color;
flat in uint chr;
uniform usamplerBuffer texture1;
out vec4 FragColor;
void main(){
  FragColor=Color*float(texelFetch(texture1, int(chr)*256+int(TexCoord.y*15)*16+int(TexCoord.x*15)).r)/255;
}
""")])
  initShaderSrc(particleShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aTXW;
layout (location = 2) in ivec3 aColor;

uniform mat4 uMVP;
uniform float uLinePos;
uniform float uTime;
out vec3 Color;
out float Fading;

void main(){
  Fading=uTime-aTXW.x;
  if(Fading<1){
    gl_Position=uMVP*vec4(
      (aPos.x*(aTXW.z)
        +aTXW.y-0.5)*2,
      aPos.y*0.01+uLinePos+Fading,0,1+Fading);
  }else{
    gl_Position=vec4(114514);
  }
  Color=vec3(aColor)/255;
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
in vec3 Color;
in float Fading;
out vec4 FragColor;
void main(){
  FragColor=vec4(Color,1-Fading);
}
""")])
  initShaderSrc(maskShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec2 aPos;

uniform float uProgress;

void main(){
  gl_Position=vec4(
    aPos.x,
    aPos.y==1?1:1-2*uProgress,
    0,1);
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
out vec4 FragColor;
void main(){
  FragColor=vec4(1,1,1,1);
}
""")])
  initShaderSrc(bgShader, [(GL_VERTEX_SHADER,
      """
#version 330 core
layout (location = 0) in vec2 aPos;
out vec2 TexCoord;

void main(){
  gl_Position=vec4(
    aPos.x,
    aPos.y,
    0,1);
  TexCoord=(aPos+1)/2;
}

"""), (GL_FRAGMENT_SHADER,
      """
#version 330 core
out vec4 FragColor;
in vec2 TexCoord;
uniform sampler2D texture1;
void main(){
  FragColor=texture(texture1, TexCoord);
}
""")])
proc quitShaders*() =
  glDeleteProgram(noteShader)
  glDeleteProgram(lineShader)
  glDeleteProgram(textShader)
  glDeleteProgram(particleShader)
  glDeleteProgram(maskShader)
  glDeleteProgram(bgShader)