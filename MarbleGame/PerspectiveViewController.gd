@tool
extends SubViewportContainer

func _ready():
	if Engine.is_editor_hint():
		if is_inside_tree():
			_setup_connections()
		else:
			tree_entered.connect(_setup_connections, CONNECT_ONE_SHOT)
	else:
		# Runtime 等待一幀確保子節點都初始化完畢
		if is_inside_tree():
			await get_tree().process_frame
		_setup_connections()

func _setup_connections():
	var world_root = get_node_or_null("SubViewport/WorldRoot")
	if not world_root:
		return
		
	var table_viewport = world_root.get_node_or_null("TableViewport")
	var table_mesh     = world_root.get_node_or_null("TableMesh")
	var input_area     = world_root.get_node_or_null("InputArea")
	
	# 1. 綁定材質與貼圖
	if table_viewport and table_mesh:
		var tex = table_viewport.get_texture()
		var mat = table_mesh.material_override
		if not mat or not (mat is StandardMaterial3D):
			mat = StandardMaterial3D.new()
			mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			table_mesh.material_override = mat
		mat.albedo_texture = tex
		print("LOG: [Tool] ViewportTexture 綁定成功 (Ready)")
		
	# 2. 綁定 InputArea 的 viewport 與 mesh
	if input_area and table_viewport and table_mesh:
		input_area.viewport = table_viewport
		input_area.mesh     = table_mesh
		print("LOG: [Tool] InputArea 綁定成功")
