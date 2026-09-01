shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D distortion_noise: repeat_enable, filter_nearest;
uniform vec2 direction = vec2(3.0, 2.0);
uniform vec4 water_color: source_color;
uniform vec4 fractal_color: source_color;
uniform sampler2D fractals: repeat_enable, filter_nearest;

varying vec2 world_position;
varying vec2 tile_uv;

uniform float scale: hint_range(1.0, 512.0, 0.5) = 64.0;
uniform float opacity: hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float distortion_strength: hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float fractal_strength: hint_range(0.0, 1.0, 0.05) = 0.5;

void vertex() {
    // Compute world position (for noise sampling) and pass along UV for base texture sampling.
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    tile_uv = UV;
}

void fragment() {
    // --- STEP 1: Sample the base texture for masking ---
    vec4 base_color = texture(TEXTURE, tile_uv);
    
    // --- STEP 2: Pixel-perfect snapping to the base texture grid ---
    // The built-in TEXTURE_PIXEL_SIZE gives the pixel size of the base texture.
    vec2 base_tex_size = 1.0 / TEXTURE_PIXEL_SIZE;
    // Snap world_position to avoid bleeding the effect over tile boundaries.
    vec2 snapped_world_pos = floor(world_position * base_tex_size) / base_tex_size;
    
    // --- STEP 3: Compute the water effect using the snapped position ---
    vec2 distort_uv = UV + vec2(5.0) * TIME;
    vec2 move_uv = UV + direction * TIME;
    
    // Sample distortion noise based on the snapped world position.
    vec4 noise1 = texture(distortion_noise, (snapped_world_pos + distort_uv) * 0.005);
    vec4 noise2 = texture(distortion_noise, (snapped_world_pos - distort_uv - 16.0) * 0.005);
    float depth = noise1.r * noise2.r;
    
    // Use the screen texture with a slight offset for the distortion.
    vec4 distortion = texture(SCREEN_TEXTURE, SCREEN_UV + distortion_strength / 50.0 * vec2(depth));
    
    // Sample fractal/foam details.
    vec4 frac_up = texture(fractals, (snapped_world_pos + depth * 3.0 + move_uv) / scale) * fractal_color;
    vec4 frac_down = texture(fractals, (snapped_world_pos + depth * 3.0 - move_uv + 16.0) / scale) * fractal_color;
    vec4 fractal = ((frac_up * frac_down) + frac_up * 0.2 + frac_down * 0.05) * fractal_strength;
    
    // Mix the distortion with the water color then add the fractal details.
    vec4 water = mix(distortion, water_color, opacity) + fractal;
    
    // --- STEP 4: Use strict channel masks (like in the overlay shader) ---
    // These masks decide where the water or fractal effects are applied.
    // For example, we might reserve areas where the base texture is predominantly red
    // to show fractal effects, or predominantly blue for water.
    float mask_fractal = step(0.9, base_color.r) * (1.0 - step(1.0, base_color.g + base_color.b));
    float mask_water   = step(0.9, base_color.b) * (1.0 - step(1.0, base_color.r + base_color.g));
    
    // --- STEP 5: Combine the base color with the water effect using the masks ---
    vec4 final_effect = base_color;
    final_effect = mix(final_effect, fractal_color * noise1.r * opacity * 2.0, mask_fractal);
    final_effect = mix(final_effect, water, mask_water);
    
    // Handle alpha: only show fragments where the base alpha is high enough.
    final_effect.a *= step(0.5, base_color.a);
    if (final_effect.a < 0.01) {
        discard;
    }
    
    COLOR = final_effect;
}