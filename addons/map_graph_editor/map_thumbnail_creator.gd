tool
extends Node

func create_thumbnail(texture_rect:TextureRect,_map:Node,class_names:Array) -> ImageTexture:
	var tilemaps:Array = []
	var tile_nodes = []
	tilemaps = _get_all_tile_map(_map, tile_nodes)
	var sprites:Array = []
	var sprite_nodes = []
	sprites = _get_all_sprite(_map, sprite_nodes)
	
	var maps = []
	# 対象とするNode
	var all_nodes = []
	if class_names == null:
		maps = _get_all_node(_map, all_nodes)
	else:
		maps = _get_all_class_node(_map, all_nodes,class_names)
#	print(maps)
	# 全体のサイズを取得して包括するViewportを作る
	var tmp_viewport = Viewport.new()
	tmp_viewport.transparent_bg = true
	tmp_viewport.usage = Viewport.USAGE_2D
	tmp_viewport.disable_3d = true
	tmp_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	get_tree().get_root().add_child(tmp_viewport)
	var right_x = 0
	var bottom_y = 0
	var left_x = 0
	var top_y = 0
	
	# 最終的なRectは包括にしたいので一番大きかったらサイズ更新してすべてを包むサイズを取得する
	if tilemaps.size() > 0:
		# TileMapが1つでもあれば全体サイズはタイルセットにする
		for map in tilemaps:
			var map_rect:Rect2 = map.get_used_rect()
			var right_bottom = (map_rect.position + map_rect.size) * map.cell_size
			var top_left = map_rect.position * map.cell_size
			if right_bottom.x > right_x:
				right_x = right_bottom.x
			if right_bottom.y > bottom_y:
				bottom_y = right_bottom.y
			if top_left.x < left_x:
				left_x = top_left.x
			if top_left.y < top_y:
				top_y = top_left.y
	elif sprites.size() > 0:
		# Spriteが1つでもあれば全体サイズはSpriteにする
		for sprite in sprites:
			if sprite.texture == null: continue
			var right_bottom = sprite.position + sprite.texture.get_size()
			var top_left = sprite.position
			if right_bottom.x > right_x:
				right_x = right_bottom.x
			if right_bottom.y > bottom_y:
				bottom_y = right_bottom.y
			if top_left.x < left_x:
				left_x = top_left.x
			if top_left.y < top_y:
				top_y = top_left.y
	else:
		# TileMapもSpriteもなければプロジェクト設定の画面単位の収まる範囲にしてお茶をにごす
		var project_width = int(ProjectSettings.get_setting("display/window/size/width"))
		var project_height = int(ProjectSettings.get_setting("display/window/size/height"))
		right_x = project_width
		bottom_y = project_height
		
	
	tmp_viewport.size = Vector2(right_x - left_x, bottom_y - top_y)

	# 出力する
	var dup_maps = []
	var index = -1
	for map in maps:
		index = index + 1
		# 一時Viewportの子に追加する
		var dup_map = map.duplicate()
		tmp_viewport.add_child(dup_map)
		dup_maps.append(dup_map)
	
	# 描画する
	yield(VisualServer, "frame_post_draw")
	var image_data:Image = tmp_viewport.get_texture().get_data()
	image_data.flip_y()
	
#	print(image_data.get_size())

	# PNG出力
#	image_data.save_png("res://hoge.png")

	for dup_map in dup_maps:
		tmp_viewport.remove_child(dup_map)
		
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image_data)
	texture_rect.texture = image_texture
	# 終了
	get_tree().get_root().remove_child(tmp_viewport)
	return image_texture

func _get_all_node(node:Node, array:Array)-> Array:
	for n in node.get_children():
		array.append(n)
		array = _get_all_node(n, array)
	return array

func _get_all_class_node(node:Node, array:Array, class_names:Array)-> Array:
	for n in node.get_children():
		for classname in class_names:
			if n.get_class() == classname:
				array.append(n)
				break
		array = _get_all_class_node(n, array,class_names)
	return array

func _get_all_tile_map(node:Node, array:Array)-> Array:
	for n in node.get_children():
		if n is TileMap:
			array.append(n)
		array = _get_all_tile_map(n, array)
	return array
func _get_all_sprite(node:Node, array:Array)-> Array:
	for n in node.get_children():
		if n is Sprite:
			array.append(n)
		array = _get_all_tile_map(n, array)
	return array
