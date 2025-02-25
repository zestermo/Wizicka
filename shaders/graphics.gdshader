shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE;
uniform vec2 VIEWPORT_SIZE;
render_mode unshaded;

#define MAXCOLORS 16
const int pixel_size = 4; //resolution must be divisible by pixel_size
uniform bool enabled = true;
uniform bool dithering = true;
uniform int colors : hint_range(1, MAXCOLORS) = 12;
uniform int dither_size: hint_range(1, 8) = 1;

float dithering_pattern(ivec2 fragcoord) {
	const float pattern[] = {
		0.00, 0.50, 0.10, 0.65,
		0.75, 0.25, 0.90, 0.35,
		0.20, 0.70, 0.05, 0.50,
		0.95, 0.40, 0.80, 0.30
	};

	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;

	return pattern[y * 4 + x];
}

float reduce_color(float raw, float dither, int depth) {
	float div = 1.0 / float(depth);
	float val = 0.0;
	int i = 0;

	while (i <= MAXCOLORS)
	{
		if (raw > div * (float(i + 1))) {
			i = i + 1;
			continue;
		}

		if (raw * float(depth) - float(i) <= dither * 0.999)
		{
			val = div * float(i);
		}
		else
		{
			val = div * float(i + 1);
		}
		return val;

		i = i+1;
	}

	return val;
}

void fragment() {
    // Pixelation effect
    float x = float(int(FRAGCOORD.x) % pixel_size);
    float y = float(int(FRAGCOORD.y) % pixel_size);
    x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
    y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;

    // Sample the pixelated texture
    vec4 pixelated_color = texture(SCREEN_TEXTURE, vec2(x, y) / VIEWPORT_SIZE);

    // Dithering effect applied to pixelated image
    ivec2 uv = ivec2(FRAGCOORD.xy / float(dither_size));
    float dithering_value = dithering ? dithering_pattern(uv) : 1.0;

    if (enabled) {
        COLOR.r = reduce_color(pixelated_color.r, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);
        COLOR.g = reduce_color(pixelated_color.g, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);
        COLOR.b = reduce_color(pixelated_color.b, (dithering_value - 0.5) * dithering_value + 0.5, colors - 1);
    } else {
        COLOR = pixelated_color;
    }
}