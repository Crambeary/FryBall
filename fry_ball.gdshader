shader_type canvas_item;

uniform float radius = 80.0;
uniform float edge_softness = 6.0;
uniform float edge_power = 1.6;

uniform float bumpiness_amplitude = 3.2;
uniform float bumpiness_scale = 3.6;
uniform float bumpiness_warp = 0.65;
uniform float macro_normal_weight = 0.55;
uniform float curvature_power = 1.35;

uniform float fry_noise_scale = 4.5;
uniform float fry_fbm_gain = 0.55;
uniform float fry_warp_amount = 1.4;
uniform float fry_warp_scale = 2.0;
uniform float rotation_speed = 0.18;
uniform float ridge_density = 20.0;
uniform float ridge_strength = 0.45;
uniform float crumb_strength = 0.35;
uniform float normal_strength = 1.6;

uniform vec2 light_dir = vec2(-0.45, -0.8);
uniform float specular_power = 24.0;
uniform float ambient_strength = 0.24;
uniform float bounce_strength = 0.18;
uniform float rim_strength = 0.28;
uniform float rim_power = 2.0;
uniform float shadow_strength = 0.6;
uniform float shadow_radius = 0.55;
uniform float shadow_softness = 0.22;
uniform float shadow_curve = 1.35;
uniform vec2 shadow_center = vec2(-0.05, -0.1);
uniform vec3 shadow_tint = vec3(0.82, 0.78, 0.9);
uniform vec2 terminator_dir = vec2(0.6, 0.45);
uniform float terminator_softness = 0.12;
uniform float terminator_offset = -0.4;
uniform float terminator_strength = 2;
uniform float terminator_contrast = 10;
uniform vec3 terminator_tint = vec3(0.82, 0.78, 0.9);

uniform vec3 base_color = vec3(0.95, 0.82, 0.45);
uniform vec3 shadow_color = vec3(0.68, 0.52, 0.22);
uniform vec3 crisp_color = vec3(1.0, 0.93, 0.68);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
    float n = sin(dot(p, vec2(269.5, 183.3)));
    return fract(vec2(262144.0, 32768.0) * n);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.55;
    float freq = 1.0;
    for (int i = 0; i < 4; i++) {
        sum += noise(p * freq) * amp;
        freq *= 2.12;
        amp *= fry_fbm_gain;
    }
    return sum;
}

float clump_noise(vec2 p) {
    // Low-cost voronoi-style clumps to mimic fries sticking together
    vec2 g = floor(p);
    vec2 f = fract(p);
    float md = 8.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 o = hash2(g + offset);
            vec2 diff = offset + o - f;
            float d = dot(diff, diff);
            md = min(md, d);
        }
    }
    return 1.0 - sqrt(md); // tighter distance -> higher value
}

float fry_height(vec2 p) {
    vec2 fry_uv = p * fry_noise_scale;

    // Domain warp to break flatness
    vec2 warp = vec2(
        fbm(fry_uv * fry_warp_scale + vec2(17.1, 9.3)),
        fbm(fry_uv * fry_warp_scale + vec2(3.7, 21.5))
    ) - 0.5;
    fry_uv += warp * fry_warp_amount;

    float base = fbm(fry_uv);

    // Clumpy fry mass: isotropic cells, less directional striping
    float clump = clump_noise(fry_uv * 0.7);
    clump = smoothstep(0.25, 0.9, clump);

    // Micro crumbs
    float crumbs = noise(p * fry_noise_scale * 6.0);

    return base * 0.35
         + clump * ridge_strength * 0.9
         + crumb_strength * (crumbs - 0.5);
}

void vertex() {
    vec2 dir = normalize(VERTEX);
    vec2 p = (VERTEX / max(radius, 1.0)) * bumpiness_scale;
    float warp = fbm(p * 0.75 + vec2(2.3, 5.1)) * bumpiness_warp;
    float displacement = (fbm(p + warp) - 0.5) * bumpiness_amplitude;
    VERTEX = dir * (radius + displacement);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);

    // 3D spin around an axis aligned with the terminator line (perpendicular to light dir in XY)
    float angle = TIME * rotation_speed;
    vec3 axis = normalize(vec3(-terminator_dir.y, terminator_dir.x, 0.0));
    float ca = cos(angle);
    float sa = sin(angle);

    float z = sqrt(max(0.0, 1.0 - dist * dist));
    vec3 spin_p = vec3(uv, z);
    vec3 rotated_p = spin_p * ca + cross(axis, spin_p) * sa + axis * dot(axis, spin_p) * (1.0 - ca);
    vec2 uv_tex = rotated_p.xy;

    float edge = smoothstep(
        radius / 100.0,
        (radius + edge_softness) / 100.0,
        dist
    );
    edge = pow(edge, edge_power);

    float height = fry_height(uv_tex);
    float shade = smoothstep(0.0, 1.0, dist);

    float h_dx = fry_height(uv_tex + vec2(0.01, 0.0)) - fry_height(uv_tex - vec2(0.01, 0.0));
    float h_dy = fry_height(uv_tex + vec2(0.0, 0.01)) - fry_height(uv_tex - vec2(0.0, 0.01));
    vec3 bump_normal = normalize(vec3(-h_dx * normal_strength, -h_dy * normal_strength, 1.0));

    float macro_z = sqrt(max(0.0, 1.0 - dist * dist));
    vec3 macro_normal = normalize(vec3(uv_tex, macro_z));
    vec3 normal = normalize(mix(macro_normal, bump_normal, macro_normal_weight));

    vec3 light = normalize(vec3(light_dir, 0.6));
    float diff = clamp(dot(normal, light), 0.0, 1.0);
    float spec = pow(max(diff, 0.0), specular_power) * 0.25;
    float rim = pow(1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0), rim_power) * rim_strength;
    float bounce = clamp(0.6 - light.y, 0.0, 1.0) * bounce_strength; // upward bounce fill

    vec3 color = mix(base_color, shadow_color, shade * 0.55 + height * 0.6);
    color = mix(color, crisp_color, 0.15 + height * 0.25);

    float curvature = pow(clamp(1.0 - dist, 0.0, 1.0), curvature_power);

    color *= ambient_strength + diff * 0.75 + bounce;
    color = mix(color * 0.6, color, curvature); // darken edges, brighten center
    color += rim * vec3(1.05, 0.95, 0.75);
    color += spec * vec3(1.0, 0.95, 0.8);

    // Directional terminator (harder day/night line)
    // Curved terminator on a unit sphere (approx) for better planet-like shading
    float r2 = clamp(dot(uv, uv), 0.0, 1.0);
    float tz = sqrt(1.0 - r2);
    vec3 sphere_p = vec3(uv, tz);
    vec3 t_light = normalize(vec3(terminator_dir, 0.6));
    float t_proj = dot(sphere_p, t_light) + terminator_offset;
    float t_mask = smoothstep(terminator_softness, -terminator_softness, t_proj);
    t_mask = pow(t_mask, terminator_contrast) * terminator_strength;
    color = mix(color, color * terminator_tint, t_mask);

    // Planetary shadow (eclipse) overlay
    vec2 shadow_uv = uv - shadow_center;
    float shadow_dist = length(shadow_uv);
    float shadow_mask = smoothstep(shadow_radius, shadow_radius - shadow_softness, shadow_dist);
    shadow_mask = pow(shadow_mask, shadow_curve);
    color = mix(color, color * shadow_tint, shadow_mask * shadow_strength);

    COLOR = vec4(color, 1.0 - edge);
}
