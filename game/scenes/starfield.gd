extends Node2D
## Static procedural star backdrop (placeholder for the sector art).

var view_size: Vector2 = Vector2(1080, 1920)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in 110:
		var p := Vector2(rng.randf() * view_size.x, rng.randf() * view_size.y)
		var b := rng.randf_range(0.25, 0.9)
		draw_circle(p, rng.randf_range(1.2, 3.2), Color(0.7 * b, 0.8 * b, b, 1.0))
