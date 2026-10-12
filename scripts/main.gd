extends Node3D

const TILE_SIZE := 0.5
const MAP_RADIUS := 16
const GRID_SCRIPT = preload("res://scripts/world_grid.gd")

var world_grid
var player: CharacterBody3D
var camera: Camera3D
var wind_time := 0.0
var tree_roots: Array[Node3D] = []
var cloud_roots: Array[Node3D] = []


func _ready() -> void:
	world_grid = GRID_SCRIPT.new()
	world_grid.name = "WorldGrid"
	world_grid.tile_size = TILE_SIZE
	add_child(world_grid)
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
	var tiles := Node3D.new()
	tiles.name = "PixelGroundTiles"
	add_child(tiles)

	for x in range(-MAP_RADIUS, MAP_RADIUS):
		for z in range(-MAP_RADIUS, MAP_RADIUS):
			var tile := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			mesh.size = Vector2(TILE_SIZE, TILE_SIZE)
			tile.mesh = mesh
			tile.rotation_degrees.x = -90.0
			tile.position = world_grid.cell_to_world(Vector2i(x, z), -0.025)
			tile.material_override = _pixel_material(_make_grass_tile_texture(x * 31 + z * 17))
			tiles.add_child(tile)

	var collision := StaticBody3D.new()
	collision.name = "GroundCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(MAP_RADIUS * 2.0 * TILE_SIZE, 0.2, MAP_RADIUS * 2.0 * TILE_SIZE)
	shape.shape = box
	shape.position.y = -0.1
	collision.add_child(shape)
	add_child(collision)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Trainer"
	player.position = world_grid.cell_to_world(Vector2i(0, 4))
	player.set_script(load("res://scripts/player.gd"))

	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE_SIZE * 0.72, 1.0, TILE_SIZE * 0.72)
	collision.shape = box
	collision.position.y = 0.5
	player.add_child(collision)

	var sprite := Sprite3D.new()
	sprite.name = "TrainerSprite"
	sprite.texture = _make_trainer_texture(0)
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
	shadow.material_override = _transparent_material(Color(0.08, 0.12, 0.16, 0.35))
	player.add_child(shadow)

	add_child(player)
	var walk_frames: Array[Texture2D] = [
		_make_trainer_texture(1),
		_make_trainer_texture(0),
		_make_trainer_texture(2),
		_make_trainer_texture(0),
	]
	player.call("configure_visual", sprite, _make_trainer_texture(0), walk_frames)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ExplorationCamera"
	camera.position = Vector3(0.0, 6.5, 8.5)
	camera.current = true
	add_child(camera)
	camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _update_camera(delta: float) -> void:
	if not camera or not player:
		return
	var desired_position := player.global_position + Vector3(0.0, 6.5, 8.5)
	camera.global_position = camera.global_position.lerp(desired_position, 1.0 - exp(-6.0 * delta))
	camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _build_test_forest() -> void:
	var tree_origins := [
		Vector2i(-8, -6),
		Vector2i(6, -8),
		Vector2i(-10, 7),
		Vector2i(8, 8),
		Vector2i(3, 12),
	]
	for origin in tree_origins:
		_create_tree(origin, Vector2i(2, 2))

	var cloud_positions := [Vector3(-3.0, 5.0, 0.0), Vector3(4.0, 5.5, 1.0), Vector3(-1.0, 5.2, -5.0)]
	for position in cloud_positions:
		_create_cloud(position)


func _create_tree(origin_cell: Vector2i, footprint: Vector2i) -> void:
	if not world_grid.occupy_rect(origin_cell, footprint, "tree"):
		return

	var root := Node3D.new()
	root.name = "Tree_%d_%d" % [origin_cell.x, origin_cell.y]
	root.position = world_grid.rect_center_world(origin_cell, footprint)
	add_child(root)
	tree_roots.append(root)

	var sprite := Sprite3D.new()
	sprite.name = "TreeSprite"
	sprite.texture = _make_tree_texture()
	sprite.pixel_size = 0.045
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position.y = 0.95
	root.add_child(sprite)

	var body := StaticBody3D.new()
	body.name = "OccupiedFootprint"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x * TILE_SIZE * 0.9, 1.8, footprint.y * TILE_SIZE * 0.9)
	collision.shape = box
	collision.position.y = 0.9
	body.add_child(collision)
	root.add_child(body)


func _create_cloud(position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Cloud"
	root.position = position
	add_child(root)
	cloud_roots.append(root)

	var sprite := Sprite3D.new()
	sprite.texture = _make_cloud_texture()
	sprite.pixel_size = 0.06
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(sprite)


func _update_wind_effects() -> void:
	for index in tree_roots.size():
		var root := tree_roots[index]
		root.rotation.z = sin(wind_time * 1.5 + float(index)) * 0.025
		root.rotation.x = cos(wind_time * 1.1 + float(index) * 0.7) * 0.018

	for cloud in cloud_roots:
		cloud.position.x += 0.0025
		if cloud.position.x > 9.0:
			cloud.position.x = -9.0


func _pixel_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = texture
	return material


func _transparent_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _make_grass_tile_texture(seed_value: int) -> ImageTexture:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(8):
			var value := absi(seed_value + x * 13 + y * 7) % 11
			var color := Color("#6f9b62")
			if value == 0:
				color = Color("#527b55")
			elif value == 1:
				color = Color("#8cac68")
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _make_trainer_texture(frame: int) -> ImageTexture:
	var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_fill_rect(image, Rect2i(5, 2, 6, 2), Color("#26314a"))
	_fill_rect(image, Rect2i(4, 4, 8, 5), Color("#e5a979"))
	_fill_rect(image, Rect2i(5, 3, 6, 2), Color("#26314a"))
	_fill_rect(image, Rect2i(4, 9, 8, 6), Color("#d84e54"))
	_fill_rect(image, Rect2i(3, 10, 2, 4), Color("#e5a979"))
	_fill_rect(image, Rect2i(11, 10, 2, 4), Color("#e5a979"))
	var left_leg_x := 5 if frame == 1 else 4 if frame == 2 else 5
	var right_leg_x := 8 if frame == 1 else 9 if frame == 2 else 8
	_fill_rect(image, Rect2i(left_leg_x, 15, 3, 6), Color("#334d83"))
	_fill_rect(image, Rect2i(right_leg_x, 15, 3, 6), Color("#334d83"))
	_fill_rect(image, Rect2i(left_leg_x - 1, 21, 4, 2), Color("#252b3b"))
	_fill_rect(image, Rect2i(right_leg_x, 21, 4, 2), Color("#252b3b"))
	image.set_pixel(6, 6, Color("#202332"))
	image.set_pixel(9, 6, Color("#202332"))
	return ImageTexture.create_from_image(image)


func _make_tree_texture() -> ImageTexture:
	var image := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_fill_rect(image, Rect2i(6, 3, 12, 5), Color("#244b3b"))
	_fill_rect(image, Rect2i(3, 7, 18, 11), Color("#244b3b"))
	_fill_rect(image, Rect2i(5, 17, 14, 5), Color("#244b3b"))
	_fill_rect(image, Rect2i(7, 5, 10, 6), Color("#39734e"))
	_fill_rect(image, Rect2i(5, 9, 14, 8), Color("#39734e"))
	_fill_rect(image, Rect2i(8, 16, 8, 4), Color("#39734e"))
	_fill_rect(image, Rect2i(10, 20, 4, 10), Color("#6e4934"))
	_fill_rect(image, Rect2i(11, 20, 2, 10), Color("#9a6844"))
	return ImageTexture.create_from_image(image)


func _make_cloud_texture() -> ImageTexture:
	var image := Image.create(32, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cloud_color := Color("#f5f5e8")
	_fill_rect(image, Rect2i(4, 5, 24, 5), cloud_color)
	_fill_rect(image, Rect2i(9, 3, 10, 5), cloud_color)
	_fill_rect(image, Rect2i(17, 1, 8, 8), cloud_color)
	return ImageTexture.create_from_image(image)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			image.set_pixel(x, y, color)
