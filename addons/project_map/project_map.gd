tool
extends GraphEdit

var file_node = preload("res://addons/project_map/pm_file_node.tscn")
var file_node_script = preload("res://addons/project_map/pm_file_node.gd")
var group_node = preload("res://addons/project_map/pm_group_node.tscn")
var group_node_script = preload("res://addons/project_map/pm_group_node.gd")
var common_node_script = preload("res://addons/project_map/pm_common_node.gd")

var comment_node = preload("res://addons/project_map/pm_comment_node.tscn")
var comment_node_script = preload("res://addons/project_map/pm_comment_node.gd")

var resource_previewer:EditorResourcePreview

var dirty = false

var add_panel: = false
var add_comment: = false
var add_comment_large: = false

var undo_redo:UndoRedo

var button_font = preload("res://addons/project_map/fonts/map_button_font.tres")
var comment_font = preload("res://addons/project_map/fonts/map_comment_font.tres")
var comment_large_font = preload("res://addons/project_map/fonts/map_comment_large_font.tres")

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
		comment_large_button.text = "Add Comment Large"
	
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
	
		var node:GraphNode = add_node(file_node, pos)

		#this sets the script variable for saving, do not remove
		var path:String = file_path
		node.path = path
		node.init(path)

		#adjust offset when dropping multiple files
		node.offset.y += last_node_row * snap_distance
		last_node_row += node.get_row_count()
		
		dirty = true
		
	pass

func _undo_create_file_nodes(undo_id):
	
	for node in get_children():
		if node.get("undo_id"):
			if node.undo_id == undo_id:
				node.queue_free()
				dirty = true
	
	pass

func drop_data(pos, data):

	var last_node_row = 0
	
	undo_redo.create_action("Create file nodes")
	
	#set exported variables before adding to tree
	#to be able to save script data
	for file_path in data.files:
	
		var node:GraphNode = add_node(file_node, pos)

		#this sets the script variable for saving, do not remove
		var path:String = file_path
		node.path = path
		node.init(path)

		#adjust offset when dropping multiple files
		node.offset.y += last_node_row * snap_distance
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
		if not node.visible:
			node.free()
	
	if dirty:
	
		var packed_scene:PackedScene = PackedScene.new()
		
		packed_scene.pack(self)

		ResourceSaver.save("res://addons/project_map/project_map_save.tscn", packed_scene)
		
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
				if selected_node is file_node_script and selected_node.selected:
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
	
#	print("node moved")
	
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
			zoom = min(zoom, 1)
			accept_event()
			
		elif event.button_index == BUTTON_WHEEL_DOWN:
			
			zoom -= zoom_speed
			accept_event()


func _on_ProjectMap_connection_request(from, from_slot, to, to_slot):
	print(from)
	print(to)
#	if from == to : return
	connect_node(from, from_slot, to, to_slot)

func _on_ProjectMap_disconnection_request(from, from_slot, to, to_slot):
	disconnect_node(from, from_slot, to, to_slot)

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
#			var graphnode:GraphNode
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
#			print(_right_click_line.points[0])
#			print(through_points[0])
#			print(through_points[1])
			var is_LtoR = Geometry.get_closest_point_to_segment_2d(_right_click_line.points[0],through_points[0],through_points[1]) == through_points[0]
			if is_LtoR and !is_node_connected(through_nodes[0].name, 0, through_nodes[1].name, 0):
					print(through_nodes[0].name)
					print(through_nodes[1].name)
					connect_node(through_nodes[0].name, 0, through_nodes[1].name, 0)
			elif !is_LtoR and !is_node_connected(through_nodes[1].name, 0, through_nodes[0].name, 0):
					print(through_nodes[1].name)
					print(through_nodes[0].name)
					connect_node(through_nodes[1].name, 0, through_nodes[0].name, 0)
		
		_right_click_line.clear_points()
		
		
		
#		var mouse_ev:InputEventMouseButton = event
#		mouse_ev.position

func _process(delta):
	if _is_right_dragging:
		_right_click_line.add_point(get_local_mouse_position())
	
	
func show():
	for graphnode in get_children():
		if graphnode.has_meta("map") and graphnode.visible:
			graphnode.update_thumbnail()
