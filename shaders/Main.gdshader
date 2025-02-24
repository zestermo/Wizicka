shader_type spatial;

uniform float height_scale = 2.0;
uniform sampler2D noise_texture;  // Noise for height
uniform sampler2D albedo_texture; // Your ground texture
uniform vec2 uv_scale = vec2(5.0, 5.0); // Texture tiling

void vertex() {
    float noise_value = texture(noise_texture, UV).r;
    VERTEX.y += noise_value * height_scale;
}

void fragment() {
    vec2 tiled_uv = UV * uv_scale;
    vec4 tex_color = texture(albedo_texture, tiled_uv);
    ALBEDO = tex_color.rgb;
}