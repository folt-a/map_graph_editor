tool
extends HBoxContainer

signal value_changed

export(int) var slot = 1
export(Color) var color
export(bool) var is_reverse = true

export(String) var custom_data_name = ""
export(String) var custom_data_value = ""
export(int) var custom_data_type = DATATYPE.STRING

enum DATATYPE {STRING = 0,INT = 1,FLOAT = 2,REFFERENCE = 3}

func _ready():
	$OptionButtonType.clear()
	$OptionButtonType.add_item("",DATATYPE.STRING)
	$OptionButtonType.set_item_icon(DATATYPE.STRING,get_icon("String", "EditorIcons"))
	$OptionButtonType.add_item("",DATATYPE.INT)
	$OptionButtonType.set_item_icon(DATATYPE.INT,get_icon("int", "EditorIcons"))
	$OptionButtonType.add_item("",DATATYPE.FLOAT)
	$OptionButtonType.set_item_icon(DATATYPE.FLOAT,get_icon("float", "EditorIcons"))
	$OptionButtonType.add_item("",DATATYPE.REFFERENCE)
	$OptionButtonType.set_item_icon(DATATYPE.REFFERENCE,get_icon("Load", "EditorIcons"))
#	set_script(self.get_script())
#	print(get_node_path_strslider(self) + "/MapPortal_" + String(_portal_counts - 1) + "/LineEdit")
	$LineEditName.text = custom_data_name
	$LineEditValue.text = custom_data_value
#	line_edit.focus_previous = NodePath(get_node_path_str(self) + "/MapPortal_" + String(_portal_counts - 1) + "/LineEdit")
#	line_edit.focus_next = NodePath(get_node_path_str(self) + "/MapPortal_" + String(_portal_counts + 1) + "/LineEdit")

func get_custom_data()->Dictionary:
	match custom_data_type:
		DATATYPE.STRING:
			return {"name":custom_data_name,"value":custom_data_value}
		DATATYPE.INT:
			return {"name":custom_data_name,"value":int(custom_data_value)}
		DATATYPE.FLOAT:
			return {"name":custom_data_name,"value":float(custom_data_value)}
		DATATYPE.REFFERENCE:
			return {"name":custom_data_name,"value":custom_data_value}
	return {}

func get_custom_data_with_type()->Dictionary:
	return {"name":custom_data_name,"value":custom_data_value, "data_type":custom_data_type}

func set_custom_data(custom_data:Dictionary)->void:
	custom_data_name = custom_data.name
	custom_data_value = custom_data.value
	$OptionButtonType.select(custom_data.data_type)
	$LineEditName.text = custom_data_name
	$LineEditValue.text = custom_data_value

#func is_reverse() -> bool: return !$ReverseButton.pressed

func get_portal_name()->String:
	return $LineEdit.text

func _on_LineEditName_text_changed(new_text):
	custom_data_name = new_text
	emit_signal("value_changed")

func _on_LineEditValue_text_changed(new_text):
	custom_data_value = new_text
	emit_signal("value_changed")

func _on_OptionButtonType_item_selected(index):
	emit_signal("value_changed")
	pass # Replace with function body.
