extends Node3D

var tile_size := 0.5
var blocked_cells: Dictionary = {}


func cell_to_world(cell: Vector2i, y := 0.0) -> Vector3:
	return Vector3((cell.x + 0.5) * tile_size, y, (cell.y + 0.5) * tile_size)


func rect_center_world(origin: Vector2i, footprint: Vector2i, y := 0.0) -> Vector3:
	return Vector3((origin.x + footprint.x * 0.5) * tile_size, y, (origin.y + footprint.y * 0.5) * tile_size)


func occupy_rect(origin: Vector2i, footprint: Vector2i, occupant: String) -> bool:
	for x in range(origin.x, origin.x + footprint.x):
		for y in range(origin.y, origin.y + footprint.y):
			if blocked_cells.has(Vector2i(x, y)):
				return false

	for x in range(origin.x, origin.x + footprint.x):
		for y in range(origin.y, origin.y + footprint.y):
			blocked_cells[Vector2i(x, y)] = occupant
	return true


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)

