import nimgl/[opengl]
import std/[tables]
type
  RType* = enum
    rFloat,rNFloat,rDouble,rInt,rUInt,rShort,rUShort,rByte,rUByte
  Rule* = (seq[(RType,int,int)],int)
  RenderInstance* = object
    vao*,ebo*:GLuint
    elements*:GLsizei
    vbos*:seq[(GLuint,int,Rule)]
    texture*:GLuint
    shader*:GLuint
    uniforms*:Table[string,GLint]
type
  Note* = object
    t1*, t2*: GLfloat
    f1*, f2*: GLfloat
    x1*, x2*: GLfloat
    width*: GLubyte
    r*, g*, b*: GLubyte
    kind*: GLubyte   # 0:note 1:catch
    judged*: GLubyte # 0:unjudged 1:judged(so don't show) 2:judging
  Event* = object
    t1*, t2*: float32              # in seconds! t2 used for x-scaling
    bpm*: float32
    speed*: float32
    jump*: float32                 # happens at t1
    xsEasing*, xs1*, xs2*: float32 # x-scale effect
  Chart* = object
    events*: seq[Event]
    notes*: seq[Note]
    offset*: float32
    title*, level*, composer*, charter*, illustrator*: string
    ri*:RenderInstance
  Particle* = object
    time*: float32 = -Inf.float32
    x*,width*: float32
    r*, g*, b*: GLubyte
