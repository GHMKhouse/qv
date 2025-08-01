import streams
# {.push define(release).}
proc readBinFont*():(seq[byte],seq[byte])=
  result=(newSeqOfCap[byte](65536),newSeqOfCap[byte](65536*256))
  var s=openFileStream("font_bitmap.bin")
  defer:s.close()
  for _ in 0..65535:
    result[0].add s.readUint8()
    var a:array[32,byte]
    doAssert s.readData(a[0].addr,32)==32
    # for i in 0..15:
    #   let
    #     x=s.readUint8()
    #     y=s.readUint8()
    #   for j in 0..7:
    #     a[i*16+j]=((x shr (7-j)) and 1)*255
    #   for j in 0..7:
    #     a[i*16+8+j]=((y shr (7-j)) and 1)*255
    result[1]&=a
# {.pop.}