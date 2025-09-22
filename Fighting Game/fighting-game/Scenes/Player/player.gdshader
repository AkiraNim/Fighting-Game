shader_type spatial;

uniform sampler2D sprite_texture;
uniform sampler2D SCREEN_TEXTURE;
uniform float alpha_cut = 0.5;
uniform float ghost_alpha = 0.5;
uniform vec3 ghost_tint = vec3(1.0);

void fragment() {
    vec4 tex = texture(sprite_texture, UV);
    if (tex.a < alpha_cut) {
        discard;
    }

    vec2 screen_uv = FRAGCOORD.xy / vec2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y);
    float scene_depth = texture(SCREEN_TEXTURE, screen_uv).r;

    if (DEPTH > scene_depth) {
        ALBEDO = mix(tex.rgb, ghost_tint, 0.7);
        ALPHA = tex.a * ghost_alpha;
    } else {
        ALBEDO = tex.rgb;
        ALPHA = tex.a;
    }
}
