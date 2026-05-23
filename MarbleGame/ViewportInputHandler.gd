extends Area3D

@export var viewport: SubViewport
@export var mesh: MeshInstance3D

var is_mouse_inside = false
var is_mouse_held = false

var last_viewport_pos = Vector2.ZERO

func _ready():
	# 設定 Area3D 監聽輸入
	input_event.connect(_on_input_event)

func _on_input_event(_camera, event, position, _normal, _shape_idx):
	if not viewport:
		return

	# 將 3D 空間座標轉為 UV 座標 (0.0 到 1.0)
	var local_pos = mesh.global_transform.affine_inverse() * position
	
	# 動態取得 QuadMesh 的大小 (此處為 4.57 x 8.14)
	var mesh_size = Vector2(1.0, 1.0)
	if mesh and mesh.mesh is QuadMesh:
		mesh_size = mesh.mesh.size
	
	# 將座標範圍從 [-size/2, size/2] 映射到 [0, 1]
	var uv = Vector2(
		(local_pos.x / mesh_size.x) + 0.5,
		0.5 - (local_pos.y / mesh_size.y)
	)
	
	# 轉換為 Viewport 的像素座標
	var viewport_pos = Vector2(
		uv.x * viewport.size.x,
		uv.y * viewport.size.y
	)
	last_viewport_pos = viewport_pos
	
	if event is InputEventMouseButton and event.pressed:
		print("LOG: 3D Input Detected. Converted to Viewport Pos: ", viewport_pos)

	if event is InputEventMouse:
		var cloned_event = event.duplicate()
		cloned_event.position = viewport_pos
		cloned_event.global_position = viewport_pos
		
		if event is InputEventMouseButton:
			if event.pressed:
				is_mouse_held = true
			else:
				is_mouse_held = false
				
		viewport.push_input(cloned_event)

func _input(event):
	if not viewport:
		return
		
	# 如果滑鼠已經按住，即便移出了 Area3D 範圍，我們也要繼續傳遞事件 (如移動和放開)
	if is_mouse_held:
		if event is InputEventMouseMotion or (event is InputEventMouseButton and not event.pressed):
			var cloned_event = event.duplicate()
			# 這裡我們無法精確計算 3D 座標，所以延用最後一次在區域內的座標
			# 這對於拉桿釋放來說已經足夠
			cloned_event.position = last_viewport_pos
			cloned_event.global_position = last_viewport_pos
			
			if event is InputEventMouseButton and not event.pressed:
				is_mouse_held = false
				
			viewport.push_input(cloned_event)
