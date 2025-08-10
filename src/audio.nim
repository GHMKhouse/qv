
import std/[encodings,monotimes]
import sdl2
import sdl2/[audio,mixer]
import os

proc getOggDuration*(filename: string): float32 =
  ## 返回 OGG 文件的音频时长（秒）
  var f: File
  if not open(f, filename):
    raise newException(IOError, "无法打开文件: " & filename)

  # 1. 读取文件头和识别码
  var header: array[27, byte]
  if readBytes(f, header, 0, 27) != 27:
    raise newException(ValueError, "无效的 OGG 文件头")

  # 验证 OggS 标识
  if header[0..3] != ['O'.ord.uint8, 'g'.ord, 'g'.ord, 'S'.ord]:
    raise newException(ValueError, "不是有效的 OGG 文件")

  # 2. 解析第一个页面获取采样率
  let nSegments = header[26].ord
  var segments: seq[uint8] = newSeq[uint8](nSegments)
  if readBytes(f, segments, 0, nSegments) != nSegments:
    raise newException(ValueError, "无法读取段表")

  # 计算第一个数据包大小
  var firstPacketSize = 0
  for s in segments:
    firstPacketSize += s.int
    if s < 255: break  # 遇到小于255的段表示数据包结束

  # 读取第一个数据包 (Vorbis 识别头)
  var packet = newSeq[byte](firstPacketSize)
  if readBytes(f, packet, 0, firstPacketSize) != firstPacketSize:
    raise newException(ValueError, "无法读取识别头")

  # 验证 Vorbis 标识 (0x01 + "vorbis")
  if packet[0] != 0x01 or packet[1..6] != ['v'.ord.uint8, 'o'.ord, 'r'.ord, 'b'.ord, 'i'.ord, 's'.ord]:
    raise newException(ValueError, "不是 Vorbis 音频流")

  # 提取采样率 (小端32位整数)
  let sampleRate = cast[ptr uint32](packet[12].unsafeAddr)[]

  # 3. 定位到最后一个页面获取总采样数
  let fileSize = getFileSize(filename)
  const searchWindow = 65536  # 64KB 搜索窗口
  let startPos = max(0, fileSize - searchWindow)

  f.setFilePos(startPos)
  var buffer = newSeq[uint8](fileSize - startPos)
  if readBytes(f, buffer, 0, buffer.len) != buffer.len:
    raise newException(IOError, "无法读取文件尾部")

  # 在缓冲区中搜索最后的 OggS 页面
  var lastGranule: uint64 = 0
  for i in countdown(buffer.len-5, 0):
    if buffer[i..i+3] == ['O'.ord.uint8, 'g'.ord, 'g'.ord, 'S'.ord]:
      # 提取 granule position (小端64位整数)
      lastGranule = cast[ptr uint64](buffer[i+6].unsafeAddr)[]
      break

  if lastGranule == 0:
    raise newException(ValueError, "无法找到音频长度信息")

  # 4. 计算时长 (采样数 / 采样率)
  result = lastGranule.float32 / sampleRate.float32
  close(f)
type
  Sound* = ptr Chunk
var
  dev:AudioDeviceID
  # source:ptr CMSource
let
  tran=open(getCurrentEncoding(true),"UTF-8")

var
  music:ptr Music
  musicLen:float32
  musicStartTime:float32
  musicPauseTime:float32
  playing:bool
  sndI:int
# proc cb(data:pointer,stream:ptr uint8,size:cint){.cdecl.}=
#   cm_process(cast[ptr CMInt16](stream),size shr 1)
proc initAudio*()=
  doAssert sdl2.init(INIT_AUDIO)==SdlSuccess, $getError()
  doAssert openAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048)>=0, $getError()
  doAssert allocateChannels(64)==64
  sndI=0
  playing=false
proc loadMusic*(path:string)=
  if not music.isNil:
    freeMusic(music)
  musicLen=getOggDuration(path)
  music=loadMUS(path)
  assert not music.isNil(),$getError()
proc loadSound*(sound:var Sound,path:string)=
  if not sound.isNil:
    freeChunk(sound)
  sound=loadWAV(path)
  assert not sound.isNil(),$getError()
proc destroySound*(sound:var Sound)=
  freeChunk(sound)
  sound=nil
proc getMusicPosF*():float32=
  if playingMusic()>0 and playing:
    getMonoTime().ticks()/1_000_000_000-musicStartTime
  else:
    musicPauseTime-musicStartTime
proc setMusicPosF*(pos:float32)=
  musicStartTime+=getMusicPosF()-pos
  case music.getMusicType
  of MUS_MP3:
    rewindMusic()
    discard setMusicPosition(pos.cdouble)
  of MUS_OGG:
    discard setMusicPosition(pos.cdouble)
  else:
    raiseAssert "oh fuck the audio format doesn't support setting position."
proc musicLength*():float32=
  musicLen
#   cm_get_length(source).float32
proc playMusic*(loop:bool=false)=
  musicStartTime=getMonoTime().ticks()/1_000_000_000
  discard playMusic(music,if loop: -1 else:0)
  playing=true
proc playSound*(sound:var Sound)=
  doAssert playChannelTimed(sndI.cint,sound,0,-1) != -1
  sndI=(sndI+1) and 63
proc resumeMusic*()=
  musicStartTime+=getMonoTime().ticks()/1_000_000_000-musicPauseTime
  mixer.resumeMusic()
  playing=true
proc musicPlaying*():bool=
  playing=playing and playingMusic()>0
  playing
proc pauseMusic*()=
  musicPauseTime=getMonoTime().ticks()/1_000_000_000
  mixer.pauseMusic()
  playing=false
proc stopMusic*()=
  discard haltMusic()
  playing=false
proc quitAudio*()=
  playing=false
  mixer.closeAudio()
  sdl2.quit()