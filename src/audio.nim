import cmixer
import std/encodings
import sdl2
import sdl2/[audio]
var
  dev:AudioDeviceID
  source:ptr CMSource
let
  tran=open(getCurrentEncoding(true),"UTF-8")
proc cb(data:pointer,stream:ptr uint8,size:cint){.cdecl.}=
  cm_process(cast[ptr CMInt16](stream),size shr 1)
proc initAudio*()=
  sdl2.init(INIT_AUDIO)
  var
    fmt=AudioSpec(freq:44100,format:AUDIO_S16,channels:2,samples:1024,callback:cb)
    got:AudioSpec
  dev=openAudioDevice(nil,0,fmt.addr,got.addr, SDL_AUDIO_ALLOW_FREQUENCY_CHANGE)
  pauseAudioDevice(dev,0)
  cm_init(got.freq)
proc loadMusic*(path:string)=
  if not source.isNil:
    cm_destroy_source(source)
  source=cm_new_source_from_file(tran.convert(path).cstring)
  if source.isNil:echo cm_get_error()
proc musicLength*():float=
  cm_get_length(source).float32
proc playMusic*(loop:bool=false)=
  cm_set_loop(source,loop.cint)
  cm_play(source)
proc pauseMusic*()=
  cm_pause(source)
proc stopMusic*()=
  cm_stop(source)
proc quitAudio*()=
  cm_destroy_source(source)
  closeAudioDevice(dev)
  sdl2.quit()