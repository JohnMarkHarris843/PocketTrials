shader_type spatial;

uniform vec3 color_a : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 color_b : source_color = vec3(0.0, 0.0, 0.0);
uniform float tiles = 8.0; // how many squares per axis


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec2 uv = UV * tiles;
    float c = mod(floor(uv.x) + floor(uv.y), 2.0); // 0 or 1
    ALBEDO = mix(color_a, color_b, c);
}
//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
