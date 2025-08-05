import std/[os,tables]
import texture
import stb_image/read as stbi
var
  textures*:Table[string,Tex]
proc initRes*()=
  stbi.setFlipVerticallyOnLoad(true)
  for kind,path in walkDir("rsc/tex"):
    if kind==pcFile or kind==pcLinkToFile:
      let (dir,name,ext)=path.splitFile()
      textures[name]=Tex()
      initTexture(textures[name],path)
  doAssert "songsbg" in textures
proc quitRes*()=
  for name,tex in textures.mpairs():
    destroyTexture(tex)