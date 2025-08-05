#version 330 core
layout (location = 0) in vec2 aPos;
uniform mat4 uColors;
uniform vec4 uPnS;
out vec4 Color;

void main(){
  gl_Position=vec4(
    aPos.x*uPnS.z+uPnS.x,
    aPos.y*uPnS.w+uPnS.y,
    0,1);
  Color=uColors[gl_VertexID];
}