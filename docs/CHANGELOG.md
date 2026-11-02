# Changelog / registro de decisiones

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
