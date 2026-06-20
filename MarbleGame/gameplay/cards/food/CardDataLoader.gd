class_name CardDataLoader

const CARDS_PATH := "res://gameplay/cards/food/cards.csv"
const SKILLS_PATH := "res://gameplay/cards/food/skills.csv"
const ICON_BASE_PATH := "res://assets/textures/"

## 讀取 skills.csv，回傳 { skill_id(int): { type, display, color_a, color_b } }
static func _load_skill_table() -> Dictionary:
	var table: Dictionary = {}
	var file := FileAccess.open(SKILLS_PATH, FileAccess.READ)
	if file == null:
		push_error("CardDataLoader: 無法開啟 skills.csv，錯誤碼: %d" % FileAccess.get_open_error())
		return table
	
	file.get_line() # 略過標題列
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var cols := line.split(",")
		if cols.size() < 5:
			continue
		table[int(cols[0])] = {
			"type":    cols[1].strip_edges(),
			"display": cols[2].strip_edges(),
			"color_a": Color.html(cols[3].strip_edges()),
			"color_b": Color.html(cols[4].strip_edges())
		}
	
	file.close()
	return table

## 根據技能類型建立具體的技能效果實體
static func _create_skill_effect(type: String) -> BaseSkillEffect:
	match type:
		"heal":
			return SkillHeal.new()
		"delay_cd":
			return SkillDelayCD.new()
		"damage_buff":
			return SkillDamageBuff.new()
		"damage", _:
			return SkillDamage.new()

## 讀取 cards.csv，回傳 Array[CardResource]
static func load_all() -> Array[CardResource]:
	var skill_table := _load_skill_table()
	var cards: Array[CardResource] = []
	
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file == null:
		push_error("CardDataLoader: 無法開啟 cards.csv，錯誤碼: %d" % FileAccess.get_open_error())
		return cards
	
	file.get_line() # 略過標題列
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var cols := line.split(",")
		if cols.size() < 8:
			push_warning("CardDataLoader: 欄位不足，略過此列: %s" % line)
			continue
		
		var card := CardResource.new()
		# card_id = cols[0]（保留供未來使用）
		card.animal_name = cols[1].strip_edges()
		card.skill_a_value = int(cols[3])
		card.skill_b_value = int(cols[5])
		
		# 解析 slots 字串 → Array[int]
		# 說明：Excel 開啟 CSV 會將「00011000」等前導零字串當數字展示為「11000」
		# 這裡診斷性左补零到 8 位，讓 Loader 對這種情況免疫
		var slots_str := cols[6].strip_edges()
		while slots_str.length() < 8:
			slots_str = "0" + slots_str
		if slots_str.length() > 8:
			push_warning("CardDataLoader: slots 超過 8 位（實際 %d 位），將只取前 8 位，卡牌: %s" % [slots_str.length(), card.animal_name])
			slots_str = slots_str.left(8)
		var slots: Array[int] = []
		for ch in slots_str:
			slots.append(int(ch))
		card.slot_map.assign(slots)
		
		# 讀取技能 A / B 的 ID，從 skill_table 取出顯示文字與顏色
		var skill_a_id := int(cols[2])
		var skill_b_id := int(cols[4])
		var default_info := { 
			"type": "damage", 
			"display": "攻擊", 
			"color_a": Color(0.6, 0.6, 0.6),
			"color_b": Color(0.6, 0.6, 0.6)
		}
		var skill_a_info: Dictionary = skill_table.get(skill_a_id, default_info)
		var skill_b_info: Dictionary = skill_table.get(skill_b_id, default_info)
		
		card.skill_a_display = skill_a_info["display"]
		card.skill_a_color_a = skill_a_info["color_a"]
		card.skill_a_color_b = skill_a_info["color_b"]
		card.skill_a_effect  = _create_skill_effect(skill_a_info["type"])
		
		card.skill_b_display = skill_b_info["display"]
		card.skill_b_color_a = skill_b_info["color_a"]
		card.skill_b_color_b = skill_b_info["color_b"]
		card.skill_b_effect  = _create_skill_effect(skill_b_info["type"])
		
		# 載入圖示
		var icon_file := cols[7].strip_edges()
		card.animal_icon = load(ICON_BASE_PATH + icon_file)
		
		cards.append(card)
		print("CardDataLoader: 載入卡牌 [%s] A技能:%s B技能:%s" % [card.animal_name, card.skill_a_display, card.skill_b_display])
	
	file.close()
	print("CardDataLoader: 共載入 %d 張卡牌" % cards.size())
	return cards

