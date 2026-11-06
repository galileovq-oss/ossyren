# Fase 6 — Vertical slice de combate

Salida: un vertical slice que demuestra el corazón del juego. Tag: `v0.6-vertical-slice`.
Flujo: **elegir clase → recorrer el piso → mini-jefe → resumen**. Objetivo de duración: 5–10 minutos.

## Clases (kit mínimo: pasiva + defensa activa + ofensiva representativa)
| Clase | Stats clave | Sets de armas | Pasiva | Slot 1 (defensa) | Ofensiva |
|---|---|---|---|---|---|
| **Vanguard** | 200 HP, 60 mana, armadura 40, vel. 5,0 | Breaching Maul / Combat Blade | Iron Will (+20 armadura, +10 % DR) | Bulwark (barrera 70, mana 25, cd 4 s) | 2 Ground Pound (físico, cuerpo a cuerpo) |
| **Ranger** | 120 HP, 90 mana, evasión 35, precisión 120, vel. 5,3 | Carbine / Combat Blade | Deadeye (+25 precisión, +25 % AS) | **Evasive Roll**: dash de 5 m hacia el cursor + 60 evasión 1,5 s (mana 10, cd 2,5 s) | 2 Frag Grenade (físico a distancia) |
| **Aether** | 100 HP, 150 mana, regen 2,5/s, armadura 0 | Arc Emitter (energía) / Combat Blade | Resonance (+40 % CS, +1 mana/s) | Aegis (barrera 90, mana 30, cd 3 s) | 2 Burst · 3 Collapse · 4 Static Field |

Las clases tienen **afinidades, no restricciones**: B / N (debug) cambian el arma de un set por cualquiera.

## Enemigos (roles)
| Enemigo | Rol | Notas |
|---|---|---|
| **Grunt** | Melee agresivo | 60 HP, básico |
| **Bulwark** | Tanque blindado | 150 HP, armadura 90: la energía y la penetración rinden mucho más (aparece "Armoured") |
| **Spitter** | Hostigador a distancia | 40 HP, escupe desde 9 m con línea de visión |
| **Skitterer** | Rápido / evasivo | 30 HP, evasión 70, más rápido que tú: los AoE (que no fallan) brillan |
| **Brute** | Criatura de área | Slam telegráfico |
| **Overseer** (mini-jefe) | Jefe con fases | 400 HP. Slam grande; al 50 % **se enfurece** (+25 % vel.) y desbloquea **Blight**, una zona persistente. Barra de jefe arriba |

## El piso — "Substation Delta"
Entrada segura → **Pump Hall** (sala central: 3 Grunts + 2 Spitters, pilares para cobertura) con tres salidas:
- Oeste: **Storage** (opcional; 2 Skitterers + cofre).
- Este: **Turbine Room** (opcional; Brute + 2 Grunts + Bulwark + cofre).
- Norte: **Control Core** (obligatoria; Overseer + cofre).
Muros **bajos** (1,5 m) para no tapar la cámara pero que bloquean movimiento y línea de visión. Explorar da pociones sin obligar a limpiar todo.

## Loot, feedback, SFX/VFX
- **Cofres placeholder**: se abren al acercarte y sueltan pociones de vida/mana (el loot real es la Fase 7).
- Números de daño por color: rojo = daño al jugador, amarillo = físico, cian = energía; "Armoured" cuando la armadura reduce mucho; "Miss", "Absorbed".
- **Sonidos procedurales** (sin archivos de audio): golpe, fallo, disparo, cast, explosión, aviso de telegraph, poción, pickup, muerte, cofre. `Sfx.enabled = false` silencia todo. Se sustituyen por audio real en la fase de pulido.
- VFX: anillos y telegraphs de zona, destello al golpear, burbuja de barrera, trazador del rifle, brillo al lanzar.

## Controles
Mismos de antes, más: **R** reinicia con la misma clase · **F2** vuelve a elegir clase. (Ya no son solo de debug.) Pantalla de selección al arrancar.

## Herramientas
- `tools/gen_level.py` regenera `core/Main.tscn` (rooms, pasillos, enemigos, cofres): `python3 tools/gen_level.py`. Si prefieres editar la escena a mano, no lo vuelvas a ejecutar.
- Pruebas automáticas: `godot --headless -s res://tests/test_game_data.gd` (reglas de diseño: kits, cooldowns cortos, coste de mana, preparación máxima de habilidades) además de las de daño y velocidad.

## Plan de pruebas
- [ ] Las tres suites de pruebas en PASS.
- [ ] La pantalla de clase aparece, cada botón arranca con esa clase (HUD, kit y stats correctos).
- [ ] Vanguard, Ranger y Aether se sienten **distintos** en el mismo piso.
- [ ] Ranger: la tecla 1 hace un dash corto hacia el cursor (se detiene en muros), cancela el ataque en curso, sale un anillo verde y suena el "swoosh"; dos dashes seguidos respetan el cooldown de 2,5 s; sirve para salir de la zona roja del Brute/Overseer.
- [ ] Pump Hall: Spitters disparan desde lejos (te rodean los Grunts mientras tanto); los pilares sirven de cobertura.
- [ ] Skitterers: difíciles de golpear con ataques normales; los AoE los alcanzan.
- [ ] Bulwark: aparece "Armoured" con armas físicas; Arc Emitter / Burst / Collapse le hacen mucho más daño.
- [ ] Brute: Slam telegráfico esquivable; Aegis/Bulwark en Auto reaccionan.
- [ ] Overseer: Slam esquivable; al 50 % "ENRAGED!" y aparece Blight (zona púrpura persistente de 7 s). La barra de jefe se ve.
- [ ] Cofres: se abren al acercarte, sueltan 2 pociones, suena el efecto.
- [ ] Matar al Overseer muestra "FLOOR CLEARED" con tiempo, enemigos y cofres. R / F2 funcionan (también en pausa y al morir).
- [ ] Recorrido completo (sala central + jefe) en 5–10 min; las salas opcionales se sienten rentables sin ser obligatorias.
- [ ] Sonidos presentes y no molestos; sin errores ni warnings en consola.

## Pendiente / decisiones abiertas
- Maniobra evasiva del Ranger: **decidido: dash real** (Evasive Roll). Falta pulir su sensación y, más adelante, valorar i-frames.
- Nombre final del mana y de las clases; más habilidades por clase (Fase 7+).
- Muerte: **decidido estilo Diablo** (reapareces en el hub y pierdes algo menor: oro o durabilidad). Se implementa cuando exista el hub (Fase 8/9); hoy se reinicia con R.
- Audio real, arte real y animaciones: fase de pulido.
