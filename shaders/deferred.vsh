#version 450 compatibility

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

out vec2 texcoord_vs;
out vec4 fragPosition_ws; // Adiciona a variável de saída para a posição do fragmento no espaço do mundo

void main() {
    // Calcula a posição do fragmento no espaço do mundo
    fragPosition_ws = modelViewMatrix * gl_Vertex;

    // Passa as coordenadas de textura para o shader de fragmento
    texcoord_vs = gl_MultiTexCoord0.st;

    // Define a posição do vértice na janela de visualização
    gl_Position = ftransform();
}
