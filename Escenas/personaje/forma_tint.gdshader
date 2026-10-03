shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float grayscale_strength = 0.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec3 sprite_color = source.rgb;
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	// Metal usa una base clara para que incluso las zonas oscuras sean plata.
	vec3 silver_color = mix(tint_color.rgb * 0.78, tint_color.rgb, luminance);
	sprite_color = mix(source.rgb, silver_color, grayscale_strength);
	COLOR = vec4(sprite_color, source.a * tint_color.a);
}
