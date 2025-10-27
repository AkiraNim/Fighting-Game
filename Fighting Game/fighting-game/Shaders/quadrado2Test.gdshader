shader_type spatial;

// --- EIXOS / REFERÊNCIAS ---
uniform vec3 up_axis  = vec3(0.0, 1.0, 0.0); // eixo "para cima" no espaço local
uniform float ground_height = 0.0;           // altura do chão no eixo up_axis (tipicamente Y=0)

// região de influência acima do chão (em unidades do mesh projetadas em up_axis)
uniform float influence_height = 1.0;        // quanto acima do chão o efeito atinge
uniform float falloff_power : hint_range(0.2, 6.0) = 2.0; // 1=linear; >1 fixa mais a base

// direção XZ para as diagonais (no plano perpendicular ao up_axis)
uniform vec3 right_dir = vec3(1.0, 0.0, 0.0); // só o componente perpendicular ao up_axis é usado

// --- AMPLITUDES ---
uniform float max_down = 0.4;                // quanto “abaixa” (distorção para baixo)
uniform float max_up   = 0.6;                // quanto “sobe”
uniform float lateral_ratio : hint_range(0.0, 2.0) = 0.35; // quanto inclina para os lados ao subir

// --- ANIMAÇÃO ---
uniform float period = 1.6;                  // duração do ciclo completo (segundos)
uniform float ease_softness : hint_range(0.0, 1.0) = 0.7; // 0=seco, 1=suave

// peso suave 0..1 pela altura (mantém o "chão" fixo)
float height_weight(vec3 p_local) {
    vec3 n = normalize(up_axis);
    float h = dot(p_local, n);                        // altura projetada no eixo "up"
    float t = clamp((h - ground_height) / max(0.00001, influence_height), 0.0, 1.0);
    // falloff com potência (gruda a base e solta o topo)
    return pow(t, falloff_power);
}

// retorna o alvo de deslocamento para cada chave do ciclo
vec3 key_target(int idx, vec3 n_up, vec3 n_right) {
    // componente vertical
    vec3 up_v   = n_up * max_up;
    vec3 down_v = -n_up * max_down;
    // laterais (só quando sobe)
    vec3 right_v = n_right * (max_up * lateral_ratio);
    vec3 left_v  = -right_v;

    if (idx == 0) return down_v;             // abaixa
    if (idx == 1) return up_v + right_v;     // sobe diagonal direita
    if (idx == 2) return down_v;             // abaixa
    // idx == 3
    return up_v + left_v;                    // sobe diagonal esquerda
}

// interpolação com suavização configurável
float ease(float t) {
    if (ease_softness <= 0.0) { return t; }
    // mistura entre linear e smoothstep
    float s = smoothstep(0.0, 1.0, t);
    return mix(t, s, ease_softness);
}

void vertex() {
    // normalizações de eixos
    vec3 n_up = normalize(up_axis);
    // remove componente ao longo do up_axis da direção lateral
    vec3 n_right = normalize(right_dir - n_up * dot(right_dir, n_up));

    // tempo normalizado 0..1 ao longo do período
    float t_loop = fract(TIME / max(0.0001, period));
    // 4 segmentos: [0,0.25) [0.25,0.5) [0.5,0.75) [0.75,1)
    float segf = t_loop * 4.0;
    int seg = int(floor(segf));
    float t_seg = fract(segf);

    // chaves
    vec3 k0 = key_target(seg, n_up, n_right);
    vec3 k1 = key_target((seg + 1) % 4, n_up, n_right);
    vec3 target = mix(k0, k1, ease(t_seg));  // destino do quadro atual

    // peso por altura (fixa o chão)
    float w = height_weight(VERTEX);

    // deslocamento final: aplica mais no topo, zero na base
    vec3 disp = target * w;

    // aplica a distorção (só move os vértices acima do chão)
    VERTEX += disp;
}
