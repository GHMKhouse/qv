import nimgl/opengl
import globals, types, unirender, res, audio, tables
type
  JudgementKind* = enum jkXExact, jkExact, jkFine, jkGood, jkLost
  Judgement* = object
    noteId*: int
    t*, x*, w*: float32
    kind*: JudgementKind
let
  colors: array[JudgementKind, (uint8, uint8, uint8)] = [
    (0, 255, 255),
    (0, 144, 144),
    (0, 255, 0),
    (255, 255, 0),
    (0, 0, 0)]
  accs: array[JudgementKind, float32] = [1, 1, 0.75, 0.5, 0]
proc makeJudgement*(judgement: Judgement) =
  acc = (acc*judged.float32+accs[judgement.kind])/(judged+1).float32
  inc judged
  let
    note=chart.notes[judgement.noteId].addr
    (r, g, b) = colors[judgement.kind]
  if judgement.kind != jkLost:
    if note.kind==1:
      lastCaughts[lastCaughtI]=note.t1
      lastCaughtI=(lastCaughtI+1) and 0xff
    if note.judged!=2 and note.t2!=note.t1:
      note.judged=2
    else:
      note.judged=1
    particles[particleIndex] = Particle(
        time: judgement.t, x: judgement.x,
        width: judgement.w,
        r: r, g: g, b: b
      )
    particleIndex = (particleIndex+1) and 0xff
    inc combo
    maxCombo = max(maxCombo, combo)
    case judgement.kind
    of jkXExact: inc xExact
    of jkExact: inc exact
    of jkFine: inc fine
    of jkGood: inc good
    else: discard
    playSound(sounds["hitsnd"])
  else:
    combo = 0
    inc lost
    when defined(debug):
      particles[particleIndex] = Particle(
        time: judgement.t, x: judgement.x,
        width: judgement.w,
        r: 255, g: 0, b: 0
      )
      particleIndex = (particleIndex+1) and 0xff
  withBuffer chart.ri, 2:
    var ptrNote = glMapBufferRange(GL_ARRAY_BUFFER,
      (judgement.noteId)*sizeof(Note), sizeof(Note),
      GL_MAP_WRITE_BIT or GL_MAP_INVALIDATE_RANGE_BIT)
    copyMem(ptrNote, chart.notes[judgement.noteId].addr,
      sizeof(Note))
    discard glUnmapBuffer(GL_ARRAY_BUFFER)
proc dealAutoPlay*() =
  while judgedNotes < chart.notes.len and
      chart.notes[judgedNotes].t1-igt < 0.004:
    let
      note = chart.notes[judgedNotes]
    makeJudgement(Judgement(noteId: judgedNotes, t: igt, x: note.x1,
        w: note.width.float32/255, kind: jkXExact))
    if note.t1==note.t2:
      lastNote=max(lastNote,judgedNotes-32)
    else:
      postJudges.add judgedNotes
    inc judgedNotes
  while postJudged<postJudges.len and
      chart.notes[postJudges[postJudged]].t2-igt<0.004:
    let
      note = chart.notes[postJudges[postJudged]]
    lastNote=max(lastNote,postJudges[postJudged]-32)
    makeJudgement(Judgement(noteId: postJudges[postJudged], t: igt, x: note.x1,
        w: note.width.float32/255, kind: jkXExact))
    inc postJudged
proc dt2Judgement*(dt:float32):int=
  int(abs(dt)/0.016/judgeFactor)
proc dealKey*()=
  while jNotes < notes.len and chart.notes[notes[jNotes]].t1<igt and dt2Judgement(igt-chart.notes[notes[jNotes]].t1)>=4:
    inc jNotes
  while jCatches < catches.len and dt2Judgement(igt-chart.notes[catches[jCatches]].t1)<4:
    if chart.notes[catches[jCatches]].kind!=0 and chart.notes[catches[jCatches]].judged==0:
      makeJudgement(Judgement(noteId: catches[jCatches], t: chart.notes[catches[jCatches]].t1, x: chart.notes[catches[jCatches]].x1,
        w: chart.notes[catches[jCatches]].width.float32/255, kind: jkXExact))
      if chart.notes[catches[jCatches]].t1!=chart.notes[catches[jCatches]].t2:
        postJudges.add catches[jCatches]
    inc jCatches
  if jNotes==notes.len:
    return
  let
    note=chart.notes[notes[jNotes]]
    dt=note.t1-igt
    j=dt2Judgement(dt)
  var c=false
  for ct in lastCaughts:
    if ct<igt and dt2Judgement(ct-igt) in 1..4:
      c=true
  if j<4 and (dt<=0 or j in 0..1 or not c):
    makeJudgement(Judgement(noteId: notes[jNotes], t: igt, x: note.x1,
      w: note.width.float32/255, kind: JudgementKind(j)))
    if note.t1!=note.t2:
      postJudges.add notes[jNotes]
    inc jNotes
proc dealUpdate*()=
  while judgedNotes < chart.notes.len and dt2Judgement(igt-chart.notes[judgedNotes].t1)>=4 and igt>chart.notes[judgedNotes].t1:
    if chart.notes[judgedNotes].judged==0:
      makeJudgement(Judgement(noteId: judgedNotes, t: chart.notes[judgedNotes].t1, x: chart.notes[judgedNotes].x1,
        w: chart.notes[judgedNotes].width.float32/255, kind: jkLost))
      if chart.notes[judgedNotes].t1!=chart.notes[judgedNotes].t2:
        inc judged
    inc judgedNotes
  while jCatches < catches.len and dt2Judgement(igt-chart.notes[catches[jCatches]].t1)<4:
    if chart.notes[catches[jCatches]].judged==0 and keyn>0:
      makeJudgement(Judgement(noteId: catches[jCatches], t: chart.notes[catches[jCatches]].t1, x: chart.notes[catches[jCatches]].x1,
        w: chart.notes[catches[jCatches]].width.float32/255, kind: jkXExact))
      if chart.notes[catches[jCatches]].t1!=chart.notes[catches[jCatches]].t2:
        postJudges.add catches[jCatches]
    inc jCatches
  while postJudged<postJudges.len and dt2Judgement(igt-chart.notes[postJudges[postJudged]].t2)>=4 and igt>chart.notes[postJudges[postJudged]].t2:
    if keyn<=0:
      makeJudgement(Judgement(noteId: postJudges[postJudged], t: igt, x: chart.notes[postJudges[postJudged]].x2,
        w: chart.notes[postJudges[postJudged]].width.float32/255, kind: jkLost))
    else:
      makeJudgement(Judgement(noteId: postJudges[postJudged], t: igt, x: chart.notes[postJudges[postJudged]].x2,
        w: chart.notes[postJudges[postJudged]].width.float32/255, kind: jkXExact))
    inc postJudged
  while postJudged<postJudges.len and dt2Judgement(igt-chart.notes[postJudges[postJudged]].t2)<4:
    if keyn>0:
      makeJudgement(Judgement(noteId: postJudges[postJudged], t: igt, x: chart.notes[postJudges[postJudged]].x2,
        w: chart.notes[postJudges[postJudged]].width.float32/255, kind: jkXExact))
      inc postJudged
    else:
      break