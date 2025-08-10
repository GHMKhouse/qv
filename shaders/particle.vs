#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aTXW;
layout (location = 2) in ivec3 aColor;

uniform mat4 uMVP;
uniform float uLinePos;
uniform float uTime;
uniform float uPersF;
out vec3 Color;
out float Fading;

void main(){
  Fading=uTime-aTXW.x;
  if(Fading<1 && Fading>=0){
    gl_Position=uMVP*vec4(
      (aPos.x*(aTXW.z)
        +aTXW.y-0.5)*2,
      aPos.y*0.01+uLinePos+Fading,0,1+Fading*uPersF);
  }else{
    gl_Position=vec4(114514);
  }
  Color=vec3(aColor)/255;
}