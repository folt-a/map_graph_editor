tool
extends GraphEdit

#class_name MapEdit

var file_node = preload("res://addons/map_graph_editor/pm_file_node.tscn")
var file_node_script = preload("res://addons/map_graph_editor/pm_file_node.gd")
var map_node = preload("res://addons/map_graph_editor/pm_map_node.tscn")
var map_node_script = preload("res://addons/map_graph_editor/pm_map_node.gd")
var group_node = preload("res://addons/map_graph_editor/pm_group_node.tscn")
var group_node_script = preload("res://addons/map_graph_editor/pm_group_node.gd")
var common_node_script = preload("res://addons/map_graph_editor/pm_common_node.gd")

var comment_node = preload("res://addons/map_graph_editor/pm_comment_node.tscn")
var comment_node_script = preload("res://addons/map_graph_editor/pm_comment_node.gd")

export(Dictionary) var connections = {}

onready var map_setting = $MapSetting

var resource_previewer:EditorResourcePreview

var dirty = false

var add_panel: = false
var add_comment: = false
var add_comment_large: = false

var undo_redo:UndoRedo

var button_font = preload("res://addons/map_graph_editor/fonts/map_button_font.tres")
var comment_font = preload("res://addons/map_graph_editor/fonts/map_comment_font.tres")
var comment_large_font = preload("res://addons/map_graph_editor/fonts/map_comment_large_font.tres")

func _enter_tree():
	
	connect("gui_input", self, "_on_ProjectMap_gui_input")
	connect("_begin_node_move", self, "_on_begin_node_move")
	connect("_end_node_move", self, "_on_end_node_move")
	
	var hbox = get_zoom_hbox()
	
	#add group button
	var group_button = Button.new()
	group_button.icon = get_icon("WindowDialog", "EditorIcons")
	group_button.add_font_override("font",button_font)
	hbox.add_child(group_button)
	group_button.connect("pressed", self, "_on_add_panel")
	
	#add comment button
	var comment_button = Button.new()
	comment_button.icon = get_icon("MultiLine", "EditorIcons")
	comment_button.add_font_override("font",button_font)
	hbox.add_child(comment_button)
	comment_button.connect("pressed", self, "_on_add_comment")
	
	#add comment button
	var comment_large_button = Button.new()
	comment_large_button.icon = get_icon("MultiLine", "EditorIcons")
	comment_large_button.add_font_override("font",button_font)
	hbox.add_child(comment_large_button)
	comment_large_button.connect("pressed", self, "_on_add_comment_large")
	
	if OS.get_locale_language() == "ja":
		group_button.text = "グループ追加"
		comment_button.text = "コメント追加"
		comment_large_button.text = "コメント(大)追加"
	else:
		group_button.text = "Add Group"
		comment_button.text = "Add Comment"
		comment_large_button.text = "Add Large Comment"
	
	var interface = get_tree().get_meta("__editor_interface")
	undo_redo = get_tree().get_meta("__undo_redo")
	
	var file_system_dock = interface.get_file_system_dock()

	file_system_dock.connect("file_removed", self, "_on_file_removed")
	file_system_dock.connect("files_moved", self, "_on_file_moved")


#snap vector to grid
func snap(pos:Vector2):
	if use_snap:
		pos = pos / snap_distance
		pos = pos.floor() * snap_distance
	return pos

func _on_add_panel():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_panel = true

func _on_add_comment():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_comment = true

func _on_add_comment_large():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_comment_large = true

func _ready():
	snap_distance = 32
	for node in get_children():
		if node is common_node_script:
			node.connect("end_node_move", self, "_on_end_node_move")
		if node is group_node_script:
			node.set_children()
		if node is map_node_script:
			node._graphedit = self
	var hbox = get_zoom_hbox()
	var hbox_children = hbox.get_children()
	hbox_children[1].icon = get_icon("ZoomLess", "EditorIcons")
	hbox_children[2].icon = get_icon("ZoomReset", "EditorIcons")
	hbox_children[3].icon = get_icon("ZoomMore", "EditorIcons")
	hbox_children[4].icon = get_icon("SnapGrid", "EditorIcons")
	hbox_children[5].visible = false
	hbox_children[6].icon = get_icon("GridMinimap", "EditorIcons")
	hbox_children[1].rect_size = Vector2(42,36)
	hbox_children[2].rect_size = Vector2(42,36)
	hbox_children[3].rect_size = Vector2(42,36)
	hbox_children[4].rect_size = Vector2(42,36)
	hbox_children[6].rect_min_size = Vector2(42,36)
	hbox_children[1].rect_min_size = Vector2(42,36)
	hbox_children[2].rect_min_size = Vector2(42,36)
	hbox_children[3].rect_min_size = Vector2(42,36)
	hbox_children[4].rect_min_size = Vector2(42,36)
	hbox_children[6].rect_min_size = Vector2(42,36)
	hbox_children[1].expand_icon = true
	hbox_children[2].expand_icon = true
	hbox_children[3].expand_icon = true
	hbox_children[4].expand_icon = true
	hbox_children[6].expand_icon = true
	restore_connections()
	
func restore_connections():
	for conn in connections:
		connect_node(conn.from,conn.from_port,conn.to,conn.to_port)

func _on_file_removed(file_path):
	for child in get_children():
		if child is GraphNode and child.get("path") and child.path == file_path:
			child.queue_free()
			dirty = true


func _on_file_moved(old_file_path, new_file_path):
	for child in get_children():
		if child is GraphNode and child.get("path") and child.path == old_file_path:
			child.path = new_file_path
			child.init(new_file_path)
			dirty = true


func can_drop_data(position, data):
	if data.type == "files" or data.type == "files_and_dirs":
		return true
	else:
		return false


#add node to the graph, snap to grid
func add_node(scn_node, pos):
	var node:GraphNode = scn_node.instance()
	var offset = scroll_offset + pos
	node.offset = snap(offset)
	add_child(node)
	if node is group_node_script:
		move_child(node, 0)
	node.owner = self
	dirty = true
	return node
	
func create_file_nodes(file_paths:Array, pos):
	var last_node_row = 0
	#set exported variables before adding to tree
	#to be able to save script data
	for file_path in file_paths:
		var node:GraphNode
		if map_setting.is_file_map_node(file_path) :
			node = add_node(map_node, pos)
			node._graphedit = self
			node.thumbnail_default_size = map_setting.get_thumbnail_default_size()
			node.custom_data_default_activate()
			node._on_TextureZoomResetButton_pressed()
		else:
			node = add_node(file_node, pos)
		#this sets the script variable for saving, do not remove
		var path:String = file_path
		node.path = path
		node.init(path)
		#adjust offset when dropping multiple files
		node.offset.y += last_node_row * snap_distance
		last_node_row += node.get_row_count()
		dirty = true


func _undo_create_file_nodes(undo_id):
	for node in get_children():
		if node.get("undo_id"):
			if node.undo_id == undo_id:
				node.queue_free()
				dirty = true

func drop_data(pos, data):
	var last_node_row = 0
	undo_redo.create_action("Create file nodes")
	#set exported variables before adding to tree
	#to be able to save script data
	for file_path in data.files:
#		var node:GraphNode = add_node(file_node, pos)
		var node:GraphNode
		if map_setting.is_file_map_node(file_path) :
			node = add_node(map_node, pos)
			node._graphedit = self
			node.thumbnail_default_size = map_setting.get_thumbnail_default_size()
			node._on_TextureZoomResetButton_pressed()
			node.custom_data_default_activate()
		else:
			node = add_node(file_node, pos)
		#this sets the script variable for saving, do not remove
		var path:String = file_path
		node.path = path
		node.init(path)
		#adjust offset when dropping multiple files
		# 横にずらすようにする
		node.offset.x += last_node_row * (snap_distance * 5)
		last_node_row += node.get_row_count()
		undo_redo.add_do_method(node, "show")
		undo_redo.add_undo_method(node, "hide")
		dirty = true

	undo_redo.commit_action()


func _on_BtnSave_pressed():
	save()


func save():
	#delete hidden nodes (deleted)
	for node in get_children():
		if node is CanvasLayer: continue
		if not node.visible:
			disconnect_node_all(node)
			node.free()
	
	if dirty:
		connections = get_connection_list()
		var packed_scene:PackedScene = PackedScene.new()
		packed_scene.pack(self)
		ResourceSaver.save("res://addons/map_graph_editor/map_graph_editor_save.tscn", packed_scene)
		dirty = false
	if undo_redo:
		undo_redo.clear_history()


func _on_GraphEdit_delete_nodes_request():
	undo_redo.create_action("Delete nodes")
	for child in get_children():
		if child is GraphNode:
			if child.selected and child.visible:
				undo_redo.add_do_method(child, "hide")
				undo_redo.add_undo_method(child, "show")
				child.selected = false

	undo_redo.commit_action()
	dirty = true


func _notify_group_move():
	#notify all groups of node moving
	for group in get_children():
		if group is group_node_script:
			for selected_node in get_children():
				if (selected_node is file_node_script or selected_node is map_node_script) and selected_node.selected:
					group.on_file_node_moved(selected_node)


func _undo_move(node, offset):
	node.offset = offset
	node.selected = true
	_notify_group_move()


func _do_move(node, offset):
	node.offset = offset
	_notify_group_move()


func _on_begin_node_move():
	for child in get_children():
		if child is GraphNode and child.selected:
			child.drag_start = child.offset


func _on_end_node_move():
	dirty = true
	undo_redo.create_action("Move node")
	for child in get_children():
		if child is GraphNode and child.selected:
			undo_redo.add_do_method(self, "_do_move", child, child.offset)
			undo_redo.add_undo_method(self, "_undo_move", child, child.drag_start)
	undo_redo.commit_action()

func _add_common_node(node_type, pos, node_name) -> Node2D:
	var node = add_node(node_type, pos)
	node.init()
	accept_event()
	node.connect("end_node_move", self, "_on_end_node_move")
	undo_redo.create_action(str("Create ", node_name))
	undo_redo.add_do_method(node, "show")
	undo_redo.add_undo_method(node, "hide")
	undo_redo.commit_action()
	return node

func _on_ProjectMap_gui_input(event):
	var zoom_speed = 0.05
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			#create group node
			if add_panel:
				add_panel = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				_add_common_node(group_node, event.position, "group")
			#create comment node
			elif add_comment:
				add_comment = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				var node = _add_common_node(comment_node, event.position, "comment")
				node.change_text_font(comment_font)
			elif add_comment_large:
				add_comment_large = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				var node = _add_common_node(comment_node, event.position, "comment")
				node.change_text_font(comment_large_font)
		elif event.button_index == BUTTON_WHEEL_UP:
			zoom += zoom_speed
#			zoom = min(zoom, 1)
			accept_event()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom -= zoom_speed
			accept_event()

### --------------------------------------------------
### マップシーンノード
### --------------------------------------------------
func get_map_data_json_str() -> String:
	var conns = get_map_data_json()
	var strr = ""
	for conn in conns:
		strr += JSON.print(conn) + "\n"
	return strr

func get_map_data_json() -> Array:
	var mapnodes:Array = []
	for node in get_children():
		if !(node is GraphNode):
			continue
		if !node.is_map:
			continue
		var portal_data_list = node.get_all_portal_data()
		if map_setting.is_include_memo():
			mapnodes.append({
				"title":node.get_title(),
				"memo":node.get_memo(),
				"portals":node.get_all_portal_data(),
				"custom_data":node.get_all_custom_data(),
			})
		else:
			mapnodes.append({
				"title":node.get_title(),
				"portals":node.get_all_portal_data(),
				"custom_data":node.get_all_custom_data(),
			})
		
	return mapnodes

func get_connection_json_str() -> String:
	var conns = get_connection_json()
	var strr = ""
	for conn in conns:
		strr += JSON.print(conn) + "\n"
	return strr
	
func get_connection_json() -> Array:
	var conns = get_connection_list()
	var connections = []
	for conn in conns:
		var from_node = get_graph_node_by_name(conn.from)
		var from_slot = from_node.conv_fromport_to_rightslot(conn.from_port)
		var to_node = get_graph_node_by_name(conn.to)
		var to_slot = to_node.conv_toport_to_leftslot(conn.to_port)
		connections.append({
			"from_title": from_node.get_title(),
			"from_portal": from_slot - 1,
			"to_title": to_node.get_title(),
			"to_portal": to_slot - 1,
			})
		# 往復ポータルの場合は逆も追加する
		if from_node.is_reverse_portal(from_slot):
			connections.append({
				"from_title": to_node.get_title(),
				"from_portal": to_slot - 1,
				"to_title": from_node.get_title(),
				"to_portal": from_slot - 1,
				})
	return connections

func _on_ProjectMap_connection_request(from:String, from_port:int, to:String, to_port:int):
	var from_node = get_graph_node_by_name(from)
	var to_node = get_graph_node_by_name(to)
	var from_slot = from_node.conv_fromport_to_rightslot(from_port)
	var to_slot = from_node.conv_toport_to_leftslot(to_port)
	connect_request(from_node,from_slot,to_node,to_slot)

func connect_request(from:GraphNode, from_right_slot:int, to:GraphNode, to_left_slot:int):
	if from.name == to.name : return
	var from_port = from.conv_rightslot_to_fromport(from_right_slot)
	var to_port = to.conv_leftslot_to_toport(to_left_slot)
	print("right_slot=",from_right_slot,"from_port=",from_port)
	print("left_slot=",to_left_slot,"to_port=",to_port)
	for conn in get_connection_list():
		if conn.from == from.name and conn.from_port == from_port:
			return
		if conn.to == to.name and conn.to_port == to_port:
			return
	connect_node_slot(from, from_right_slot, to, to_left_slot)

func _on_ProjectMap_disconnection_request(from, from_port, to, to_port):
	var from_node = get_graph_node_by_name(from)
	var to_node = get_graph_node_by_name(to)
	var from_slot = from_node.conv_fromport_to_rightslot(from_port)
	var to_slot = from_node.conv_toport_to_leftslot(to_port)
	disconnect_request(from_node,from_slot,to_node,to_slot)

func disconnect_request(from:GraphNode, from_right_slot:int, to:GraphNode, to_left_slot:int):
	disconnect_node_slot(from, from_right_slot, to, to_left_slot)

onready var _right_click_line:Line2D = $Line2D
var _is_right_dragging:bool = false
func _input(event):
	if !visible : return
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed:
		_is_right_dragging = true
		$Line2D/AnimationPlayer.play("blink")
	elif event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		_is_right_dragging = false
		$Line2D/AnimationPlayer.play("RESET")	
		var through_nodes = []
		var through_points = []
		for graphnode in get_children():
			if graphnode.has_meta("map") and graphnode.visible:
#				選択中GraphNodeのポリゴンを取得
				var poly_lt = graphnode.rect_position
				var poly_rt = Vector2(poly_lt.x + graphnode.get_rect().size.x, poly_lt.y)
				var poly_rb = Vector2(poly_lt.x + graphnode.get_rect().size.x, poly_lt.y + graphnode.get_rect().size.y)
				var poly_lb = Vector2(poly_lt.x, poly_lt.y + graphnode.get_rect().size.y)
				var poly:PoolVector2Array = PoolVector2Array([poly_lt,poly_rt,poly_rb,poly_lb])
				var intersect_points = Geometry.intersect_polyline_with_polygon_2d(_right_click_line.points,poly)
				if 0 < intersect_points.size():
					through_nodes.append(graphnode)
					through_points.append(intersect_points[0][0])
					
		# 2つ以上通過していたら最初の２GraphNodeをつなげる 近い方から遠い方につなぐ
		if 2 <= through_nodes.size():
			var is_LtoR = Geometry.get_closest_point_to_segment_2d(_right_click_line.points[0],through_points[0],through_points[1]) == through_points[0]
			if is_LtoR:
#				print(get_connection_list())
				var from_slot:int = get_top_right_slot_idx(through_nodes[0])
				var to_slot:int = get_top_left_slot_idx(through_nodes[1])
#				print(Vector2(from_slot,to_slot))
				if from_slot != -1 and to_slot != -1:
					connect_request(through_nodes[0], from_slot, through_nodes[1], to_slot)
			else:
				var from_slot:int = get_top_right_slot_idx(through_nodes[1])
				var to_slot:int = get_top_left_slot_idx(through_nodes[0])
#				print(Vector2(from_slot,to_slot))
				if from_slot != -1 and to_slot != -1:
					connect_request(through_nodes[1], from_slot, through_nodes[0], to_slot)
		_right_click_line.clear_points()

func disconnect_node_all(node:GraphNode):
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.from or node.name == conn.to:
			disconnect_node(conn.from,conn.from_port,conn.to,conn.to_port)

func connect_node_slot(from_node:GraphNode,right_slot:int,to_node:GraphNode,left_slot:int):
	var from_port = from_node.conv_rightslot_to_fromport(right_slot)
	var to_port = to_node.conv_leftslot_to_toport(left_slot)
#	print("right_slot=",right_slot,"from_port=",from_port)
#	print("left_slot=",left_slot,"to_port=",to_port)
	connect_node(from_node.name,from_port,to_node.name,to_port)

func disconnect_node_slot(from_node:GraphNode,right_slot:int,to_node:GraphNode,left_slot:int):
	var from_port = from_node.conv_rightslot_to_fromport(right_slot)
	var to_port = to_node.conv_leftslot_to_toport(left_slot)
	disconnect_node(from_node.name,from_port,to_node.name,to_port)

func disconnect_node_port(node:GraphNode, idx:int):
	disconnect_node_from_port(node, idx)
	disconnect_node_to_port(node, idx)

func disconnect_node_from_port(node:GraphNode, idx:int):
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.from and conn.from_port == idx:
			disconnect_node(conn.from,conn.from_port,conn.to,conn.to_port)
			
func disconnect_node_to_port(node:GraphNode, idx:int):
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.to and conn.to_port == idx:
#			print([conn.from,conn.from_port,conn.to,conn.to_port])
			disconnect_node(conn.from,conn.from_port,conn.to,conn.to_port)

func get_connections_node_idx(node:GraphNode, idx:int)->Array:
	var array := []
	array.append_array(get_connections_node_idx_from(node, idx))
	array.append_array(get_connections_node_idx_to(node, idx))
	return array

func get_connections_node_from(node:GraphNode)->Array:
	var array := []
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.from:
			array.append(conn)
	return array

func get_connections_node_idx_from(node:GraphNode, idx:int)->Array:
	var array := []
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.from and conn.from_port == idx:
			array.append(conn)
	return array

func get_connections_node_to(node:GraphNode)->Array:
	var array := []
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.to:
			array.append(conn)
	return array

func get_connections_node_idx_to(node:GraphNode, idx:int)->Array:
	var array := []
	var connections:Array = get_connection_list()
	for conn in connections:
		if node.name == conn.to and conn.to_port == idx:
			array.append(conn)
	return array
	
func get_graph_node_by_name(name:String)->Node:
	var node = get_node_or_null(NodePath("./" + name))
	if node == null:
		assert(name + "is not GraphEdit's child")
	assert(node is GraphNode)
	return node

# 最も上の空きスロットNoを返す
func get_top_right_slot_idx(node:GraphNode) -> int:
	var slot_count = node.get_slot_count()
	var connections:Array = get_connection_list()
	connections.sort_custom(MyCustomSorter,"sort_from_port_ascending")
	for slot_idx in range(0,slot_count):
		if !node.is_slot_enabled_right(slot_idx):
			continue
		# 空きスロットかどうか判定＝connをすべてチェックする
		var is_empty = true
		for conn in connections:
			if node.name != conn.from:
				continue
#			print("[from_port]",conn.from_port)
			var from_slot = node.conv_fromport_to_rightslot(conn.from_port)
#			print("[from_slot]",from_slot)
			if slot_idx == from_slot:
				is_empty = false
				continue
		if is_empty:
			print("[top_right_slot]",slot_idx)
			return slot_idx
	return -1
func get_top_left_slot_idx(node:GraphNode) -> int:
	var slot_count = node.get_slot_count()
	var connections:Array = get_connection_list()
	connections.sort_custom(MyCustomSorter,"sort_from_port_ascending")
	for slot_idx in range(0,slot_count):
		if !node.is_slot_enabled_left(slot_idx):
			continue
		# 空きスロットかどうか判定＝connをすべてチェックする
		var is_empty = true
		for conn in connections:
			if node.name != conn.to:
				continue
#			print("[to_port]",conn.from_port)
			var to_slot = node.conv_toport_to_leftslot(conn.to_port)
#			print("[to_slot]",to_slot)
			if slot_idx == to_slot:
				is_empty = false
				continue
		if is_empty:
			print("[top_left_slot]",slot_idx)
			return slot_idx
	return -1
#	var node_count = node.get_slot_count()
#	var connections:Array = get_connection_list()
#	connections.sort_custom(MyCustomSorter,"sort_to_port_ascending")
#	# { from_port: 0, from: "GraphNode name 0", to_port: 1, to: "GraphNode name 1" }
#	var idx:int = 0
#	for conn in connections:
#		if node.name != conn.to:
#			continue
#		if int(conn.to_port) == node_count - 1:
#			return -1
#		idx = idx+1
#	print("leftslot_top",idx)
#	return idx
func slide_down_left_slots(node:GraphNode,to_port:int) -> void:
	var connections:Array = get_connection_list()
#	connections.sort_custom(MyCustomSorter,"sort_to_port_ascending")
#	print_debug(node)
#	print_debug(to_port)
	# ずらし対象のコネクションのみとる
	var filtered_conns:Array = []
	for conn in connections:
		if node.name != conn.from:
			continue
		if int(conn.to_port) > to_port:
			filtered_conns.append(conn)
#	print_debug(filtered_conns)
	# コネクションを消してからずらしたものを追加する
	for conn in filtered_conns:
		disconnect_node(conn.from,conn.from_port,conn.to,conn.to_port)
		connect_node(conn.from,conn.from_port + 1,conn.to,conn.to_port)

func slide_up_right_slots(node:GraphNode,from_port:int) -> void:
	var connections:Array = get_connection_list()
	# ずらし対象のコネクションのみとる, node,slotに変換
	var filtered_conns:Array = []
	for conn in connections:
		if node.name != conn.from:
			continue
		if int(conn.from_port) > from_port:
			var from_node = get_graph_node_by_name(conn.from)
			var to_node = get_graph_node_by_name(conn.to)
			filtered_conns.append({
				"from_node": from_node,
				"right_slot": from_node.conv_fromport_to_rightslot(conn.from_port),
				"to_node": to_node,
				"left_slot": to_node.conv_toport_to_leftslot(conn.to_port)
				})
	print(filtered_conns)
	# コネクションを消してからずらしたものを追加する
	for conn in filtered_conns:
		disconnect_node_slot(conn.from_node,conn.right_slot,conn.to_node,conn.left_slot)

	for conn in filtered_conns:
		var fromport = conn.from_node.conv_rightslot_to_fromport(conn.right_slot)
		var toport = conn.to_node.conv_leftslot_to_toport(conn.left_slot)
		connect_node(conn.from_node.name,fromport-1,conn.to_node.name,toport)

func slide_down_right_slots(node:GraphNode,from_port:int) -> void:
	var connections:Array = get_connection_list()
	# ずらし対象のコネクションのみとる
	var filtered_conns:Array = []
	for conn in connections:
		if node.name != conn.from:
			continue
		if int(conn.from_port) > from_port:
			var from_node = get_graph_node_by_name(conn.from)
			var to_node = get_graph_node_by_name(conn.to)
			filtered_conns.append({
				"from_node": from_node,
				"right_slot": from_node.conv_fromport_to_rightslot(conn.from_port),
				"to_node": to_node,
				"left_slot": to_node.conv_toport_to_leftslot(conn.to_port)
				})
	# コネクションを消してからずらしたものを追加する
	for conn in filtered_conns:
		disconnect_node_slot(conn.from_node,conn.right_slot,conn.to_node,conn.left_slot)

	for conn in filtered_conns:
		var fromport = conn.from_node.conv_rightslot_to_fromport(conn.right_slot)
		var toport = conn.to_node.conv_leftslot_to_toport(conn.left_slot)
		connect_node(conn.from_node.name,fromport+1,conn.to_node.name,toport)

func _process(delta):
#	var dic = {}
#	dic["maps"] = get_map_data_json()
#	dic["connections"] = get_connection_json()
#	$MapSetting/DEBUG.text = JSON.print(dic)
	if _is_right_dragging:
		_right_click_line.add_point(get_local_mouse_position())
	
func show():
	for graphnode in get_children():
		if graphnode.has_meta("map") and graphnode.visible:
			graphnode._on_TextureUpdateButton_pressed()
			
func get_custom_data_defaults() -> Array:
	return map_setting.get_custom_data_list(true)

class MyCustomSorter:
	static func sort_from_port_ascending(a, b):
		if a.from_port < b.from_port:
			return true
		return false
	static func sort_to_port_ascending(a, b):
		if a.to_port < b.to_port:
			return true
		return false


func _on_MapSetting_exportjson():
	$CanvasLayer/FileDialog.show_modal()


func _on_MapSetting_save():
	save()

func _on_FileDialog_file_selected(path:String):
	var save_path = path.get_basename().split(".")[0] + ".json"
	var file = File.new()
	file.open(save_path,File.WRITE)
	var dic = {}
	dic["maps"] = get_map_data_json()
	dic["connections"] = get_connection_json()
	var json_str = JSON.print(dic)
	file.store_string(json_str)
	file.close()
