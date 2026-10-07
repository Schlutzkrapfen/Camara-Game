@tool
extends Camera2D
class_name CameraController

## When true, the camera uses the "Locked Limits" below instead of the normal
## "Limits". At the moment it becomes locked, the camera glides to the centre
## of the locked limits. Edge scrolling and zooming then work as usual inside them.
@export var locked: bool = false
@export var lock_smoothing: float = 6.0 # higher = snappier glide

@export_group("Edge Scrolling")
## Master switch for edge scrolling (both axes). When off, moving the mouse to
## the screen edge never scrolls the camera. WASD movement and zoom still work.
@export var edge_scrolling_enabled: bool = true
@export var max_speed: float = 700.0 # screen pixels/sec at the very screen edge
@export_range(0.02, 0.5) var edge_size: float = 0.15 # fraction of screen height that scrolls
@export var speed_smoothing: float = 10.0 # higher = faster speed changes

@export_subgroup("Horizontal")
@export var scroll_x_enabled: bool = true
@export var max_speed_x: float = 700.0 # screen pixels/sec at the very left/right screen edge
@export_range(0.02, 0.5) var edge_size_x: float = 0.08 # fraction of screen width that scrolls

@export_group("Keyboard Movement")
## Move the camera with W/A/S/D (physical keys, so it also works on AZERTY etc.).
## Independent of edge scrolling. Ignored while a UI control has keyboard focus.
@export var keyboard_enabled: bool = true
@export var keyboard_speed: float = 700.0 # screen pixels/sec
@export var keyboard_smoothing: float = 10.0 # higher = faster speed changes

@export_group("Zoom")
@export var min_zoom: float = 0.5 # zoomed out (sees more)
@export var max_zoom: float = 3.0 # zoomed in (sees less)
@export var zoom_step: float = 1.1 # multiplier per mouse-wheel notch
@export var zoom_smoothing: float = 12.0 # higher = snappier zoom
## Keep the world point under the mouse cursor fixed while zooming.
@export var zoom_to_cursor: bool = true
## Don't allow zooming out so far that the view is larger than the current
## limits (so you never see outside the bounds). The effective minimum zoom
## is raised automatically, e.g. when `locked` switches to smaller limits.
@export var fit_zoom_to_limits: bool = true

@export_group("Limits")
## All limits bound the camera's OUTER EDGES (the visible area on screen), not
## its position. They adapt to the viewport size and the current zoom. If the
## view is larger than the bounds on an axis, the camera stays centred between
## them on that axis.
@export var min_y: float = -2000.0
@export var max_y: float = 2000.0
@export var min_x: float = -2000.0
@export var max_x: float = 2000.0

@export_group("Locked Limits")
## Same rules as "Limits", but used while `locked` is true.
@export var locked_min_y: float = -500.0
@export var locked_max_y: float = 500.0
@export var locked_min_x: float = -500.0
@export var locked_max_x: float = 500.0

@export_group("Gizmos")
## Draws the limits in the 2D editor and in game. The active set is drawn
## bold and the inactive set faded. The locked set also gets a cross at its
## centre (where the camera glides to when locking).
@export var show_gizmos: bool = true
@export var limits_color: Color = Color(0.25, 0.85, 1.0)
@export var locked_limits_color: Color = Color(1.0, 0.6, 0.15)

var _velocity: float = 0.0
var _velocity_x: float = 0.0
var _key_velocity: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.0
var _was_locked: bool = false
var _gliding: bool = false
var _glide_target: Vector2 = Vector2.ZERO
var _gizmo: Node2D


func _ready() -> void:
	_target_zoom = zoom.x

	# Gizmos are drawn by a top-level child so we can draw in world coordinates.
	var existing := get_node_or_null("LimitGizmos")
	if existing:
		existing.free() # avoid duplicates if the tool script reloads in the editor
	_gizmo = Node2D.new()
	_gizmo.name = "LimitGizmos"
	_gizmo.top_level = true
	_gizmo.z_as_relative = false
	_gizmo.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_gizmo.draw.connect(_draw_gizmos)
	add_child(_gizmo)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom *= zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom /= zoom_step


func _process(delta: float) -> void:
	_update_gizmo_visibility()
	if Engine.is_editor_hint():
		return # in the editor we only draw the gizmos

	var limits := _active_limits()

	_update_lock_state(limits)
	_update_zoom(delta, limits)

	if _gliding:
		_glide(delta)
	else:
		_edge_scroll(delta, limits)
		_keyboard_move(delta)

	# Final safety net: whatever moved or zoomed the camera this frame,
	# the visible area never leaves the limits.
	global_position = _constrain(global_position, limits)


## The world-space rectangle currently visible through this camera
## (its outer bounds). Depends on viewport size and zoom.
func get_view_rect() -> Rect2:
	var half := _half_view()
	return Rect2(global_position - half, half * 2.0)


## Half the visible world size, from the viewport size and zoom.
func _half_view() -> Vector2:
	return get_viewport_rect().size * 0.5 / zoom


## The limits currently in effect, as a Rect2 (position = min corner, end = max corner).
func _active_limits() -> Rect2:
	return _locked_limits() if locked else _normal_limits()


func _normal_limits() -> Rect2:
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _locked_limits() -> Rect2:
	return Rect2(locked_min_x, locked_min_y, locked_max_x - locked_min_x, locked_max_y - locked_min_y)


## Detects lock/unlock and starts a glide to the right spot.
func _update_lock_state(limits: Rect2) -> void:
	if locked == _was_locked:
		return
	_was_locked = locked
	_velocity = 0.0
	_velocity_x = 0.0
	_key_velocity = Vector2.ZERO
	_gliding = true
	if locked:
		_glide_target = limits.get_center() # centre of the locked limits
	else:
		# Back to normal limits: nearest valid position (no-op if already inside)
		_glide_target = _constrain(global_position, limits)


## Frame-rate independent smooth move; edge scrolling pauses until we arrive.
func _glide(delta: float) -> void:
	global_position = global_position.lerp(_glide_target, 1.0 - exp(-lock_smoothing * delta))
	if global_position.distance_to(_glide_target) < 1.0:
		global_position = _glide_target
		_gliding = false


func _edge_scroll(delta: float, limits: Rect2) -> void:
	var viewport := get_viewport()
	var view_size := viewport.get_visible_rect().size
	var mouse := viewport.get_mouse_position()

	# Smooth the speed so starting/stopping isn't abrupt
	var blend := 1.0 - exp(-speed_smoothing * delta)

	# Divide by zoom so the scroll speed looks the same on screen at any zoom.
	# With the master toggle off the strength is 0, so any leftover speed
	# eases out smoothly instead of stopping dead.
	var strength_y := _edge_strength(mouse.y, view_size.y, edge_size) if edge_scrolling_enabled else 0.0
	_velocity = lerpf(_velocity, strength_y * max_speed / zoom.y, blend)
	global_position.y += _velocity * delta

	if scroll_x_enabled:
		var strength_x := _edge_strength(mouse.x, view_size.x, edge_size_x) if edge_scrolling_enabled else 0.0
		_velocity_x = lerpf(_velocity_x, strength_x * max_speed_x / zoom.x, blend)
		global_position.x += _velocity_x * delta
	else:
		_velocity_x = 0.0


## WASD movement. Speed is divided by zoom so it feels the same on screen at
## any zoom level, and diagonals are normalised so they aren't faster.
func _keyboard_move(delta: float) -> void:
	var dir := Vector2.ZERO
	# Don't steal keys while the player is typing in a LineEdit etc.
	if keyboard_enabled and get_viewport().gui_get_focus_owner() == null:
		dir = Vector2(
			int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
			int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W)))
		dir = dir.normalized()

	var blend := 1.0 - exp(-keyboard_smoothing * delta)
	_key_velocity = _key_velocity.lerp(dir * keyboard_speed / zoom.x, blend)
	if _key_velocity.length_squared() < 0.01:
		_key_velocity = Vector2.ZERO
	global_position += _key_velocity * delta


## Smoothly moves zoom toward the (bounds-aware) target zoom.
func _update_zoom(delta: float, limits: Rect2) -> void:
	_target_zoom = clampf(_target_zoom, _min_zoom_for(limits), max_zoom)

	var old_zoom := zoom.x
	var new_zoom := lerpf(old_zoom, _target_zoom, 1.0 - exp(-zoom_smoothing * delta))
	if absf(new_zoom - _target_zoom) < 0.0001:
		new_zoom = _target_zoom
	if is_equal_approx(new_zoom, old_zoom):
		return

	if zoom_to_cursor and not _gliding:
		# Shift the camera so the world point under the cursor stays put.
		var offset_px := get_viewport().get_mouse_position() - get_viewport_rect().size * 0.5
		global_position += offset_px / old_zoom - offset_px / new_zoom
	zoom = Vector2(new_zoom, new_zoom)


## Lowest zoom allowed right now: `min_zoom`, raised if needed so the view fits
## inside `limits` (never above `max_zoom`).
func _min_zoom_for(limits: Rect2) -> float:
	var z := min_zoom
	if fit_zoom_to_limits:
		var view_size := get_viewport_rect().size
		z = maxf(z, view_size.x / maxf(limits.size.x, 1.0))
		z = maxf(z, view_size.y / maxf(limits.size.y, 1.0))
	return minf(z, max_zoom)


## Returns -1 (low edge) .. 0 (middle) .. +1 (high edge) for one axis.
func _edge_strength(pos: float, length: float, zone_fraction: float) -> float:
	var zone := length * zone_fraction
	var strength := 0.0
	if pos < zone:
		strength = -(1.0 - pos / zone)
	elif pos > length - zone:
		strength = (pos - (length - zone)) / zone
	return clampf(strength, -1.0, 1.0)


## Clamps the camera position so its outer edges (the visible area) stay
## within the limits.
func _constrain(pos: Vector2, limits: Rect2) -> Vector2:
	var half := _half_view()
	return Vector2(
		_clamp_axis(pos.x, limits.position.x, limits.end.x, half.x),
		_clamp_axis(pos.y, limits.position.y, limits.end.y, half.y))


func _clamp_axis(value: float, lo_limit: float, hi_limit: float, half_view: float) -> float:
	var lo := lo_limit + half_view
	var hi := hi_limit - half_view
	if lo > hi:
		return (lo_limit + hi_limit) * 0.5 # view larger than the bounds: stay centred
	return clampf(value, lo, hi)


# ---------------------------------------------------------------- Gizmos ---

func _update_gizmo_visibility() -> void:
	if _gizmo == null:
		return
	_gizmo.visible = show_gizmos
	if show_gizmos:
		_gizmo.queue_redraw() # limits/zoom can change any frame (and in the editor)


func _draw_gizmos() -> void:
	# The set matching the `locked` flag is drawn bold; the other one faded.
	_draw_limits(_normal_limits(), limits_color, "LIMITS", not locked)
	_draw_limits(_locked_limits(), locked_limits_color, "LOCKED LIMITS", locked)


func _draw_limits(rect: Rect2, color: Color, label: String, active: bool) -> void:
	var zoom_px := 1.0 / zoom.x # world units per screen pixel: keeps lines/text a constant size
	var c := Color(color, 1.0 if active else 0.35)
	var width := (3.0 if active else 1.5) * zoom_px

	_gizmo.draw_rect(rect, c, false, width)

	# Cross at the centre of the limits (where the camera glides to when locked)
	var center := rect.get_center()
	var arm := 14.0 * zoom_px
	_gizmo.draw_line(center - Vector2(arm, 0), center + Vector2(arm, 0), c, width)
	_gizmo.draw_line(center - Vector2(0, arm), center + Vector2(0, arm), c, width)

	# Label in the top-left corner, drawn in screen-sized units
	_gizmo.draw_set_transform(rect.position, 0.0, Vector2(zoom_px, zoom_px))
	_gizmo.draw_string(ThemeDB.fallback_font, Vector2(6, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c)
	_gizmo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
