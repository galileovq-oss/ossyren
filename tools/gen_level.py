#!/usr/bin/env python3
"""Generates core/Main.tscn: the vertical-slice floor ("Substation Delta").

Run from the project root:  python3 tools/gen_level.py
Edit ROOMS / CORRIDORS / ENEMIES / CHESTS below and regenerate. Coordinates are metres on the XZ plane
(north = -Z). Walls are LOW (1.5 m) so the isometric camera never hides the player but they still
block movement and line of sight (eye height 1.2 m). Pillars are tall (3 m).
"""
import os

WALL_H = 1.5
WALL_T = 1.0
DOOR = 4.0

# name: (cx, cz, w, d, {side: offset_along_wall})   sides: N S E W
ROOMS = {
    "Entry":   (0, 24, 16, 12, {"N": 0}),
    "Pump":    (0, 0, 28, 24, {"S": 0, "N": 0, "W": 0, "E": 0}),
    "Storage": (-30, 0, 12, 14, {"E": 0}),
    "Turbine": (30, 0, 16, 16, {"W": 0}),
    "Core":    (0, -34, 24, 28, {"S": 0}),
}
# (axis, fixed coordinate, start, end): corridor along Z at x=fixed or along X at z=fixed
CORRIDORS = [
    ("Z", 0, 12, 18),      # Entry <-> Pump
    ("X", 0, -24, -14),    # Pump <-> Storage
    ("X", 0, 14, 22),      # Pump <-> Turbine
    ("Z", 0, -20, -12),    # Pump <-> Core
]
PILLARS = [(-7, 4), (7, 4), (-7, -4), (7, -4),            # Pump
           (-6, -30), (6, -30), (-6, -38), (6, -38),      # Core
           (30, -2), (34, 3)]                             # Turbine cover
LIGHTS = [  # x, y, z, colour, energy, range
    (0, 3.2, 24, (0.2, 0.83, 0.78), 2.2, 14),
    (-8, 3.2, -4, (0.91, 0.45, 0.23), 2.6, 14), (8, 3.2, 5, (0.2, 0.83, 0.78), 2.2, 14),
    (-30, 3.0, 0, (0.95, 0.7, 0.3), 2.4, 12),
    (30, 3.2, 0, (0.95, 0.35, 0.2), 2.8, 14),
    (0, 3.5, -34, (0.7, 0.2, 0.55), 3.2, 20),
]
# (name, x, z, stats, weapon, abilities, extra properties)
ENEMIES = [
    ("GruntA", -3, -6, "grunt", None, [], {}),
    ("GruntB", 3, -6, "grunt", None, [], {}),
    ("GruntC", 0, -9, "grunt", None, [], {}),
    ("SpitterA", -10, -9, "spitter", "acid_spit", [], {"aggro_radius": 11.0}),
    ("SpitterB", 10, -9, "spitter", "acid_spit", [], {"aggro_radius": 11.0}),
    ("SkittererA", -32, -3, "skitterer", "skitter_bite", [], {"potion_drop_chance": 0.15}),
    ("SkittererB", -32, 3, "skitterer", "skitter_bite", [], {"potion_drop_chance": 0.15}),
    ("BruteA", 33, 0, "brute", None, ["brute_slam"], {"potion_drop_chance": 0.6}),
    ("GruntD", 29, -5, "grunt", None, [], {}),
    ("GruntE", 29, 5, "grunt", None, [], {}),
    ("BulwarkA", 35, -5, "bulwark", "bulwark_fists", [], {"potion_drop_chance": 0.5}),
    ("Overseer", 0, -41, "overseer", "overseer_swipe", ["overseer_slam", "blight"],
     {"aggro_radius": 14.0, "visual_scale": 1.6, "is_boss": "true", "enrage_threshold": 0.5,
      "potion_drop_chance": 1.0}),
]
CHESTS = [("ChestStorage", -34, 0), ("ChestTurbine", 36, 6), ("ChestCore", 0, -46)]
PLAYER_START = (0, 0, 27)

SCRIPTS = {
    "main": "res://core/main.gd", "cam": "res://core/camera_rig.gd", "dbg": "res://ui/hud/debug_overlay.gd",
    "level": "res://world/level_navigation.gd", "tools": "res://core/debug_tools.gd", "hud": "res://ui/hud/hud.gd",
    "pause": "res://core/tactical_pause.gd", "chest": "res://world/interactables/loot_chest.gd",
    "keys": "res://core/session_keys.gd", "ability_data": "res://combat/attacks/ability_data.gd",
}
SCENES = {"enemy": "res://enemies/base/EnemyBase.tscn"}
RES = {}
for st in ["grunt", "bulwark", "spitter", "skitterer", "brute", "overseer"]:
    RES["stats_" + st] = "res://data/enemies/%s_stats.tres" % st
for w in ["acid_spit", "skitter_bite", "bulwark_fists", "overseer_swipe"]:
    RES["w_" + w] = "res://data/weapons/%s.tres" % w
for a in ["brute_slam", "overseer_slam", "blight"]:
    RES["a_" + a] = "res://data/abilities/%s.tres" % a

out_sub, out_nodes = [], []
sub_count = [0]


def sub(kind, props):
    sub_count[0] += 1
    sid = "%s_%d" % (kind, sub_count[0])
    out_sub.append('[sub_resource type="%s" id="%s"]\n%s\n' % (kind, sid, props))
    return sid


# shared materials
out_sub.append('[sub_resource type="StandardMaterial3D" id="Mat_floor"]\nalbedo_color = Color(0.13, 0.15, 0.17, 1)\nroughness = 0.9\n')
out_sub.append('[sub_resource type="StandardMaterial3D" id="Mat_wall"]\nalbedo_color = Color(0.2, 0.22, 0.25, 1)\nroughness = 0.85\n')
out_sub.append('[sub_resource type="StandardMaterial3D" id="Mat_pillar"]\nalbedo_color = Color(0.24, 0.26, 0.3, 1)\nroughness = 0.85\n')


def box(name, parent, cx, cy, cz, sx, sy, sz, mat):
    mesh = sub("BoxMesh", "size = Vector3(%g, %g, %g)" % (sx, sy, sz))
    shape = sub("BoxShape3D", "size = Vector3(%g, %g, %g)" % (sx, sy, sz))
    out_nodes.append(
        '[node name="%s" type="StaticBody3D" parent="%s"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)\n'
        'collision_layer = 1\ncollision_mask = 0\n\n'
        '[node name="Mesh" type="MeshInstance3D" parent="%s/%s"]\nmesh = SubResource("%s")\n'
        'surface_material_override/0 = SubResource("%s")\n\n'
        '[node name="Collision" type="CollisionShape3D" parent="%s/%s"]\nshape = SubResource("%s")\n'
        % (name, parent, cx, cy, cz, parent, name, mesh, mat, parent, name, shape))


def floor_box(name, cx, cz, w, d):
    mesh = sub("BoxMesh", "size = Vector3(%g, 0.2, %g)" % (w, d))
    shape = sub("BoxShape3D", "size = Vector3(%g, 0.2, %g)" % (w, d))
    out_nodes.append(
        '[node name="%s" type="StaticBody3D" parent="Level/Floors"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, -0.1, %g)\n'
        'collision_layer = 1\ncollision_mask = 0\n\n'
        '[node name="Mesh" type="MeshInstance3D" parent="Level/Floors/%s"]\nmesh = SubResource("%s")\n'
        'surface_material_override/0 = SubResource("Mat_floor")\n\n'
        '[node name="Collision" type="CollisionShape3D" parent="Level/Floors/%s"]\nshape = SubResource("%s")\n'
        % (name, cx, cz, name, mesh, name, shape))


out_nodes.append('[node name="Level" type="NavigationRegion3D" parent="."]\nscript = ExtResource("level")\n')
out_nodes.append('[node name="Floors" type="Node3D" parent="Level"]\n')
out_nodes.append('[node name="Walls" type="Node3D" parent="Level"]\n')
out_nodes.append('[node name="Pillars" type="Node3D" parent="Level"]\n')

wall_n = [0]


def wall(cx, cz, sx, sz):
    wall_n[0] += 1
    box("Wall%02d" % wall_n[0], "Level/Walls", cx, WALL_H / 2, cz, sx, WALL_H, sz, "Mat_wall")


def hwall(cz, x0, x1):  # wall along X
    if x1 - x0 > 0.01:
        wall((x0 + x1) / 2, cz, x1 - x0, WALL_T)


def vwall(cx, z0, z1):  # wall along Z
    if z1 - z0 > 0.01:
        wall(cx, (z0 + z1) / 2, WALL_T, z1 - z0)


for name, (cx, cz, w, d, doors) in ROOMS.items():
    floor_box("Floor" + name, cx, cz, w, d)
    x0, x1, z0, z1 = cx - w / 2, cx + w / 2, cz - d / 2, cz + d / 2
    for side in "NSEW":
        if side in "NS":
            wz = z0 - WALL_T / 2 if side == "N" else z1 + WALL_T / 2
            ex0, ex1 = x0 - WALL_T, x1 + WALL_T
            if side in doors:
                o = cx + doors[side]
                hwall(wz, ex0, o - DOOR / 2)
                hwall(wz, o + DOOR / 2, ex1)
            else:
                hwall(wz, ex0, ex1)
        else:
            wx = x1 + WALL_T / 2 if side == "E" else x0 - WALL_T / 2
            if side in doors:
                o = cz + doors[side]
                vwall(wx, z0, o - DOOR / 2)
                vwall(wx, o + DOOR / 2, z1)
            else:
                vwall(wx, z0, z1)

for i, (axis, fixed, a, b) in enumerate(CORRIDORS):
    length = b - a
    mid = (a + b) / 2
    if axis == "Z":
        floor_box("FloorCorridor%d" % i, fixed, mid, DOOR, length)
        wall(fixed - DOOR / 2 - WALL_T / 2, mid, WALL_T, length)
        wall(fixed + DOOR / 2 + WALL_T / 2, mid, WALL_T, length)
    else:
        floor_box("FloorCorridor%d" % i, mid, fixed, length, DOOR)
        wall(mid, fixed - DOOR / 2 - WALL_T / 2, length, WALL_T)
        wall(mid, fixed + DOOR / 2 + WALL_T / 2, length, WALL_T)

for i, (px, pz) in enumerate(PILLARS):
    box("Pillar%02d" % i, "Level/Pillars", px, 1.5, pz, 1.5, 3.0, 1.5, "Mat_pillar")

# ---- header, environment, lights ----
ext = []
for k, v in SCRIPTS.items():
    ext.append('[ext_resource type="Script" path="%s" id="%s"]' % (v, k))
for k, v in SCENES.items():
    ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % (v, k))
for k, v in RES.items():
    ext.append('[ext_resource type="Resource" path="%s" id="%s"]' % (v, k))

head = '[gd_scene load_steps=%d format=3]\n\n' % (len(ext) + len(out_sub) + 2) + "\n".join(ext) + "\n\n"
head += '''[sub_resource type="Environment" id="Environment_main"]
background_mode = 1
background_color = Color(0.02, 0.03, 0.04, 1)
ambient_light_source = 2
ambient_light_color = Color(0.25, 0.32, 0.4, 1)
ambient_light_energy = 0.5
tonemap_mode = 2
glow_enabled = true
glow_intensity = 0.6
fog_enabled = true
fog_light_color = Color(0.05, 0.08, 0.1, 1)
fog_density = 0.01

'''
head += "\n".join(out_sub) + "\n"

body = '''[node name="Main" type="Node3D"]
script = ExtResource("main")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_main")

[node name="Sun" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-55, -35, 0)
light_color = Color(0.55, 0.65, 0.8, 1)
light_energy = 0.45
shadow_enabled = true

'''
for i, (x, y, z, col, en, rng) in enumerate(LIGHTS):
    body += ('[node name="Light%d" type="OmniLight3D" parent="."]\nposition = Vector3(%g, %g, %g)\n'
             'light_color = Color(%g, %g, %g, 1)\nlight_energy = %g\nomni_range = %g\n\n' % (i, x, y, z, *col, en, rng))
body += "\n".join(out_nodes) + "\n"

body += '[node name="Enemies" type="Node3D" parent="."]\n\n'
for name, x, z, st, weapon, abilities, extra in ENEMIES:
    body += '[node name="%s" parent="Enemies" instance=ExtResource("enemy")]\n' % name
    body += 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, 0, %g)\n' % (x, z)
    body += 'stats = ExtResource("stats_%s")\n' % st
    if weapon:
        body += 'weapon = ExtResource("w_%s")\n' % weapon
    if abilities:
        body += 'abilities = Array[ExtResource("ability_data")]([%s])\n' % ", ".join('ExtResource("a_%s")' % a for a in abilities)
    for k, v in extra.items():
        body += '%s = %s\n' % (k, v)
    body += '\n'

body += '[node name="Chests" type="Node3D" parent="."]\n\n'
for name, x, z in CHESTS:
    body += ('[node name="%s" type="Node3D" parent="Chests"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, 0, %g)\n'
             'script = ExtResource("chest")\n\n' % (name, x, z))

body += '[node name="PlayerStart" type="Marker3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)\n\n' % PLAYER_START
body += '''[node name="CameraRig" type="Node3D" parent="."]
script = ExtResource("cam")

[node name="Camera3D" type="Camera3D" parent="CameraRig"]

[node name="DebugTools" type="Node" parent="."]
script = ExtResource("tools")

[node name="TacticalPause" type="Node" parent="."]
script = ExtResource("pause")

[node name="SessionKeys" type="Node" parent="."]
script = ExtResource("keys")

[node name="HUD" type="CanvasLayer" parent="."]
script = ExtResource("hud")

[node name="DebugOverlay" type="Label" parent="HUD"]
offset_left = 16.0
offset_top = 12.0
offset_right = 1200.0
offset_bottom = 140.0
script = ExtResource("dbg")
'''
# replace shorthand ids in nodes' ExtResource("level")
text = head + body
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "core", "Main.tscn")
open(path, "w").write(text)
print("Wrote", os.path.normpath(path), "-", wall_n[0], "walls,", len(PILLARS), "pillars,", len(ENEMIES), "enemies")
