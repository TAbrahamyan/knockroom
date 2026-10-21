extends RefCounted

## One equipped item and the purse. Statics live on the script, so a scene
## reload keeps both without writing a save.

static var item_id := ""
static var item_name := ""
static var item_tint := Color(1.0, 0.86, 0.42)
static var money := 0
static var last_earn := 0

## speed scales the launch. mass scales the stone's 2.5 base.
## impact is extra hit speed on the first body. The rest are on-hit effects.
const CATALOG: Array = [
	{
		"id": "heavy_stone",
		"name": "Heavy Stone",
		"line": "Hits harder. Flies shorter.",
		"mark": 0,
		"tint": Color(0.38, 0.34, 0.32),
		"price": 16,
		"speed": 0.68,
		"mass": 2.2,
		"bounce": 0.04,
		"impact": 170.0,
	},
	{
		"id": "light_stone",
		"name": "Light Stone",
		"line": "Flies farther off the sling.",
		"mark": 0,
		"tint": Color(0.92, 0.88, 0.78),
		"price": 6,
		"speed": 1.16,
		"mass": 0.46,
		"bounce": 0.2,
	},
	{
		"id": "spring_stone",
		"name": "Spring Stone",
		"line": "Bounces hard off everything.",
		"mark": 1,
		"tint": Color(0.42, 0.82, 0.38),
		"price": 10,
		"bounce": 0.88,
		"friction": 0.08,
	},
	{
		"id": "blast_stone",
		"name": "Blast Stone",
		"line": "Pops nearby props on impact.",
		"mark": 1,
		"tint": Color(0.95, 0.32, 0.16),
		"price": 24,
		"blast": 124.0,
		"blast_force": 360.0,
	},
	{
		"id": "magnet_stone",
		"name": "Magnet Stone",
		"line": "Tugs nearby props after a hit.",
		"mark": 2,
		"tint": Color(0.38, 0.58, 0.96),
		"price": 20,
		"magnet": 0.75,
		"magnet_radius": 148.0,
		"magnet_pull": 1100.0,
	},
	{
		"id": "wide_stone",
		"name": "Wide Stone",
		"line": "A fatter stone. Easier to clip.",
		"mark": 2,
		"tint": Color(0.96, 0.74, 0.22),
		"price": 12,
		"radius": 26.0,
	},
	{
		"id": "glass_charm",
		"name": "Glass Charm",
		"line": "Shatters bottles near the hit.",
		"mark": 3,
		"tint": Color(0.55, 0.86, 0.94),
		"price": 12,
		"glass": 110.0,
	},
	{
		"id": "high_pop",
		"name": "High Pop",
		"line": "The hit throws props upward.",
		"mark": 1,
		"tint": Color(0.98, 0.48, 0.18),
		"price": 14,
		"pop": 116.0,
		"pop_lift": 440.0,
	},
]


static func equip(id: String, display_name: String, tint: Color = Color(1.0, 0.86, 0.42)) -> void:
	item_id = id
	item_name = display_name
	item_tint = tint


static func clear_item() -> void:
	item_id = ""
	item_name = ""
	item_tint = Color(1.0, 0.86, 0.42)


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


static func stone_radius() -> float:
	var item := effect()
	if item.is_empty():
		return 15.0
	return float(item.get("radius", 15.0))


static func payout_for(chain_count: int) -> int:
	# A single knock still buys the cheapest stone. Misses pay nothing.
	if chain_count <= 0:
		return 0
	if chain_count == 1:
		return 6
	if chain_count == 2:
		return 9
	if chain_count == 3:
		return 12
	var pay := chain_count * 3
	if chain_count >= 10:
		pay += 8
	elif chain_count >= 4:
		pay += 4
	return pay


static func earn(chain_count: int) -> int:
	var pay := payout_for(chain_count)
	last_earn = pay
	money += pay
	return pay


static func can_afford(price: int) -> bool:
	return price >= 0 and money >= price


static func spend(price: int) -> bool:
	if not can_afford(price):
		return false
	money -= price
	return true
