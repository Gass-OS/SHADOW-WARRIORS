extends Node3D

const ModelLoader = preload("res://scripts/ModelLoader.gd")

var torches: Array = []
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
	sky_mat.sky_horizon_color = Color(0.62, 0.74, 0.86)
	sky_mat.ground_bottom_color = Color(0.14, 0.18, 0.22)
	sky_mat.ground_horizon_color = Color(0.45, 0.54, 0.64)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.48, 0.60, 0.75)
	env.fog_density = 0.013

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_energy = 1.85
	sun.rotation_degrees = Vector3(-40, 36, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var rim_sky := DirectionalLight3D.new()
	rim_sky.light_color = Color(0.45, 0.70, 1.0)
	rim_sky.light_energy = 0.8
	rim_sky.rotation_degrees = Vector3(20, -145, 0)
	add_child(rim_sky)

func _place_prop(res_path: String, pos: Vector3, rot_y: float = 0.0, scl: float = 1.0, matte_wood: bool = false) -> Node3D:
	var n: Node3D = ModelLoader.load_scene(res_path)
	if n == null:
		return null
	n.position = pos
	n.rotation_degrees.y = rot_y
	n.scale = Vector3(scl, scl, scl)
	if matte_wood:
		_reduce_glare(n)
	add_child(n)
	return n

func _reduce_glare(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					dup.specular = 0.12
					dup.roughness = 0.90
					dup.metallic = 0.0
					mi.set_surface_override_material(s, dup)
	for child in node.get_children():
		_reduce_glare(child)

func _build_kasserine_quaternius_arena() -> void:
	# 1. Matte Wooden Bridge Deck + Back Railings + Cliff Foundation Below
	var plank_test: Node3D = ModelLoader.load_scene("res://assets/quaternius/village/Floor_WoodDark.gltf")
	if plank_test != null:
		var b := ModelLoader.get_bounds(plank_test)
		var tile_w: float = maxf(1.5, (b["aabb"] as AABB).size.x) if bool(b["valid"]) else 2.0
		plank_test.queue_free()
		for ix in range(-6, 7):
			for iz in [-1, 0, 1, 2]:
				_place_prop("res://assets/quaternius/village/Floor_WoodDark.gltf", Vector3(float(ix) * tile_w, 0.0, float(iz) * tile_w), 0.0, 1.0, true)
		for ix in range(-6, 7):
			_place_prop("res://assets/quaternius/village/Balcony_Simple_Straight.gltf", Vector3(float(ix) * tile_w, 0.0, -tile_w * 1.05), 180.0, 1.0, true)

	# Dark Canyon Gorge Foundation under the bridge so no empty sky shows below
	var gorge_mat := StandardMaterial3D.new()
	gorge_mat.albedo_color = Color(0.16, 0.14, 0.13)
	gorge_mat.roughness = 0.96
	var sub_wall := MeshInstance3D.new()
	var swm := BoxMesh.new()
	swm.size = Vector3(30.0, 6.0, 10.0)
	sub_wall.mesh = swm
	sub_wall.material_override = gorge_mat
	sub_wall.position = Vector3(0, -3.15, -2.5)
	add_child(sub_wall)

	# 2. Uncovered Kasserine Village Houses (Left & Right)
	for side in [-1.0, 1.0]:
		var hx: float = side * 6.8
		var hz: float = -7.2
		_place_prop("res://assets/quaternius/village/Wall_Plaster_Door_Round.gltf", Vector3(hx, -0.3, hz), side * -18.0, 1.0)
		_place_prop("res://assets/quaternius/village/Wall_Plaster_Window_Wide_Round.gltf", Vector3(hx + side * 3.6, -0.3, hz - 1.1), side * -18.0, 1.0)
		_place_prop("res://assets/quaternius/village/Roof_RoundTiles_4x4.gltf", Vector3(hx + side * 1.8, 3.0, hz - 0.5), side * -18.0, 1.05)

	# 3. Center Stone Arch & Distant Watchtower
	_place_prop("res://assets/quaternius/village/Wall_Arch.gltf", Vector3(0.0, -0.3, -6.5), 0.0, 1.1)
	_place_prop("res://assets/quaternius/village/Wall_Plaster_Straight.gltf", Vector3(3.4, -0.3, -13.5), -15.0, 1.0)
	_place_prop("res://assets/quaternius/village/Wall_Plaster_Window_Wide_Round.gltf", Vector3(3.4, 3.2, -13.5), -15.0, 1.0)
	_place_prop("res://assets/quaternius/village/Roof_Tower_RoundTiles.gltf", Vector3(3.4, 6.6, -13.5), -15.0, 1.05)

	# 4. Rocks & Pines pushed outside the houses so nothing blocks the buildings
	_place_prop("res://assets/quaternius/nature/Rock_Medium_1.gltf", Vector3(-11.8, -0.6, -5.0), 25.0, 1.5)
	_place_prop("res://assets/quaternius/nature/Rock_Medium_2.gltf", Vector3(11.8, -0.6, -5.0), -40.0, 1.6)
	_place_prop("res://assets/quaternius/nature/Rock_Medium_3.gltf", Vector3(-4.2, -0.8, -12.5), 10.0, 1.8)
	_place_prop("res://assets/quaternius/nature/Pine_1.gltf", Vector3(-10.2, -0.5, -10.5), 15.0, 1.4)
	_place_prop("res://assets/quaternius/nature/Pine_2.gltf", Vector3(10.5, -0.5, -11.0), -25.0, 1.5)
	_place_prop("res://assets/quaternius/nature/Pine_1.gltf", Vector3(-5.5, -0.8, -17.5), 40.0, 1.8)

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

	# 6. Crimson Banners & Proper Torch Posts (fixed SphereMesh height!)
	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.68, 0.10, 0.12)
	for hx in [-5.6, 5.6]:
		var banner := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.50, 1.8, 0.05)
		banner.mesh = bm
		banner.material_override = banner_mat
		banner.position = Vector3(hx, 2.2, -6.2)
		add_child(banner)
		banners.append(banner)

	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.22, 0.16, 0.11)
	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.72, 0.24)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.48, 0.12)
	ember_mat.emission_energy_multiplier = 3.2
	for tx in [-4.5, 4.5]:
		var post := MeshInstance3D.new()
		var ptm := CylinderMesh.new()
		ptm.top_radius = 0.07; ptm.bottom_radius = 0.09; ptm.height = 1.45
		post.mesh = ptm; post.material_override = post_mat
		post.position = Vector3(tx, 0.72, -2.1)
		add_child(post)

		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.12; om.height = 0.24
		orb.mesh = om
		orb.material_override = ember_mat
		orb.position = Vector3(tx, 1.50, -2.1)
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
