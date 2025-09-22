shader_type spatial;

uniform float time : hint_range(0, 10) = 0.0;
uniform float height_amplitude : hint_range(0, 5) = 1.0;
uniform float bend_amplitude : hint_range(0, 1) = 0.2;

void vertex() {
    // faz o cubo subir e descer
    VERTEX.y += sin(time * 4.0 + VERTEX.x + VERTEX.z) * height_amplitude;

    // distorce para os lados
    VERTEX.x += sin(time * 3.0 + VERTEX.y) * bend_amplitude;
    VERTEX.z += cos(time * 3.0 + VERTEX.y) * bend_amplitude;
}
