#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 coord;
layout(location = 1) out float theta;

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
    coord = qt_MultiTexCoord0;
    theta = strip.x + (0.5 - coord.x) * strip.y;
    float y = strip.w + (0.5 - coord.y) * strip.z;
    if (pose.z > 0.5)
        y = 2.0 * pose.w - y;

    // seen from (0, 0, -back), principal point at (centreX, centreY)
    float z = pose.y * cos(theta) + view.w;
    vec2 bent = vec2(view.y - view.x * pose.y * sin(theta) / z, view.z - view.x * y / z);
    vec2 flatPos = flatRect.xy + coord * flatRect.zw;
    gl_Position = qt_Matrix * vec4(mix(flatPos, bent, pose.x), 0.0, 1.0);
}
