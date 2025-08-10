import nimgl/[glfw]
import types
var window*: GLFWWindow
type
  State* = enum
    sTitle, sMainMenu, sSongs, sOptions, sLoading, sGamePlay, sGameEdit, sResults, sEndGame
var compatibilityMode*:bool
var
  scrnW* = 1200
  scrnH* = 900
  state* = sSongs
  chartPath*: string
  chart*: Chart
  numOfNotes*: int
  autoPlay*: bool = false
  speed*: float32 = 5
  recentlyCaught*: bool
  lastCaught*: float32
  lastCaughts*:array[256,float32]
  lastCaughtI*:int
  notes*, catches*: seq[int]
  jNotes*, jCatches*: int
  postJudges*: seq[int]
  postJudged*: int
  keyn*: int = 0
  judgeFactor*: float = 2
  judged*: int = 0
  judgedNotes*, combo*, maxCombo*, xExact*, exact*, fine*, good*, lost*: int = 0
  lastNote*: int = 0
  acc*: float = 1.0
  score*: int = 0
  particles*: ptr array[256, Particle]
  particleIndex*: int
  lastTime*, startTime*, time*: int64
  igt*: float32
