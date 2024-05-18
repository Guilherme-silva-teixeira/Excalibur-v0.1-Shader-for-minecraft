#version 450 compatibility

uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform sampler2D colortex0;  // Textura de cor
uniform sampler2D colortex1;  // Normais no espaço de visão
uniform sampler2D colortex2;  // Cor da luz do bloco e do céu

in vec2 texcoord_vs;
layout(location = 0) out vec3 final_color;

// Função para calcular a cor da luz principal
vec3 calculateMainLightColor() {
    if (worldTime < 1500 || worldTime > 12500) {
        // É noite! Use uma cor de luz fraca para representar a lua
        return vec3(0.01);
    } else {
        // É dia! Use uma luz brilhante para o sol
        return vec3(5.3,4.3,1.7);
    }
}


uniform mat4 shadowViewProjectionMatrix;
uniform sampler2D shadowMap;
uniform float shadowBias;

// Função para calcular o fator de sombra
float calculateShadowFactor(vec4 shadowCoord) {
    vec3 projCoords = shadowCoord.xyz / shadowCoord.w;
    float depth = texture(shadowMap, projCoords.xy).r;
    float visibility = (projCoords.z - shadowBias) > depth ? 1.0 : 0.0;
    return visibility;
}

uniform sampler2D noiseTexture; // Textura de ruído para movimento das folhas
uniform float movementSpeed; 

void main() {

     // Ler as coordenadas de textura originais da folha
    vec2 texCoord = texcoord_vs;

    // Amostrar a textura de ruído para obter um valor de deslocamento
    vec2 noiseOffset = texture(noiseTexture, texCoord * movementSpeed).rg * 2.0 - 1.0;

    // Aplicar o deslocamento às coordenadas de textura originais da folha
    vec2 offsetTexCoord = texCoord + noiseOffset * movementSpeed;

    // Amostrar a textura da folha usando as coordenadas de textura deslocadas
    vec3 leafColor = texture(colortex0, offsetTexCoord).rgb;

    // Calcular a cor final do fragmento
    final_color = leafColor;

    // Ler a textura de cor, trazendo-a para o espaço linear para iluminação
    vec3 fragmentColor = pow(texture(colortex0, texcoord_vs).rgb, vec3(2.2));

    // Pular os cálculos de iluminação para, por exemplo, o céu
    bool shouldReceiveLighting = texture(colortex2, texcoord_vs).a > 0.5;

    if (shouldReceiveLighting) {
        // Ler as normais do g-buffer
        vec3 normal = texture(colortex1, texcoord_vs).rgb * 2.0 - 1.0;

        // Calcular a luz difusa básica. O Minecraft usa uma luz difusa fraca para ajudar a dar profundidade à cena
        vec3 mainLightDirection = normalize(shadowLightPosition);
        float mainLightStrength = clamp(dot(normal, mainLightDirection), 0, 1);  // Difusão lambertiana
        vec3 mainLight = calculateMainLightColor() * mainLightStrength;

        vec3 blockAndSkyLight = texture(colortex2, texcoord_vs).rgb;

        vec3 incomingDiffuseLight = mainLight + blockAndSkyLight;
        vec3 reflectedDiffuseLight = incomingDiffuseLight * fragmentColor;


        final_color = reflectedDiffuseLight / (vec3(1) + reflectedDiffuseLight);
    } else {
        final_color = fragmentColor;
    }

    // Corrigir para gama antes de enviar a cor final para o alvo de renderização
    final_color = pow(final_color, vec3(0.49 / 0.7));
}
