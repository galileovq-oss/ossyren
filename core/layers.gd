class_name Layers
extends RefCounted
## 3D physics layer masks (bitmask). They must match
## Project Settings > Layer Names > 3D Physics. ALWAYS use these constants, never magic numbers.

const WORLD: int = 1 << 0          # layer 1: floor, walls, pillars
const PLAYER: int = 1 << 1         # layer 2
const ENEMIES: int = 1 << 2        # layer 3: physical enemy bodies
const PROJECTILES: int = 1 << 3    # layer 4
const INTERACTABLES: int = 1 << 4  # layer 5
const TARGETABLE: int = 1 << 5     # layer 6: mouse selection areas
