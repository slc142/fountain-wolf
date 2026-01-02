shader_type spatial;
render_mode cull_disabled;

uniform vec3 water_color : source_color = vec3(0.0, 0.5, 1.0);
uniform float fill_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flow_speed = 2.0;

void fragment() {
    // UV.x represents the progress along the path (0.0 to 1.0)
    // If progress is greater than fill_amount, we make it invisible
    if (UV.x > fill_amount) {
        discard;
    }
    
    // Simple flowing texture effect using sine waves
    float flow = sin(UV.x * 20.0 - TIME * flow_speed) * 0.1;
    ALBEDO = water_color + flow;
    ALPHA = 0.9;
    METALLIC = 0.5;
    ROUGHNESS = 0.2;
}