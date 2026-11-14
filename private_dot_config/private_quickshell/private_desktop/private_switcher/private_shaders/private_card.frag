#version 440

layout(location = 0) in vec2 coord;
layout(location = 1) in float theta;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 flatRect;
    vec4 view;
    vec4 strip;
    vec4 pose;
    vec4 light;
    vec4 colorTop;
    vec4 colorBottom;
    vec4 box;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 s = texture(source, coord);
    if (s.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 c = s.rgb / s.a;

    // lit in linear light: ambient 0.55, one light of 0.5 from the upper left behind
    // the viewer, Blinn-Phong shininess 70; reflections stay unlit
    if (pose.z < 0.5) {
        c = pow(c, vec3(2.2));
        float y = strip.w + (0.5 - coord.y) * strip.z;
        vec3 n = vec3(-sin(theta), 0.0, -cos(theta));
        vec3 l = normalize(vec3(0.9, 0.7, -1.0));
        vec3 v = normalize(vec3(0.0, 0.0, -view.w) - vec3(pose.y * sin(theta), y, pose.y * cos(theta)));
        float nl = max(dot(n, l), 0.0);
        float spec = light.x / 2.0 * 4.5 * nl * pow(max(dot(n, normalize(l + v)), 0.0), 70.0);
        c = pow(c * (0.55 + 0.5 * nl) + vec3(spec), vec3(1.0 / 2.2));
    }

    float top = 0.55 * clamp(1.0 - coord.y / 0.035, 0.0, 1.0);
    float bottom = 0.7 * clamp((coord.y - 0.88) / 0.12, 0.0, 1.0);
    c = mix(c, vec3(1.0), top * light.y);
    c = mix(c, vec3(0.0), bottom * light.y);

    // the bend comes from geometry, so soften the strip's own edges by hand
    vec2 e = min(coord, 1.0 - coord) / max(fwidth(coord), vec2(1e-6));
    fragColor = vec4(c * s.a, s.a) * qt_Opacity * clamp(min(e.x, e.y), 0.0, 1.0);
}
