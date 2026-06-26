extends TileMapLayer

const SPAWN_RANGE := 4
const REDUCTION_FROM_MAX := 3
var max_exponent := 0
var is_dragging := false
var square_hovered: Square
var connected_squares: Array[Square]
var squares: Dictionary[Vector2i, Square]
const order_letters := ['', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y', 'R', 'Q']
const colors := [
	Color(0.0, 0.0, 0.0, 1.0),
	Color(0.0, 0.0, 1.0, 1.0),
	Color(0.5, 0.0, 1.0, 1.0),
	Color(1.0, 0.0, 1.0, 1.0),
	Color(1.0, 0.0, 0.0, 1.0),
	Color(1.0, 0.5, 0.0, 1.0),
	Color(1.0, 1.0, 0.0, 1.0),
	Color(0.0, 1.0, 0.0, 1.0),
	Color(0.0, 1.0, 1.0, 1.0),
	Color(0.0, 0.5, 1.0, 1.0),
]


func _ready() -> void:
	spawned.resize(get_used_rect().size.x)
	child_entered_tree.connect(connect_squares_at_start)
	await get_tree().process_frame
	child_entered_tree.disconnect(connect_squares_at_start)
	Event.square_hovered.connect(_on_square_hovered)
	Event.square_unhovered.connect(_on_square_unhovered)


func connect_squares_at_start(square: Square):
	var coord := local_to_map(square.position)
	squares[coord] = square
	make_random(square)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if square_hovered:
				_on_square_clicked(square_hovered)
		else:
			unclick()


func _on_square_clicked(square: Square):
	is_dragging = true
	square.outline.show()
	connected_squares.append(square)
	highlight_available_connections_around(square)


func _on_square_hovered(square: Square):
	square_hovered = square
	if is_dragging:
		if square in connected_squares:
			if connected_squares.size() > 1 and square == connected_squares[-2]:
				var last_square := connected_squares.pop_back() as Square
				last_square.outline.hide()
				last_square.connection.hide()
				highlight_available_connections_around(square)
			return
		if not square in highlighted: return
		square.connect_to(connected_squares[-1])
		connected_squares.append(square)
		highlight_available_connections_around(square)
		square.outline.show()


func _on_square_unhovered(square: Square): 
	if square == square_hovered:
		square_hovered = null


func unclick():
	if not connected_squares: return
	while highlighted:
		highlighted.pop_back().highlight.hide()
	is_dragging = false
	
	if connected_squares.size() == 1:
		prints('no squares were connected')
		connected_squares.pop_back().outline.hide()
		return
	
	var sum := 0
	for square: Square in connected_squares:
		sum += square.value
	var last_square := connected_squares.pop_back() as Square
	var exponent := Utils.log2(sum)
	last_square.value = 2 ** exponent
	update_square(last_square)
	last_square.outline.hide()
	last_square.connection.hide()
	
	if exponent > max_exponent:
		max_exponent = exponent
		%MaxNumLabel.text = str( 2 ** max_exponent )
		for square: Square in squares.values():
			if square.input_pickable \
			and not square in connected_squares \
			and not square == last_square \
			and Utils.log2(square.value) < max_exponent - SPAWN_RANGE - REDUCTION_FROM_MAX:
				connected_squares.append(square)
				prints('deleting', square.value)
	
	prints('deleting squares', connected_squares)
	var holes: Array[Vector2i]
	for square: Square in connected_squares:
		var coord := local_to_map(square.position)
		square.queue_free()
		squares.erase(coord)
		holes.append(coord)
	connected_squares.clear()
	holes.sort()
	
	var moved_squares_coords: Dictionary[Square, Vector2i]
	for hole: Vector2i in holes:
		while hole.y >= 0:
			var square := squares[hole+Vector2i.UP] if hole.y else spawn(hole.x)
			squares[hole] = square
			moved_squares_coords[square] = hole
			hole += Vector2i.UP
	
	for square: Square in moved_squares_coords:
		square.input_pickable = false
		var tween := square.create_tween()
		var new_pos := moved_squares_coords[square] as Vector2
		new_pos *= tile_set.tile_size as Vector2
		new_pos += Vector2(tile_set.tile_size) * .5
		tween.tween_property(square, 'position', new_pos, 0.3)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(func(): square.input_pickable = true )


var spawned: Array[Square]
func spawn(x: int) -> Square:
	var square := preload("res://square.tscn").instantiate() as Square
	var new_pos = Vector2(tile_set.tile_size) * Vector2(x + .5, 0.5)
	if spawned[x] and is_instance_valid(spawned[x]):
		if spawned[x].position.y < new_pos.y:
			new_pos = spawned[x].position
	new_pos.y -= tile_set.tile_size.y
	square.position = new_pos
	add_child(square)
	spawned[x] = square
	make_random(square)
	return square


var highlighted: Array[Square]
func highlight_available_connections_around(square: Square):
	while highlighted:
		highlighted.pop_back().highlight.hide()
	var coord := local_to_map(square.position)
	for i: int in 8:
		var adjacent_coord := Vector2i(Vector2(1.9, 0).rotated(TAU/8 * i)) + coord
		var neighbor := squares.get(adjacent_coord) as Square
		if not neighbor or neighbor in connected_squares: continue
		if not neighbor.input_pickable: continue
		if square.value == neighbor.value or (
			connected_squares.size()>1 and square.value*2 == neighbor.value
		):
			neighbor.highlight.show()
			highlighted.append(neighbor)


func update_square(square: Square):
	var exponent := Utils.log2(square.value)
	square.number_color_fill.color = colors[exponent % colors.size()]
	var reduced := square.value
	var order := 0
	while reduced > 1000:
		reduced /= 1000
		order += 1
	square.label.text = str( reduced ) + order_letters[order]


func make_random(square: Square):
	var min_power := maxi(0, max_exponent - SPAWN_RANGE - REDUCTION_FROM_MAX)
	square.value = 2 ** randi_range(min_power, min_power + SPAWN_RANGE)
	update_square(square)

