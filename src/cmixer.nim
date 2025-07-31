##
## * Copyright (c) 2017 rxi
## *
## * This library is free software; you can redistribute it and/or modify it
## * under the terms of the MIT license. See `cmixer.c` for details.
##
{.passl:"-dCM_USE_STB_VORBIS".}
{.compile: "csources/cmixer_impl.c".}
{.compile: "csources/stb_vorbis.c".}

type
  CMInt16* = int16
  CMInt32* = int32
  CMInt64* = int64
  CMUInt16* = uint16
  CMUInt32* = uint32
  CMUInt64* = uint64
  CMSource* = object
  CMEvent* {.bycopy.} = object
    `type`*: cint
    udata*: pointer
    msg*: cstring
    buffer*: ptr CMInt16
    length*: cint

  CMEventHandler* = proc (e: ptr CMEvent)
  CMSourceInfo* {.bycopy.} = object
    handler*: CMEventHandler
    udata*: pointer
    samplerate*: cint
    length*: cint


const
  CM_STATE_STOPPED* = 0
  CM_STATE_PLAYING* = 1
  CM_STATE_PAUSED* = 2

const
  CM_EVENT_LOCK* = 0
  CM_EVENT_UNLOCK* = 1
  CM_EVENT_DESTROY* = 2
  CM_EVENT_SAMPLES* = 3
  CM_EVENT_REWIND* = 4

proc cm_get_error*(): cstring {.cdecl,importc.}
proc cm_init*(samplerate: cint) {.cdecl,importc.}
proc cm_set_lock*(lock: CMEventHandler) {.cdecl,importc.}
proc cm_set_master_gain*(gain: cdouble) {.cdecl,importc.}
proc cm_process*(dst: ptr CMInt16; len: cint) {.cdecl,importc.}
proc cm_new_source*(info: ptr CMSourceInfo): ptr CMSource {.cdecl,importc.}
proc cm_new_source_from_file*(filename: cstring): ptr CMSource {.cdecl,importc.}
proc cm_new_source_from_mem*(data: pointer; size: cint): ptr CMSource {.cdecl,importc.}
proc cm_destroy_source*(src: ptr CMSource) {.cdecl,importc.}
proc cm_get_length*(src: ptr CMSource): cdouble {.cdecl,importc.}
proc cm_get_position*(src: ptr CMSource): cdouble {.cdecl,importc.}
proc cm_get_state*(src: ptr CMSource): cint {.cdecl,importc.}
proc cm_set_gain*(src: ptr CMSource; gain: cdouble) {.cdecl,importc.}
proc cm_set_pan*(src: ptr CMSource; pan: cdouble) {.cdecl,importc.}
proc cm_set_pitch*(src: ptr CMSource; pitch: cdouble) {.cdecl,importc.}
proc cm_set_loop*(src: ptr CMSource; loop: cint) {.cdecl,importc.}
proc cm_play*(src: ptr CMSource) {.cdecl,importc.}
proc cm_pause*(src: ptr CMSource) {.cdecl,importc.}
proc cm_stop*(src: ptr CMSource) {.cdecl,importc.}