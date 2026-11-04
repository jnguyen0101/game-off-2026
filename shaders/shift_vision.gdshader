shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.35;
uniform vec4 tint : source_color = vec4(0.70, 0.72, 1.0, 1.0);

void fragment() {
	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	float luminance = dot(original, vec3(0.299, 0.587, 0.114));
	vec3 shifted = mix(original, vec3(luminance), desaturation) * tint.rgb;
	COLOR = vec4(mix(original, shifted, strength), 1.0);
}
