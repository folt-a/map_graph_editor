tool
extends GraphNode

var custom_data_tscn:PackedScene = preload("res://addons/map_graph_editor/map_custom_data.tscn")

#uses exported variables so that data can be saved
export var path:String
export(bool) var is_map = true
export(int) var resource_type
export(String) var icon_class
export(String) var script_path
export(String) var script_name

export(int) var thumbnail_default_size = 24

export(Array) var custom_datas = []

onready var main_resource = $VB/Resource
onready var script_resource = $VB/Script

var _graphedit:GraphEdit

var drag_start #used for undo move

var undo_id

func _ready():
	main_resource.connect("resource_activated", self, "_on_resource_activated")
	script_resource.connect("resource_activated", self, "_on_resource_activated")
	self.connect("resize_request",self,"_on_FileNode_resize_request")
	self.set_meta("map","")
#	$MapPortal_0/DisconnectButton.connect("pressed",self,"_on_DisconnectButton_pressed",[$MapPortal_0/DisconnectButton,1])
#	$MapPortal_0/ReverseButton.connect("pressed",self,"_on_ReverseButton_pressed",[$MapPortal_0/ReverseButton,1])
	
	var nde_resource = main_resource
	
	#load data
	if icon_class:
		nde_resource.resource_type = resource_type
		nde_resource.icon_class = icon_class
		
		if script_path:
			nde_resource.script_path = script_path
		
	if path:
		init(path)
			
	$AnimationPlayer.play("btn_show")
	yield($AnimationPlayer,"animation_finished")
	$AnimationPlayer.play("RESET")
	
	map_activate()
	
func set_selected(value):
	pass

func init(path):
	var nde_resource = main_resource
	main_resource.is_map = true
	nde_resource.init(path)
	#store data to be saved
	resource_type = nde_resource.resource_type
	icon_class = nde_resource.icon_class
	script_path = nde_resource.script_path
	
	#scene has a script
	if nde_resource.script_path and nde_resource.resource_type != nde_resource.TYPE_MAP:
		script_resource.resource_name = script_name
		script_resource.resource_type = script_resource.TYPE_SCRIPT
		script_resource.icon_class = "Script"
		script_resource.init(nde_resource.script_path)
		script_name = script_resource.resource_name
		script_resource.show()

func get_row_count():
	if script_resource.visible:
		return 2
	else:
		return 1

func collapse_selected(node, depth = 1):
	for child in node.get_children():
		if child is Tree:
			var item:TreeItem = child.get_selected()
			if item:
				item.collapsed = true
		collapse_selected(child, depth + 1)

func expand_selected(node, depth = 1):
	for child in node.get_children():
		if child is Tree:
			var item:TreeItem = child.get_selected()
			if item:
				if item.get_text(0) == main_resource.resource_name:
					item.collapsed = false
		expand_selected(child, depth + 1)


func _on_resource_activated(pm_resource):
	var interface = get_tree().get_meta("__editor_interface")
		
	if pm_resource.resource_type == pm_resource.TYPE_2D \
	or pm_resource.resource_type == pm_resource.TYPE_3D \
	or pm_resource.resource_type == pm_resource.TYPE_MAP:
		
		if pm_resource.resource_type == pm_resource.TYPE_2D \
		or pm_resource.resource_type == pm_resource.TYPE_MAP:
			interface.set_main_screen_editor("2D")
		else:
			interface.set_main_screen_editor("3D")
			
		interface.open_scene_from_path(pm_resource.resource_path)
	
	elif pm_resource.resource_type == pm_resource.TYPE_DIR:
		var file_dock:FileSystemDock = interface.get_file_system_dock()
		
		collapse_selected(file_dock)
		file_dock.navigate_to_path(pm_resource.resource_path)
		expand_selected(file_dock)
		
	else:
		var resource = ResourceLoader.load(pm_resource.resource_path)
		interface.edit_resource(resource)
				
		if resource is Script:
			interface.set_main_screen_editor("Script")

func map_activate():
	$VB/MapHeader/MC/VB/MapTitle.text = path.get_file().split(".")[0]
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_min_size.y = thumbnail_default_size
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_size.y = thumbnail_default_size
	$VB/MapHeader/MC/VB/MapHeader_1/TscnJumpButton.icon = get_icon("PackedScene", "EditorIcons")
	$VB/MapHeader/MC/VB/MapHeader_1/TextureUpdateButton.icon = get_icon("Reload", "EditorIcons")
	$VB/MapHeader/MC/VB/MapHeader_1/VisibleToggleMemo.icon = get_icon("Edit", "EditorIcons")
	$VB/MapHeader/MC/VB/MapHeader_1/TextureZoomOutButton.icon = get_icon("ZoomLess", "EditorIcons")
	$VB/MapHeader/MC/VB/MapHeader_1/TextureZoomResetButton.icon = get_icon("ZoomReset", "EditorIcons")
	$VB/MapHeader/MC/VB/MapHeader_1/TextureZoomInButton.icon = get_icon("ZoomMore", "EditorIcons")
	$VB/MapDataHeader/AddDataButton.icon = get_icon("Add", "EditorIcons")
	$VB/MapDataHeader/RemoveDataButton.icon = get_icon("CurveConstant", "EditorIcons")
	$VB/MapFooter/AddPortalButton.icon = get_icon("Add", "EditorIcons")
	$VB/MapFooter/RemovePortalButton.icon = get_icon("CurveConstant", "EditorIcons")
#	$MapPortal_0/LineEdit.focus_next = NodePath(get_node_path_str(self) + "/MapPortal_2/LineEdit")

	for custom_data in custom_datas:
		add_data(custom_data)
	
	_on_TextureUpdateButton_pressed()
	
	
func custom_data_default_activate():
	var custom_data_array = _graphedit.get_custom_data_defaults()
	for data in custom_data_array:
		add_data()
	
static func get_node_path_str(node:Node):
	var path:NodePath = node.get_path()
	var count:int = path.get_name_count()
	var strr:String = "/"
	for i in range(0,count):
		strr = strr + path.get_name(i) + "/"
		pass
	strr = strr.trim_suffix("/")
	return strr

### --------------------------------------------------
### データ
### --------------------------------------------------
	
func get_title()->String:
	return $VB/MapHeader/MC/VB/MapTitle.text
func get_memo()->String:
	return $VB/MapMemo.text
func get_all_portal_data()->Array:
	var portal_data_list = []
	for portal_id in range(0,_portal_counts):
		var portal_node = get_portal(portal_id)
		portal_data_list.append({
			"id":portal_id,
			"name":portal_node.get_portal_name()
		})
	return portal_data_list
func get_all_custom_data()->Array:
	var custom_data_list = []
	for data_id in range(0,_data_counts):
		var custom_data_node = get_custom_data_node(data_id)
		var custom_data = custom_data_node.get_custom_data()
		if custom_data.name != "":
			custom_data_list.append(custom_data)
	return custom_data_list
	
func is_reverse_portal(right_slot:int) -> bool: return get_portal(right_slot-1).is_reverse

### --------------------------------------------------
### ポータル
### --------------------------------------------------

func get_portal(slot_id) -> Node:
	return get_child(3 + slot_id)

func _on_RemovePortalButton_pressed():
	if get_child_count() == 4:
		return
	var node = get_child(get_child_count()-1)
	_graphedit.disconnect_node_port(self,get_child_count() - 2)
	remove_child(node)
	_portal_counts = _portal_counts - 1

var _portal_counts:int = 1
var _portal_colors = [null,
					 Color.white,Color.blue,Color.red,Color.green,Color.yellow,Color.cyan,Color.magenta,Color.coral \
					,Color.aqua,Color.greenyellow,Color.brown,Color.slateblue,Color.darkgoldenrod,Color.lightcoral\
					,Color.lightcyan,Color.chocolate,Color.turquoise,Color.deepskyblue,Color.palegreen,Color.forestgreen\
					,Color.orangered,\
					Color.white,Color.blue,Color.red,Color.green,Color.yellow,Color.cyan,Color.magenta,Color.coral \
					,Color.aqua,Color.greenyellow,Color.brown,Color.slateblue,Color.darkgoldenrod,Color.lightcoral\
					,Color.lightcyan,Color.chocolate,Color.turquoise,Color.deepskyblue,Color.palegreen,Color.forestgreen\
					,Color.orangered,\
					Color.white,Color.blue,Color.red,Color.green,Color.yellow,Color.cyan,Color.magenta,Color.coral \
					,Color.aqua,Color.greenyellow,Color.brown,Color.slateblue,Color.darkgoldenrod,Color.lightcoral\
					,Color.lightcyan,Color.chocolate,Color.turquoise,Color.deepskyblue,Color.palegreen,Color.forestgreen\
					,Color.orangered,\
					Color.white,Color.blue,Color.red,Color.green,Color.yellow,Color.cyan,Color.magenta,Color.coral \
					,Color.aqua,Color.greenyellow,Color.brown,Color.slateblue,Color.darkgoldenrod,Color.lightcoral\
					,Color.lightcyan,Color.chocolate,Color.turquoise,Color.deepskyblue,Color.palegreen,Color.forestgreen\
					,Color.orangered,\
					Color.white,Color.blue,Color.red,Color.green,Color.yellow,Color.cyan,Color.magenta,Color.coral \
					,Color.aqua,Color.greenyellow,Color.brown,Color.slateblue,Color.darkgoldenrod,Color.lightcoral\
					,Color.lightcyan,Color.chocolate,Color.turquoise,Color.deepskyblue]
func _on_AddPortalButton_pressed():
	if get_child_count() == _portal_colors.size() + 1:
		return
	_portal_counts = _portal_counts + 1
	var dup_portal_node:HBoxContainer = $MapPortal_0.clone(_portal_counts,_portal_colors[_portal_counts])
	add_child(dup_portal_node)
	dup_portal_node.owner = _graphedit
	dup_portal_node.slot_activate()

func _on_DisconnectButton_pressed(disc_btn:Button,slot:int):
	var button_pressed:bool = disc_btn.pressed
	var from_port = conv_leftslot_to_toport(slot)
	if button_pressed:
		
		disc_btn.icon = get_icon("GuiChecked", "EditorIcons")
		
		# 1つ上にずれているので下にずらして戻す
		var dup_portal_node:HBoxContainer = $MapPortal_0.clone(_portal_counts,_portal_colors[_portal_counts])
		add_child(dup_portal_node)
		_graphedit.slide_down_right_slots(self,from_port-1)
		remove_child(dup_portal_node)
		set_slot_enabled_right(slot,true)
	else:
		var to_ports_conns:Array = _graphedit.get_connections_node_idx_from(self,from_port)
		_graphedit.disconnect_node_from_port(self, from_port)
		
		# 1つ下にずれているので上にずらして戻す
		var dup_portal_node:HBoxContainer = $MapPortal_0.clone(_portal_counts,_portal_colors[_portal_counts])
		add_child(dup_portal_node)
		_graphedit.slide_up_right_slots(self,from_port)
		remove_child(dup_portal_node)
		set_slot_enabled_right(slot,false)

		disc_btn.icon = get_icon("CurveConstant", "EditorIcons")

func get_slot_count()->int:
	return get_child_count() - 2

func conv_rightslot_to_fromport(right_slot:int) -> int:
	var port_num:int = 0
	for slot_idx in range(0,right_slot):
		if is_slot_enabled_right(slot_idx):
			port_num += 1
	return port_num

func conv_leftslot_to_toport(left_slot:int) -> int:
	var port_num:int = 0
	for slot_idx in range(0,left_slot):
		if is_slot_enabled_left(slot_idx):
			port_num += 1
	return port_num


func conv_toport_to_leftslot(to_port:int) -> int:
	var enable_slots:Array = []
	for slot_idx in range(0,get_slot_count()):
		if is_slot_enabled_left(slot_idx):
			enable_slots.append(slot_idx)
	return enable_slots[to_port]

func conv_fromport_to_rightslot(from_port:int) -> int:
	var enable_slots:Array = []
	for slot_idx in range(0,get_slot_count()):
		if is_slot_enabled_right(slot_idx):
			enable_slots.append(slot_idx)
#	print("right_enable_slots",enable_slots)
	return enable_slots[from_port]

### --------------------------------------------------
### イベント
### --------------------------------------------------

func _on_FileNode_resize_request(new_minsize):
	resize(new_minsize)
	_graphedit.dirty = true
	
func resize(size):
	rect_min_size = size + Vector2(0,32)
	rect_size = size + Vector2(0,32)
	if size.x > 100:
		$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_min_size.x = size.x
		$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_size.x = size.x
	var _vb_size_y = $VB.rect_size.y - $VB/MapMemo.rect_size.y
	var sizey = size.y - (24 * _portal_counts) - _vb_size_y
	if sizey > 24:
		$VB/MapMemo.rect_min_size = Vector2(size.x - 10, sizey)
		$VB/MapMemo.rect_size = Vector2(size.x - 10, sizey)
	else:
		$VB/MapMemo.rect_min_size.y = 24
		$VB/MapMemo.rect_size.y = 24
		
func _on_VisibleToggleMemo_pressed():
	if $VB/MapMemo.visible:
		$VB/MapMemo.visible = false
	else:
		$VB/MapMemo.visible = true

func _on_ReverseButton_pressed(reverse_btn:Button,port_num:int):
	var button_pressed:bool = reverse_btn.pressed
	if button_pressed:
		reverse_btn.icon = get_icon("ArrowRight", "EditorIcons")
	else:
		reverse_btn.icon = get_icon("MirrorX", "EditorIcons")

func _on_TextureUpdateButton_pressed():
	var loaded_resource = ResourceLoader.load(path)
	if loaded_resource is PackedScene:
		var node:Node = loaded_resource.instance()
		$ThumbnailCreator.create_thumbnail($VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail,node,["TileMap","Sprite","Node2D","AnimatedSprite"])

func _on_TscnJumpButton_pressed():
	_on_resource_activated(main_resource)
func _on_TextureZoomOutButton_pressed():
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_min_size.y *= 0.8
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_size.y *= 0.8
func _on_TextureZoomResetButton_pressed():
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_min_size = Vector2(thumbnail_default_size * 1.1,thumbnail_default_size)
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_size = Vector2(thumbnail_default_size * 1.1,thumbnail_default_size)
	
	
func _on_TextureZoomInButton_pressed():
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_min_size.y *= 1.3
	$VB/MapHeader/MC/VB/MapHeader_2/MapThumbnail.rect_size.y *= 1.3

### --------------------------------------------------
### カスタムデータ
### --------------------------------------------------
func get_custom_data_node(id:int):
	return $VB/VBCustomData.get_child(id)

var data_array:Array = []
var max_data_count = 10
var _data_counts = 0
func _on_AddDataButton_pressed():
	if _data_counts >= max_data_count:
		return
	add_data()

func add_data(custom_data:Dictionary = {"name":"","value":"", "data_type":0}) -> Node:
	_data_counts = _data_counts + 1
	var new_custom_data_node:HBoxContainer = custom_data_tscn.instance()
	new_custom_data_node.set_custom_data(custom_data)
	$VB/VBCustomData.add_child(new_custom_data_node)
	return new_custom_data_node

func _on_RemoveDataButton_pressed():
	if _data_counts == 0:
		return
	var node = $VB/VBCustomData.get_child(_data_counts-1)
	$VB/VBCustomData.remove_child(node)
	_data_counts = _data_counts - 1

func _on_custom_data_value_changed():
	custom_datas = get_all_custom_data()
