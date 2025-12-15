#version 330

in vec2 fragTexCoord;
uniform sampler2D texture0;
out vec4 finalColor;

void main()
{
    vec4 tex = texture(texture0, fragTexCoord);

    vec3 lightBlue = vec3(0.43, 0.85, 1.0);
    vec3 darkBlue = vec3(0.09, 0.57, 0.9);
    vec3 white = vec3(1.0);
    
    float lightAmount = 0.20;

    vec3 lighter = mix(tex.rgb, darkBlue, lightAmount);

    finalColor = vec4(lighter, tex.a);
}
