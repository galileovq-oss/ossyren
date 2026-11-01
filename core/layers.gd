class_name Layers
extends RefCounted
## Mascaras de capas de fisica 3D (bitmask). Deben coincidir con
## Project Settings > Layer Names > 3D Physics. Usar SIEMPRE estas constantes, nunca numeros magicos.

const WORLD: int = 1 << 0          # capa 1: suelo, muros, pilares
const PLAYER: int = 1 << 1         # capa 2
const ENEMIES: int = 1 << 2        # capa 3: cuerpos fisicos de enemigos
const PROJECTILES: int = 1 << 3    # capa 4
const INTERACTABLES: int = 1 << 4  # capa 5
const TARGETABLE: int = 1 << 5     # capa 6: areas de seleccion con el raton
