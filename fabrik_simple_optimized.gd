extends Node2D

const ITERATIONS = 32

@onready var info: Label = $info

var base_point = Vector2(140, 135)
var limbs := [
	80,
	60,
	80,
]
var joints := PackedVector2Array()
var limbs_size := 0
var limbs_len := 0

var all_iterations := 0
var iterations_count := 0

func update_ik(target: Vector2) -> void:
	var dist := base_point.distance_squared_to(target)
	var iterations := 0
	
	if dist > limbs_len * limbs_len:
		_backward_pass(target)
		_forward_pass()
		iterations = 1
	else:
		var min_dist := INF
		var min_joints: PackedVector2Array
		while iterations < ITERATIONS:
			_backward_pass(target)
			_forward_pass()
			iterations += 1
			dist = joints[limbs_size].distance_squared_to(target)
#			if min_dist > dist:
#				min_dist = dist
#				min_joints = joints.duplicate()
#			else:
#				break
#
#		if dist > min_dist:
#			joints = min_joints
	
	all_iterations += iterations
	iterations_count += 1
	@warning_ignore(integer_division)
	info.text = str(all_iterations / iterations_count)

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
		limbs_len += limbs[i]
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
