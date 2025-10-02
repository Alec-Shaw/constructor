extends Node2D

@onready var single_list_elements = $Tabs/Одностенные
@onready var sandvich_list_elements = $Tabs/Утепленные
@onready var accessories_list_elements = $Tabs/Комплектующие
@onready var display_sprite = $DisplaySprite
@onready var build_area = $BuildArea
@onready var sphere_option = $SphereOptionButton  # Назначение
@onready var single_series_option = $SingleSeriesOptionButton  # Серия одностенных
@onready var sandvich_series_option = $SandvichSeriesOptionButton  # Серия утепленных
#@onready var accessories_series_option = $AccessoriesSeriesOptionButton  # Серия комплектующих
@onready var diameter_option = $DiameterOptionButton  # Диаметр (обязательный)
@onready var cost_panel = $CostPanel  # Новая панель для стоимости (VBoxContainer)

var data = {}  # Loaded JSON data
var single_items = []
var sandvich_items = []
var accessories_items = []
var added_elements = {}  # Словарь добавленных элементов по sku: {sku: {item, quantity, total_price}}
var total_cost = 0.0  # Итоговая стоимость

func _ready():
	# Load JSON data from data.json
	var file = FileAccess.open("res://data/data.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_object = JSON.new()
		var error = json_object.parse(json_text)
		if error == OK:
			data = json_object.data
			print("JSON loaded successfully: ", data)
			populate_sphere_option()
		else:
			print("Error parsing JSON: ", error)
	else:
		print("Error opening file data.json")
	
	# Connect signals
	sphere_option.item_selected.connect(_on_sphere_selected)
	single_series_option.item_selected.connect(_on_single_series_selected)
	sandvich_series_option.item_selected.connect(_on_sandvich_series_selected)
	#accessories_series_option.item_selected.connect(_on_accessories_series_selected)
	diameter_option.item_selected.connect(_on_diameter_selected)
	
	# Connect to BuildArea signal for element addition
	build_area.element_added.connect(update_cost_list)
	build_area.element_removed.connect(remove_element)

func update_cost_list(item: Dictionary):
	var sku = item["sku"]
	if sku in added_elements:
		added_elements[sku]["quantity"] += 1
		added_elements[sku]["total_price"] = added_elements[sku]["item"]["price"] * added_elements[sku]["quantity"]
	else:
		added_elements[sku] = {
			"item": item,
			"quantity": 1,
			"total_price": item["price"]
		}
	total_cost = 0.0
	for entry in added_elements.values():
		total_cost += entry["total_price"]
	update_cost_panel()

func remove_element(sku: String):
	if sku in added_elements:
		added_elements[sku]["quantity"] -= 1
		if added_elements[sku]["quantity"] > 0:
			added_elements[sku]["total_price"] = added_elements[sku]["item"]["price"] * added_elements[sku]["quantity"]
		else:
			added_elements.erase(sku)
	total_cost = 0.0
	for entry in added_elements.values():
		total_cost += entry["total_price"]
	update_cost_panel()

func update_cost_panel():	
	# Удаляем все дочерние узлы
	for child in cost_panel.get_children():
		child.queue_free()
	
	# Добавляем элементы с форматированием
	for entry in added_elements.values():
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 10)  # Отступ между элементами в строке
		# Изображение
		var texture_rect = TextureRect.new()
		var icon = load(entry["item"]["texture"])
		texture_rect.texture = icon
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.size = Vector2(32, 32)
		texture_rect.add_theme_constant_override("margin_right", 10)  # Отступ справа от изображения
		hbox.add_child(texture_rect)
		
		# Название
		var name_label = Label.new()
		name_label.text = entry["item"]["name"]
		name_label.add_theme_font_size_override("font_size", 14)  # Увеличиваем размер шрифта
		name_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))  # Черный цвет
		name_label.mouse_filter = Control.MOUSE_FILTER_STOP
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.connect("gui_input", func(event): _on_name_clicked(event, entry["item"]["link"]))
		hbox.add_child(name_label)
		
		# Артикул (меньше и серый)
		var sku_label = Label.new()
		sku_label.text = "Арт: " + entry["item"]["sku"]
		sku_label.add_theme_font_size_override("font_size", 10)
		sku_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # Серый цвет
		hbox.add_child(sku_label)
		
		# Количество
		var qty_label = Label.new()
		qty_label.text = str(entry["quantity"]) + " шт."
		qty_label.add_theme_font_size_override("font_size", 12)
		qty_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))  # Черный цвет
		hbox.add_child(qty_label)
		
		# Стоимость (выравнивание по правому краю)
		var price_label = Label.new()
		price_label.text = str(entry["total_price"]) + " руб."
		price_label.add_theme_font_size_override("font_size", 12)
		price_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))  # Черный цвет
		#price_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		price_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(price_label)
		
		cost_panel.add_child(hbox)
	
	# Итоговая строка с улучшенным стилем
	var total_label = Label.new()
	total_label.text = "Итого: " + str(total_cost) + " руб."
	total_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 16)  # Больший шрифт для итога
	total_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Красный цвет
	cost_panel.add_child(total_label)

func _on_name_clicked(event, link):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if link:
			OS.shell_open(link)
			print("Открыта ссылка: ", link)

func populate_sphere_option():
	sphere_option.clear()
	for sphere in data["spheres"]:
		sphere_option.add_item(sphere["name"])
	if sphere_option.get_item_count() > 0:
		sphere_option.select(0)
		_on_sphere_selected(0)

func _on_sphere_selected(index: int):
	var selected_sphere_name = sphere_option.get_item_text(index)
	# Обновляем FurnaceSprite
	var furnace = $BuildAreaBackground/FurnaceSprite
	if furnace:
		for sphere in data["spheres"]:
			if sphere["name"] == selected_sphere_name and sphere.has("furnace_texture"):
				var texture_path = sphere["furnace_texture"]
				var texture = load(texture_path)
				if texture:
					furnace.texture = texture
					print("FurnaceSprite обновлён для сферы: ", selected_sphere_name)
				else:
					print("Ошибка загрузки текстуры: ", texture_path)
				break
	else:
		print("FurnaceSprite не найден.")
	
	# Dynamically update series options
	for sphere in data["spheres"]:
		if sphere["name"] == selected_sphere_name:
			single_series_option.clear()
			sandvich_series_option.clear()
			#accessories_series_option.clear()
			single_series_option.add_item(sphere["single_series"])
			for series in sphere["sandvich_series"]:
				sandvich_series_option.add_item(series)
			#accessories_series_option.add_item(sphere["accessories_series"])
			# Trigger series selection with default (first) option
			if single_series_option.get_item_count() > 0:
				single_series_option.select(0)
			if sandvich_series_option.get_item_count() > 0:
				sandvich_series_option.select(0)
			#if accessories_series_option.get_item_count() > 0:
			#	accessories_series_option.select(0)
			_on_series_selected(0)  # Trigger update with default series
			break

func _on_series_selected(index: int):
	_update_diameter_options()
	_on_diameter_selected(diameter_option.selected)  # Trigger update if diameter is selected

func _on_single_series_selected(index: int):
	_on_series_selected(index)

func _on_sandvich_series_selected(index: int):
	_on_series_selected(index)

func _on_accessories_series_selected(index: int):
	_on_series_selected(index)

func _update_diameter_options():
	var selected_sphere = sphere_option.get_item_text(sphere_option.selected)
	diameter_option.clear()
	var diameters = {}
	for sphere in data["spheres"]:
		if sphere["name"] == selected_sphere:
			# Collect diameters from single, sandvich, and accessories
			var single_series = sphere["single_series"]
			if single_series in sphere["items"]:
				for item in sphere["items"][single_series]:
					if item["diameter"] != "" and item["diameter"] != null:
						diameters[item["diameter"]] = true
			
			var sandvich_series = [sandvich_series_option.get_item_text(sandvich_series_option.selected)]
			for series in sandvich_series:
				if series in sphere["items"]:
					for item in sphere["items"][series]:
						if item["diameter"] != "" and item["diameter"] != null:
							diameters[item["diameter"]] = true
			
			var accessories_series = sphere["accessories_series"]
			if accessories_series in sphere["items"]:
				for item in sphere["items"][accessories_series]:
					if item["diameter"] != "" and item["diameter"] != null:
						diameters[item["diameter"]] = true
			break
	for diameter in diameters.keys():
		diameter_option.add_item(diameter)
	if diameter_option.get_item_count() > 0:
		diameter_option.select(0)  # Select first diameter (mandatory)
		_on_diameter_selected(0)
	else:
		print("No diameters available for selected series")

func _on_diameter_selected(index: int):
	if index < 0 or index >= diameter_option.get_item_count():
		print("No diameter selected, skipping update")
		return
	var selected_sphere = sphere_option.get_item_text(sphere_option.selected)
	var selected_diameter = diameter_option.get_item_text(index)
	update_item_lists(selected_sphere, selected_diameter)

func update_item_lists(sphere_name: String, diameter: String):
	single_items.clear()
	sandvich_items.clear()
	accessories_items.clear()
	single_list_elements.clear()
	sandvich_list_elements.clear()
	accessories_list_elements.clear()

	for sphere in data["spheres"]:
		if sphere["name"] == sphere_name:
			var single_series = sphere["single_series"]
			var sandvich_series = [sandvich_series_option.get_item_text(sandvich_series_option.selected)]
			var accessories_series = sphere["accessories_series"]

			# Filter single items
			if single_series in sphere["items"]:
				for item in sphere["items"][single_series]:
					if item["diameter"] == diameter:
						single_items.append(item)
			for item in single_items:
				single_list_elements.add_item("")
				var index = single_list_elements.item_count - 1
				single_list_elements.set_item_icon(index, load(item["texture"]))
				single_list_elements.set_item_metadata(index, item)
				single_list_elements.set_item_tooltip(index, item["name"])
				print("Added to Одностенные: ", item["name"])

			# Filter sandvich items
			for series in sandvich_series:
				if series in sphere["items"]:
					for item in sphere["items"][series]:
						if item["diameter"] == diameter:
							sandvich_items.append(item)
			for item in sandvich_items:
				sandvich_list_elements.add_item("")
				var index = sandvich_list_elements.item_count - 1
				sandvich_list_elements.set_item_icon(index, load(item["texture"]))
				sandvich_list_elements.set_item_metadata(index, item)
				sandvich_list_elements.set_item_tooltip(index, item["name"])
				print("Added to Утепленные: ", item["name"])

			# Filter accessories items (include items without diameter)
			if accessories_series in sphere["items"]:
				for item in sphere["items"][accessories_series]:
					if item["diameter"] == "" or item["diameter"] == diameter:
						accessories_items.append(item)
			for item in accessories_items:
				accessories_list_elements.add_item("")
				var index = accessories_list_elements.item_count - 1
				accessories_list_elements.set_item_icon(index, load(item["texture"]))
				accessories_list_elements.set_item_metadata(index, item)
				accessories_list_elements.set_item_tooltip(index, item["name"])
				print("Added to Комплектующие: ", item["name"])
			break

func _on_single_list_elements_selected(index: int):
	var item = single_list_elements.get_item_metadata(index)
	if item and item.has("texture"):
		display_sprite.texture = load(item["texture"])
		print("Выбран элемент в Одностенные: ", item["name"])
	else:
		display_sprite.texture = null
		print("Ошибка: Метаданные отсутствуют для элемента ", single_list_elements.get_item_text(index))

func _on_sandvich_list_elements_selected(index: int):
	var item = sandvich_list_elements.get_item_metadata(index)
	if item and item.has("texture"):
		display_sprite.texture = load(item["texture"])
		print("Выбран элемент в Утепленные: ", item["name"])
	else:
		display_sprite.texture = null
		print("Ошибка: Метаданные отсутствуют для элемента ", sandvich_list_elements.get_item_text(index))

func _on_accessories_list_elements_selected(index: int):
	var item = accessories_list_elements.get_item_metadata(index)
	if item and item.has("texture"):
		display_sprite.texture = load(item["texture"])
		print("Выбран элемент в Комплектующие: ", item["name"])
	else:
		display_sprite.texture = null
		print("Ошибка: Метаданные отсутствуют для элемента ", accessories_list_elements.get_item_text(index))
