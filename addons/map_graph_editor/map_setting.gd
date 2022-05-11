tool
extends MarginContainer

signal save
signal exportjson

export var _is_contidition_enable_class_name:bool = true
export var _is_contidition_enable_dir_path:bool = false

export var is_visible_map_condition:bool = true
export var is_visible_output_setting:bool = true
export var is_visible_map_setting:bool = true

func _ready():
	$VB/MCMainButtons/HBoxContainer/SaveButton.icon = get_icon("Save", "EditorIcons")
	$VB/MCMainButtons/HBoxContainer/ExportButton.icon = get_icon("Object", "EditorIcons")
	$VB/MC/SettingVisibleButton.icon = get_icon("TripleBar", "EditorIcons")
	$VB/PC/MC/VB/MCMapSetting/HBoxContainer/VisibleMapSettingButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	$VB/PC/MC/VB/MCOutputSetting/HBoxContainer/VisibleOutputSettingButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	$VB/PC/MC/VB/MCMapCondition/HBoxContainer/VisibleMapConditionButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
	$VB/PC/MC/VB/PanelClassName/HBoxContainer/ReloadButton.icon = get_icon("ArrowRight", "EditorIcons")
	$VB/PC/MC/VB/MapCustomDataHead/HBoxContainer/AddCustomDataButton.icon = get_icon("Add", "EditorIcons")
	$VB/PC/MC/VB/MapCustomDataHead/HBoxContainer/RemoveCustomDataButton.icon = get_icon("CurveConstant", "EditorIcons")
	reload_class_name()

func is_include_memo() -> bool:
	return $VB/PC/MC/VB/PanelOutputSetting/HBoxContainer/CheckButtonIncludeMemo.pressed
	
func get_thumbnail_default_size() -> int:
	return int($VB/PC/MC/VB/PanelMapSetting/HBoxContainer/SpinBoxThumbnailSize.value)

onready var menu_vb = $VB/PC/MC/VB
func get_custom_data_list(is_auto_add_only:bool = true)->Array:
	var ary = []
	for i in range(0,_data_counts):
		var map_custom_data_node:HBoxContainer = menu_vb.get_node("./MapCustomData_" + String(i)).get_child(0)
		var is_autoadd_pressed = map_custom_data_node.get_child(0).pressed
		var data_name = map_custom_data_node.get_child(1).text
		var data_value = map_custom_data_node.get_child(3).text
		
		if is_auto_add_only and !is_autoadd_pressed: continue
#		if data_name == "": continue
		
		var objecta = {"name":data_name,"value":data_value}
		ary.append(objecta)
	print(ary)
#	print(JSON.print(ary))
	return ary

func is_file_map_node(file_path) ->bool:
	# チェックボックス未チェックならならパスする
	var pass_class_name = !_is_contidition_enable_class_name
	var pass_dir_path = !_is_contidition_enable_dir_path
	if !pass_class_name:
		pass_class_name = is_file_class_name(file_path)
	if !pass_dir_path:
		pass_dir_path = is_file_in_dir(file_path,$VB/PC/MC/VB/PanelDirPath/HBoxContainer/CenterContainer_2/LineEditDirPath.text)
	return pass_class_name and pass_dir_path

func is_file_class_name(file_path)->String:
	var dir = Directory.new()
	if dir.dir_exists(file_path):
		return "Folder"
	else:
		var resource = ResourceLoader.load(file_path)
		if resource is PackedScene:
			var instance = resource.instance()
			return $IsMapCheck.is_file_class(instance)
		elif resource is Resource:
			return $IsMapCheck.is_file_class(resource)
#			return resource.get_class()
	return ""
	
static func is_file_in_dir(file_path:String,dir_path:String)->bool:
	return file_path.begins_with(dir_path)

func _on_SettingVisibleButton_pressed():
	$VB/PC.visible = !$VB/PC.visible
#	$ColorRect.visible = !$ColorRect.visible

func _on_CheckButtonClassName_toggled(button_pressed):
	$VB/PC/MC/VB/PanelClassName/HBoxContainer/CenterContainer_2/LineEditClassName.visible = button_pressed
	_is_contidition_enable_class_name = button_pressed

func _on_CheckButtonDirPath_toggled(button_pressed):
	$VB/PC/MC/VB/PanelDirPath/HBoxContainer/CenterContainer_2/LineEditDirPath.visible = button_pressed
	_is_contidition_enable_dir_path = button_pressed

func reload_class_name():
	var script = GDScript.new()
	var classname_text = $VB/PC/MC/VB/PanelClassName/HBoxContainer/CenterContainer_2/LineEditClassName.text
	script.source_code = "tool\nextends Node\nfunc is_file_class(node):return node is " + classname_text
	script.reload()
	$IsMapCheck.set_script(script)
	
func _on_ReloadButton_pressed():
	reload_class_name()

var _data_counts:int = 1
func _on_AddCustomDataButton_pressed():
	_data_counts = _data_counts + 1
	var dup_data_node:PanelContainer = $VB/PC/MC/VB/MapCustomData_0.duplicate(Node.DUPLICATE_GROUPS && Node.DUPLICATE_SIGNALS && Node.DUPLICATE_SCRIPTS)
	dup_data_node.get_child(0).get_child(0).pressed = false
	dup_data_node.get_child(0).get_child(1).text = ""
	dup_data_node.get_child(0).get_child(3).text = ""
	menu_vb.add_child(dup_data_node)
	menu_vb.move_child(dup_data_node,8 + _data_counts)

func _on_RemoveCustomDataButton_pressed():
	if menu_vb.get_child_count() == 11:
		return
	var node = menu_vb.get_node("./MapCustomData_" + String(_data_counts - 1))
	menu_vb.remove_child(node)
	_data_counts = _data_counts - 1

func _on_LineEditCustomDataName_text_changed(new_text):
	get_custom_data_list()

func _on_LineEditCustomDataValue_text_changed(new_text):
	get_custom_data_list()

func _on_VisibleMapConditionButton_pressed():
	is_visible_map_condition = !is_visible_map_condition
	if is_visible_map_condition:
		$VB/PC/MC/VB/MCMapCondition/HBoxContainer/VisibleMapConditionButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
		$VB/PC/MC/VB/PanelClassName.visible = true
		$VB/PC/MC/VB/PanelDirPath.visible = true
	else:
		$VB/PC/MC/VB/MCMapCondition/HBoxContainer/VisibleMapConditionButton.icon = get_icon("GuiVisibilityHidden", "EditorIcons")
		$VB/PC/MC/VB/PanelClassName.visible = false
		$VB/PC/MC/VB/PanelDirPath.visible = false

func _on_VisibleOutputSettingButton_pressed():
	is_visible_output_setting = !is_visible_output_setting
	if is_visible_output_setting:
		$VB/PC/MC/VB/MCOutputSetting/HBoxContainer/VisibleOutputSettingButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
		$VB/PC/MC/VB/PanelOutputSetting.visible = true
	else:
		$VB/PC/MC/VB/MCOutputSetting/HBoxContainer/VisibleOutputSettingButton.icon = get_icon("GuiVisibilityHidden", "EditorIcons")
		$VB/PC/MC/VB/PanelOutputSetting.visible = false

func _on_VisibleMapSettingButton_pressed():
	is_visible_map_setting = !is_visible_map_setting
	if is_visible_map_setting:
		$VB/PC/MC/VB/MCMapSetting/HBoxContainer/VisibleMapSettingButton.icon = get_icon("GuiVisibilityVisible", "EditorIcons")
		$VB/PC/MC/VB/PanelMapSetting.visible = true
	else:
		$VB/PC/MC/VB/MCMapSetting/HBoxContainer/VisibleMapSettingButton.icon = get_icon("GuiVisibilityHidden", "EditorIcons")
		$VB/PC/MC/VB/PanelMapSetting.visible = false
	pass # Replace with function body.


func _on_SaveButton_pressed():
	emit_signal("save")

func _on_ExportButton_pressed():
	emit_signal("exportjson")
	
