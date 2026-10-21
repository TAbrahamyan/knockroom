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
		"shape": "heavy",
		"tint": Color(0.38, 0.34, 0.32),
		"price": 15,
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
		"price": 8,
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
		"price": 9,
		"bounce": 0.8,
		"friction": 0.16,
	},
	{
		"id": "blast_stone",
		"name": "Blast Stone",
		"line": "Pops nearby props on impact.",
		"shape": "blast",
		"tint": Color(0.95, 0.32, 0.16),
		"price": 22,
		"blast": 118.0,
		"blast_force": 250.0,
	},
	{
		"id": "magnet_stone",
		"name": "Magnet Stone",
		"line": "Tugs nearby props after a hit.",
		"shape": "magnet",
		"tint": Color(0.38, 0.58, 0.96),
		"price": 18,
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
		"price": 10,
		"radius": 26.0,
	},
	{
		"id": "glass_charm",
		"name": "Glass Charm",
		"line": "Shatters bottles near the hit.",
		"shape": "glass",
		"tint": Color(0.55, 0.86, 0.94),
		"price": 11,
		"glass": 110.0,
	},
	{
		"id": "high_pop",
		"name": "High Pop",
		"line": "The hit throws props upward.",
		"shape": "pop",
		"tint": Color(0.98, 0.48, 0.18),
		"price": 13,
		"pop": 108.0,
		"pop_lift": 260.0,
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


static func shape() -> String:
	var item := effect()
	if item.is_empty():
		return ""
	return str(item.get("shape", ""))


static func shards(amount: int) -> String:
	if amount == 1:
		return "1 shard"
	return "%d shards" % amount


static func stone_radius() -> float:
	var item := effect()
	if item.is_empty():
		return 15.0
	return float(item.get("radius", 15.0))


static func payout_for(chain_count: int) -> int:
	# A miss or a single knock pays nothing. A good chain banks a little.
	# A long chain buys one cheap or medium stone, then stops climbing.
	if chain_count <= 1:
		return 0
	if chain_count < 4:
		return chain_count - 1
	if chain_count < 10:
		return chain_count
	var extra := (chain_count - 10) / 2
	return mini(11 + extra, 16)


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
