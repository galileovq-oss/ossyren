# OSSYREN

> Título provisional (antes *Fallen Eden*). RPG de acción isométrico 3D de ciencia ficción oscura,
> exploración compacta y combate en tiempo real con pausa (RTwP). PC / Windows. Godot 4.7.2 + GDScript.

**Estado:** Fase 0 — Fundación (`v0.0.1-foundation`).
**Documento de diseño:** [`docs/GDD_v0.1_original_Fallen_Eden.pdf`](docs/GDD_v0.1_original_Fallen_Eden.pdf)
(el GDD sigue usando el título antiguo; las decisiones nuevas se registran en [`docs/CHANGELOG.md`](docs/CHANGELOG.md)).

## Requisitos

- **Godot 4.7.2-stable** (versión estándar, *no* .NET). Fijada para toda la producción hasta nueva decisión.
  Descarga: <https://godotengine.org/download/archive/>
- Git. Opcional: Export Templates de 4.7.2 (Editor → Manage Export Templates) para exportar.

## Cómo ejecutar

1. Abrir Godot 4.7.2 → **Import** → seleccionar `project.godot`.
2. Pulsar **F5**. Debe verse un suelo oscuro, tres pilares, un personaje placeholder con visor cian,
   cámara isométrica ortográfica y un overlay con versión/FPS (F3 lo oculta).

## Cómo exportar (build mínima Windows)

1. Editor → *Manage Export Templates* → instalar los de 4.7.2.
2. *Project → Export → Add… → Windows Desktop*. Ruta de salida: `builds/ossyren.exe`.
3. *Export Project*. La carpeta `builds/` está en `.gitignore`.
4. Una vez creado, commitear `export_presets.cfg` (sin credenciales).

## Estructura

Ver GDD §13. Carpetas vacías llevan `.gitkeep`. Escena principal: `core/Main.tscn`.
Convenciones de código y Git: [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md).

## Hoja de ruta

| Fase | Contenido | Tag |
|------|-----------|-----|
| 0 | Fundación | `v0.0.1-foundation` |
| 1 | Movimiento, cámara y selección | `v0.1-targeting-movement` |
| 2 | Combate automático | `v0.2-auto-combat` |
| 3 | Pausa táctica y defensas | `v0.3-rtwp` |
| 4 | Armas y velocidad | `v0.4-weapons-speed` |
| 5 | Habilidades y AoE | `v0.5-abilities-aoe` |
| 6 | Vertical slice de combate | `v0.6-vertical-slice` |
| 7 | Progresión y loot | `v0.7-progression-loot` |
| 8 | Piso y misiones | `v0.8-level-quest-loop` |
| 9 | Prototipo completo | `v0.9-complete-prototype` |

## Pendiente (Fase 0)

- Crear y commitear `export_presets.cfg` tras la primera exportación.
- Confirmar el mapa de inputs en *Project Settings → Input Map* (se definió a mano en `project.godot`).
- Valores de cámara (pitch/ortho size/distancia) son provisionales; se validan en Fase 1.
