tool
extends "res://addons/map_graph_editor/pm_common_node.gd"

export(bool) var is_map = false
var icon = NodePath("MarginContainer/HBox/Icon")

export(String) var comment_text = "Comment"
export(Vector2) var comment_rect = Vector2(400, 200)

onready var text_node = get_node("MarginContainer/HBox/TextBox")

var last_text:String = ""

func _enter_tree():
	
	connect("resize_request", self, "_on_GraphNode_resize_request")
	get_node(icon).texture = get_icon("MultiLine", "EditorIcons")
	
	connect("mouse_entered", self, "_on_Node_mouse_entered")
	connect("mouse_exited", self, "_on_Node_mouse_exited")
	
	rect_min_size = Vector2(50,50)
	rect_size = Vector2(50,50)
	
func _on_Node_mouse_entered():
	
	resizable = true


func _on_Node_mouse_exited():
	
	resizable = false


func _ready():

	text_node.text = comment_text
	
	resize(comment_rect)

	snap = false
	pass

func init():

	pass

func resize(size):
	
	comment_rect = size

	$MarginContainer.rect_min_size = Vector2(comment_rect.x - 60, comment_rect.y - 40)
	$MarginContainer.rect_size = Vector2(comment_rect.x - 60, comment_rect.y - 40)
	
	rect_min_size = comment_rect
	rect_size = comment_rect


func _on_GraphNode_resize_request(new_minsize:Vector2):

	resize(new_minsize)

	get_parent().dirty = true


func _on_TextBox_mouse_entered():
	_on_Node_mouse_entered()


func _on_TextBox_mouse_exited():
	_on_Node_mouse_exited()


func _on_TextBox_text_changed():
	
	comment_text = get_node("MarginContainer/HBox/TextBox").text
	get_parent().dirty = true


func _on_TextBox_focus_exited():
	
	var undo_redo:UndoRedo = get_parent().undo_redo
	
	undo_redo.create_action("Change text")
	
	undo_redo.add_do_property(text_node, "text", text_node.text)
	undo_redo.add_undo_property(text_node, "text", last_text)
	
	undo_redo.commit_action()
	

func _on_TextBox_focus_entered():
	last_text = text_node.text

func change_text_font(d_font:DynamicFont):
	$MarginContainer/HBox/TextBox.add_font_override("font", d_font)
