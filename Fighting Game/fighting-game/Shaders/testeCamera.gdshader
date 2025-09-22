shader_type spatial;

uniform sampler2D sprite_texture;
uniform bool facing_right = true; // true = normal, false = virar

uniform float alpha_cut = 0.5;

void fragment() {
    vec2 uv = UV;

    // Inverte horizontalmente se estiver virando
    if (!facing_right) {
        uv.x = 1.0 - uv.x;
    }

    vec4 tex = texture(sprite_texture, uv);

    // Alpha Cut
    if (tex.a < alpha_cut) {
        discard;
    }

    ALBEDO = tex.rgb;
    ALPHA = tex.a;
}
