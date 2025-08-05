#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in int aHoT; // head or tail
layout (location = 2) in vec4 aTnF; // time and floor
layout (location = 3) in vec2 aPosX;
layout (location = 4) in uvec4 aMisc1;
layout (location = 5) in uvec2 aMisc2;

uniform mat4 uMVP;
uniform float uSpeed;
uniform float uFloor;
uniform float uLinePos;
uniform float uXSF;
out vec4 Color;

void main(){
  if(aMisc2.y==uint(1) || (aTnF[2]-uFloor)*uSpeed>10){ // judged note should'nt be drawn
    gl_Position=vec4(0,114,0,1);
  }
  else{
    float y=(aTnF[2+aHoT]-uFloor)*uSpeed+(aTnF.x==aTnF.y?float(aHoT)*0.1:0);
    gl_Position = uMVP*vec4(
      ((aPos.x*(float(aMisc1.x)/255)
      +aPosX[aHoT])-0.5)*pow(2,1-y*uXSF),
      y+uLinePos,
      0,1+y);
  }
  Color = vec4(
    float(aMisc1.y)/255,
    float(aMisc1.z)/255,
    float(aMisc1.w)/255,
    (aMisc2.x==uint(0) || aMisc2.y==uint(2))?1:0.5
    );
}