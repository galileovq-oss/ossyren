# Changelog / registro de decisiones

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
