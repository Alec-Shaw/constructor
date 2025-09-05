extends ItemList

func _get_drag_data(at_position: Vector2) -> Variant:
	var item_index = get_item_at_position(at_position, true)
	print("Drag начат в ItemList, индекс: ", item_index)  # Отладка: Начало drag
	if item_index >= 0:
		var data = get_item_metadata(item_index)
		print("Данные для drag: ", data)  # Отладка: Какие данные передаются
		if data and data is Dictionary and data.has("texture"):
			var preview = TextureRect.new()
			preview.texture = load(data["texture"])
			preview.size = Vector2(64, 64)
			set_drag_preview(preview)
			return data
	print("Drag не начат: некорректные данные или индекс")  # Отладка: Ошибка
	return null

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return false  # ItemList не принимает drop
