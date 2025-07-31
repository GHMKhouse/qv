import nimgl/opengl
# import std/monotimes
import globals,types,unirender
proc dealAutoPlay*()=
  while judgedNotes < chart.notes.len and chart.notes[
      judgedNotes].t1-igt < 0.004:
    inc combo
    maxCombo = max(maxCombo, combo)
    inc xExact
    acc = (acc*judgedNotes.float+1)/(judgedNotes+1).float
    inc judged
    if chart.notes[judgedNotes].t2==chart.notes[judgedNotes].t1:
      chart.notes[judgedNotes].judged=1
    else:
      chart.notes[judgedNotes].judged=2
      postJudges.add judgedNotes
    particles[particleIndex]=Particle(
      time:igt,x:chart.notes[judgedNotes].x1,
      width:chart.notes[judgedNotes].width.float32/255,
      r:255,g:255,b:255
    )
    particleIndex = (particleIndex+1) and 0xff
    inc judgedNotes
    withBuffer chart.ri,2:
      var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
          judgedNotes-1)*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
      copyMem(ptrNote, chart.notes[judgedNotes-1].addr, sizeof(Note))
      discard glUnmapBuffer(GL_ARRAY_BUFFER)
  while postJudged<postJudges.len and chart.notes[postJudges[postJudged]].t2-igt<0.004:
    inc combo
    maxCombo = max(maxCombo, combo)
    inc xExact
    acc = (acc*judgedNotes.float+1)/(judgedNotes+1).float
    inc judged
    chart.notes[postJudges[postJudged]].judged=1
    particles[particleIndex]=Particle(
      time:igt,x:chart.notes[postJudges[postJudged]].x2,
      width:chart.notes[postJudges[postJudged]].width.float32/255,
      r:255,g:255,b:255
    )
    particleIndex = (particleIndex+1) and 0xff
    withBuffer chart.ri,2:
      var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
          postJudges[postJudged])*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
      copyMem(ptrNote, chart.notes[postJudges[postJudged]].addr, sizeof(Note))
      discard glUnmapBuffer(GL_ARRAY_BUFFER)
    inc postJudged

let
  colors:array[4,(uint8,uint8,uint8)]=[(0,255,255),(0,144,144),(0,255,0),(255,255,0)]
  accs:array[4,float32]=[1,1,0.75,0.5]
proc dealKey*()=
  # time = getMonoTime().ticks()
  # igt = (time-startTime)/1_000_000_000-chart.offset
  while jCatches<catches.len:
    let
      note=chart.notes[catches[jCatches]].addr
      dt=abs(igt-note.t1)
      judgement=int(dt/judgeFactor/0.016)
    if judgement<2:
      lastCaught=max(lastCaught,note.t1)
      acc = (acc*judgedNotes.float+1)/(judgedNotes+1).float
      inc judged
      if note.t2==note.t1:
        note.judged=1
      else:
        note.judged=2
        postJudges.add catches[jCatches]
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            catches[jCatches])*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, note, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
      inc jCatches
      recentlyCaught=true
    else:break
  if jNotes<notes.len:
    let
      note=chart.notes[notes[jNotes]].addr
      dt=abs(igt-note.t1)
      judgement=int(dt/judgeFactor/0.016) # 0:xExact 1:exact 2:fine 3:good
    # echo igt
    # echo note.t1
    # echo lastCaught
    # echo (igt-note.t1)/judgeFactor/0.016
    # echo judgement
    if judgement<4 and not ((lastCaught<note.t1) and (lastCaught-note.t1 >= -0.064*judgeFactor) and ((igt-note.t1)/judgeFactor/0.016 < -1)):
      let 
        (r,g,b)=colors[judgement]
      if judgement<3:
        inc combo
        maxCombo = max(maxCombo, combo)
      case judgement
      of 0:inc xExact
      of 1:inc exact
      of 2:inc fine
      of 3:inc good
      else:discard
      acc = (acc*judged.float+accs[judgement])/(judged+1).float
      inc judged
      if note.t2==note.t1:
        note.judged=1
      else:
        note.judged=2
        postJudges.add notes[jNotes]
      particles[particleIndex]=Particle(
        time:igt,x:note.x1,
        width:note.width.float32/255,
        r:r,g:g,b:b
      )
      particleIndex = (particleIndex+1) and 0xff
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            notes[jNotes])*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, note, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
      inc jNotes
proc dealUpdate*()=
  while judgedNotes < chart.notes.len and igt-chart.notes[judgedNotes].t2 > 0.064*judgeFactor:
    case chart.notes[judgedNotes].judged
    of 1,2:
      inc judgedNotes
      continue
    of 0:
      combo = 0
      inc lost
      acc = acc*(judged/(judged+1))
      inc judged
      chart.notes[judgedNotes].judged = 1
      case chart.notes[judgedNotes].kind
      of 0:inc jNotes
      of 1:inc jCatches
      else:discard
      inc judgedNotes
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            judgedNotes-1)*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, chart.notes[judgedNotes-1].addr, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
    else:discard
  var catchingNotes=judgedNotes
  while catchingNotes < chart.notes.len and igt>chart.notes[catchingNotes].t1:
    if chart.notes[catchingNotes].kind!=0 and chart.notes[catchingNotes].judged==0 and keyn>0:
      if chart.notes[catchingNotes].t1!=chart.notes[catchingNotes].t2:
        postJudges.add catchingNotes
      chart.notes[catchingNotes].judged = 2
      acc = (acc*judged.float+1)/(judged+1).float
      inc judged
      lastCaught=max(lastCaught,chart.notes[catchingNotes].t1)
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            catchingNotes)*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, chart.notes[catchingNotes].addr, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
      particles[particleIndex]=Particle(
        time:igt,x:chart.notes[catchingNotes].x1,
        width:chart.notes[catchingNotes].width.float32/255,
        r:0,g:255,b:255
      )
      particleIndex = (particleIndex+1) and 0xff
    inc catchingNotes
  var pJudged=postJudged
  while pJudged<postJudges.len and chart.notes[postJudges[pJudged]].t2-igt < 0.0*judgeFactor:
    if keyn>0:
      inc combo
      maxCombo = max(maxCombo, combo)
      inc xExact
      acc = (acc*judged.float+1)/(judged+1).float
      inc judged
      chart.notes[postJudges[pJudged]].judged=1
      particles[particleIndex]=Particle(
        time:igt,x:chart.notes[postJudges[pJudged]].x2,
        width:chart.notes[postJudges[pJudged]].width.float32/255,
        r:0,g:255,b:255
      )
      particleIndex = (particleIndex+1) and 0xff
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            postJudges[pJudged])*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, chart.notes[postJudges[pJudged]].addr, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
      inc postJudged
    inc pJudged
  while postJudged<postJudges.len and chart.notes[postJudges[postJudged]].t2-igt < -0.064*judgeFactor:
    if keyn<=0 and chart.notes[postJudges[postJudged]].judged==2:
      combo = 0
      inc lost
      acc = acc*(judged/(judged+1))
      inc judged
      chart.notes[postJudges[postJudged]].judged = 1
      withBuffer chart.ri,2:
        var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER, (
            postJudges[postJudged])*sizeof(Note), sizeof(Note), GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
        copyMem(ptrNote, chart.notes[postJudges[postJudged]].addr, sizeof(Note))
        discard glUnmapBuffer(GL_ARRAY_BUFFER)
    inc postJudged