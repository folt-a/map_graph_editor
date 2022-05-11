tool
extends LineEdit

func set_focus_next(value):
	get_node(value).focus_previous = get_path()
	.set_focus_next(value)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_TAB && event.shift and has_focus():
			if focus_previous != "":
				if get_node_or_null(focus_previous) != null:
					get_node(focus_previous).grab_focus()
			get_tree().set_input_as_handled()
		elif event.pressed and event.scancode == KEY_TAB and has_focus():
			if focus_next != "":
				if get_node_or_null(focus_next) != null:
					get_node(focus_next).grab_focus()
			get_tree().set_input_as_handled()
