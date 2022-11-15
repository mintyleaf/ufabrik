extends Node2D

enum {
	LIMB_LEN,
	LIMB_MIN,
	LIMB_MAX
}
var pa = Vector2(140, 135)
var pb = Vector2(250, 135)

var limbs := [
	[80, -deg_to_rad(65), deg_to_rad(65)],
	[60, -deg_to_rad(65), deg_to_rad(65)],
	[80, -deg_to_rad(65), deg_to_rad(65)],
]
var joints = PackedVector2Array()
var limbs_size := 0
var iteration = -1
var direction = false
var font: Font = load("res://gohufont-11.ttf")

func _ready():
	limbs_size = limbs.size()
	joints.resize(limbs_size + 1)
	await get_tree().process_frame
	joints[0] = pa
	await get_tree().process_frame
	for i in range(limbs_size):
		joints[i + 1] = joints[i] + Vector2(limbs[i][LIMB_LEN], 0)
		queue_redraw()
		#await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
	for _i in range(3):
		iteration = _i
		# backward pass
		direction = false
		joints[limbs_size] = pb
		queue_redraw()
		#await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
		for i in range(limbs_size, 0, -1):
			var limb := limbs[i - 1]
			var a := joints[i]
			var b := joints[i - 1]
			var c := joints[i - 2] if i > 1 else pa
			var root_angle := c.angle_to_point(b)
			var diff_angle_raw := b.angle_to_point(a) - root_angle
			var diff_angle := clampf(
					diff_angle_raw, limb[LIMB_MIN], limb[LIMB_MAX]
			)
			var angle := root_angle + diff_angle
			
			joints[i - 1] = a + Vector2(limb[LIMB_LEN], 0).rotated(angle + PI)
			queue_redraw()
			#await get_tree().create_timer(0.5).timeout
			await get_tree().process_frame
		direction = true
		# forward pass
		joints[0] = pa
		var root_angle := 0.0
		queue_redraw()
		#await get_tree().create_timer(0.5).timeout
		await get_tree().process_frame
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
			queue_redraw()
		#	await get_tree().create_timer(0.5).timeout
			await get_tree().process_frame
	get_tree().quit()

func _draw():
	var text = "Initialization"
	if iteration > -1:
		var dtext = "Backward pass"
		if direction:
			dtext = "Forward pass"
		text = "Iteration: " + str(iteration + 1) + ", " + dtext
	draw_string(font, Vector2(133, 200), text, 0, -1, 11)
	draw_circle(pa, 6, Color.YELLOW_GREEN)
	draw_circle(pb, 6, Color.RED)
	
	for i in range(limbs_size + 1):
		if i > 0 && joints[i] != Vector2() && joints[i - 1] != Vector2():
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
		if joints[i] == Vector2(): continue
		draw_circle(joints[i], 2, Color.WHITE)
