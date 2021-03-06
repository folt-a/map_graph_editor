tool
extends VBoxContainer

signal resource_activated(pm_resource)

enum {TYPE_2D, TYPE_3D, TYPE_SCRIPT, TYPE_OTHER, TYPE_DIR, TYPE_MAP,TYPE_TEXTURE}

var resource_path
var resource_type
var resource_name

var icon_class:String
var script_path:String

var is_map:bool = false

func _ready():
	
	pass


func set_icon(icon_class):
	
	$HB/Icon.texture = get_icon(icon_class, "EditorIcons")
	
	if icon_class == "Folder":
		$HB/Icon.modulate = Color("83a3d2")


func set_name(resource_path):
	
	if not resource_name:
		
		resource_name = get_resource_name(resource_path)
		
		if resource_name.find("::") >= 0:
			resource_name = "built-in script"
			
	$HB/Button.text = resource_name


func init(resource_path):
	
	self.resource_path = resource_path

	if icon_class.empty():
		get_resource_info(resource_path)
		
	set_name(resource_path)

	set_icon(icon_class)
	
	if not script_path.empty():
		pass


func get_resource_info(resource_path):
	
	var dir = Directory.new()
	
	if dir.dir_exists(resource_path):
		resource_type = TYPE_DIR
		icon_class = "Folder"
		
	else:
		
		var resource = ResourceLoader.load(resource_path)
	
		if resource is PackedScene:

			var instance = resource.instance()
			
			# TODO Dynamic ClassName
			if is_map:
				$HB/Button.mouse_filter = Control.MOUSE_FILTER_IGNORE
				resource_type = TYPE_MAP
				icon_class = instance.get_class()
			elif instance is Spatial:
				resource_type = TYPE_3D
				icon_class = instance.get_class()
			else:
				resource_type = TYPE_2D
				icon_class = instance.get_class()
			
			var scn_script = instance.get_script()
			
			if scn_script:
				script_path = scn_script.resource_path
			
		elif resource is Resource:
			
			if resource is StreamTexture:
				resource_type = TYPE_TEXTURE
				icon_class = resource.get_class()
			elif resource is Script:
				
				resource_type = TYPE_SCRIPT
				icon_class = "Script"
			else:

				resource_type = TYPE_OTHER
				icon_class = resource.get_class()


func get_resource_name(resource_path):
	
	var split:Array = resource_path.split("/")

	var name = split.pop_back()
	
	if name.empty():
		name = split.pop_back()
		
	return name


func _on_Button_pressed():
	if resource_type != TYPE_MAP:
		emit_signal("resource_activated", self)
