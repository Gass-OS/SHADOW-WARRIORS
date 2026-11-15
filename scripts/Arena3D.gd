extends Node3D

var torches: Array = []
var dust_motes: Array = []
var time_acc := 0.0

func _ready() -> void:
	_build_environment()
	_build_kasserine_stage()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.09, 0.08)
	sky_mat.sky_horizon_color = Color(0.68, 0.35, 0.18)
	sky_mat.ground_bottom_color = Color(0.18, 0.11, 0.08)
	sky_mat.ground_horizon_color = Color(0.45, 0.25, 0.14)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.42, 0.25, 0.16)
	env.fog_density = 0.014

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.78, 0.52)
	sun.light_energy = 1.9
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _build_kasserine_stage() -> void:
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.52, 0.36, 0.23)
	sand_mat.roughness = 0.92
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.62, 0.50, 0.37)
	stone_mat.roughness = 0.85
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.27, 0.18, 0.14)
	rock_mat.roughness = 0.95

	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 15.0
	floor_mesh.bottom_radius = 16.5
	floor_mesh.height = 1.0
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.material_override = sand_mat
	floor_node.position = Vector3(0, -0.5, 0)
	add_child(floor_node)

	for i in range(-3, 4, 2):
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(1.0, 4.5 + absf(float(i)) * 0.35, 1.0)
		var pillar := MeshInstance3D.new()
		pillar.mesh = p_mesh
		pillar.material_override = stone_mat
		pillar.position = Vector3(float(i) * 3.0, 2.2, -6.2)
		add_child(pillar)

	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(14.5, 0.85, 1.1)
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.material_override = stone_mat
	beam.position = Vector3(0, 5.1, -6.2)
	add_child(beam)

	for i in range(9):
		var peak_mesh := CylinderMesh.new()
		peak_mesh.top_radius = 0.0
		peak_mesh.bottom_radius = 4.2 + float(i % 3) * 1.8
		peak_mesh.height = 9.0 + float(i % 4) * 2.8
		var peak := MeshInstance3D.new()
		peak.mesh = peak_mesh
		peak.material_override = rock_mat
		peak.position = Vector3(float(i - 4) * 6.0, 4.0, -17.0 - float(i % 2) * 4.5)
		add_child(peak)

	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.65, 0.18)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.45, 0.08)
	ember_mat.emission_energy_multiplier = 3.0

	for x_pos in [-5.2, 5.2]:
		var stand_mesh := CylinderMesh.new()
		stand_mesh.top_radius = 0.24
		stand_mesh.bottom_radius = 0.34
		stand_mesh.height = 1.5
		var stand := MeshInstance3D.new()
		stand.mesh = stand_mesh
		stand.material_override = rock_mat
		stand.position = Vector3(x_pos, 0.75, -4.4)
		add_child(stand)

		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.22
		var orb := MeshInstance3D.new()
		orb.mesh = orb_mesh
		orb.material_override = ember_mat
		orb.position = Vector3(x_pos, 1.72, -4.4)
		add_child(orb)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.52, 0.16)
		light.light_energy = 2.6
		light.omni_range = 10.5
		light.position = orb.position
		add_child(light)
		torches.append(light)

	var dust_mesh := BoxMesh.new()
	dust_mesh.size = Vector3(0.06, 0.06, 0.06)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.95, 0.78, 0.52)
	dust_mat.emission_enabled = true
	dust_mat.emission = Color(0.85, 0.62, 0.3)
	for i in range(36):
		var mote := MeshInstance3D.new()
		mote.mesh = dust_mesh
		mote.material_override = dust_mat
		mote.position = Vector3(randf_range(-10.0, 10.0), randf_range(0.3, 4.5), randf_range(-5.0, 3.0))
		add_child(mote)
		dust_motes.append(mote)

func _process(delta: float) -> void:
	time_acc += delta
	for i in torches.size():
		var lt: OmniLight3D = torches[i]
		lt.light_energy = 2.4 + sin(time_acc * 11.0 + float(i) * 2.5) * 0.5
	for mote in dust_motes:
		var m: MeshInstance3D = mote
		m.position.x += delta * 1.35
		if m.position.x > 10.5:
			m.position.x = -10.5
