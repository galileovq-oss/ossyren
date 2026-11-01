# Changelog / registro de decisiones

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
