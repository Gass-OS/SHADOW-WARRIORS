extends Node3D

const ModelLoader = preload("res://scripts/ModelLoader.gd")

var torches: Array = []
var dust_motes: Array = []
var banners: Array = []
var time_acc: float = 0.0

func _ready() -> void:
	_build_environment()
	_build_kasserine_quaternius_arena()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.34, 0.56)
	sky_mat.sky_horizon_color = Color(0.64, 0.76, 0.88)
	sky_mat.ground_bottom_color = Color(0.16, 0.20, 0.25)
	sky_mat.ground_horizon_color = Color(0.55, 0.65, 0.76)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.48, 0.60, 0.76)
	env.fog_density = 0.014

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 2.0
	sun.rotation_degrees = Vector3(-38, 36, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var rim_sky := DirectionalLight3D.new()
	rim_sky.light_color = Color(0.42, 0.68, 1.0)
	rim_sky.light_energy = 0.75
	rim_sky.rotation_degrees = Vector3(20, -145, 0)
	add_child(rim_sky)

func _place_prop(res_path: String, pos: Vector3, rot_y: float = 0.0, scl: float = 1.0) -> Node3D:
	var n: Node3D = ModelLoader.load_scene(res_path)
	if n == null:
		return null
	n.position = pos
	n.rotation_degrees.y = rot_y
	n.scale = Vector3(scl, scl, scl)
	add_child(n)
	return n

func _build_kasserine_quaternius_arena() -> void:
	# 1. Wooden Bridge Deck & Railings using Quaternius Medieval Village assets
	var plank_test: Node3D = ModelLoader.load_scene("res://assets/quaternius/village/Floor_WoodDark.gltf")
	if plank_test != null:
		var b := ModelLoader.get_bounds(plank_test)
		var tile_w: float = maxf(1.5, (b["aabb"] as AABB).size.x) if bool(b["valid"]) else 2.0
		plank_test.queue_free()
		for ix in range(-5, 6):
			for iz in [-1, 0, 1]:
				_place_prop("res://assets/quaternius/village/Floor_WoodDark.gltf", Vector3(float(ix) * tile_w, 0.0, float(iz) * tile_w))
		for ix in range(-5, 6):
			_place_prop("res://assets/quaternius/village/Balcony_Simple_Straight.gltf", Vector3(float(ix) * tile_w, 0.0, -tile_w * 1.15), 180.0)
	else:
		var fallback := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(22.0, 0.4, 5.5)
		fallback.mesh = bm
		fallback.position = Vector3(0, -0.2, 0)
		add_child(fallback)

	# 2. Left & Right Kasserine Village Houses
	for side in [-1.0, 1.0]:
		var hx: float = side * 7.8
		var hz: float = -8.2
		_place_prop("res://assets/quaternius/village/Wall_Plaster_Door_Round.gltf", Vector3(hx, -0.4, hz), side * -18.0, 1.0)
		_place_prop("res://assets/quaternius/village/Wall_Plaster_Window_Wide_Round.gltf", Vector3(hx + side * 3.8, -0.4, hz - 1.2), side * -18.0, 1.0)
		_place_prop("res://assets/quaternius/village/Roof_RoundTiles_4x4.gltf", Vector3(hx + side * 1.8, 3.2, hz - 0.5), side * -18.0, 1.15)

	# 3. Center-Back Watchtower & Stone Arch
	_place_prop("res://assets/quaternius/village/Wall_Arch.gltf", Vector3(0.0, -0.4, -7.2), 0.0, 1.1)
	_place_prop("res://assets/quaternius/village/Wall_Plaster_Straight.gltf", Vector3(3.8, -0.4, -14.0), -15.0, 1.0)
	_place_prop("res://assets/quaternius/village/Wall_Plaster_Window_Wide_Round.gltf", Vector3(3.8, 3.1, -14.0), -15.0, 1.0)
	_place_prop("res://assets/quaternius/village/Roof_Tower_RoundTiles.gltf", Vector3(3.8, 6.6, -14.0), -15.0, 1.1)

	# 4. Quaternius Rocks & Pines framing the Mountain Pass
	_place_prop("res://assets/quaternius/nature/Rock_Medium_1.gltf", Vector3(-9.5, -0.5, -4.5), 25.0, 2.2)
	_place_prop("res://assets/quaternius/nature/Rock_Medium_2.gltf", Vector3(9.5, -0.5, -4.5), -40.0, 2.4)
	_place_prop("res://assets/quaternius/nature/Rock_Medium_3.gltf", Vector3(-3.8, -0.8, -11.5), 10.0, 3.0)
	_place_prop("res://assets/quaternius/nature/Pine_1.gltf", Vector3(-11.2, -0.5, -10.0), 15.0, 1.45)
	_place_prop("res://assets/quaternius/nature/Pine_2.gltf", Vector3(11.0, -0.5, -11.0), -25.0, 1.55)
	_place_prop("res://assets/quaternius/nature/Pine_1.gltf", Vector3(-5.5, -0.8, -17.5), 40.0, 1.9)

	# 5. Distant Mountain Cliffs
	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.24, 0.30, 0.38)
	cliff_mat.roughness = 0.94
	for i in range(11):
		var peak := MeshInstance3D.new()
		var pkm := CylinderMesh.new()
		pkm.top_radius = 0.5 + float(i % 2) * 0.7
		pkm.bottom_radius = 4.8 + float(i % 3) * 2.2
		pkm.height = 15.0 + float(i % 4) * 4.5
		peak.mesh = pkm
		peak.material_override = cliff_mat
		peak.position = Vector3(float(i - 5) * 5.2, 5.5, -27.0 - float(i % 3) * 6.0)
		add_child(peak)

	# 6. Crimson Banners & Torch Braziers
	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.68, 0.10, 0.12)
	for hx in [-6.0, 6.0]:
		var banner := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 1.9, 0.05)
		banner.mesh = bm
		banner.material_override = banner_mat
		banner.position = Vector3(hx, 2.1, -6.2)
		add_child(banner)
		banners.append(banner)

	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.72, 0.24)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.48, 0.12)
	ember_mat.emission_energy_multiplier = 3.2
	for tx in [-4.5, 4.5]:
		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.16
		orb.mesh = om
		orb.material_override = ember_mat
		orb.position = Vector3(tx, 1.35, -2.2)
		add_child(orb)
		var lt := OmniLight3D.new()
		lt.light_color = Color(1.0, 0.56, 0.18)
		lt.light_energy = 2.0
		lt.omni_range = 8.0
		lt.position = orb.position
		add_child(lt)
		torches.append(lt)

func _process(delta: float) -> void:
	time_acc += delta
	for i in torches.size():
		var lt: OmniLight3D = torches[i]
		lt.light_energy = 1.9 + sin(time_acc * 12.0 + float(i) * 2.1) * 0.45
	for i in banners.size():
		var b: MeshInstance3D = banners[i]
		b.rotation.x = sin(time_acc * 3.0 + float(i)) * 0.08
