extends Node2D

enum {
	LIMB_LEN,
	LIMB_MIN,
	LIMB_MAX
}
const BIAS = 3
const ITERATIONS = 32

var base_point = Vector2(140, 135)
var limbs := [
	[80, -deg_to_rad(65), deg_to_rad(65)],
	[60, -deg_to_rad(65), deg_to_rad(65)],
	[80, -deg_to_rad(65), deg_to_rad(65)],
]
var joints := PackedVector2Array()

var limbs_size := 0
var limbs_len := 0

var lerp_amount := 1.0

func update(target: Vector2) -> void:
	var joints_p := joints.duplicate()
	var dist := update_ik(target)
	
	if dist > BIAS * BIAS:
		joints = joints_p
		@warning_ignore(return_value_discarded)
		update_ik(
			base_point + (target - base_point).normalized() *
			(base_point.distance_to(joints[limbs_size]))
		)
		return
	
	if lerp_amount != 1.0:
		for i in range(limbs_size + 1):
			joints[i] = joints_p[i].lerp(joints[i], lerp_amount)

func update_ik(target: Vector2) -> float:
	var dist := base_point.distance_squared_to(target)
	var iterations := 0
	
	if dist > limbs_len * limbs_len:
		_backward_pass(target)
		_forward_pass()
		return 0.0
	
	var min_dist := INF
	var min_joints: PackedVector2Array
	while iterations < ITERATIONS:
		_backward_pass(target)
		_forward_pass()
		iterations += 1
		dist = joints[limbs_size].distance_squared_to(target)
		if min_dist > dist:
			min_dist = dist
			min_joints = joints.duplicate()
		else:
			break
	
	if dist > min_dist:
		joints = min_joints
	
	return joints[limbs_size].distance_squared_to(target)

func _forward_pass() -> void:
	var root_angle := 0.0
	joints[0] = base_point
	for i in range(limbs_size):
		var limb := limbs[i]
		var a := joints[i]
		var b := joints[i + 1]
		var diff_angle_raw := wrapf(a.angle_to_point(b) - root_angle, -PI, PI)
		var diff_angle := clampf(
				diff_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX]
		)
		var angle := root_angle + diff_angle
		
		joints[i + 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(angle)
		root_angle = angle

func _backward_pass(target: Vector2) -> void:
	joints[limbs_size] = target
	for i in range(limbs_size, 0, -1):
		var limb := limbs[i - 1]
		var a := joints[i]
		var b := joints[i - 1]
		var c := joints[i - 2] if i > 1 else base_point
		var root_angle := c.angle_to_point(b)
		var diff_angle_raw := b.angle_to_point(a) - root_angle
		var diff_angle := clampf(
				diff_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX]
		)
		var angle := root_angle + diff_angle
		
		joints[i - 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(angle + PI)

func _ready():
	limbs_size = limbs.size()
	@warning_ignore(return_value_discarded)
	joints.resize(limbs_size + 1)
	joints[0] = base_point
	for i in range(limbs_size):
		limbs_len += limbs[i][LIMB_LEN]
		joints[i + 1] = joints[i] + Vector2(limbs[i][LIMB_LEN], 0)

func _process(_delta):
	update(get_global_mouse_position())
	queue_redraw()

func _draw():
	for i in range(limbs_size + 1):
		if i > 0:
			draw_line(joints[i - 1], joints[i], Color.WEB_GRAY, 1)
			draw_line(
					joints[i - 1], joints[i - 1] + (
						(joints[i - 1] - joints[i - 2]) if i > 1 else Vector2.RIGHT
					).rotated(limbs[i - 1][LIMB_MIN]).normalized() * 32,
					Color.DARK_GOLDENROD, 0.5
			)
			draw_line(
					joints[i - 1], joints[i - 1] + (
						(joints[i - 1] - joints[i - 2]) if i > 1 else Vector2.RIGHT
					).rotated(limbs[i - 1][LIMB_MAX]).normalized() * 32,
					Color.DARK_GOLDENROD, 0.5
			)
	for i in range(limbs_size + 1):
		draw_circle(joints[i], 2, Color.WHITE)
