shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 impact_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec2 impact_dir = vec2(1.0, 0.0);
uniform float t = 0.0;

uniform float max_angle = 1.15;
uniform float time_power = 1.8;
uniform float ring_width = 0.10;
uniform float ring_softness = 0.08;
uniform float local_falloff = 1.35;
uniform float core_glow = 0.22;
uniform float edge_fade = 0.25;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float r2 = dot(uv, uv);
    float inside = 1.0 - step(1.0, r2);

    float z = sqrt(max(0.0, 1.0 - r2));
    vec3 n = normalize(vec3(uv, z));

    vec2 d2 = impact_dir;
    float l = max(length(d2), 1e-4);
    d2 /= l;
    vec3 i = normalize(vec3(d2, 0.0));

    float ang = acos(clamp(dot(n, i), -1.0, 1.0));

    float tt = pow(clamp(t, 0.0, 1.0), time_power);
    float ring_r = max_angle * tt;
    float x = abs(ang - ring_r);

    float band = 1.0 - smoothstep(ring_width - ring_softness, ring_width + ring_softness, x);
    band = max(band, 0.0);

    float glow = smoothstep(0.0, ring_width, ring_width - x) * core_glow;
    float locality = exp(-ang * local_falloff);

    float edge = smoothstep(1.0 - edge_fade, 1.0, sqrt(r2));
    float alpha = (band + glow) * locality * (1.0 - edge) * inside;

    COLOR = vec4(impact_color.rgb, impact_color.a * alpha);
}
