extends RefCounted

## UI copy for English, Russian, and Chinese. Widgets ask here. They do not
## keep their own sentences. Default language is English.

static var code := "en"

const EN := {
	"menu.start": "Start Game",
	"menu.meta": "Meta Shop",
	"menu.settings": "Settings",
	"menu.quit": "Quit",
	"menu.title": "Menu",
	"menu.restart": "Restart Room",
	"menu.main": "Main Menu",
	"menu.close": "Close",
	"menu.tooltip": "Menu",
	"menu.tagline": "One throw. A chain reaction.",
	"hint.ready": "Hold LMB and pull back — stone flies backward.   R — restart",
	"hint.aim": "Release to throw",
	"hint.watch": "Watch the chain",
	"hint.look": "Watch the result",
	"hint.shop": "Buy one for the next throw, or skip",
	"hint.menu": "Menu",
	"shop.title": "For the next throw",
	"shop.earned": "Earned %s.  You have %s.",
	"shop.have": "You have %s. Buy one, or skip.",
	"shop.skip": "Skip",
	"shop.buy": "Buy  %s",
	"shop.need": "Need %s",
	"shop.equip": "Equip",
	"shop.owned": "Owned",
	"coins.one": "1 coin",
	"coins.few": "%d coins",
	"coins.many": "%d coins",
	"coins.many_one": "%d coins",
	"equipped": "Equipped: %s",
	"chain.word": "chain",
	"chain.miss": "Miss",
	"chain.short": "Short chain",
	"chain.good": "Good chain",
	"chain.excellent": "Excellent chain",
	"meta.title": "Meta Shop",
	"meta.sub": "Cheapest first. Stones join the throw shop. Rooms join the next layout.",
	"meta.back": "Back",
	"meta.new_room": "New room",
	"meta.owned_count": "Owned %d of %d",
	"meta.unlock": "Unlock  %s",
	"meta.need": "Need %s",
	"meta.owned": "Owned",
	"meta.note": "Unlocked %s: %s.",
	"meta.stones": "Stones",
	"meta.rooms": "Rooms",
	"kind.stone": "Stone",
	"kind.room": "Room",
	"settings.title": "Settings",
	"settings.language": "Language",
	"settings.music": "Music",
	"settings.sfx": "Effects",
	"settings.close": "Close",
	"lang.en": "English",
	"lang.ru": "Русский",
	"lang.zh": "中文",
	"room.long": "Long shelf",
	"room.sides": "Side shelves",
	"room.stack": "Stack",
	"room.stairs": "Stairs",
	"room.balcony": "Balcony",
	"room.low_loft": "Low loft",
	"room.split_bay": "Split bay",
	"room.narrow": "Narrow shelves",
	"room.floor_clutter": "Floor clutter",
	"room.window_heavy": "Window heavy",
	"room.market": "Market row",
	"room.alcove": "Alcove",
	"room.generic": "Room",
	"name.heavy_stone": "Heavy Stone",
	"name.light_stone": "Light Stone",
	"name.spring_stone": "Spring Stone",
	"name.blast_stone": "Blast Stone",
	"name.magnet_stone": "Magnet Stone",
	"name.wide_stone": "Wide Stone",
	"name.glass_charm": "Glass Charm",
	"name.high_pop": "High Pop",
	"name.cork_stone": "Cork Stone",
	"name.needle_stone": "Needle Stone",
	"name.thud_stone": "Thud Stone",
	"name.split_stone": "Split Stone",
	"name.sticky_stone": "Sticky Stone",
	"name.bounce_stone": "Bounce Stone",
	"line.heavy_stone": "Hits harder. Flies shorter.",
	"line.light_stone": "Flies farther off the sling.",
	"line.spring_stone": "Bounces hard off everything.",
	"line.blast_stone": "Pops nearby props on impact.",
	"line.magnet_stone": "Tugs nearby props after a hit.",
	"line.wide_stone": "A fatter stone. Easier to clip.",
	"line.glass_charm": "Shatters bottles near the hit.",
	"line.high_pop": "The hit throws props upward.",
	"line.cork_stone": "Stops where it lands.",
	"line.needle_stone": "Small and fast. Flies far.",
	"line.thud_stone": "The first hit shoves harder.",
	"line.split_stone": "The first hit breaks it into two smaller stones.",
	"line.sticky_stone": "Sticks to the first thing it hits, then they fall together.",
	"line.bounce_stone": "Bounces hard and keeps rebounding.",
	"line.narrow": "Short planks with a tall drop between them.",
	"line.low_loft": "Both shelves sit close to the floor.",
	"line.floor_clutter": "A small high shelf. Almost everything sits on the floor.",
	"line.split_bay": "Two shelves far apart, one much higher than the other.",
	"line.window_heavy": "A large window. Shelves and the lamp crowd under it.",
	"line.market": "A long low counter with the stock lined up on it.",
	"blurb.cork_stone": "Throw shop, 8 coins",
	"blurb.needle_stone": "Throw shop, 9 coins",
	"blurb.thud_stone": "Throw shop, 10 coins",
	"blurb.split_stone": "Throw shop, 11 coins",
	"blurb.sticky_stone": "Throw shop, 12 coins",
	"blurb.bounce_stone": "Throw shop, 13 coins",
	"blurb.room_pool": "Next rooms can roll this",
}

const RU := {
	"menu.start": "Начать игру",
	"menu.meta": "Мета-магазин",
	"menu.settings": "Настройки",
	"menu.quit": "Выход",
	"menu.title": "Меню",
	"menu.restart": "Заново",
	"menu.main": "Главное меню",
	"menu.close": "Закрыть",
	"menu.tooltip": "Меню",
	"menu.tagline": "Один бросок. Цепная реакция.",
	"hint.ready": "Зажмите ЛКМ и потяните назад — камень летит обратно.   R — заново",
	"hint.aim": "Отпустите, чтобы бросить",
	"hint.watch": "Смотрите цепь",
	"hint.look": "Смотрите результат",
	"hint.shop": "Купите камень на следующий бросок или пропустите",
	"hint.menu": "Меню",
	"shop.title": "На следующий бросок",
	"shop.earned": "Получено %s.  У вас %s.",
	"shop.have": "У вас %s. Купите или пропустите.",
	"shop.skip": "Пропустить",
	"shop.buy": "Купить  %s",
	"shop.need": "Нужно %s",
	"shop.equip": "Взять",
	"shop.owned": "Есть",
	"coins.one": "1 монета",
	"coins.few": "%d монеты",
	"coins.many": "%d монет",
	"coins.many_one": "%d монета",
	"equipped": "Взято: %s",
	"chain.word": "цепь",
	"chain.miss": "Мимо",
	"chain.short": "Короткая цепь",
	"chain.good": "Хорошая цепь",
	"chain.excellent": "Отличная цепь",
	"meta.title": "Мета-магазин",
	"meta.sub": "Сначала дешёвые. Камни идут в магазин броска, комнаты — в планировку.",
	"meta.back": "Назад",
	"meta.new_room": "Новая комната",
	"meta.owned_count": "Открыто %d из %d",
	"meta.unlock": "Открыть  %s",
	"meta.need": "Нужно %s",
	"meta.owned": "Есть",
	"meta.note": "Открыто: %s — %s.",
	"meta.stones": "Камни",
	"meta.rooms": "Комнаты",
	"kind.stone": "Камень",
	"kind.room": "Комната",
	"settings.title": "Настройки",
	"settings.language": "Язык",
	"settings.music": "Музыка",
	"settings.sfx": "Эффекты",
	"settings.close": "Закрыть",
	"lang.en": "English",
	"lang.ru": "Русский",
	"lang.zh": "中文",
	"room.long": "Длинная полка",
	"room.sides": "Боковые полки",
	"room.stack": "Стопка",
	"room.stairs": "Лестница",
	"room.balcony": "Балкон",
	"room.low_loft": "Низкий ярус",
	"room.split_bay": "Разделённый пролёт",
	"room.narrow": "Узкие полки",
	"room.floor_clutter": "Захламлённый пол",
	"room.window_heavy": "Большое окно",
	"room.market": "Рыночный ряд",
	"room.alcove": "Ниша",
	"room.generic": "Комната",
	"name.heavy_stone": "Тяжёлый камень",
	"name.light_stone": "Лёгкий камень",
	"name.spring_stone": "Пружинный камень",
	"name.blast_stone": "Взрывной камень",
	"name.magnet_stone": "Магнитный камень",
	"name.wide_stone": "Широкий камень",
	"name.glass_charm": "Стеклянный оберег",
	"name.high_pop": "Высокий подброс",
	"name.cork_stone": "Пробковый камень",
	"name.needle_stone": "Игольчатый камень",
	"name.thud_stone": "Глухой камень",
	"name.split_stone": "Раздвоенный камень",
	"name.sticky_stone": "Липкий камень",
	"name.bounce_stone": "Прыгучий камень",
	"line.heavy_stone": "Бьёт сильнее. Летит короче.",
	"line.light_stone": "Летит дальше с рогатки.",
	"line.spring_stone": "Сильно отскакивает.",
	"line.blast_stone": "При ударе раскидывает соседние вещи.",
	"line.magnet_stone": "После удара тянет соседние вещи.",
	"line.wide_stone": "Толще. Легче задеть.",
	"line.glass_charm": "Разбивает бутылки рядом с ударом.",
	"line.high_pop": "Удар подбрасывает вещи вверх.",
	"line.cork_stone": "Останавливается там, где упал.",
	"line.needle_stone": "Маленький и быстрый. Летит далеко.",
	"line.thud_stone": "Первый удар толкает сильнее.",
	"line.split_stone": "При первом ударе распадается на два камня поменьше.",
	"line.sticky_stone": "Прилипает к первому, во что попал, и падает вместе с ним.",
	"line.bounce_stone": "Сильно отскакивает и прыгает дольше.",
	"line.narrow": "Короткие доски и длинный пролёт между ними.",
	"line.low_loft": "Обе полки близко к полу.",
	"line.floor_clutter": "Маленькая высокая полка. Почти всё стоит на полу.",
	"line.split_bay": "Две полки далеко друг от друга, одна гораздо выше.",
	"line.window_heavy": "Большое окно. Полки и лампа толпятся под ним.",
	"line.market": "Длинный низкий прилавок, товар выстроен в ряд.",
	"blurb.cork_stone": "Магазин броска, 8 монет",
	"blurb.needle_stone": "Магазин броска, 9 монет",
	"blurb.thud_stone": "Магазин броска, 10 монет",
	"blurb.split_stone": "Магазин броска, 11 монет",
	"blurb.sticky_stone": "Магазин броска, 12 монет",
	"blurb.bounce_stone": "Магазин броска, 13 монет",
	"blurb.room_pool": "Может выпасть в следующей комнате",
}

const ZH := {
	"menu.start": "开始游戏",
	"menu.meta": "永久商店",
	"menu.settings": "设置",
	"menu.quit": "退出",
	"menu.title": "菜单",
	"menu.restart": "重开房间",
	"menu.main": "主菜单",
	"menu.close": "关闭",
	"menu.tooltip": "菜单",
	"menu.tagline": "一次投掷。一场连锁。",
	"hint.ready": "按住鼠标左键向后拉 — 石头会反向飞出。   R — 重开",
	"hint.aim": "松开投掷",
	"hint.watch": "看连锁",
	"hint.look": "看结果",
	"hint.shop": "为下次投掷购买，或跳过",
	"hint.menu": "菜单",
	"shop.title": "下次投掷",
	"shop.earned": "获得 %s。  现有 %s。",
	"shop.have": "现有 %s。购买或跳过。",
	"shop.skip": "跳过",
	"shop.buy": "购买  %s",
	"shop.need": "需要 %s",
	"shop.equip": "装备",
	"shop.owned": "已拥有",
	"coins.one": "1 枚硬币",
	"coins.few": "%d 枚硬币",
	"coins.many": "%d 枚硬币",
	"coins.many_one": "%d 枚硬币",
	"equipped": "已装备：%s",
	"chain.word": "连锁",
	"chain.miss": "未中",
	"chain.short": "短连锁",
	"chain.good": "不错的连锁",
	"chain.excellent": "出色的连锁",
	"meta.title": "永久商店",
	"meta.sub": "从便宜到贵。石头进入投掷商店，房间进入下一局。",
	"meta.back": "返回",
	"meta.new_room": "新房间",
	"meta.owned_count": "已拥有 %d / %d",
	"meta.unlock": "解锁  %s",
	"meta.need": "需要 %s",
	"meta.owned": "已拥有",
	"meta.note": "已解锁%s：%s。",
	"meta.stones": "石头",
	"meta.rooms": "房间",
	"kind.stone": "石头",
	"kind.room": "房间",
	"settings.title": "设置",
	"settings.language": "语言",
	"settings.music": "音乐",
	"settings.sfx": "音效",
	"settings.close": "关闭",
	"lang.en": "English",
	"lang.ru": "Русский",
	"lang.zh": "中文",
	"room.long": "长架",
	"room.sides": "两侧架",
	"room.stack": "叠架",
	"room.stairs": "阶梯",
	"room.balcony": "阳台",
	"room.low_loft": "低阁",
	"room.split_bay": "断开间",
	"room.narrow": "窄架",
	"room.floor_clutter": "满地杂物",
	"room.window_heavy": "大窗",
	"room.market": "市场长柜台",
	"room.alcove": "壁龛",
	"room.generic": "房间",
	"name.heavy_stone": "重石",
	"name.light_stone": "轻石",
	"name.spring_stone": "弹石",
	"name.blast_stone": "爆石",
	"name.magnet_stone": "磁石",
	"name.wide_stone": "宽石",
	"name.glass_charm": "玻璃符",
	"name.high_pop": "上抛石",
	"name.cork_stone": "软木石",
	"name.needle_stone": "针石",
	"name.thud_stone": "闷击石",
	"name.split_stone": "分裂石",
	"name.sticky_stone": "粘石",
	"name.bounce_stone": "弹跳石",
	"line.heavy_stone": "打得更重，飞得更近。",
	"line.light_stone": "从弹弓飞得更远。",
	"line.spring_stone": "碰到什么都猛弹。",
	"line.blast_stone": "命中时炸开附近的东西。",
	"line.magnet_stone": "命中后吸拉附近的东西。",
	"line.wide_stone": "更粗，更容易擦到。",
	"line.glass_charm": "打碎命中处附近的瓶子。",
	"line.high_pop": "命中把东西向上抛。",
	"line.cork_stone": "落在哪里就停在哪里。",
	"line.needle_stone": "又小又快，飞得远。",
	"line.thud_stone": "第一下推得更狠。",
	"line.split_stone": "第一次撞上时裂成两颗小石子。",
	"line.sticky_stone": "粘在第一件撞到的东西上，然后一起掉下去。",
	"line.bounce_stone": "弹得很高，而且弹得更久。",
	"line.narrow": "短板，中间是很高的落差。",
	"line.low_loft": "两层架子都靠近地面。",
	"line.floor_clutter": "一块高处的小架子，几乎所有东西都在地上。",
	"line.split_bay": "两块架子离得很远，一高一低。",
	"line.window_heavy": "一扇大窗，架子和灯都挤在窗下。",
	"line.market": "一条低矮的长柜台，货物排成一行。",
	"blurb.cork_stone": "投掷商店，8 枚硬币",
	"blurb.needle_stone": "投掷商店，9 枚硬币",
	"blurb.thud_stone": "投掷商店，10 枚硬币",
	"blurb.split_stone": "投掷商店，11 枚硬币",
	"blurb.sticky_stone": "投掷商店，12 枚硬币",
	"blurb.bounce_stone": "投掷商店，13 枚硬币",
	"blurb.room_pool": "下一间可能抽到这种布局",
}


static func set_code(next: String) -> void:
	if next == "ru" or next == "zh" or next == "en":
		code = next
	else:
		code = "en"


static func text(key: String) -> String:
	var table := _table()
	if table.has(key):
		return str(table[key])
	if EN.has(key):
		return str(EN[key])
	return key


static func format(key: String, args: Array) -> String:
	return text(key) % args


static func coins(amount: int) -> String:
	if code == "zh":
		return text("coins.many") % amount
	if code == "ru":
		var n := absi(amount) % 100
		var n1 := n % 10
		if n > 10 and n < 20:
			return text("coins.many") % amount
		if n1 == 1:
			if amount == 1:
				return text("coins.one")
			return text("coins.many_one") % amount
		if n1 >= 2 and n1 <= 4:
			return text("coins.few") % amount
		return text("coins.many") % amount
	if amount == 1:
		return text("coins.one")
	return text("coins.many") % amount


static func item_name(id: String) -> String:
	var key := "name." + id
	if EN.has(key):
		return text(key)
	return room_name(id)


static func line_for(id: String) -> String:
	return text("line." + id)


static func blurb_for(id: String, kind: String) -> String:
	if kind == "room":
		return text("blurb.room_pool")
	return text("blurb." + id)


static func room_name(id: String) -> String:
	if id == "stack_l" or id == "stack_r":
		id = "stack"
	var key := "room." + id
	if EN.has(key):
		return text(key)
	return text("room.generic")


static func _table() -> Dictionary:
	if code == "ru":
		return RU
	if code == "zh":
		return ZH
	return EN
