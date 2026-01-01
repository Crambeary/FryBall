shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 ring_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform float ring_radius = 0.43;
uniform float ring_thickness = 0.08;
uniform float ring_softness = 0.06;
uniform vec2 squash = vec2(1.15, 0.85);

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    p *= squash;
    float d = length(p);

    float inner = ring_radius - ring_thickness;
    float a1 = smoothstep(inner - ring_softness, inner + ring_softness, d);
    float a2 = 1.0 - smoothstep(ring_radius - ring_softness, ring_radius + ring_softness, d);
    float alpha = a1 * a2;

    COLOR = vec4(ring_color.rgb, ring_color.a * alpha);
}
