extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var wind_time := 0.0
var tree_roots: Array[Node3D] = []
var cloud_roots: Array[Node3D] = []


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_player()
	_build_camera()
	_build_test_forest()


func _process(delta: float) -> void:
	wind_time += delta
	_update_camera(delta)
	_update_wind_effects()


func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8dbbd4")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d6e8e1")
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color("#ffe3ae")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(28.0, 28.0)
	ground.mesh = mesh
	ground.material_override = _material(Color("#6f9b62"))
	add_child(ground)

	var collision := StaticBody3D.new()
	collision.name = "GroundCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(28.0, 0.2, 28.0)
	shape.shape = box
	shape.position.y = -0.1
	collision.add_child(shape)
	add_child(collision)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Trainer"
	player.position = Vector3(0.0, 0.0, 2.0)
	player.set_script(load("res://scripts/player.gd"))

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.0
	collision.shape = capsule
	collision.position.y = 0.5
	player.add_child(collision)

	var sprite := Sprite3D.new()
	sprite.name = "TrainerSprite"
	sprite.texture = _make_trainer_texture()
	sprite.pixel_size = 0.045
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position.y = 0.78
	player.add_child(sprite)

	var shadow := MeshInstance3D.new()
	shadow.name = "PixelShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.34
	shadow_mesh.bottom_radius = 0.34
	shadow_mesh.height = 0.015
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.01
	shadow.material_override = _material(Color(0.08, 0.12, 0.16, 0.35), true)
	player.add_child(shadow)

	add_child(player)
	player.visual = sprite


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ExplorationCamera"
	camera.position = Vector3(6.5, 6.5, 6.5)
	camera.current = true
	add_child(camera)
	camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _update_camera(delta: float) -> void:
	if not camera or not player:
		return
	var desired_position := player.global_position + Vector3(6.5, 6.5, 6.5)
	camera.global_position = camera.global_position.lerp(desired_position, 1.0 - exp(-6.0 * delta))
	camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _build_test_forest() -> void:
	for position in [Vector3(-4.0, 0.0, -3.0), Vector3(3.0, 0.0, -4.0), Vector3(-5.0, 0.0, 4.0), Vector3(5.0, 0.0, 4.0), Vector3(1.5, 0.0, 6.0)]:
		_create_tree(position)

	for position in [Vector3(-3.0, 0.0, 0.0), Vector3(4.0, 0.0, 1.0), Vector3(-1.0, 0.0, -5.0)]:
		_create_cloud(position + Vector3(0.0, 5.0, 0.0))


func _create_tree(position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	add_child(root)
	tree_roots.append(root)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 1.5
	trunk.mesh = trunk_mesh
	trunk.position.y = 0.75
	trunk.material_override = _material(Color("#6e4934"))
	root.add_child(trunk)

	var canopy := MeshInstance3D.new()
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 1.0
	canopy_mesh.height = 1.7
	canopy.mesh = canopy_mesh
	canopy.scale = Vector3(1.0, 0.85, 1.0)
	canopy.position.y = 1.75
	canopy.material_override = _material(Color("#326b4d"))
	root.add_child(canopy)


func _create_cloud(position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	add_child(root)
	cloud_roots.append(root)

	var cloud := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.9
	mesh.height = 0.65
	cloud.mesh = mesh
	cloud.scale = Vector3(2.2, 0.4, 1.0)
	cloud.material_override = _material(Color(1.0, 1.0, 1.0, 0.72), true)
	root.add_child(cloud)


func _update_wind_effects() -> void:
	for index in tree_roots.size():
		var root := tree_roots[index]
		root.rotation.z = sin(wind_time * 1.5 + float(index)) * 0.025
		root.rotation.x = cos(wind_time * 1.1 + float(index) * 0.7) * 0.018

	for index in cloud_roots.size():
		var cloud := cloud_roots[index]
		cloud.position.x += 0.0025
		if cloud.position.x > 9.0:
			cloud.position.x = -9.0


func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _make_trainer_texture() -> ImageTexture:
	var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_fill_rect(image, Rect2i(5, 2, 6, 2), Color("#26314a"))
	_fill_rect(image, Rect2i(4, 4, 8, 5), Color("#e5a979"))
	_fill_rect(image, Rect2i(5, 3, 6, 2), Color("#26314a"))
	_fill_rect(image, Rect2i(4, 9, 8, 6), Color("#d84e54"))
	_fill_rect(image, Rect2i(3, 10, 2, 4), Color("#e5a979"))
	_fill_rect(image, Rect2i(11, 10, 2, 4), Color("#e5a979"))
	_fill_rect(image, Rect2i(5, 15, 3, 6), Color("#334d83"))
	_fill_rect(image, Rect2i(8, 15, 3, 6), Color("#334d83"))
	_fill_rect(image, Rect2i(4, 21, 4, 2), Color("#252b3b"))
	_fill_rect(image, Rect2i(8, 21, 4, 2), Color("#252b3b"))
	image.set_pixel(6, 6, Color("#202332"))
	image.set_pixel(9, 6, Color("#202332"))
	return ImageTexture.create_from_image(image)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			image.set_pixel(x, y, color)

