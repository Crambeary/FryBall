shader_type canvas_item;

uniform vec2 pixel_grid = vec2(4.0, 4.0);
uniform float density = 0.0005;
uniform float twinkle_speed = 1.5;
uniform float twinkle_amount = 0.75;
uniform float base_brightness = 0.08;

uniform vec4 bg_color : source_color = vec4(0.01, 0.01, 0.02, 1.0);
uniform vec4 star_color : source_color = vec4(0.75, 0.85, 1.0, 1.0);

uniform float glare_strength = 1.1;
uniform float glare_range = 8.0;
uniform float glare_sharpness = 1.6;
uniform float star_threshold_for_glare = 0.7;

uniform float warp_strength_px = 50;
uniform float warp_scale = 0.0025;
uniform float layer2_strength = 0.55;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float twinkle(vec2 cell_id, float tone, float phase) {
    float rate = twinkle_speed * mix(0.25, 3.25, tone);
    float seed = hash21(cell_id + vec2(91.7, 17.3)) * 1000.0;

    float t = TIME * rate + phase * 0.37;

    float warp_t = (value_noise(cell_id * 0.035 + vec2(TIME * 0.08, TIME * 0.06)) * 2.0 - 1.0);
    t += warp_t * 0.9;

    float ti = floor(t);
    float tf = fract(t);
    tf = tf * tf * (3.0 - 2.0 * tf);

    float a = hash21(vec2(ti + 0.0, seed));
    float b = hash21(vec2(ti + 1.0, seed));
    float rw = mix(a, b, tf);

    float hf = value_noise(vec2(t * 4.7, seed + 31.0));
    float flicker = rw * 0.78 + hf * 0.22;

    flicker = smoothstep(0.15, 0.95, flicker);
    return mix(1.0 - twinkle_amount, 1.0, flicker);
}

vec2 warp(vec2 screen_px) {
    vec2 p = screen_px * warp_scale;
    float nx = value_noise(p + vec2(13.1, 7.7));
    float ny = value_noise(p + vec2(4.2, 19.3));
    vec2 w = (vec2(nx, ny) * 2.0 - 1.0);
    return screen_px + w * warp_strength_px;
}

float star_in_cell(vec2 cell_id, out float rnd_phase, out float rnd_size, out float rnd_tone) {
    float r1 = hash21(cell_id + 17.0);
    float r2 = hash21(cell_id + 29.0);
    float r3 = hash21(cell_id + 61.0);

    rnd_phase = r2 * 6.28318530718;
    rnd_size = mix(0.6, 1.0, r3);
    rnd_tone = r1;

    return step(1.0 - density, r1);
}

float cross_glare(vec2 dp_px) {
    float ax = abs(dp_px.x);
    float ay = abs(dp_px.y);

    float gx = exp(-pow(ax / max(glare_range, 0.001), glare_sharpness)) * exp(-ay * 0.35);
    float gy = exp(-pow(ay / max(glare_range, 0.001), glare_sharpness)) * exp(-ax * 0.35);

    return gx + gy;
}

void fragment() {
    vec2 screen_px = SCREEN_UV / max(SCREEN_PIXEL_SIZE, vec2(1e-6));

    vec2 screen_px_w = warp(screen_px);

    vec2 cell = floor(screen_px_w / max(pixel_grid, vec2(1.0)));
    vec2 cell_origin_px = (cell + 0.5) * pixel_grid;

    float phase;
    float size_var;
    float tone;
    float present = star_in_cell(cell, phase, size_var, tone);

    float tw = twinkle(cell, tone, phase);

    float star_intensity = present * size_var * tw;
    star_intensity = clamp(star_intensity, 0.0, 1.0);

    vec2 dp_px = screen_px_w - cell_origin_px;
    float flare_mask = smoothstep(star_threshold_for_glare, 1.0, star_intensity);
    float glare = flare_mask * cross_glare(dp_px) * glare_strength;

    vec2 pixel_grid2 = pixel_grid * 1.37;
    vec2 screen_px_w2 = warp(screen_px + vec2(123.0, 57.0));
    vec2 cell2 = floor((screen_px_w2 + vec2(0.37, 0.63) * pixel_grid2) / max(pixel_grid2, vec2(1.0)));
    vec2 cell2_origin_px = (cell2 + 0.5) * pixel_grid2;

    float phase2;
    float size_var2;
    float tone2;
    float present2 = star_in_cell(cell2 + vec2(1000.0, 2000.0), phase2, size_var2, tone2);

    float tw2 = twinkle(cell2 + vec2(1000.0, 2000.0), tone2, phase2 + 1.7);
    float star_intensity2 = present2 * size_var2 * tw2 * layer2_strength;
    star_intensity2 = clamp(star_intensity2, 0.0, 1.0);

    vec2 dp_px2 = screen_px_w2 - cell2_origin_px;
    float flare_mask2 = smoothstep(star_threshold_for_glare, 1.0, star_intensity2);
    float glare2 = flare_mask2 * cross_glare(dp_px2) * glare_strength;

    vec3 sc = star_color.rgb;
    sc = mix(sc * vec3(1.05, 0.95, 1.15), sc, 0.6);

    vec3 col = bg_color.rgb;
    col += base_brightness;
    col += sc * star_intensity;
    col += sc * glare * 0.12;
    col += sc * star_intensity2;
    col += sc * glare2 * 0.10;

    COLOR = vec4(col, 1.0);
}
