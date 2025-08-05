#version 330 core
in vec2 TexCoord;
in vec4 Color;
flat in uint chr;
uniform usamplerBuffer texture1;
out vec4 FragColor;
void main(){
  FragColor=Color*float(
    int(texelFetch(texture1,
      int(chr)*32+((int(TexCoord.y)*2)&31)+((int(TexCoord.x)>>3)&1)
    ).r)>>(7-(int(TexCoord.x)&7))&1);
}