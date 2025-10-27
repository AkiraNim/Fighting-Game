shader_type spatial;

// --- CONTROLES GERAIS ---
uniform vec3 axis = vec3(0.0, 1.0, 0.0);     // eixo da torção (local do mesh)
uniform vec3 center = vec3(0.0);             // ponto de referência (origem da torção), no espaço local

// região ao longo do eixo que sofre o efeito (em unidades locais projetadas no eixo)
uniform float region_start = -1.0;
uniform float region_end   =  1.0;

// intensidade máxima da torção (em graus). É o "máximo que ele roda".
uniform float twist_max_deg : hint_range(-1080.0, 1080.0) = 80.0;

// perfil da queda/entrada (0 = liga/desliga seco, 1 = suave). Use >0 para bordas suaves.
uniform float edge_softness : hint_range(0.0, 1.0) = 1.0;

// --- ANIMAÇÃO ---
uniform bool  use_time = true;                // se true, anima com TIME*speed; senão usa "progress"
uniform float speed    : hint_range(-10.0, 10.0) = 1.0;     // “ciclos” por segundo (cada ciclo = direita+esquerda)
uniform float progress : hint_range(0.0, 1.0) = 0.0;        // use como fase quando animar fora do shader

// --- AVANÇO HELICOIDAL (opcional) ---
uniform float pitch_per_turn = 0.0; // avanço ao longo do eixo por volta completa (em unidades do mesh)

// --- PERFIL AO LONGO DO EIXO ---
uniform float along_power : hint_range(0.1, 4.0) = 1.0; // 1 = linear; >1 concentra no fim; <1 espalha

// função auxiliar: *smoothstep* opcional
float softstep(float a, float b, float x, float softness) {
    if (softness <= 0.0) {
        return step(a, x) * step(x, b); // liga/desliga “seco”
    }
    // mapeia para 0..1 e aplica smoothstep
    float t = clamp((x - a) / max(0.00001, (b - a)), 0.0, 1.0);
    return smoothstep(0.0, 1.0, t);
}

void vertex() {
    // normaliza parâmetros
    vec3 n = normalize(axis);
    float twist_max = radians(twist_max_deg);

    // posição local relativa ao centro de torção
    vec3 p = VERTEX - center;

    // decompõe em componente paralela e perpendicular ao eixo
    float t = dot(p, n);            // coordenada ao longo do eixo
    vec3  par = n * t;              // componente paralela
    vec3  perp = p - par;           // componente perpendicular (a que realmente roda)

    // peso pela região ao longo do eixo
    float w_region = softstep(region_start, region_end, t, edge_softness);
    // perfil adicional ao longo do eixo (ex.: dar mais torção perto do fim)
    float w_profile = pow(clamp((t - region_start) / max(0.00001, (region_end - region_start)), 0.0, 1.0), along_power);
    float w = w_region * w_profile;

    // --- NOVO: ÂNGULO BIDIRECIONAL ---
    // 'phase' oscila em [-1, +1]. Com TIME: sin(TIME * speed * 2π). Com progress: sin(progress * 2π).
    float phase;
    if (use_time) {
        phase = sin(TIME * speed * 2.0 * PI);
    } else {
        phase = sin(progress * 2.0 * PI);
    }

    // ângulo final vai de -twist_max a +twist_max e alterna direita/esquerda continuamente
    float angle = twist_max * phase * w;

    // Rodrigues: gira 'perp' ao redor de 'n'
    vec3 rot_perp = perp * cos(angle) + cross(n, perp) * sin(angle);

    // avanço helicoidal (tradução ao longo do eixo proporcional ao ângulo aplicado)
    float advance = (pitch_per_turn / (2.0 * PI)) * angle;

    // reconstrói posição
    vec3 pos = center + (par + n * advance) + rot_perp;

    VERTEX = pos;
}
