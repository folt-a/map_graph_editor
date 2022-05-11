tool
extends HBoxContainer

var text_edit_script:Script = preload("res://addons/map_graph_editor/map_portal_text_edit.gd")

export(int) var slot = 1
export(Color) var color
export(bool) var is_reverse = true

export(String) var portal_name = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$DisconnectButton.icon = get_icon("GuiChecked", "EditorIcons")
	$ReverseButton.icon = get_icon("MirrorX", "EditorIcons")
	$TextureRectIcon.texture = get_icon("EditorPathSharpHandle", "EditorIcons")
	
#	set_script(self.get_script())
	$TextureRectIcon.modulate = color #Texture
	$Label.text = String(slot-1) # Label
#	print(get_node_path_strslider(self) + "/MapPortal_" + String(_portal_counts - 1) + "/LineEdit")
	$LineEdit.set_script(text_edit_script)
	$LineEdit.text = portal_name
#	line_edit.focus_previous = NodePath(get_node_path_str(self) + "/MapPortal_" + String(_portal_counts - 1) + "/LineEdit")
#	line_edit.focus_next = NodePath(get_node_path_str(self) + "/MapPortal_" + String(_portal_counts + 1) + "/LineEdit")
	$DisconnectButton.pressed = true
	if !$DisconnectButton.is_connected("pressed",get_parent(),"_on_DisconnectButton_pressed"):
		$DisconnectButton.connect("pressed",get_parent(),"_on_DisconnectButton_pressed",[$DisconnectButton,slot])
	if !$ReverseButton.is_connected("pressed",get_parent(),"_on_ReverseButton_pressed"):
		$ReverseButton.connect("pressed",get_parent(),"_on_ReverseButton_pressed",[$ReverseButton,slot])

#func is_reverse() -> bool: return !$ReverseButton.pressed

func get_portal_name()->String:
	return $LineEdit.text

func slot_activate():
	get_parent().set_slot_enabled_left(slot,true)
	get_parent().set_slot_enabled_right(slot,true)
	get_parent().set_slot_color_left(slot,color)
	get_parent().set_slot_color_right(slot,color)
	get_parent().set_slot_type_left(slot,1)
	get_parent().set_slot_type_right(slot,1)
	pass
	
func clone(slot:int,color:Color) -> HBoxContainer:
	self.slot = slot
	self.color = Color(color.r,color.g,color.b,0.6)
	var dup_portal_node:HBoxContainer = self.duplicate(Node.DUPLICATE_SCRIPTS)
	return dup_portal_node

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ReverseButton_toggled(button_pressed):
	is_reverse = !button_pressed


func _on_LineEdit_text_changed(new_text):
	portal_name = new_text
	
