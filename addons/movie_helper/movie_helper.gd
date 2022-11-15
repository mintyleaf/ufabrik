@tool
extends EditorPlugin

const DATA = {
	false: {
		"display/window/size/viewport_width": 960,
		"display/window/size/viewport_height": 540,
		"display/window/size/window_width_override": 960,
		"display/window/size/window_height_override": 540,
		"display/window/stretch/scale": 2,
	},
	true: {
		"display/window/size/viewport_width": 1920,
		"display/window/size/viewport_height": 1080,
		"display/window/size/window_width_override": 1920,
		"display/window/size/window_height_override": 1080,
		"display/window/stretch/scale": 4,
	}
}

var mwbutt: Button

func mwtoggled(toggled: bool) -> void:
	for i in DATA[toggled]:
		ProjectSettings.set_setting(i, DATA[toggled][i])
	ProjectSettings.save()

func _enter_tree() -> void:
	var needed = get_editor_interface().get_base_control()
	for i in needed.get_children():
		if i is VBoxContainer:
			needed = i
			break
	for i in needed.get_children():
		if !i is HSplitContainer:
			needed = i
			break
	for i in needed.get_children():
		if i is PanelContainer:
			needed = i.get_child(0)
			break
	for i in needed.get_children():
		if i is PanelContainer:
			mwbutt = i.get_child(0)
			break
	mwbutt.toggled.connect(Callable(self, "mwtoggled"))


func _exit_tree() -> void:
	mwbutt.toggled.disconnect(Callable(self, "mwtoggled"))
