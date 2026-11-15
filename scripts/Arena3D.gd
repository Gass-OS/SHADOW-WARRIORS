extends Node3D

var torches: Array = []
var dust_motes: Array = []
var banners: Array = []
var time_acc: float = 0.0

func _ready() -> void:
	_build_environment()
	_build_kasserine_bridge_arena()

func _make_normal_tex(freq: float, strength: float) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.frequency = freq
	var img: Image = noise.get_image(128, 128)
	img.bump_map_to_normal_map(strength)
	return ImageTexture.create_from_image(img)

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.32, 0.52)
	sky_mat.sky_horizon_color = Color(0.62, 0.74, 0.85)
	sky_mat.ground_bottom_color = Color(0.16, 0.20, 0.25)
	sky_mat.ground_horizon_color = Color(0.55, 0.65, 0.76)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.45, 0.58, 0.74)
	env.fog_density = 0.016

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 1.95
	sun.rotation_degrees = Vector3(-36, 38, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var rim_sky := DirectionalLight3D.new()
	rim_sky.light_color = Color(0.42, 0.68, 1.0)
	rim_sky.light_energy = 0.75
	rim_sky.rotation_degrees = Vector3(20, -145, 0)
	add_child(rim_sky)

func _build_kasserine_bridge_arena() -> void:
	var wood_norm := _make_normal_tex(0.14, 3.0)
	var stone_norm := _make_normal_tex(0.08, 4.0)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.38, 0.27, 0.18)
	wood_mat.roughness = 0.88
	wood_mat.normal_enabled = true
	wood_mat.normal_texture = wood_norm

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.56, 0.48, 0.38)
	stone_mat.roughness = 0.86
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = stone_norm

	var cliff_mat := StandardMaterial3D.new()
	cliff_mat.albedo_color = Color(0.24, 0.30, 0.36)
	cliff_mat.roughness = 0.94
	cliff_mat.normal_enabled = true
	cliff_mat.normal_texture = stone_norm

	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.68, 0.55, 0.34)
	roof_mat.roughness = 0.9

	var banner_mat := StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.68, 0.10, 0.12)
	banner_mat.roughness = 0.75

	# Timber Bridge Planks (Foreground Arena Deck)
	for i in range(-18, 19):
		var plank := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.54, 0.25, 5.4)
		plank.mesh = pm
		plank.material_override = wood_mat
		plank.position = Vector3(float(i) * 0.58, -0.14 + (float(i % 2) * 0.015), 0.0)
		add_child(plank)

	# Bridge Wooden Railing & Posts behind fighters
	var rail := MeshInstance3D.new()
	var rail_m := BoxMesh.new()
	rail_m.size = Vector3(22.0, 0.16, 0.16)
	rail.mesh = rail_m
	rail.material_override = wood_mat
	rail.position = Vector3(0, 1.15, -2.5)
	add_child(rail)

	var rail2 := MeshInstance3D.new()
	rail2.mesh = rail_m
	rail2.material_override = wood_mat
	rail2.position = Vector3(0, 0.62, -2.5)
	add_child(rail2)

	for i in range(-4, 5):
		var post := MeshInstance3D.new()
		var post_m := BoxMesh.new()
		post_m.size = Vector3(0.22, 1.45, 0.22)
		post.mesh = post_m
		post.material_override = wood_mat
		post.position = Vector3(float(i) * 2.5, 0.68, -2.5)
		add_child(post)

	# Midground Kasserine Village Structures & Watchtower
	for hx in [-7.8, 7.6]:
		var house := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(4.2, 3.0, 3.6)
		house.mesh = hm
		house.material_override = stone_mat
		house.position = Vector3(hx, 0.8, -8.5)
		add_child(house)

		var roof := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.0
		rm.bottom_radius = 3.2
		rm.height = 1.8
		rm.radial_segments = 4
		roof.mesh = rm
		roof.material_override = roof_mat
		roof.rotation_degrees = Vector3(0, 45, 0)
		roof.position = Vector3(hx, 3.2, -8.5)
		add_child(roof)

		var banner := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 1.9, 0.05)
		banner.mesh = bm
		banner.material_override = banner_mat
		banner.position = Vector3(hx * 0.72, 1.6, -6.5)
		add_child(banner)
		banners.append(banner)

	# Distant Watchtower Silhouette
	var tower := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.8, 7.5, 1.8)
	tower.mesh = tm
	tower.material_override = cliff_mat
	tower.position = Vector3(3.4, 3.0, -16.0)
	add_child(tower)

	# Deep Misty Chaambi Mountain Spires
	for i in range(11):
		var peak := MeshInstance3D.new()
		var pkm := CylinderMesh.new()
		pkm.top_radius = 0.4 + float(i % 2) * 0.6
		pkm.bottom_radius = 4.6 + float(i % 3) * 2.1
		pkm.height = 14.0 + float(i % 4) * 4.5
		peak.mesh = pkm
		peak.material_override = cliff_mat
		peak.position = Vector3(float(i - 5) * 5.2, 5.2, -26.0 - float(i % 3) * 6.0)
		add_child(peak)

	# Torch Braziers
	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.72, 0.24)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.48, 0.12)
	ember_mat.emission_energy_multiplier = 3.2

	for tx in [-4.5, 4.5]:
		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.18
		orb.mesh = om
		orb.material_override = ember_mat
		orb.position = Vector3(tx, 1.48, -2.5)
		add_child(orb)

		var lt := OmniLight3D.new()
		lt.light_color = Color(1.0, 0.56, 0.18)
		lt.light_energy = 2.2
		lt.omni_range = 8.5
		lt.position = orb.position
		add_child(lt)
		torches.append(lt)

	# Drifting Wind Motes
	var mote_m := BoxMesh.new()
	mote_m.size = Vector3(0.05, 0.05, 0.05)
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(0.95, 0.90, 0.75)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(0.85, 0.80, 0.65)
	for i in range(36):
		var mote := MeshInstance3D.new()
		mote.mesh = mote_m
		mote.material_override = mote_mat
		mote.position = Vector3(randf_range(-10.0, 10.0), randf_range(0.3, 4.2), randf_range(-4.0, 2.5))
		add_child(mote)
		dust_motes.append(mote)

func _process(delta: float) -> void:
	time_acc += delta
	for i in torches.size():
		var lt: OmniLight3D = torches[i]
		lt.light_energy = 2.0 + sin(time_acc * 12.0 + float(i) * 2.1) * 0.45
	for i in banners.size():
		var b: MeshInstance3D = banners[i]
		b.rotation.x = sin(time_acc * 3.0 + float(i)) * 0.08
	for mote in dust_motes:
		var m: MeshInstance3D = mote
		m.position.x += delta * 1.4
		if m.position.x > 10.5:
			m.position.x = -10.5
