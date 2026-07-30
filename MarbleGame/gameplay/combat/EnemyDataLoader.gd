class_name EnemyDataLoader

const ENEMIES_PATH := "res://gameplay/combat/data/enemies.csv"
const SKILLS_PATH := "res://gameplay/combat/data/enemy_skills.csv"
const ITEMS_PATH := "res://gameplay/combat/data/item_cards.csv"
const ICON_BASE_PATH := "res://assets/textures/"

## 讀取 enemy_skills.csv，回傳 { skill_id(int): { skill_type, display_text } }
static func _load_skills() -> Dictionary:
	var skills := {}
	var file := FileAccess.open(SKILLS_PATH, FileAccess.READ)
	if file == null:
		push_error("EnemyDataLoader: 無法開啟 enemy_skills.csv，錯誤碼: %d" % FileAccess.get_open_error())
		return skills
	
	file.get_csv_line() # 略過標題列
	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.size() < 3 or cols[0].strip_edges().is_empty():
			continue
		
		skills[int(cols[0])] = {
			"skill_type": cols[1].strip_edges(),
			"display_text": cols[2].strip_edges()
		}
	file.close()
	return skills

## 讀取 item_cards.csv，回傳 { item_id(int): { name, icon, cd_default, skill_type, skill_value } }
static func _load_items(skills: Dictionary) -> Dictionary:
	var items := {}
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		push_error("EnemyDataLoader: 無法開啟 item_cards.csv，錯誤碼: %d" % FileAccess.get_open_error())
		return items
	
	file.get_csv_line() # 略過標題列
	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.size() < 6 or cols[0].strip_edges().is_empty():
			continue
		
		var item_id := int(cols[0])
		var display_name := cols[1].strip_edges()
		var icon_path := cols[2].strip_edges()
		var cd_default := int(cols[3])
		var skill_id := int(cols[4])
		var skill_value := int(cols[5])
		
		# 預設技能類型為 damage
		var skill_info: Dictionary = skills.get(skill_id, { "skill_type": "damage" })
		
		items[item_id] = {
			"name": display_name,
			"icon": icon_path,
			"cd_default": cd_default,
			"skill_type": skill_info["skill_type"],
			"skill_value": skill_value
		}
	file.close()
	return items

## 根據敵人 ID 載入敵人與其道具卡組成的 Dictionary 資料
static func load_enemy(target_id: int) -> Dictionary:
	var skills := _load_skills()
	var items := _load_items(skills)
	var enemy_data := {}
	
	var file := FileAccess.open(ENEMIES_PATH, FileAccess.READ)
	if file == null:
		push_error("EnemyDataLoader: 無法開啟 enemies.csv，錯誤碼: %d" % FileAccess.get_open_error())
		return enemy_data
	
	file.get_csv_line() # 略過標題列
	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.size() < 5 or cols[0].strip_edges().is_empty():
			continue
		
		var enemy_id := int(cols[0])
		if enemy_id == target_id:
			enemy_data["display_name"] = cols[1].strip_edges()
			enemy_data["max_hp"] = int(cols[2])
			enemy_data["icon"] = load(ICON_BASE_PATH + cols[3].strip_edges())
			
			# 解析並載入道具卡 (get_csv_line 會自動去除雙引號，得到乾淨的 "1,2,3")
			var item_ids_str := cols[4].strip_edges()
			var item_ids := item_ids_str.split(",")
			
			var enemy_item_cards: Array[ItemCardResource] = []
			for id_str in item_ids:
				if id_str.strip_edges().is_empty():
					continue
				var item_id := int(id_str)
				var item_info: Dictionary = items.get(item_id, {})
				if not item_info.is_empty():
					var card := ItemCardResource.new()
					card.item_name = item_info["name"]
					card.item_icon = load(ICON_BASE_PATH + item_info["icon"])
					card.cd_default = item_info["cd_default"]
					card.cd = item_info["cd_default"]
					card.skill_value = item_info["skill_value"]
					card.skill_type = item_info["skill_type"]
					card.lock_turns = 0
					enemy_item_cards.append(card)
			
			enemy_data["item_cards"] = enemy_item_cards
			break
			
	file.close()
	
	if enemy_data.is_empty():
		push_error("EnemyDataLoader: 找不到指定的敵人 ID [%d]" % target_id)
		
	return enemy_data
