@tool
extends EditorPlugin
class_name BrushEditor

var brush: Brush
var editorCamera: Camera3D
var mouseOverlayPos: Vector2
var lastDrawnMouseOverlayPos: Vector2

var mouseHitPoint: Vector3
var mouseHitNormal: Vector3

enum ButtonStatus {RELEASED, PRESSED}
var drawStatus = ButtonStatus.RELEASED
var eraseStatus = ButtonStatus.RELEASED

const Brush = preload("Brush.gd")

var drawCursor: bool = false
var drawnEver: bool = false

var _prevMouseHitPoint := Vector3.ZERO
var _isDrawDirty := true
var _isEraseDirty := true

var prevMouseHitPoint: Vector3:
	get:
		return _prevMouseHitPoint
	set(value):
		_isDrawDirty = false
		_isEraseDirty = false
		_prevMouseHitPoint = value

func _handles(object):
#	print("_handles")

	if(object is Brush):
		brush = object as Brush
		return object.is_visible_in_tree()

	return false

func _enter_tree():
	#print("editor _enter_tree")
	add_custom_type("Brush", "Node3D", Brush, null)
	set_process(true)
#
func _exit_tree():
	#print("editor_exit_tree")
	remove_custom_type("Brush")
	set_process(false)
	
func _process(delta):
	if(lastDrawnMouseOverlayPos.distance_to(mouseOverlayPos) > 0.0001):
		lastDrawnMouseOverlayPos = mouseOverlayPos
		drawCursor = testCursorSurface()

	if(drawCursor):
		drawHit()
		drawBrush()

func _forward_3d_draw_over_viewport(overlay: Control):
#	print("_forward_3d_draw_over_viewport "+ str(overlay.get_local_mouse_position()))
	mouseOverlayPos = overlay.get_local_mouse_position()

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent):
#	print("_forward_3d_gui_input")
	if(not editorCamera):
		editorCamera = camera
	
	var prevDrawStatus = drawStatus
	var prevEraseStatus = eraseStatus
	
	if event is InputEventMouseButton:
		var buttonEvent = event as InputEventMouseButton
		if buttonEvent.pressed:
			if buttonEvent.button_index == MOUSE_BUTTON_LEFT:
				drawStatus = ButtonStatus.PRESSED
			elif buttonEvent.button_index == MOUSE_BUTTON_RIGHT:
				eraseStatus = ButtonStatus.PRESSED
		else:
			if buttonEvent.button_index == MOUSE_BUTTON_LEFT:
				drawStatus = ButtonStatus.RELEASED
			elif buttonEvent.button_index == MOUSE_BUTTON_RIGHT:
				eraseStatus = ButtonStatus.RELEASED
				
		if(prevDrawStatus == ButtonStatus.PRESSED && drawStatus == ButtonStatus.RELEASED):
			_isDrawDirty = true
		
		if(prevEraseStatus == ButtonStatus.PRESSED && eraseStatus == ButtonStatus.RELEASED):
			_isEraseDirty = true
			
		processMouse()
		
		if(drawStatus == ButtonStatus.PRESSED or eraseStatus == ButtonStatus.PRESSED):
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		
	elif event is InputEventMouseMotion:
		update_overlays()
			
		if drawStatus == ButtonStatus.PRESSED or eraseStatus == ButtonStatus.PRESSED:
			processMouse()
			
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func processMouse():
	if drawStatus == ButtonStatus.PRESSED:
		drawReq()
	if eraseStatus == ButtonStatus.PRESSED:
		eraseReq()

func drawReq():
#	print("drawReq")
	if(_isDrawDirty || mouseHitPoint.distance_to(prevMouseHitPoint) > brush.brushSize):
		prevMouseHitPoint = mouseHitPoint
		draw()

func eraseReq():
#	print("eraseReq")
	if(_isEraseDirty || mouseHitPoint.distance_to(prevMouseHitPoint) > brush.brushSize):
		prevMouseHitPoint = mouseHitPoint
		erase()
	
func erase():
	for child in brush.get_children():
		
		var dist: float = mouseHitPoint.distance_to(child.position)
		
		if(dist < brush.brushSize):
			child.queue_free()
	
func draw():
#	print("draw")
	var localDensity: int = brush.brushDensity
	
	for i in localDensity:
		var dir: Vector3 = Quaternion(Vector3.UP, randf_range(0, 360)) * Vector3.RIGHT;
		
		var spawnPos: Vector3 = (dir * brush.brushSize * randf_range(0.05, 1)) + mouseHitPoint
		spawnObject(spawnPos)

func spawnObject(pos: Vector3):
	var result: Dictionary = raycastTestPos(pos, mouseHitNormal)
	var canPlace: bool = result.wasHit
	#print(result)
	
	if(canPlace):
		var finalPos: Vector3 = result.hitResult.position
		var normal: Vector3 = result.hitResult.normal
		var rotatedNormal: Vector3 = Quaternion.from_euler(brush.getRotation()) * normal

		brush.draw_debug_ray(finalPos, finalPos + normal * 3, Color.BLUE)
		brush.draw_debug_ray(finalPos, finalPos + rotatedNormal * 3, Color.CYAN)
		
		var obj := brush.get_random_paintable()
		
		if(obj == null):
			return

		brush.add_child(obj)
		obj.owner = get_tree().get_edited_scene_root()
		obj.position = finalPos

		obj.global_transform.basis = align_up(obj.global_transform.basis, rotatedNormal)
		
		obj.scale = Vector3.ONE * brush.getRandomSize()
		obj.name = brush.name + "_" + getUnixTimestamp()

# used to test whether to spawn an object over cursor
func raycastTestPos(pos: Vector3, normal: Vector3) -> Dictionary:
	var dir := Vector3.UP
	
	if(brush.useSurfaceNormal):
		dir = normal
	
	var params := PhysicsRayQueryParameters3D.new()
	params.from = pos + dir * 3
	params.to = pos
	
	brush.draw_debug_ray(params.from, params.to, Color.YELLOW)
	
	var result := brush.get_world_3d().direct_space_state.intersect_ray(params)
	
	if result:
		return { "wasHit": true, "hitResult": result }
		
	return { "wasHit": false, "hitResult": result }

# used to test whether to display cursor over a surface
func testCursorSurface() -> bool:
	if(editorCamera == null):
		return false
	
	var from = editorCamera.global_position
	var dir = editorCamera.project_ray_normal(mouseOverlayPos)
	var to = from + dir * 1000
	
	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to

	var result := brush.get_world_3d().direct_space_state.intersect_ray(params)

	if result:
		if result.collider:
			#print("Collided with: ", result.collider.name)
			if(brush.limitToBodies.size() > 0):
				var found: bool = false
				
				for body in brush.limitToBodies:
					#print(body, result.collider)
					if(body == result.collider):
						found = true
						break;
				
				if(!found):
					return false
					
			mouseHitPoint = result.position
			mouseHitNormal = result.normal
			return true
			
	return false
	
func drawHit():
	drawCursorIndicator(0.1, brush.cursorInnerColor)

func drawBrush():
	drawCursorIndicator(brush.brushSize, brush.cursorOuterColor)
	
func drawCursorIndicator(radius: float, color: Color):
	brush.draw_sphere(mouseHitPoint, radius, color)
	
func getUnixTimestamp() -> String:
	return str(Time.get_unix_time_from_system())

# ref: https://github.com/Yog-Shoggoth/Intersection_Test/blob/master/Intersect.gd
func align_up(node_basis: Basis, normal: Vector3):
	node_basis.y = normal
	var potential_z = -node_basis.x.cross(normal)
	var potential_x = -node_basis.z.cross(normal)
	if potential_z.length() > potential_x.length():
		node_basis.x = potential_z
	else:
		node_basis.x = potential_x
	node_basis.z = node_basis.x.cross(node_basis.y)
	node_basis = node_basis.orthonormalized()
	
	return node_basis
