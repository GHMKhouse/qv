#version 330 core
layout (location = 0) in vec2 aPos;

uniform mat4 uMVP;
uniform float uLinePos;

void main(){
  gl_Position=uMVP*vec4(
    aPos.x,
    aPos.y*0.01+uLinePos,
    0,1);
}