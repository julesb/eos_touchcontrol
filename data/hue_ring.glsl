precision mediump float;

uniform vec2 resolution;

float PI = 3.14159265359;
uniform float inner_radius; // = 0.7; // specify in range 0 to 1
uniform float outer_radius; // = 0.96; // specify in range 0 to 1

float sm = 0.005;

vec3 rgb_to_hsv(vec3 c)
{
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void main(void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy - 0.5) * 2.0;
    float dist = length(uv); // Distance from the center
    float alpha = smoothstep(inner_radius-sm, inner_radius, dist)
                * (1.0 - smoothstep(outer_radius, outer_radius+sm, dist));
    float hue = (PI + atan(-uv.y, -uv.x)) / (2.0 * PI);
    vec3 col = hsv_to_rgb(vec3(hue, 1.0, 1.0));
    gl_FragColor = vec4(col, alpha);
}

