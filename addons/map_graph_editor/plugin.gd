tool
extends EditorPlugin

var map_graph_editor
var map_graph_editor_path = "res://addons/map_graph_editor/map_graph_editor.tscn"
var map_graph_editor_save_path = "res://addons/map_graph_editor/map_graph_editor_save.tscn"

func _enter_tree():
	
	get_tree().set_meta("__editor_interface", get_editor_interface())
	get_tree().set_meta("__undo_redo", get_undo_redo())
	
	var file_save = File.new()
	if file_save.file_exists(map_graph_editor_save_path):
		map_graph_editor = load(map_graph_editor_save_path).instance()
	else:
		map_graph_editor = load(map_graph_editor_path).instance()
	map_graph_editor.resource_previewer = get_editor_interface().get_resource_previewer()
	get_editor_interface().get_editor_viewport().add_child(map_graph_editor)
	map_graph_editor.visible = false
	

func _exit_tree():
	
	map_graph_editor.save()

	get_editor_interface().get_editor_viewport().remove_child(map_graph_editor)
	map_graph_editor.queue_free()


func _input(event):

	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_F4:
#		if event.pressed and event.scancode == KEY_SPACE && event.control:
			get_editor_interface().set_main_screen_editor("Maps")


func has_main_screen():
	return true


func get_plugin_name():
	return "Maps"
	

func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("FileThumbnail", "EditorIcons")


func make_visible(visible):
	map_graph_editor.visible = visible
	if visible:
		map_graph_editor.show()


func apply_changes():

	map_graph_editor.save()


func save_external_data():
	
	map_graph_editor.save()
