# Changelog / registro de decisiones

## 2026-11-02 — Decisiones para la Fase 7 y ajuste del Ranger
- **Atributos: cuatro.** Strength (daño físico/requisitos), **Agility (evasión + precisión/impacto + movilidad)**, Vitality (HP/supervivencia), Tech (energía/eficiencia y requisitos). Accuracy se fusiona en Agility.
- **Muerte estilo Diablo:** reaparecer en el hub y perder algo menor (oro o durabilidad). Pendiente de implementar con el hub (Fase 8/9); definir qué se pierde cuando exista la moneda/durabilidad (Fase 7).
- **Ranger: dash real.** Nuevo efecto `DASH` (`MovementController.dash`): Evasive Roll avanza 5 m hacia el cursor en 0,22 s (los muros lo detienen), cancela el ataque en curso, bloquea ataques durante el dash y da +60 evasión 1,5 s. Sustituye a Evasive Stance. Sonido "dash" y marcador de salida.

## 2026-11-02 — Fase 6 (vertical slice)
- `ClassData` + 3 clases jugables (Vanguard, Ranger, Aether) con kit mínimo (pasiva, defensa activa, ofensiva). `Player` recibe su clase **antes** de entrar al árbol; pantalla de selección (`ClassSelect`) y `GameSession` para sobrevivir a los reinicios.
- Armas de energía (`damage_physical = false`, familia ENERGY: Arc Emitter). Nuevo efecto **BUFF** de habilidades y bonos de AS/CS/mana regen en pasivas.
- Enemigos por rol: Bulwark (tanque), Spitter (a distancia), Skitterer (evasivo), Brute (área), **Overseer** (mini-jefe con fase 2 `enrage_threshold` y `min_enemy_phase`). `EnemyBase` ahora tiene `abilities`, `aggro_radius`, `visual_scale`, `is_boss`.
- Piso "Substation Delta" generado por `tools/gen_level.py`: muros bajos, 5 salas, 2 opcionales, cofres placeholder (`LootChest`), resumen al derrotar al jefe.
- `Sfx`: sonidos procedurales placeholder. Feedback: colores por tipo de daño y aviso "Armoured". Barra de jefe en el HUD. `SessionKeys` (R reinicia, F2 elige clase) disponible siempre.
- Pruebas de reglas de datos (`tests/test_game_data.gd`): cooldowns cortos (≤ 5 s), coste de mana, preparación ≤ 3 intervalos.

## 2026-11-02 — Decisiones de Fase 5
- Apuntado de AoE: cursor directo (confirmado). AoE no se esquivan con Evasion (confirmado).
- **Recurso de habilidades: mana clásico** (nombre de trabajo) + **cooldowns cortos** estilo Diablo 2 (0,5–3 s); odiamos los cooldowns largos.
- `ManaComponent` (100 máx., regen 1,5/s); `AbilityData.mana_cost` (se gasta al resolver; un cast interrumpido es gratis); `StatBlock.max_mana/mana_regen`; `request_failed` con avisos flotantes ("Not enough mana", "Out of range", "No target").
- Pociones de mana: `ConsumableData.kind` (HEALTH/MANA), mismo modelo que las de vida (5 cargas, drops, hub, mejoras Estus). `PotionPickup` y `EnemyBase.mana_drop_share`. Tecla V.
- Renombres: `heal_amount` -> `restore_amount`, `heal_per_upgrade` -> `restore_per_upgrade`.

## 2026-11-02 — Fase 5
- `AbilityData` ampliado: targeting (self/target/ground), alcance, LoS, efecto AREA con wind-up propio, duración y ticks, tipo de daño (físico/energía) y `can_miss`.
- `AreaEffect`: zona circular con telegraph; cubre AoE instantáneo, con wind-up y persistente. Se registra en el grupo `area_effects`.
- `AbilityController.request_cast`: apunta con cursor, camina hasta alcance/LoS antes de lanzar (reusa `MovementController.chase` con un ancla), cast quieto, cancelable por cualquier orden. Las acciones encoladas en pausa guardan el punto apuntado.
- Habilidades del jugador: Brace, Burst (instantáneo), Collapse (wind-up ≈ 1,9 s en total), Static Field (persistente). Se retira Channelled Brace.
- Enemigo **Brute** con Slam telegráfico (usa la misma maquinaria que el jugador). Regla Auto de Brace: también se activa ante una zona hostil que va a impactar.
- `DamageCalculator.resolve_attack` acepta `physical` y `can_miss`; pruebas ampliadas.
- Decidido por defecto: AoE no se esquivan con Evasion (se esquivan moviéndose). Pendiente de confirmar.

## 2026-11-02 — Decisiones de Fase 4
- Casteo: el personaje se queda quieto y cualquier orden lo interrumpe (confirmado).
- Cambio de set de armas: cooldown de 1,5 s **solo si ocurre en combate** (`EquipmentComponent.combat_swap_cooldown`; "en combate" = objetivo engranado o hasta 4 s tras dar/recibir un ataque, `CombatController.combat_linger`).
- Techo de bonos de velocidad de movimiento: se decide en la Fase 7 con el sistema de equipo.

## 2026-11-02 — Fase 4
- `SpeedCalculator` (funciones puras con pruebas): breakpoints de AS por arma y de CS globales; tasas 1/1, 3/2, 2/1; techo por tipo de arma.
- `WeaponData` ampliado: familia, `attack_interval`, `impact_fraction` (sustituye a `impact_delay`), `attack_speed_bonus`, umbrales y tasas. Tres familias de prueba: Maul (melee pesada, techo 3/2), Blade (melee rápida) y Rifle.
- `EquipmentComponent`: dos sets, cambio sin pausar con 0,4 s de demora; el cambio bloquea ataques y reevalúa rango/LoS al terminar.
- `CombatController`: bloqueos por fuente (`swap`, `cast`) y cadencia derivada de AS.
- `AbilityController`: cast time con CS, el lanzamiento inmoviliza y bloquea ataques; cualquier orden interrumpe. Habilidad de prueba Channelled Brace.
- `StatsComponent`: `attack_speed` y `cast_speed`. Herramientas debug para AS/CS y para cambiar armas de los sets.
- Todo el ritmo base sigue al 85 % (decisión anterior); los techos de movimiento quedan pendientes.

## 2026-11-02 — Ajustes de Fase 3 (decisiones)
- Acciones en pausa: se encolan y se ejecutan al reanudar (confirmado).
- Idioma de trabajo: **inglés en código y comentarios**; **español en commits y documentos de trabajo**. Todos los comentarios existentes pasaron a inglés.
- Modelo de pociones: máx. 5 cargas; se recuperan con drops de enemigos/cofres (autopickup) y en el hub; la poción mejora tipo Estus (sin tiers) con recurso o sidequest recurrente.
- Implementado: `ConsumableController` con `add_charges`, `refill`, `upgrade` y `get_heal_amount`; `PotionPickup` (autopickup); `EnemyBase.potion_drop_chance`. Teclas debug G (recarga) y U (mejora).

## 2026-11-02 — Fase 3 (+ idioma)
- **Idioma:** inglés británico como base del proyecto (texto, UI, datos, identificadores propios). `armor` -> `armour` en todo el código y datos; `StyleGuide.md` creado. Setting probable: Inglaterra (homenaje a Hellgate).
- Pausa táctica (`TacticalPause`, `SceneTree.paused`): HUD, targeting y `PlayerController` siguen activos (`PROCESS_MODE_ALWAYS`). Órdenes de movimiento/ataque dadas en pausa se ejecutan al reanudar.
- Habilidades y pasivas: `AbilityData` / `AbilityController` (4 ranuras activas, cooldown, modo Auto/Manual con regla de salud). Primera defensa activa: **Brace** (barrera). Pasiva: **Hardened** (+10 % DR).
- `StatsComponent` con modificadores aditivos por fuente; `HealthComponent` con barrera y curación.
- Consumibles: `ConsumableController` (poción manual, 3 cargas, enfriamiento 8 s; nunca automática).
- Acciones pedidas en pausa: se **encolan** y se ejecutan al reanudar (`queue_actions_while_paused`, por defecto true; pendiente de confirmar).
- HUD mínimo táctico en código (`ui/hud/hud.gd`): vida, barra de acciones, objetivo, banner de pausa.
- `use_potion` (F) registrada vía `InputSetup`.

## 2026-11-02 — Ajuste de ritmo base (nivel 1)
- Decidido: ritmo base **15 % más lento** para que el juego no sea frenético en niveles altos.
- Movimiento ×0,85: jugador 6,0 -> 5,1 m/s; grunt 4,5 -> 3,8 m/s.
- Cadencia ×0,85: intervalo de referencia 1,0 s -> 1,18 s (melee y rifle); garras 1,4 -> 1,65 s. Retardos de impacto escalados igual.
- El jugador ahora lee su velocidad de `StatBlock` (antes usaba el valor por defecto del controlador).
- Pendiente (Fases 4 y 7): definir techos de velocidad de movimiento/ataque por equipo y talentos para mantener el ritmo en niveles altos.

## 2026-11-02 — Fase 2
- Combate automático: `CombatController` (ciclo de ataque con impacto diferido y cancelación), `DamageCalculator` (fórmulas puras con pruebas en `tests/`), `HealthComponent`, `StatsComponent`, `StatBlock`.
- Decidido: click en el suelo deselecciona al objetivo. Evitación RVO entre agentes.
- `EnemyBase.tscn` (datos en la raíz: stats/arma/agresividad) + `EnemyAI` mínima (aggro por radio o por ataque recibido). Sustituye a `TargetDummy`.
- `WeaponData` ampliado (daño, penetración, intervalo, retardo de impacto).
- Feedback procedural (`CombatFeedback`), números flotantes y `CombatLog` en overlay.
- K ahora mata vía `HealthComponent.kill()`.
- Fix previo: llegada de movimiento medida en horizontal.

## 2026-11-01 — Fase 1
- Click-to-move con NavigationAgent3D (malla generada en runtime desde StaticBody3D).
- Selección por raycast de cámara; `Targetable` (Area3D, capa 6) con anillo hover/selección.
- `MovementController` genérico en `core/`: move_to / chase / stop, rango borde a borde, histéresis, LoS opcional, detección de bloqueo.
- `WeaponData` mínimo (rango, requiere LoS) + dos armas de prueba. Cambio de arma Q/E es solo *debug*.
- `Layers` (class_name) centraliza las máscaras de física.
- CameraRig movido a `_physics_process`; recomendado activar Physics Interpolation.
- Herramientas debug (K/R) solo en builds de depuración.

## 2026-11-01 — Fase 0
- Título provisional cambiado de *Fallen Eden* a **Ossyren**.
- Motor fijado: **Godot 4.7.2-stable** (verificado en godotengine.org; 4.8 aún en dev snapshots).
- Renderizador: Forward+. Viewport base 1920×1080, stretch `canvas_items`, aspect `expand`.
- Escena principal: `core/Main.tscn` (cámara isométrica ortográfica 45° yaw / −35.264° pitch, placeholder).
- Añadida referencia de atmósfera: **Hellgate: London** (ver `ART_REFERENCES.md`).
