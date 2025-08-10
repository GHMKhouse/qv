#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in float aFloor;
layout (location = 2) in uvec2 aFrac;

// const vec4 colors1[9]={vec4(1),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0)};
// const vec4 colors2[9]={vec4(1),vec4(1,0,0,1),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0)};
// const vec4 colors3[9]={vec4(1),vec4(0,1,0,1),vec4(0,1,0,1),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0)};
// const vec4 colors4[9]={vec4(1),vec4(0,0,1,1),vec4(1,0,0,1),vec4(0,0,1,1),vec4(0),vec4(0),vec4(0),vec4(0),vec4(0)};
// const vec4 colors5[9]={vec4(1),vec4(1,1,0,1),vec4(1,1,0,1),vec4(1,1,0,1),vec4(1,1,0,1),vec4(0),vec4(0),vec4(0),vec4(0)};
// const vec4 colors6[9]={vec4(1),vec4(1,0.5,0,1),vec4(0,1,0,1),vec4(1,0,0,1),vec4(0,1,0,1),vec4(1,0.5,0,1),vec4(0),vec4(0),vec4(0)};
// const vec4 colors7[9]={vec4(1),vec4(1,0,1,1),vec4(1,0,1,1),vec4(1,0,1,1),vec4(1,0,1,1),vec4(1,0,1,1),vec4(1,0,1,1),vec4(0),vec4(0)};
// const vec4 colors8[9]={vec4(1),vec4(0,1,1,1),vec4(0,0,1,1),vec4(0,1,1,1),vec4(1,0,0,1),vec4(0,1,1,1),vec4(0,0,1,1),vec4(0,1,1,1),vec4(0)};
// const vec4 colors9[9]={vec4(1),vec4(1,0,0.5,1),vec4(1,0,0.5,1),vec4(0,1,0,1),vec4(1,0,0.5,1),vec4(1,0,0.5,1),vec4(0,1,0,1),vec4(1,0,0.5,1),vec4(1,0,0.5,1)};
// const vec4 colors[9][9]={
//   colors1,
//   colors2,
//   colors3,
//   colors4,
//   colors5,
//   colors6,
//   colors7,
//   colors8,
//   colors9,
// };
uniform vec4 uColors[81];
uniform mat4 uMVP;
uniform float uFloor;
uniform float uSpeed;
uniform float uLinePos;
out vec4 Color;

void main(){
  gl_Position=uMVP*vec4(
    aPos.x,
    aPos.y*0.01+(aFloor-uFloor)*uSpeed+uLinePos,
    0,1);
  if(aFrac.x<uint(10))
    Color=uColors[(aFrac.x-uint(1))*uint(9)+aFrac.y];
  else
    Color=vec4(0.5,0.5,0.5,1);
}