#version 330 core
layout (location = 0) in vec4 aPos;
layout (location = 1) in uvec3 aCOL;

uniform mat4 uMVP;
uniform vec2 uPos;
uniform float uSize;
uniform vec4 uColor;
out vec2 TexCoord;
out vec4 Color;
flat out uint chr;

void main(){
  gl_Position=uMVP*vec4(
    uPos.x+aCOL.y*2u*uSize/16+uSize*aPos.z*2u,
    (aPos.y-float(aCOL.z)*2)*uSize+uPos.y,0,1);
  TexCoord=vec2(aPos.z*15,(1-aPos.w)*15);
  chr=aCOL.x;
  Color=uColor;
}