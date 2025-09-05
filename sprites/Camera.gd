extends Camera2D

var panning = false
var pan_start_pos = Vector2.ZERO
var build_area = null

func _ready():
	build_area = get_parent().get_node("BuildArea")  # Ссылка на BuildArea

func _input(event):
	# Панорамирование камеры (движение) с помощью правой кнопки мыши
	if event is InputEventMouseButton:
		# Панорамирование по нажатию правой кнопки
		if event.button_index == MOUSE_BUTTON_RIGHT:
			panning = event.pressed
			pan_start_pos = event.position
		
		# Вертикальная прокрутка с помощью колеса мыши
		if event.is_pressed():
			var scroll_speed = 32  # Настраиваемая скорость прокрутки
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				position.y -= scroll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				position.y += scroll_speed
				
	elif event is InputEventMouseMotion and panning:
		var delta = pan_start_pos - event.position
		position += delta
		pan_start_pos = event.position
	
	# Ограничение камеры
	if build_area:
		position.x = clamp(position.x, 0, build_area.size.x)
		position.y = clamp(position.y, 0, build_area.size.y)
	else:
		position.x = clamp(position.x, 0, 1264)
		position.y = clamp(position.y, 0, 851)
