#version 330 core
layout (location = 0) in vec2 aPos;

uniform float uProgress;

void main(){
  gl_Position=vec4(
    aPos.x,
    aPos.y==1?1:1-2*uProgress,
    0,1);
}