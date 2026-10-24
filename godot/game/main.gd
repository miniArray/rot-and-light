extends Node3D
## Root of the slice. Applies the look to the sky, moon, and ground, reloads
## the tuning and the look on request, and in debug builds starts the
## scripted demo when the game runs with `-- --demo`.

@export var tuning: Tuning
@export var look: Look

## An APK cannot read the project folder, so on Android the tuning and the
## look come from these files when they exist, at start and on
## reload_tuning. They are in the app's own external files folder: `adb push`
## can write it, the app needs no permission to read it. The package id
## matches export_presets.cfg.
const ANDROID_FILES := "/sdcard/Android/data/dev.rotandlight.prototype/files/"

@onready var _environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
@onready var _moon: DirectionalLight3D = $Sun
@onready var _ground: ShaderMaterial = ($Ground/Mesh as MeshInstance3D).mesh.surface_get_material(0)


func _ready() -> void:
	look.changed.connect(_apply_look)
	_apply_look()
	if OS.has_feature("android"):
		_reload()
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--demo"):
		var demo: Node = load("res://debug/demo.gd").new()
		demo.name = "Demo"
		add_child(demo)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload_tuning"):
		_reload()


## Reloads the tuning and the look. On Android, only a file pushed to
## ANDROID_FILES replaces the one in the APK.
func _reload() -> void:
	_reload_into(tuning, "tuning.tres")
	_reload_into(look, "look.tres")


func _reload_into(current: Resource, file: String) -> void:
	var path := current.resource_path
	if OS.has_feature("android"):
		path = ANDROID_FILES + file
		if not FileAccess.file_exists(path):
			return
	var fresh := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if fresh == null or fresh.get_script() != current.get_script():
		push_error("main: cannot load %s; kept the old one" % path)
		return
	current.copy_from(fresh)
	print("main: reloaded %s" % path)


func _apply_look() -> void:
	var sky := _environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = look.sky_top
	sky.sky_horizon_color = look.sky_horizon
	sky.ground_horizon_color = look.sky_horizon
	sky.ground_bottom_color = look.sky_top
	_environment.glow_enabled = look.bloom_strength > 0.0
	_environment.glow_intensity = look.bloom_strength
	_environment.glow_hdr_threshold = look.bloom_threshold
	_moon.light_color = look.moon_colour
	_moon.light_energy = look.moon_energy
	_moon.shadow_enabled = look.moon_shadows
	look.apply_bands(_ground)
	_ground.set_shader_parameter("base_colour", look.ground)
	_ground.set_shader_parameter("line_colour", look.ground_lines)
	_ground.set_shader_parameter("cell_size", look.ground_cell)
