import types,unirender,shaders,globals,tricks,readcht
import nimgl/[opengl]
template `^`(x: int): pointer = cast[pointer](x)
proc initChart*(chart: var Chart,j:bool=true) =
  if j:
    numOfNotes=0
    for i,n in chart.notes:
      if n.t1!=n.t2:
        numOfNotes+=2
      else:
        inc numOfNotes
      case n.kind
      of 0:notes.add i
      of 1:catches.add i
      else:discard
  var
    verts: array[8, GLfloat] = [-1, -1, -1, 1, 1, 1, 1, -1]
    inds: array[6, Gluint] = [0, 1, 2, 2, 3, 0]
    data: array[4, byte] = [0, 1, 1, 0]
  initRenderInstance(chart.ri,inds,[
    (@[(rFloat,2,0)],2*sizeof(GLfloat)),
    (@[(rUByte,1,0)],1),
    (@[(rFloat,4,1),(rFloat,2,1),(rUByte,4,1),(rUByte,3,1)],sizeof(Note)),
    ],0,noteShader,["uMVP","uXSF","uSpeed","uFloor","uLinePos","uPersF"])
  chart.ri.updateBuffer(0,8*sizeof(GLfloat),verts[0].addr)
  chart.ri.updateBuffer(1,4,data[0].addr)
  if chart.notes.len>0:
    chart.ri.updateBuffer(2,len(chart.notes)*sizeof(Note),chart.notes[0].addr)
proc updateNotes*(chart: var Chart)=
  for n in chart.notes.mitems():
    n.f1=convertFloor(n.t1,chart.events)
    n.f2=convertFloor(n.t2,chart.events)
  chart.ri.updateBuffer(2,len(chart.notes)*sizeof(Note),chart.notes[0].addr)
proc updateChart*(chart: var Chart)=
  chart.ri.updateBuffer(2,len(chart.notes)*sizeof(Note),chart.notes[0].addr)
proc addNote*(chart:var Chart,note:Note):int {.discardable.}=
  if chart.notes.len==0:
    result=0
  else:
    result=(chart.notes.seek(proc (x:Note):bool=x.t1>note.t1)+len(chart.notes)) mod len(chart.notes)
  chart.notes.insert(note,result)
  if chart.notes[result].t1==chart.notes[result].t2:
    chart.notes[result].x2=chart.notes[result].x1