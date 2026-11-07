shader_type canvas_item;

uniform bool railing_pass = true;
uniform float lower_floor_height : hint_range(0.0, 16.0, 1.0) = 6.0;

void fragment() {
	// Only the bottom railing has floor pixels to render beneath the player.
	float pixel_y = floor(UV.y / TEXTURE_PIXEL_SIZE.y);
	float atlas_row = floor(pixel_y / 16.0);
	float local_y = mod(pixel_y, 16.0);
	bool railing = true;
	if (atlas_row == 3.0) {
		railing = local_y >= lower_floor_height;
	}
	if (railing != railing_pass) {
		COLOR.a = 0.0;
	}
}
