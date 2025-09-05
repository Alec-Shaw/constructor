extends Panel

var selected_node = null  # Узел, который сейчас перемещается
var offset = Vector2.ZERO  # Смещение для точного перемещения
var min_size = Vector2(1264, 851)  # Ваш новый минимальный размер

func _ready():
	mouse_filter = MOUSE_FILTER_PASS  # Пропускаем события мыши к дочерним узлам
	size = min_size  # Устанавливаем начальный размер
	# Синхронизируем BuildAreaBackground
	var background = get_parent().get_node_or_null("BuildAreaBackground")
	if background:
		background.size = size
		background.position = position
		var furnace = background.get_node_or_null("FurnaceSprite")
		if furnace:
			furnace.position = Vector2(size.x / 2, size.y - furnace.texture.get_height() / 2)  # Печь внизу по центру
	print("BuildArea ready, size: ", size, " global_position: ", global_position, " children: ", get_children().size())

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	print("Проверка drop в BuildArea, позиция: ", at_position, " данные: ", data)
	var can_drop = data is Dictionary and data.has("scene") and ResourceLoader.exists(data["scene"])
	print("Можно ли drop: ", can_drop, " Путь сцены: ", data.get("scene", "нет пути"))
	return can_drop

func _drop_data(at_position: Vector2, data: Variant) -> void:
	print("Drop в BuildArea, позиция: ", at_position, " данные: ", data)
	if ResourceLoader.exists(data["scene"]):
		var scene = load(data["scene"]).instantiate()
		var grid_size = 32
		var new_pos = at_position
		# Расширение поля вниз, если new_pos.y < 0
		var expand_amount = 0
		if new_pos.y < 0:
			expand_amount = abs(new_pos.y) + grid_size  # Расширяем на нужное расстояние
			size.y += expand_amount
			# Смещаем все существующие элементы вниз
			for child in get_children():
				child.position.y += expand_amount
			# Синхронизация с BuildAreaBackground
			var background = get_parent().get_node_or_null("BuildAreaBackground")
			if background:
				background.size.y = size.y
				var furnace = background.get_node_or_null("FurnaceSprite")
				if furnace:
					furnace.position.y += expand_amount  # Смещаем печь вниз
			print("Расширено BuildArea вниз на ", expand_amount)
			new_pos.y = expand_amount + new_pos.y  # Корректируем позицию для нового элемента
		# Ограничение позиции внутри границ BuildArea
		new_pos.x = clamp(new_pos.x, 0, size.x - grid_size)
		new_pos.y = clamp(new_pos.y, 0, size.y - grid_size)
		scene.position = Vector2(
			round(new_pos.x / grid_size) * grid_size,
			round(new_pos.y / grid_size) * grid_size
		)
		scene.z_index = 1  # Выше фона
		add_child(scene)
		print("Добавлена сцена: ", data["scene"], " в позиции: ", scene.position)
		print("Теперь детей в BuildArea: ", get_children().size())
	else:
		print("Ошибка: Сцена не найдена: ", data["scene"])

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var local_pos = get_local_mouse_position()
			print("Клик мыши в BuildArea на позиции: ", local_pos)
			print("Текущие дети: ", get_children())
			selected_node = null
			for child in get_children():
				var area = child.get_node_or_null("Area2D")
				if area:
					var collision_shape = area.get_node_or_null("CollisionShape2D")
					if collision_shape and collision_shape.shape is RectangleShape2D:
						var rect = Rect2(
							child.position + area.position - collision_shape.shape.extents,
							collision_shape.shape.extents * 2
						)
						print("Проверка Area2D для ", child.name, ": rect = ", rect, " child.position = ", child.position, " area.position = ", area.position)
						if rect.has_point(local_pos):
							selected_node = child
							offset = local_pos - child.position
							print("Выбран узел: ", child.name, " с offset: ", offset)
							break
				elif child.has_node("Sprite2D"):
					var sprite = child.get_node("Sprite2D")
					if sprite.texture:
						var rect = Rect2(
							child.position + sprite.position - sprite.texture.get_size() * 0.5 * sprite.scale,
							sprite.texture.get_size() * sprite.scale
						)
						print("Проверка Sprite2D для ", child.name, ": rect = ", rect, " child.position = ", child.position, " sprite.position = ", sprite.position)
						if rect.has_point(local_pos):
							selected_node = child
							offset = local_pos - child.position
							print("Выбран узел: ", child.name, " с offset: ", offset)
							break
			if selected_node == null:
				print("Нет узла под курсором")
		else:
			selected_node = null
	elif event is InputEventMouseMotion and selected_node != null:
		var grid_size = 32
		var local_pos = get_local_mouse_position()
		var new_pos = local_pos - offset
		# Расширение поля вниз, если new_pos.y < 0
		var expand_amount = 0
		if new_pos.y < 0:
			expand_amount = abs(new_pos.y) + grid_size  # Расширяем на нужное расстояние
			size.y += expand_amount
			# Смещаем все существующие элементы вниз
			for child in get_children():
				child.position.y += expand_amount
			# Синхронизация с BuildAreaBackground
			var background = get_parent().get_node_or_null("BuildAreaBackground")
			if background:
				background.size.y = size.y
				var furnace = background.get_node_or_null("FurnaceSprite")
				if furnace:
					furnace.position.y += expand_amount  # Смещаем печь вниз
			print("Расширено BuildArea вниз на ", expand_amount)
			new_pos.y = expand_amount + new_pos.y  # Корректируем позицию для перемещаемого элемента
		# Ограничение позиции внутри границ BuildArea
		new_pos.x = clamp(new_pos.x, 0, size.x - grid_size)
		new_pos.y = clamp(new_pos.y, 0, size.y - grid_size)
		selected_node.position = Vector2(
			round(new_pos.x / grid_size) * grid_size,
			round(new_pos.y / grid_size) * grid_size
		)
		print("Перемещение узла: ", selected_node.name, " в позицию: ", selected_node.position, " offset: ", offset)
