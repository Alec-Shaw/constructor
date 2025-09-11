extends Panel

var selected_node = null  # Узел, который сейчас перемещается
var offset = Vector2.ZERO  # Смещение для точного перемещения
var min_size = Vector2(1264, 851)  # Ваш новый минимальный размер
var rotation_angles = [30, 45, 90, 135, -90, 0]  # Углы вращения
var current_rotation_index = 0  # Индекс текущего угла для выбранного элемента
var control_panel = null  # Ссылка на ControlPanel
var is_dragging = false  # Флаг для отслеживания перетаскивания

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
	control_panel = get_parent().get_node_or_null("ControlPanel")
	if control_panel:
		control_panel.visible = true  # Панель всегда видима
		print("ControlPanel найден, начальная позиция: ", control_panel.position, " размер: ", control_panel.size)
		var rotate_button = control_panel.get_node_or_null("RotateButton")
		var delete_button = control_panel.get_node_or_null("DeleteButton")
		if rotate_button:
			rotate_button.pressed.connect(_on_rotate_pressed)
			print("RotateButton подключён")
		else:
			print("RotateButton не найден. Проверьте имя узла в сцене!")
		if delete_button:
			delete_button.pressed.connect(_on_delete_pressed)
			print("DeleteButton подключён")
		else:
			print("DeleteButton не найден. Проверьте имя узла в сцене!")
	else:
		print("ControlPanel не найден")
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
		# Добавляем метаданные для прилипания (если нет)
		var metadata = scene.get_meta("metadata", {})
		metadata["type"] = data.get("type", "unknown")
		metadata["is_start_sandvich"] = data.get("is_start_sandvich", false)
		scene.set_meta("metadata", metadata)
		print("Добавлена сцена: ", data["scene"], " в позиции: ", scene.position, " type: ", metadata["type"])
		print("Теперь детей в BuildArea: ", get_children().size())
	else:
		print("Ошибка: Сцена не найдена: ", data["scene"])

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = get_local_mouse_position()
		if event.pressed and get_rect().has_point(local_pos):  # Проверяем, что клик внутри BuildArea
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
						print("Проверка Area2D для ", child.name, ": rect = ", rect, " содержит точку: ", rect.has_point(local_pos))
						if rect.has_point(local_pos):
							selected_node = child
							offset = local_pos - child.position
							is_dragging = true
							print("Выбран узел: ", child.name, " с offset: ", offset)
							break
				var sprite = child.get_node_or_null("Sprite2D")
				if sprite and sprite.texture:
					var rect = Rect2(
						child.position + sprite.position - sprite.texture.get_size() * 0.5 * sprite.scale,
						sprite.texture.get_size() * sprite.scale
					)
					print("Проверка Sprite2D для ", child.name, ": rect = ", rect, " содержит точку: ", rect.has_point(local_pos))
					if rect.has_point(local_pos):
						selected_node = child
						offset = local_pos - child.position
						is_dragging = true
						print("Выбран узел: ", child.name, " с offset: ", offset)
						break
		else:
			if is_dragging and selected_node:
				var grid_size = 32
				var new_pos = local_pos - offset
				new_pos.x = clamp(new_pos.x, 0, size.x - grid_size)
				new_pos.y = clamp(new_pos.y, 0, size.y - grid_size)
				selected_node.position = Vector2(
					round(new_pos.x / grid_size) * grid_size,
					round(new_pos.y / grid_size) * grid_size
				)
				print("Элемент размещён: ", selected_node.name, " в позиции: ", selected_node.position)
			is_dragging = false
			if not any_child_contains_point(local_pos) and get_rect().has_point(local_pos):  # Проверяем клик внутри BuildArea
				selected_node = null
				print("Клик вне узла, selected_node сброшен")
			else:
				print("Кнопка отпущена, selected_node сохранён")
	elif event is InputEventMouseMotion and is_dragging and selected_node:
		var grid_size = 32
		var local_pos = get_local_mouse_position()
		var new_pos = local_pos - offset
		# Расширение поля вниз, если new_pos.y < 0
		var expand_amount = 0
		if new_pos.y < 0:
			expand_amount = abs(new_pos.y) + grid_size
			size.y += expand_amount
			for child in get_children():
				child.position.y += expand_amount
			var background = get_parent().get_node_or_null("BuildAreaBackground")
			if background:
				background.size.y = size.y
				var furnace = background.get_node_or_null("FurnaceSprite")
				if furnace:
					furnace.position.y += expand_amount
			print("Расширено BuildArea вниз на ", expand_amount)
			new_pos.y = expand_amount + new_pos.y
		# Ограничение позиции внутри границ BuildArea
		new_pos.x = clamp(new_pos.x, 0, size.x - grid_size)
		new_pos.y = clamp(new_pos.y, 0, size.y - grid_size)
		selected_node.position = Vector2(
			round(new_pos.x / grid_size) * grid_size,
			round(new_pos.y / grid_size) * grid_size
		)
		print("Перемещение узла: ", selected_node.name, " в позицию: ", selected_node.position, " offset: ", offset)

# Новая вспомогательная функция для проверки клика вне всех элементов
func any_child_contains_point(local_pos: Vector2) -> bool:
	for child in get_children():
		var area = child.get_node_or_null("Area2D")
		if area:
			var collision_shape = area.get_node_or_null("CollisionShape2D")
			if collision_shape and collision_shape.shape is RectangleShape2D:
				var rect = Rect2(
					child.position + area.position - collision_shape.shape.extents,
					collision_shape.shape.extents * 2
				)
				if rect.has_point(local_pos):
					return true
		var sprite = child.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			var rect = Rect2(
				child.position + sprite.position - sprite.texture.get_size() * 0.5 * sprite.scale,
				sprite.texture.get_size() * sprite.scale
			)
			if rect.has_point(local_pos):
				return true
	return false

func _on_rotate_pressed():
	if selected_node:
		current_rotation_index = (current_rotation_index + 1) % rotation_angles.size()
		selected_node.rotation_degrees = rotation_angles[current_rotation_index]
		print("Вращение узла: ", selected_node.name, " на ", selected_node.rotation_degrees, " градусов")
	else:
		print("Ошибка: Нет выбранного узла для вращения")

func _on_delete_pressed():
	if selected_node:
		selected_node.queue_free()
		selected_node = null
		print("Удалён узел")
	else:
		print("Ошибка: Нет выбранного узла для удаления")
