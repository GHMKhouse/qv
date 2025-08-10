import std/[os,tables]
import texture,audio
import stb_image/read as stbi
var
  textures*:Table[string,Tex]
  sounds*:Table[string,Sound]
proc initRes*()=
  stbi.setFlipVerticallyOnLoad(true)
  for kind,path in walkDir("rsc/tex"):
    if kind==pcFile or kind==pcLinkToFile:
      let (dir,name,ext)=path.splitFile()
      textures[name]=Tex()
      initTexture(textures[name],path)
  for kind,path in walkDir("rsc/snd"):
    if kind==pcFile or kind==pcLinkToFile:
      let (dir,name,ext)=path.splitFile()
      sounds[name]=nil
      loadSound(sounds[name],path)
proc quitRes*()=
  for name,tex in textures.mpairs():
    destroyTexture(tex)
  for name,snd in sounds.mpairs():
    destroySound(snd)