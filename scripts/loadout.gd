extends RefCounted

## One equipped item and the purse. Statics live on the script, so a scene
## reload keeps both without writing a save.

static var item_id := ""
static var item_name := ""
static var item_tint := Color(1.0, 0.86, 0.42)
static var money := 0
static var last_earn := 0
static var owned: PackedStringArray = PackedStringArray()

## speed scales the launch. mass scales the stone's 2.5 base.
## impact is extra hit speed on the first body. The rest are on-hit effects.
const CATALOG: Array = [
	{
		"id": "heavy_stone",
		"name": "Heavy Stone",
		"line": "Hits harder. Flies shorter.",
		"shape": "heavy",
		"tint": Color(0.38, 0.34, 0.32),
		"price": 13,
		"speed": 0.68,
		"mass": 2.2,
		"bounce": 0.03,
		"friction": 0.78,
		"impact": 95.0,
	},
	{
		"id": "light_stone",
		"name": "Light Stone",
		"line": "Flies farther off the sling.",
		"shape": "light",
		"tint": Color(0.92, 0.88, 0.78),
		"price": 7,
		"speed": 1.16,
		"mass": 0.46,
		"bounce": 0.12,
		"friction": 0.42,
	},
	{
		"id": "spring_stone",
		"name": "Spring Stone",
		"line": "Bounces hard off everything.",
		"shape": "spring",
		"tint": Color(0.42, 0.82, 0.38),
		"price": 8,
		"bounce": 0.8,
		"friction": 0.16,
	},
	{
		"id": "blast_stone",
		"name": "Blast Stone",
		"line": "Pops nearby props on impact.",
		"shape": "blast",
		"tint": Color(0.95, 0.32, 0.16),
		"price": 19,
		"blast": 118.0,
		"blast_force": 250.0,
	},
	{
		"id": "magnet_stone",
		"name": "Magnet Stone",
		"line": "Tugs nearby props after a hit.",
		"shape": "magnet",
		"tint": Color(0.38, 0.58, 0.96),
		"price": 16,
		"magnet": 0.75,
		"magnet_radius": 148.0,
		"magnet_pull": 1100.0,
	},
	{
		"id": "wide_stone",
		"name": "Wide Stone",
		"line": "A fatter stone. Easier to clip.",
		"shape": "wide",
		"tint": Color(0.96, 0.74, 0.22),
		"price": 9,
		"radius": 26.0,
	},
	{
		"id": "glass_charm",
		"name": "Glass Charm",
		"line": "Shatters bottles near the hit.",
		"shape": "glass",
		"tint": Color(0.55, 0.86, 0.94),
		"price": 10,
		"glass": 110.0,
	},
	{
		"id": "high_pop",
		"name": "High Pop",
		"line": "The hit throws props upward.",
		"shape": "pop",
		"tint": Color(0.98, 0.48, 0.18),
		"price": 11,
		"pop": 108.0,
		"pop_lift": 260.0,
	},
	{
		"id": "cork_stone",
		"unlock": "cork_stone",
		"name": "Cork Stone",
		"line": "Stops where it lands.",
		"shape": "cork",
		"tint": Color(0.73, 0.50, 0.30),
		"price": 8,
		"speed": 0.92,
		"mass": 1.35,
		"bounce": 0.0,
		"friction": 0.95,
	},
	{
		"id": "needle_stone",
		"unlock": "needle_stone",
		"name": "Needle Stone",
		"line": "Small and fast. Flies far.",
		"shape": "needle",
		"tint": Color(0.86, 0.91, 0.96),
		"price": 9,
		"speed": 1.28,
		"mass": 0.34,
		"radius": 9.0,
		"bounce": 0.04,
		"friction": 0.22,
	},
	{
		"id": "thud_stone",
		"unlock": "thud_stone",
		"name": "Thud Stone",
		"line": "The first hit shoves harder.",
		"shape": "thud",
		"tint": Color(0.55, 0.36, 0.28),
		"price": 10,
		"speed": 0.86,
		"mass": 1.45,
		"bounce": 0.02,
		"friction": 0.7,
		"impact": 150.0,
	},
]

## Permanent unlocks. A full clear pays 11, so 28 takes about three strong throws.
## kind is "stone" or "room". The shop sorts this list by cost.
const META: Array = [
	{
		"id": "cork_stone",
		"kind": "stone",
		"name": "Cork Stone",
		"line": "Stops where it lands.",
		"blurb": "Throw shop, 8 coins",
		"cost": 28,
		"shape": "cork",
		"tint": Color(0.73, 0.50, 0.30),
	},
	{
		"id": "narrow",
		"kind": "room",
		"name": "Narrow Shelves",
		"line": "Short planks with a tall drop between them.",
		"blurb": "Next rooms can roll this",
		"cost": 36,
		"shape": "narrow",
		"tint": Color(0.72, 0.78, 0.86),
	},
	{
		"id": "low_loft",
		"kind": "room",
		"name": "Low Loft",
		"line": "Both shelves sit close to the floor.",
		"blurb": "Next rooms can roll this",
		"cost": 46,
		"shape": "loft",
		"tint": Color(0.86, 0.72, 0.42),
	},
	{
		"id": "needle_stone",
		"kind": "stone",
		"name": "Needle Stone",
		"line": "Small and fast. Flies far.",
		"blurb": "Throw shop, 9 coins",
		"cost": 56,
		"shape": "needle",
		"tint": Color(0.86, 0.91, 0.96),
	},
	{
		"id": "floor_clutter",
		"kind": "room",
		"name": "Floor Clutter",
		"line": "A small high shelf. Almost everything sits on the floor.",
		"blurb": "Next rooms can roll this",
		"cost": 66,
		"shape": "clutter",
		"tint": Color(0.78, 0.58, 0.36),
	},
	{
		"id": "split_bay",
		"kind": "room",
		"name": "Split Bay",
		"line": "Two shelves far apart, one much higher than the other.",
		"blurb": "Next rooms can roll this",
		"cost": 78,
		"shape": "bay",
		"tint": Color(0.55, 0.72, 0.84),
	},
	{
		"id": "window_heavy",
		"kind": "room",
		"name": "Window Heavy",
		"line": "A large window. Shelves and the lamp crowd under it.",
		"blurb": "Next rooms can roll this",
		"cost": 88,
		"shape": "window",
		"tint": Color(0.62, 0.84, 0.90),
	},
	{
		"id": "thud_stone",
		"kind": "stone",
		"name": "Thud Stone",
		"line": "The first hit shoves harder.",
		"blurb": "Throw shop, 10 coins",
		"cost": 98,
		"shape": "thud",
		"tint": Color(0.55, 0.36, 0.28),
	},
]

const SAVE_PATH := "user://knockroom.cfg"


static func equip(id: String, display_name: String, tint: Color = Color(1.0, 0.86, 0.42)) -> void:
	item_id = id
	item_name = display_name
	item_tint = tint
	save_game()


static func clear_item() -> void:
	item_id = ""
	item_name = ""
	item_tint = Color(1.0, 0.86, 0.42)
	save_game()


static func effect() -> Dictionary:
	return find(item_id)


static func find(id: String) -> Dictionary:
	for offer in CATALOG:
		var item: Dictionary = offer
		if str(item["id"]) == id:
			return item
	return {}


static func price_of(id: String) -> int:
	var item := find(id)
	if item.is_empty():
		return 0
	return int(item["price"])


static func speed_scale() -> float:
	var item := effect()
	if item.is_empty():
		return 1.0
	return float(item.get("speed", 1.0))


static func shape() -> String:
	var item := effect()
	if item.is_empty():
		return ""
	return str(item.get("shape", ""))


static func coins(amount: int) -> String:
	if amount == 1:
		return "1 coin"
	return "%d coins" % amount


static func stone_radius() -> float:
	var item := effect()
	if item.is_empty():
		return 15.0
	return float(item.get("radius", 15.0))


static func payout_for(chain_count: int) -> int:
	# A miss or a couple of knocks pay nothing. A short chain pays pocket change.
	# Around 8 links the cheapest stone is exact. A full clear tops out at one
	# medium stone, with too little left for a second buy.
	if chain_count <= 2:
		return 0
	if chain_count <= 4:
		return 1
	if chain_count < 8:
		return chain_count - 3
	# 8 pays 6, 10 pays 7, 12 pays 8, 14 pays 9, 15 pays 9.
	if chain_count < 16:
		return 6 + (chain_count - 8) / 2
	# 16 pays 10. 18 and above pay 11, one medium stone and no second buy.
	return mini(10 + (chain_count - 16) / 2, 11)


static func earn(chain_count: int) -> int:
	var pay := payout_for(chain_count)
	last_earn = pay
	money += pay
	save_game()
	return pay


static func can_afford(price: int) -> bool:
	return price >= 0 and money >= price


static func spend(price: int) -> bool:
	if not can_afford(price):
		return false
	money -= price
	save_game()
	return true


static func owns(id: String) -> bool:
	return owned.has(id)


static func meta_sorted() -> Array:
	var rows: Array = []
	for offer in META:
		rows.append(offer)
	rows.sort_custom(func(a, b): return int(a["cost"]) < int(b["cost"]))
	return rows


static func throw_pool() -> Array:
	var pool: Array = []
	for offer in CATALOG:
		var item: Dictionary = offer
		var gate := str(item.get("unlock", ""))
		if gate == "" or owns(gate):
			pool.append(item)
	return pool


static func meta_offer(id: String) -> Dictionary:
	for offer in META:
		var item: Dictionary = offer
		if str(item["id"]) == id:
			return item
	return {}


static func unlock(id: String) -> bool:
	if owns(id):
		return false
	var item := meta_offer(id)
	if item.is_empty():
		return false
	var cost := int(item["cost"])
	if not can_afford(cost):
		return false
	money -= cost
	owned.append(id)
	save_game()
	return true


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("purse", "coins", money)
	cfg.set_value("purse", "item_id", item_id)
	cfg.set_value("purse", "item_name", item_name)
	cfg.set_value("purse", "tint", item_tint)
	cfg.set_value("unlocks", "ids", owned)
	cfg.save(SAVE_PATH)


static func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	money = int(cfg.get_value("purse", "coins", 0))
	item_id = str(cfg.get_value("purse", "item_id", ""))
	item_name = str(cfg.get_value("purse", "item_name", ""))
	var tint = cfg.get_value("purse", "tint", Color(1.0, 0.86, 0.42))
	if tint is Color:
		item_tint = tint
	var ids = cfg.get_value("unlocks", "ids", PackedStringArray())
	owned = PackedStringArray()
	if ids is PackedStringArray:
		owned = ids
	elif ids is Array:
		for entry in ids:
			owned.append(str(entry))
