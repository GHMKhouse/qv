#version 330 core
in vec4 Color;
out vec4 FragColor;
void main(){
  FragColor=Color;
  FragColor.a=0.5;
}