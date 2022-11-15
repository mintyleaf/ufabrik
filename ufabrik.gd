extends Node2D
class_name UFabrik

const ACCEPT_DIST = 3
const MAX_ATTEMPTS = 32

enum {
	LIMB_LEN,
	LIMB_MIN,
	LIMB_MAX
}

var limbs := [
	[40, -deg_to_rad(15), deg_to_rad(65)],
	[40, deg_to_rad(15), deg_to_rad(170)],
	[50, -deg_to_rad(170), deg_to_rad(-15)],
]
var lerp_amount := 0.5

var limbs_size: int
var joints := PackedVector2Array()
var sum_len := 0

var draw_target := Vector2()

func setup() -> void:
	limbs_size = limbs.size()
	@warning_ignore(return_value_discarded)
	joints.resize(limbs_size + 1)
	for i in limbs:
		sum_len += i[LIMB_LEN]

func _draw() -> void:
	for i in range(limbs_size + 1):
		if i > 0:
			draw_line(joints[i - 1], joints[i], Color.YELLOW, 0.1)
		draw_circle(joints[i], 1, Color.WHITE)
	draw_circle(draw_target, 2, Color.RED)

func backward_pass(target: Vector2) -> void:
	joints[limbs_size] = target
	for i in range(limbs_size, 0, -1):
		var a := joints[i]
		var b := joints[i - 1]
		var c := joints[i - 2] if i > 1 else Vector2.ZERO
		var limb := limbs[i - 1]
		var p_angle := wrapf(c.angle_to_point(b), -PI, PI)
		var d_angle_raw := wrapf(b.angle_to_point(a) - p_angle, -PI, PI)
		var d_angle := clampf(d_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX])
		var angle := p_angle + d_angle
		
		joints[i - 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(
			angle + PI
		)

func forward_pass() -> void:
	joints[0] = Vector2.ZERO
	var p_angle := 0.0
	for i in range(limbs_size):
		var a := joints[i]
		var b := joints[i + 1]
		var limb := limbs[i]
		var d_angle_raw := wrapf(a.angle_to_point(b) - p_angle, -PI, PI)
		var d_angle := clampf(d_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX])
		var angle := p_angle + d_angle
		
		joints[i + 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(
			angle
		)
		p_angle = angle

func update_ik(target: Vector2, recursed: bool = false) -> void:
	var cdist := target.length_squared()
	var attempts := 0
	var min_dist := INF
	var min_joints: PackedVector2Array
	var joints_p := joints.duplicate()
	
	if cdist > sum_len * sum_len:
		recursed = true
		attempts = MAX_ATTEMPTS - 1
	
	while attempts < MAX_ATTEMPTS:
		backward_pass(target)
		forward_pass()
		attempts += 1
		cdist = joints[limbs_size].distance_squared_to(target)
		if min_dist > cdist:
			min_dist = cdist
			min_joints = joints.duplicate()
		else:
			break
	
	if !recursed && cdist > ACCEPT_DIST * ACCEPT_DIST:
		joints = joints_p
		update_ik(
			target.normalized() *
			(Vector2.ZERO.distance_to(joints[limbs_size])),
			true
		)
		return
	
	if cdist > min_dist:
		joints = min_joints
	
	if lerp_amount != 1.0:
		for i in range(limbs_size + 1):
			joints[i] = joints_p[i].lerp(joints[i], lerp_amount)
	
	draw_target = target
	queue_redraw()
