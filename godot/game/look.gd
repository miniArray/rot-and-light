class_name Look
extends Resource
## Every look value of the slice: tone bands, ink outlines, palette, glow, and
## the burning and withering states. The values live only in res://look.tres;
## this script holds their types and meaning. The game shares one instance.
## Edit that file while the game runs and press reload_tuning
## (F5 / gamepad Back / RELOAD) to apply it with the tuning.
##
## Nodes that draw something read the values they need and connect to
## [signal Resource.changed] to apply them again after a reload.

@export_group("Tone bands")
## Lit amount (N·L × shadow, 0 to 1) where the shadow band ends and the
## middle band starts.
@export_range(0.0, 1.0) var band_low: float
## Lit amount where the middle band ends and the lit band starts.
@export_range(0.0, 1.0) var band_high: float
## Brightness of the middle band, from 0 (as dark as shadow) to 1 (as bright
## as lit).
@export_range(0.0, 1.0) var band_mid_level: float
## Half-width of the blend between two bands, in lit amount. Small is hard.
@export_range(0.0, 0.2) var band_softness: float
## Light in the shadow band, as a colour. Every surface gets it; the sun adds
## on top. Cold, so shadows belong to the rot.
@export var shadow_tint: Color
## The moon: the scene's directional light.
@export var moon_colour: Color
@export var moon_energy: float
## Moon shadows. Off is cheaper on a phone.
@export var moon_shadows: bool

@export_group("Ink outline")
## Ink colour. Alpha is the strength.
@export var ink_colour: Color
## Line width in pixels at a 1080-pixel-high screen. It scales with the
## screen height.
@export_range(0.5, 6.0) var ink_width: float
## A depth step bigger than this fraction of the distance draws a line.
## Smaller draws more lines.
@export_range(0.001, 0.5) var ink_depth_threshold: float
## A bend sharper than this between two neighbour normals draws a line, in
## degrees. Forward+ only: the Mobile renderer has no normal buffer, so it
## draws depth lines only.
@export_range(1.0, 90.0) var ink_crease_degrees: float
## Lines fade out between these distances from the camera, metres.
@export var ink_fade_start: float
@export var ink_fade_end: float

@export_group("Sky and glow")
@export var sky_top: Color
@export var sky_horizon: Color
## Bloom around bright things (caps, flames, burning minions). 0 turns it off,
## which is cheaper on a phone.
@export_range(0.0, 4.0) var bloom_strength: float
## Only light brighter than this blooms.
@export_range(0.0, 4.0) var bloom_threshold: float

@export_group("Rot")
## The lord's robe and his glowing crown cap.
@export var lord_robe: Color
@export var lord_cap: Color
@export var lord_eyes: Color
## Emission strength of the lord's eyes, 0 for none. His crown glows like a
## minion's cap.
@export_range(0.0, 8.0) var lord_glow: float
## The minion stalk and cap.
@export var minion_stalk: Color
@export var minion_cap: Color
## Colour and strength of the glow of a healthy minion's cap (and the
## lord's crown): bright in a few spots on the dome, faint elsewhere.
@export var cap_glow: Color
@export_range(0.0, 8.0) var cap_glow_strength: float
## The spore cloud ring around the lord.
@export var spore_colour: Color
@export_range(0.0, 1.0) var spore_fill_alpha: float
@export_range(0.0, 1.0) var spore_edge_alpha: float
## The ground where a lamp went out: two mottled rot colours, the glowing
## spore specks in it, and how many little caps grow on it.
@export var rot_deep: Color
@export var rot_bloom: Color
@export var rot_speck: Color
@export_range(0.0, 8.0) var rot_speck_strength: float
@export_range(0, 64) var rot_caps: int

@export_group("Light")
## Colour and energy of the lamp light on things inside it. The light has a
## hard edge: full inside the lamp's radius, none outside.
@export var lamp_colour: Color
@export var lamp_energy: float
## Light on the far side of a lit thing, 0 to 1 of the lit side.
@export_range(0.0, 1.0) var lamp_back_level: float
## The lit disc on the ground: its fill and its hard rim.
@export var lamp_ground: Color
@export_range(0.0, 1.0) var lamp_ground_alpha: float
@export var lamp_rim: Color
## Width of the bright rim at the edge of the lit disc, metres.
@export var lamp_rim_width: float
## The flame on top of the post.
@export var flame: Color
@export_range(0.0, 8.0) var flame_glow: float
@export var lamp_iron: Color

@export_group("Burning")
## Colour of a burning minion's rim, cap, and embers.
@export var burn_colour: Color
## Strength of the bright rim around a burning minion.
@export_range(0.0, 8.0) var burn_rim: float
## Strength of the glow over a burning minion's whole body.
@export_range(0.0, 4.0) var burn_body: float
## Flicker speed of the burn, times per second.
@export var burn_flicker_hz: float
## How far a burning minion shakes, metres.
@export var burn_shake: float
## Embers that fly off a burning minion per second.
@export_range(0, 64) var ember_rate: int

@export_group("Withering")
## The grey-brown a withering minion fades toward.
@export var wither_colour: Color
## How much of its colour a fully withered minion loses, 0 to 1.
@export_range(0.0, 1.0) var wither_fade: float
## How far a fully withered minion leans forward, degrees.
@export var wither_droop_degrees: float
## Size of a fully withered minion, 1 = no change.
@export_range(0.2, 1.0) var wither_shrink: float

@export_group("World")
@export var ground: Color
@export var ground_lines: Color
## Size of a ground grid cell, metres.
@export var ground_cell: float
@export var crate_wood: Color
## Colour a crate flashes when it is hit.
@export var crate_hit: Color


const TOON := preload("res://game/toon.gdshader")
const MINION := preload("res://game/minion.gdshader")

## Shared toon materials by their recipe, see material().
var _materials := {}
## Shared minion.gdshader materials by part, see minion_material().
var _parts := {}


## Copies every exported value from [param other] into this instance and
## emits [signal Resource.changed]. Nodes keep their reference to this one.
func copy_from(other: Look) -> void:
	for property in get_property_list():
		var exported := PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE
		if property.usage & exported == exported:
			set(property.name, other.get(property.name))
	for key in _materials:
		_fill(_materials[key], key.split("|"))
	for part in _parts:
		_fill_part(_parts[part], part)
	emit_changed()


## Sets the tone band uniforms of a material whose shader includes
## toon.gdshaderinc.
func apply_bands(material: ShaderMaterial) -> void:
	material.set_shader_parameter("band_low", band_low)
	material.set_shader_parameter("band_high", band_high)
	material.set_shader_parameter("band_mid_level", band_mid_level)
	material.set_shader_parameter("band_softness", band_softness)
	material.set_shader_parameter("shadow_tint", shadow_tint)
	material.set_shader_parameter("lamp_back_level", lamp_back_level)


## The shared toon material (toon.gdshader) whose colour is the look value
## named [param albedo], such as &"crate_wood". [param glow] names a glow
## colour and [param strength] its strength; [param flash] names the colour
## the per-instance `flash` parameter blends to. Everything that asks for the
## same recipe shares one material, so the renderer can batch it; a reload
## updates it in place.
func material(albedo: StringName, glow := &"", strength := &"", flash := &"") -> ShaderMaterial:
	var key := "|".join(PackedStringArray([albedo, glow, strength, flash]))
	if not _materials.has(key):
		var made := ShaderMaterial.new()
		made.shader = TOON
		_fill(made, key.split("|"))
		_materials[key] = made
	return _materials[key]


## A shared minion.gdshader material: &"stalk" and &"cap" for minions,
## &"crown" for the lord's cap.
func minion_material(part: StringName) -> ShaderMaterial:
	if not _parts.has(part):
		var made := ShaderMaterial.new()
		made.shader = MINION
		_fill_part(made, part)
		_parts[part] = made
	return _parts[part]


func _fill_part(made: ShaderMaterial, part: StringName) -> void:
	var colours := {&"stalk": minion_stalk, &"cap": minion_cap, &"crown": lord_cap}
	apply_bands(made)
	made.set_shader_parameter("albedo", colours[part])
	made.set_shader_parameter("glow", cap_glow)
	made.set_shader_parameter("glow_strength", 0.0 if part == &"stalk" else cap_glow_strength)
	made.set_shader_parameter("burn_colour", burn_colour)
	made.set_shader_parameter("burn_rim", burn_rim)
	made.set_shader_parameter("burn_body", burn_body)
	made.set_shader_parameter("burn_flicker_hz", burn_flicker_hz)
	made.set_shader_parameter("wither_colour", wither_colour)
	made.set_shader_parameter("wither_fade", wither_fade)


func _fill(made: ShaderMaterial, recipe: PackedStringArray) -> void:
	apply_bands(made)
	made.set_shader_parameter("albedo", get(recipe[0]))
	made.set_shader_parameter("glow", get(recipe[1]) if recipe[1] else Color.BLACK)
	made.set_shader_parameter("glow_strength", get(recipe[2]) if recipe[2] else 0.0)
	made.set_shader_parameter("flash_colour", get(recipe[3]) if recipe[3] else Color.WHITE)
