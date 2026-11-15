extends RefCounted

static func load_scene(res_path: String) -> Node3D:
	if not ResourceLoader.exists(res_path):
		return null
	var res: Resource = load(res_path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	return null

static func get_bounds(node: Node) -> Dictionary:
	var bounds := {"valid": false, "aabb": AABB()}
	_collect_aabb(node, Transform3D.IDENTITY, bounds)
	return bounds

static func fit_to_height(inst: Node3D, target_height: float) -> void:
	var bounds := get_bounds(inst)
	if bool(bounds["valid"]):
		var box: AABB = bounds["aabb"]
		var h: float = maxf(0.01, box.size.y)
		var sc: float = target_height / h
		inst.scale = Vector3(sc, sc, sc)
		inst.position.y -= box.position.y * sc

static func _collect_aabb(node: Node, xform: Transform3D, bounds: Dictionary) -> void:
	var cur: Transform3D = xform
	if node is Node3D:
		cur = xform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var local_box: AABB = cur * mi.get_aabb()
			if not bool(bounds["valid"]):
				bounds["aabb"] = local_box
				bounds["valid"] = true
			else:
				bounds["aabb"] = (bounds["aabb"] as AABB).merge(local_box)
	for child in node.get_children():
		_collect_aabb(child, cur, bounds)

static func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = find_skeleton(child)
		if found != null:
			return found
	return null

static func find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = find_anim_player(child)
		if found != null:
			return found
	return null

static func attach_ual_animations(char_root: Node3D, ual_path: String) -> AnimationPlayer:
	var char_skel: Skeleton3D = find_skeleton(char_root)
	var ual_inst: Node3D = load_scene(ual_path)
	if char_skel == null or ual_inst == null:
		if ual_inst != null:
			ual_inst.queue_free()
		return null

	var ual_ap: AnimationPlayer = find_anim_player(ual_inst)
	if ual_ap == null or not ual_ap.has_animation_library(""):
		ual_inst.queue_free()
		return null

	var src_lib: AnimationLibrary = ual_ap.get_animation_library("")
	var new_lib := AnimationLibrary.new()
	var skel_rel: String = String(char_root.get_path_to(char_skel))
	var loop_names := ["Idle_Loop", "Sword_Idle", "Walk_Loop", "Jog_Fwd_Loop", "Sprint_Loop", "Crouch_Idle_Loop", "Jump_Loop"]

	for anim_name in src_lib.get_animation_list():
		var src_anim: Animation = src_lib.get_animation(anim_name)
		var dup_anim: Animation = src_anim.duplicate() as Animation
		for t in range(dup_anim.get_track_count()):
			var old_path: NodePath = dup_anim.track_get_path(t)
			var sub: String = old_path.get_concatenated_subnames()
			if sub != "":
				dup_anim.track_set_path(t, NodePath(skel_rel + ":" + sub))
		if String(anim_name) in loop_names:
			dup_anim.loop_mode = Animation.LOOP_LINEAR
		new_lib.add_animation(anim_name, dup_anim)

	ual_inst.queue_free()

	var new_ap := AnimationPlayer.new()
	char_root.add_child(new_ap)
	new_ap.root_node = NodePath("..")
	new_ap.add_animation_library("", new_lib)
	return new_ap
