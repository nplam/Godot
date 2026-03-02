// uv_hidden_object.gdshader
shader_type spatial;

// Texture for the hidden message/blood stain
uniform sampler2D tex;
// Color of the UV glow (cyan/blue works well for UV effect)
uniform vec4 glow_color: source_color = vec4(0, 1, 1, 1);
// Intensity of the glow
uniform float energy: hint_range(0, 16) = 1;

void fragment() {
	// Make the object invisible normally
	ALPHA = 0.0;
	
	// Set emission for when UV light hits it
	EMISSION = glow_color.rgb * energy;
}

void light() {
	// This is called when light hits the object
	vec4 pixel = textureLod(tex, UV, 1.0);
	
	// Don't contribute to normal lighting
    DIFFUSE_LIGHT = vec3(0.0);
    SPECULAR_LIGHT = vec3(0.0);
    
    // Alpha is controlled by light attenuation and texture alpha
    ALPHA = ATTENUATION * pixel.a;
    
    // Prevent double exposure
    if (ATTENUATION == 1.0) {
        ALPHA = 0.0;
    }
}
