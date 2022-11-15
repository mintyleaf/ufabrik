extends Node2D

const ITERATIONS = 32

var base_point = Vector2(140, 135)
var limbs := [
	80,
	60,
	80,
]
var joints := PackedVector2Array()
var limbs_size := 0

func update_ik(target: Vector2) -> void:
	for _q in range(ITERATIONS):
		_backward_pass(target)
		_forward_pass()

func _forward_pass() -> void:
	joints[0] = base_point
	for i in range(limbs_size):
		var a := joints[i]
		var b := joints[i + 1]
		var angle := a.angle_to_point(b)
		
		joints[i + 1] = a + Vector2(limbs[i], 0).rotated(angle)

func _backward_pass(target: Vector2) -> void:
	joints[limbs_size] = target
	for i in range(limbs_size, 0, -1):
		var a := joints[i]
		var b := joints[i - 1]
		var angle := a.angle_to_point(b)
		
		joints[i - 1] = a + Vector2(limbs[i - 1], 0).rotated(angle)

func _ready():
	limbs_size = limbs.size()
	@warning_ignore(return_value_discarded)
	joints.resize(limbs_size + 1)
	joints[0] = base_point
	for i in range(limbs_size):
		joints[i + 1] = joints[i] + Vector2(limbs[i], 0)

func _process(_delta):
	update_ik(get_global_mouse_position())
	queue_redraw()

func _draw():
	for i in range(limbs_size + 1):
		if i > 0:
			draw_line(joints[i - 1], joints[i], Color.WEB_GRAY, 1)
	for i in range(limbs_size + 1):
		draw_circle(joints[i], 2, Color.WHITE)
