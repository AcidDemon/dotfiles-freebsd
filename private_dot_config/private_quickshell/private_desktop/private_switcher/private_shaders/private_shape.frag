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

void main() {
    // rounded rectangle in units of the strip's height, shrunk by box.w, edge blurred over ±box.y
    vec2 half_ = vec2(box.z, 1.0) * 0.5 - box.w;
    vec2 q = abs((coord - 0.5) * vec2(box.z, 1.0)) - half_ + box.x;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - box.x;
    float cover = 1.0 - smoothstep(-box.y, box.y, d);
    fragColor = mix(colorTop, colorBottom, coord.y) * cover * qt_Opacity;
}
