# Fase 1 — Movimiento, cámara y selección

Salida: el personaje se mueve y persigue un maniquí manteniendo el rango adecuado. Tag: `v0.1-targeting-movement`.

## Controles (provisionales)
| Entrada | Acción |
|---|---|
| Click izq. en suelo | Mover (mantener pulsado = seguir moviendo) |
| Click izq. en enemigo | Seleccionar y perseguir hasta el rango del arma |
| Click der. | Cancelar orden y deseleccionar (a confirmar) |
| Q / E | *Debug*: alternar melee (2 m) / rifle (10 m, requiere línea de visión) |
| K | *Debug*: "matar" objetivo actual |
| R | *Debug*: reiniciar escena |
| F3 | Ocultar overlay |

## Flujo de datos
```
Input -> PlayerController -> TargetingController.pick_at() (raycast cámara -> WORLD | TARGETABLE)
                          -> MovementController.move_to() / chase(objetivo, rango, radio, LoS)
MovementController (NavigationAgent3D + CharacterBody3D) -> señales: entered_range / left_range /
        chase_failed / destination_reached / movement_blocked   (Fase 2 escuchará entered_range)
Targetable (Area3D, capa 6) -> invalidate() -> TargetingController.target_lost -> PlayerController.stop()
```

## Decisiones tomadas (provisionales)
- Rango medido **de borde a borde**: distancia al centro − `target_radius`.
- Histéresis de rango (0,35 m) para evitar parpadeo entrar/salir.
- Click en suelo **conserva** el objetivo seleccionado (`ground_click_clears_target = false`).
- `MovementController` vive en `core/` (no en `player/`) porque lo reutilizarán los enemigos.
- Sin evitación RVO todavía: los enemigos son sólidos físicamente (el jugador los rodea por colisión).

## Plan de pruebas (Definition of Done)
- [ ] Mover por el suelo, rodear pilares y el muro largo.
- [ ] Mantener click: el personaje sigue el cursor sin saltos.
- [ ] Melee: se detiene a ~2 m del borde del maniquí. Rifle: a ~10 m **y con línea de visión**.
- [ ] `DummyBehindWall` con rifle: rodea el muro hasta tener LoS antes de detenerse.
- [ ] `DummyPatrol` (se mueve): la persecución lo sigue y reajusta.
- [ ] Click en suelo durante persecución: interrumpe y el objetivo sigue marcado.
- [ ] K sobre objetivo mientras se acerca: se detiene y **no** elige otro.
- [ ] Q/E durante la persecución: el rango cambia al vuelo.
- [ ] Click der. cancela. R reinicia sin errores.
- [ ] Sin errores/warnings en la consola de Godot.

## Pendiente / fuera de alcance
- Ataques y daño (Fase 2). Pausa (Fase 3). WeaponData real (Fase 4).
- Decidir si tras reposicionarse el auto-ataque se reanuda sobre el objetivo conservado.
- Evitación entre agentes (RVO) cuando los enemigos se muevan.
