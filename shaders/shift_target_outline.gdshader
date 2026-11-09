shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.45, 0.8);

void fragment() {
	COLOR = vec4(outline_color.rgb, texture(TEXTURE, UV).a * outline_color.a);
}
