extends RefCounted

## One equipped item and the purse. Statics live on the script, so a scene
## reload keeps both without writing a save.

const Locale := preload("res://scripts/locale.gd")

static var item_id := ""
static var item_name := ""
static var item_tint := Color(1.0, 0.86, 0.42)
static var money := 0
static var last_earn := 0
static var owned: PackedStringArray = PackedStringArray()
static var music_volume := 40
static var sfx_volume := 70
## Session only. A reload returns to the menu when this is still true.
static var start_in_menu := true
## A run is five rooms. These survive a scene reload. The save file does not store them.
const RUN_ROOMS := 5
## Coins still in the run, after debt, that count as a won run on Run Complete.
const RUN_GOAL := 24
static var run_active := false
static var run_index := 1
static var run_earned := 0
static var run_best := 0
## Highest chain across finished runs. Written with the purse. A quit does not clear it.
static var best_ever := 0
static var run_show_complete := false
## True after Run Complete has moved run_earned into the purse. Abandon never sets this.
static var run_banked := false
## Failure state for the current run. Not written to the save.
static var run_fails := 0
static var run_streak := 0
static var run_debt := 0
static var run_debt_paid := 0
static var run_strain := false
static var run_gamble := false
static var run_gamble_next := false
## 0–5. Clears raise it. A miss lowers it by one. The next clear pays a little more.
static var run_heat := 0
const HEAT_MAX := 5
static var run_double := false
static var run_double_next := false
## One faster throw, granted by a Chain Master clear. Consumed on launch.
static var run_afterglow := false
const AFTERGLOW_SCALE := 1.08
## A throw that starts after the clock hits zero. Still playable.
const SOFT_SCALE := 0.88
static var last_lost := 0
static var last_bonus := 0
static var last_cleared := true
## Set when the room timer expires. The next launch is softer.
static var soft_throw := false

## speed scales the launch. mass scales the stone's 2.5 base.
## impact is extra hit speed on the first body. The rest are on-hit effects.
const CATALOG: Array = [
	{
		"id": "heavy_stone",
		"name": "Heavy Stone",
		"line": "Slow throw. A heavy downward hit.",
		"shape": "heavy",
		"tint": Color(0.38, 0.34, 0.32),
		"price": 12,
		"speed": 0.6,
		"mass": 2.35,
		"bounce": 0.02,
		"friction": 0.82,
		"weight": true,
	},
	{
		"id": "light_stone",
		"name": "Light Stone",
		"line": "Light. A short knock.",
		"shape": "light",
		"tint": Color(0.92, 0.88, 0.78),
		"price": 4,
		"speed": 1.08,
		"mass": 0.55,
		"bounce": 0.05,
		"friction": 0.58,
	},
	{
		"id": "spring_stone",
		"name": "Spring Stone",
		"line": "A small bounce and a weak hit.",
		"shape": "spring",
		"tint": Color(0.42, 0.82, 0.38),
		"price": 5,
		"speed": 1.0,
		"mass": 0.62,
		"bounce": 0.28,
		"friction": 0.4,
	},
	{
		"id": "blast_stone",
		"name": "Blast Stone",
		"line": "Pops nearby props on impact.",
		"shape": "blast",
		"tint": Color(0.95, 0.32, 0.16),
		"price": 16,
		"mass": 1.15,
		"blast": 146.0,
		"blast_force": 320.0,
	},
	{
		"id": "magnet_stone",
		"name": "Magnet Stone",
		"line": "Tugs nearby props after a hit.",
		"shape": "magnet",
		"tint": Color(0.38, 0.58, 0.96),
		"price": 14,
		"mass": 1.05,
		"magnet": 0.85,
		"magnet_radius": 176.0,
		"magnet_pull": 1500.0,
	},
	{
		"id": "wide_stone",
		"name": "Wide Stone",
		"line": "A little wider. Still a light hit.",
		"shape": "wide",
		"tint": Color(0.96, 0.74, 0.22),
		"price": 6,
		"speed": 0.96,
		"mass": 0.78,
		"radius": 18.0,
	},
	{
		"id": "glass_charm",
		"name": "Glass Charm",
		"line": "Shatters bottles near the hit.",
		"shape": "glass",
		"tint": Color(0.55, 0.86, 0.94),
		"price": 8,
		"mass": 0.85,
		"glass": 64.0,
	},
	{
		"id": "high_pop",
		"name": "High Pop",
		"line": "The hit throws props upward.",
		"shape": "pop",
		"tint": Color(0.98, 0.48, 0.18),
		"price": 8,
		"speed": 1.02,
		"mass": 0.9,
		"pop": 100.0,
		"pop_lift": 170.0,
	},
	{
		"id": "cork_stone",
		"unlock": "cork_stone",
		"name": "Cork Stone",
		"line": "Stops where it lands.",
		"shape": "cork",
		"tint": Color(0.73, 0.50, 0.30),
		"price": 5,
		"speed": 0.86,
		"mass": 0.7,
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
		"price": 6,
		"speed": 1.15,
		"mass": 0.26,
		"radius": 8.0,
		"bounce": 0.02,
		"friction": 0.28,
	},
	{
		"id": "thud_stone",
		"unlock": "thud_stone",
		"name": "Thud Stone",
		"line": "The first hit shoves harder.",
		"shape": "thud",
		"tint": Color(0.55, 0.36, 0.28),
		"price": 8,
		"speed": 0.88,
		"mass": 0.95,
		"bounce": 0.02,
		"friction": 0.7,
		"impact": 70.0,
	},
	{
		"id": "split_stone",
		"unlock": "split_stone",
		"name": "Split Stone",
		"line": "The first hit breaks it into two smaller stones.",
		"shape": "split",
		"tint": Color(0.95, 0.55, 0.72),
		"price": 9,
		"speed": 0.96,
		"mass": 1.05,
		"radius": 16.0,
		"bounce": 0.12,
		"friction": 0.4,
		"split": true,
	},
	{
		"id": "sticky_stone",
		"unlock": "sticky_stone",
		"name": "Sticky Stone",
		"line": "Sticks to the first thing it hits, then they fall together.",
		"shape": "sticky",
		"tint": Color(0.62, 0.78, 0.36),
		"price": 9,
		"speed": 0.94,
		"mass": 1.15,
		"bounce": 0.02,
		"friction": 0.8,
		"sticky": true,
	},
	{
		"id": "bounce_stone",
		"unlock": "bounce_stone",
		"name": "Bounce Stone",
		"line": "Rebounds a lot. The direct hit stays light.",
		"shape": "bounce",
		"tint": Color(0.38, 0.82, 0.96),
		"price": 10,
		"speed": 1.0,
		"mass": 0.62,
		"radius": 14.0,
		"bounce": 0.92,
		"friction": 0.08,
		"damp": 0.02,
		"spin_damp": 0.08,
	},
	{
		"id": "ricochet_stone",
		"unlock": "ricochet_stone",
		"name": "Ricochet Stone",
		"line": "Bounces harder off walls and shelves.",
		"shape": "ricochet",
		"tint": Color(0.96, 0.78, 0.28),
		"price": 12,
		"speed": 1.02,
		"mass": 0.78,
		"radius": 14.0,
		"bounce": 0.55,
		"friction": 0.2,
		"ricochet": true,
	},
	{
		"id": "heavy_drop",
		"unlock": "heavy_drop",
		"name": "Heavy Drop Stone",
		"line": "After the first hit it drops faster and knocks downward.",
		"shape": "drop",
		"tint": Color(0.45, 0.34, 0.28),
		"price": 13,
		"speed": 0.78,
		"mass": 1.85,
		"bounce": 0.02,
		"friction": 0.6,
		"heavy_drop": true,
	},
	{
		"id": "pebble_stone",
		"unlock": "pebble_stone",
		"name": "Pebble",
		"line": "Small and quick. A short knock.",
		"shape": "pebble",
		"tint": Color(0.78, 0.74, 0.66),
		"price": 5,
		"speed": 1.14,
		"mass": 0.5,
		"radius": 10.0,
		"bounce": 0.2,
		"friction": 0.35,
	},
	{
		"id": "pillow_stone",
		"unlock": "pillow_stone",
		"name": "Pillow",
		"line": "Big and slow. A soft wide hit.",
		"shape": "pillow",
		"tint": Color(0.95, 0.62, 0.68),
		"price": 6,
		"speed": 0.76,
		"mass": 0.95,
		"radius": 22.0,
		"bounce": 0.42,
		"friction": 0.22,
		"damp": 0.1,
	},
	{
		"id": "feather_stone",
		"unlock": "feather_stone",
		"name": "Feather",
		"line": "Light. Lifts what it hits.",
		"shape": "feather",
		"tint": Color(0.96, 0.94, 0.86),
		"price": 8,
		"speed": 1.06,
		"mass": 0.48,
		"radius": 12.0,
		"bounce": 0.12,
		"friction": 0.3,
		"pop": 120.0,
		"pop_lift": 210.0,
	},
	{
		"id": "spark_stone",
		"unlock": "spark_stone",
		"name": "Spark",
		"line": "A small pop around the hit.",
		"shape": "spark",
		"tint": Color(0.98, 0.72, 0.22),
		"price": 9,
		"speed": 0.98,
		"mass": 0.85,
		"radius": 14.0,
		"blast": 88.0,
		"blast_force": 170.0,
	},
	{
		"id": "skip_stone",
		"unlock": "skip_stone",
		"name": "Skip Stone",
		"line": "Fast. Kicks off walls.",
		"shape": "skip",
		"tint": Color(0.42, 0.78, 0.62),
		"price": 10,
		"speed": 1.16,
		"mass": 0.52,
		"radius": 12.0,
		"bounce": 0.45,
		"friction": 0.1,
		"damp": 0.04,
		"ricochet": true,
	},
]

## Permanent unlocks. A strong chain pays well. Late stones still take several runs.
## kind is "stone" or "room". The shop sorts this list by cost.
## kind is "stone" or "room". The shop sorts this list by cost.
const META: Array = [
	{
		"id": "cork_stone",
		"kind": "stone",
		"name": "Cork Stone",
		"line": "Stops where it lands.",
		"blurb": "Between throws, 5 coins",
		"cost": 24,
		"shape": "cork",
		"tint": Color(0.73, 0.50, 0.30),
	},
	{
		"id": "narrow",
		"kind": "room",
		"name": "Narrow Shelves",
		"line": "Short planks with a tall drop between them.",
		"blurb": "Joins the mix from room 2",
		"cost": 18,
		"shape": "narrow",
		"tint": Color(0.72, 0.78, 0.86),
	},
	{
		"id": "low_loft",
		"kind": "room",
		"name": "Low Loft",
		"line": "Both shelves sit close to the floor.",
		"blurb": "Joins the mix from room 2",
		"cost": 32,
		"shape": "loft",
		"tint": Color(0.86, 0.72, 0.42),
	},
	{
		"id": "needle_stone",
		"kind": "stone",
		"name": "Needle Stone",
		"line": "Small and fast. Flies far.",
		"blurb": "Between throws, 6 coins",
		"cost": 78,
		"shape": "needle",
		"tint": Color(0.86, 0.91, 0.96),
	},
	{
		"id": "floor_clutter",
		"kind": "room",
		"name": "Floor Clutter",
		"line": "A small high shelf. Almost everything sits on the floor.",
		"blurb": "Joins the mix from room 2",
		"cost": 44,
		"shape": "clutter",
		"tint": Color(0.78, 0.58, 0.36),
	},
	{
		"id": "market",
		"kind": "room",
		"name": "Market Row",
		"line": "A long low counter with the stock lined up on it.",
		"blurb": "Joins the mix from room 2",
		"cost": 54,
		"shape": "market",
		"tint": Color(0.84, 0.62, 0.28),
	},
	{
		"id": "split_bay",
		"kind": "room",
		"name": "Split Bay",
		"line": "Two shelves far apart, one much higher than the other.",
		"blurb": "Joins the mix from room 2",
		"cost": 66,
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
		"blurb": "Between throws, 8 coins",
		"cost": 120,
		"shape": "thud",
		"tint": Color(0.55, 0.36, 0.28),
	},
	{
		"id": "closet",
		"kind": "room",
		"name": "Closet",
		"line": "A tight shaft of stacked shelves.",
		"blurb": "Next rooms can roll this",
		"cost": 104,
		"shape": "closet",
		"tint": Color(0.62, 0.4, 0.24),
	},
	{
		"id": "split_stone",
		"kind": "stone",
		"name": "Split Stone",
		"line": "The first hit breaks it into two smaller stones.",
		"blurb": "Throw shop, 11 coins",
		"cost": 160,
		"shape": "split",
		"tint": Color(0.95, 0.55, 0.72),
	},
	{
		"id": "cellar",
		"kind": "room",
		"name": "Cellar",
		"line": "Dark and low. Bottles and jars in the damp.",
		"blurb": "Next rooms can roll this",
		"cost": 118,
		"shape": "cellar",
		"tint": Color(0.28, 0.46, 0.42),
	},
	{
		"id": "sticky_stone",
		"kind": "stone",
		"name": "Sticky Stone",
		"line": "Sticks to the first thing it hits, then they fall together.",
		"blurb": "Throw shop, 12 coins",
		"cost": 175,
		"shape": "sticky",
		"tint": Color(0.62, 0.78, 0.36),
	},
	{
		"id": "attic",
		"kind": "room",
		"name": "Attic",
		"line": "Dusty wood under a steep roof. Crates split when hit hard.",
		"blurb": "Next rooms can roll this",
		"cost": 134,
		"shape": "attic",
		"tint": Color(0.72, 0.52, 0.28),
	},
	{
		"id": "bounce_stone",
		"kind": "stone",
		"name": "Bounce Stone",
		"line": "Rebounds a lot. The direct hit stays light.",
		"blurb": "Throw shop, 13 coins",
		"cost": 195,
		"shape": "bounce",
		"tint": Color(0.38, 0.82, 0.96),
	},
	{
		"id": "workshop",
		"kind": "room",
		"name": "Workshop",
		"line": "A metal bench. Parts spin as they fall and clip what they touch.",
		"blurb": "Next rooms can roll this",
		"cost": 150,
		"shape": "workshop",
		"tint": Color(0.55, 0.58, 0.62),
	},
	{
		"id": "ricochet_stone",
		"kind": "stone",
		"name": "Ricochet Stone",
		"line": "Bounces harder off walls and shelves.",
		"blurb": "Throw shop, 14 coins",
		"cost": 220,
		"shape": "ricochet",
		"tint": Color(0.96, 0.78, 0.28),
	},
	{
		"id": "heavy_drop",
		"kind": "stone",
		"name": "Heavy Drop Stone",
		"line": "After the first hit it drops faster and knocks downward.",
		"blurb": "Throw shop, 15 coins",
		"cost": 245,
		"shape": "drop",
		"tint": Color(0.45, 0.34, 0.28),
	},
	{
		"id": "gallery",
		"kind": "room",
		"name": "Gallery",
		"line": "Short shelves under a few frames.",
		"blurb": "Next rooms can roll this",
		"cost": 182,
		"shape": "gallery",
		"tint": Color(0.86, 0.78, 0.62),
	},
	{
		"id": "pebble_stone",
		"kind": "stone",
		"name": "Pebble",
		"line": "Small and quick. A short knock.",
		"blurb": "Throw shop, 6 coins",
		"cost": 265,
		"shape": "pebble",
		"tint": Color(0.78, 0.74, 0.66),
	},
	{
		"id": "greenhouse",
		"kind": "room",
		"name": "Greenhouse",
		"line": "A low bench between two high pots.",
		"blurb": "Next rooms can roll this",
		"cost": 198,
		"shape": "greenhouse",
		"tint": Color(0.46, 0.72, 0.4),
	},
	{
		"id": "pillow_stone",
		"kind": "stone",
		"name": "Pillow",
		"line": "Big and slow. A soft wide hit.",
		"blurb": "Throw shop, 7 coins",
		"cost": 290,
		"shape": "pillow",
		"tint": Color(0.95, 0.62, 0.68),
	},
	{
		"id": "laundry",
		"kind": "room",
		"name": "Laundry",
		"line": "A high line and one low tub.",
		"blurb": "Next rooms can roll this",
		"cost": 214,
		"shape": "laundry",
		"tint": Color(0.62, 0.78, 0.9),
	},
	{
		"id": "feather_stone",
		"kind": "stone",
		"name": "Feather",
		"line": "Light. Lifts what it hits.",
		"blurb": "Throw shop, 8 coins",
		"cost": 310,
		"shape": "feather",
		"tint": Color(0.96, 0.94, 0.86),
	},
	{
		"id": "library",
		"kind": "room",
		"name": "Library",
		"line": "Stacked bookshelves and a low table.",
		"blurb": "Next rooms can roll this",
		"cost": 230,
		"shape": "library",
		"tint": Color(0.55, 0.36, 0.22),
	},
	{
		"id": "spark_stone",
		"kind": "stone",
		"name": "Spark",
		"line": "A small pop around the hit.",
		"blurb": "Throw shop, 9 coins",
		"cost": 335,
		"shape": "spark",
		"tint": Color(0.98, 0.72, 0.22),
	},
	{
		"id": "kitchen",
		"kind": "room",
		"name": "Kitchen",
		"line": "A long counter with two wall shelves.",
		"blurb": "Next rooms can roll this",
		"cost": 246,
		"shape": "kitchen",
		"tint": Color(0.93, 0.84, 0.68),
	},
	{
		"id": "pantry",
		"kind": "room",
		"name": "Pantry",
		"line": "A high middle shelf with two low wings.",
		"blurb": "Next rooms can roll this",
		"cost": 268,
		"shape": "pantry",
		"tint": Color(0.72, 0.48, 0.22),
	},
	{
		"id": "porch",
		"kind": "room",
		"name": "Porch",
		"line": "Three steps down toward the door.",
		"blurb": "Next rooms can roll this",
		"cost": 312,
		"shape": "porch",
		"tint": Color(0.62, 0.7, 0.58),
	},
	{
		"id": "bath",
		"kind": "room",
		"name": "Bathroom",
		"line": "A high rail and a low tub.",
		"blurb": "Next rooms can roll this",
		"cost": 348,
		"shape": "bath",
		"tint": Color(0.7, 0.84, 0.88),
	},
	{
		"id": "hall",
		"kind": "room",
		"name": "Hall",
		"line": "Shelves zigzag down the wall.",
		"blurb": "Next rooms can roll this",
		"cost": 392,
		"shape": "hall",
		"tint": Color(0.55, 0.62, 0.48),
	},
	{
		"id": "study",
		"kind": "room",
		"name": "Study",
		"line": "A desk and two shelves on the left.",
		"blurb": "Next rooms can roll this",
		"cost": 438,
		"shape": "study",
		"tint": Color(0.48, 0.32, 0.22),
	},
	{
		"id": "skip_stone",
		"kind": "stone",
		"name": "Skip Stone",
		"line": "Fast. Kicks off walls.",
		"blurb": "Throw shop, 10 coins",
		"cost": 355,
		"shape": "skip",
		"tint": Color(0.42, 0.78, 0.62),
	},
]

const SAVE_PATH := "user://knockroom.cfg"
## One old coin. Prices, payouts, debt, and a saved purse from before this scale use it once.
const COIN_SCALE := 100000


static func coin_value(raw: int) -> int:
	if raw <= 0:
		return 0
	return raw * COIN_SCALE


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
	return coin_value(int(item["price"]))


static func speed_scale() -> float:
	var item := effect()
	if item.is_empty():
		return 1.0
	return float(item.get("speed", 1.0))


## Aim preview and the launch share this. Afterglow and a late throw both show up.
static func throw_scale() -> float:
	var scale := speed_scale()
	if run_afterglow:
		scale *= AFTERGLOW_SCALE
	if soft_throw:
		scale *= SOFT_SCALE
	return scale


static func shape() -> String:
	var item := effect()
	if item.is_empty():
		return ""
	return str(item.get("shape", ""))


static func coins(amount: int) -> String:
	return Locale.coins(amount)


static func stone_radius() -> float:
	var item := effect()
	if item.is_empty():
		return 15.0
	return float(item.get("radius", 15.0))


static func payout_for(chain_count: int) -> int:
	# One knock pays nothing. Room coins and the run total use the same cut.
	# The old table topped out at 60, then 30% was taken off. This takes off another 70%.
	var full := 0
	if chain_count <= 1:
		return 0
	if chain_count == 2:
		full = 8
	elif chain_count == 3:
		full = 12
	elif chain_count == 4:
		full = 16
	elif chain_count < 8:
		full = chain_count * 4
	elif chain_count < 12:
		full = 32 + (chain_count - 8) * 2
	elif chain_count < 16:
		full = 42 + (chain_count - 12)
	else:
		full = mini(48 + (chain_count - 16), 60)
	return receive_coins(full)


## 70% less than the previous payout, then the purse scale. A 1-coin bonus can become 0.
static func receive_coins(amount: int) -> int:
	if amount <= 0:
		return 0
	var previous := (amount * 7 + 5) / 10
	var cut := (previous * 3 + 5) / 10
	return coin_value(cut)


## Coins added on the next clear for the heat already banked. Heat 0 pays nothing.
static func heat_bonus() -> int:
	if run_heat >= 5:
		return receive_coins(3)
	if run_heat >= 3:
		return receive_coins(2)
	if run_heat >= 1:
		return receive_coins(1)
	return 0


static func earn(chain_count: int) -> int:
	var pay := payout_for(chain_count)
	last_earn = pay
	money += pay
	save_game()
	return pay


## Run coins stay out of the purse until Run Complete calls bank_run().
static func note_room(chain_count: int, pay: int) -> void:
	run_earned += pay
	if chain_count > run_best:
		run_best = chain_count


## Every room needs 5. Fewer than 5 pays nothing for that room.
static func chain_need() -> int:
	return 5


## Cuts this run's coins. At least 1 when the run has any. Returns how many were lost.
static func take_run_cut(percent: int) -> int:
	if run_earned <= 0:
		last_lost = 0
		return 0
	var lost := (run_earned * percent) / 100
	if lost < 1:
		lost = mini(COIN_SCALE, run_earned)
	if lost > run_earned:
		lost = run_earned
	run_earned -= lost
	last_lost = lost
	return lost


static func mark_pass() -> void:
	run_streak = 0
	run_strain = false
	last_cleared = true
	run_heat = mini(run_heat + 1, HEAT_MAX)


static func mark_fail() -> void:
	run_fails += 1
	run_streak += 1
	run_strain = true
	last_cleared = false
	run_heat = maxi(run_heat - 1, 0)
	if run_streak >= 4:
		run_debt = mini(run_debt + 1, 1)


static func grant_afterglow() -> void:
	run_afterglow = true


static func arm_gamble() -> void:
	run_gamble_next = true
	run_double_next = false


static func arm_double() -> void:
	run_double_next = true
	run_gamble_next = false


static func clear_gamble_arm() -> void:
	run_gamble_next = false
	run_double_next = false


## The shop's risk buttons apply to the room that is about to start.
static func accept_gamble() -> void:
	run_gamble = run_gamble_next
	run_gamble_next = false
	run_double = run_double_next
	run_double_next = false


## Moves this run's coins into the purse once. Debt is paid first. Later calls do not add them again.
static func bank_run() -> void:
	if not run_banked:
		var debt := mini(coin_value(run_debt), run_earned)
		run_debt_paid = debt
		run_earned -= debt
		money += run_earned
		run_banked = true
	save_game()


static func begin_run() -> void:
	run_active = true
	run_index = 1
	run_earned = 0
	run_best = 0
	run_show_complete = false
	run_banked = false
	_clear_run_risk()


## Shop pick or skip. Room 5 ends the run. Earlier rooms move the index forward.
static func advance_run() -> void:
	if run_index >= RUN_ROOMS:
		run_show_complete = true
		run_active = false
		save_game()
		return
	run_index += 1


static func _clear_run_risk() -> void:
	run_fails = 0
	run_streak = 0
	run_debt = 0
	run_debt_paid = 0
	run_strain = false
	run_gamble = false
	run_gamble_next = false
	run_double = false
	run_double_next = false
	run_heat = 0
	run_afterglow = false
	last_lost = 0
	last_bonus = 0
	last_cleared = true
	soft_throw = false


## Drops coins earned this run. The purse keeps only what was already saved.
static func abandon_run() -> void:
	run_active = false
	run_index = 1
	run_earned = 0
	run_best = 0
	run_show_complete = false
	run_banked = false
	_clear_run_risk()
	save_game()


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


## Stones already in the backpack. Buying one once keeps it here.
static func backpack_stones() -> Array:
	var rows: Array = []
	for offer in CATALOG:
		var item: Dictionary = offer
		if not owns(str(item["id"])):
			continue
		var copy: Dictionary = item.duplicate()
		copy["owned_stone"] = true
		rows.append(copy)
	return rows


## Rooms and stones the player has bought. Rooms stay out of the throw shop.
static func backpack_entries() -> Array:
	var rows: Array = []
	for id in owned:
		var stone := find(str(id))
		if not stone.is_empty():
			rows.append({"id": str(id), "kind": "stone"})
			continue
		var meta := meta_offer(str(id))
		if meta.is_empty():
			continue
		rows.append({"id": str(id), "kind": str(meta.get("kind", "stone"))})
	return rows


## Puts a bought throw-shop stone into the backpack. A second buy does nothing.
static func keep_stone(id: String) -> void:
	if id == "" or owns(id):
		return
	if find(id).is_empty():
		return
	owned.append(id)
	save_game()


## Three stones from the backpack, chosen at random, to take for free.
## With an empty backpack, three stones from the shop that are still for sale.
static func throw_offers(count: int) -> Array:
	var bag := backpack_stones()
	if not bag.is_empty():
		bag.shuffle()
		var picks: Array = []
		var n := mini(count, bag.size())
		for i in n:
			picks.append(bag[i])
		return picks
	var base: Array = []
	for offer in CATALOG:
		var item: Dictionary = offer
		var gate := str(item.get("unlock", ""))
		var id := str(item["id"])
		if gate != "":
			continue
		if owns(id) or id == item_id:
			continue
		base.append(item.duplicate())
	if base.is_empty():
		for offer in CATALOG:
			var item: Dictionary = offer
			if str(item.get("unlock", "")) == "":
				base.append(item.duplicate())
	base.shuffle()
	var picks: Array = []
	var n := mini(count, base.size())
	for i in n:
		picks.append(base[i])
	return picks


## Names the cheapest locked unlock the purse cannot buy yet.
## Owned items are skipped. Something you can already buy is not repeated here.
static func next_goal_line() -> String:
	var locked: Array = []
	for offer in META:
		var item: Dictionary = offer
		if owns(str(item["id"])):
			continue
		locked.append(item)
	if locked.is_empty():
		return Locale.text("goal.done")
	locked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["cost"]) < int(b["cost"]))
	var target: Dictionary = {}
	for offer in locked:
		var item: Dictionary = offer
		if coin_value(int(item["cost"])) > money:
			target = item
			break
	if target.is_empty():
		return Locale.text("goal.enough")
	var id := str(target["id"])
	var kind := str(target.get("kind", "stone"))
	var display := Locale.room_name(id) if kind == "room" else Locale.item_name(id)
	var gap := coin_value(int(target["cost"])) - money
	return Locale.format("goal.need", [Locale.coins(gap), display])


static func next_goal_short() -> String:
	var best_id := ""
	var best_cost := 0
	for offer in META:
		var item: Dictionary = offer
		var id := str(item["id"])
		if owns(id):
			continue
		var cost := coin_value(int(item["cost"]))
		if best_id == "" or cost < best_cost:
			best_id = id
			best_cost = cost
	if best_id == "":
		return ""
	var tag := Locale.short_for(best_id)
	var gap := best_cost - money
	if gap <= 0:
		return ""
	return "+%s  %s" % [Locale.coins(gap), tag]


## True the first time this run's best chain beats the saved record. A miss-only run does not count.
static func note_best() -> bool:
	if run_best <= 0 or run_best <= best_ever:
		return false
	best_ever = run_best
	return true


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
	var cost := coin_value(int(item["cost"]))
	if not can_afford(cost):
		return false
	money -= cost
	owned.append(id)
	save_game()
	return true


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("purse", "coins", money)
	cfg.set_value("purse", "coin_scale", COIN_SCALE)
	cfg.set_value("purse", "item_id", item_id)
	cfg.set_value("purse", "item_name", item_name)
	cfg.set_value("purse", "tint", item_tint)
	cfg.set_value("unlocks", "ids", owned)
	cfg.set_value("settings", "language", Locale.code)
	cfg.set_value("settings", "music", music_volume)
	cfg.set_value("settings", "sfx", sfx_volume)
	cfg.set_value("settings", "best_ever", best_ever)
	cfg.save(SAVE_PATH)


static func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	money = int(cfg.get_value("purse", "coins", 0))
	var stored_scale := int(cfg.get_value("purse", "coin_scale", 1))
	if stored_scale < 1:
		stored_scale = 1
	var scaled_purse := false
	if stored_scale != COIN_SCALE and COIN_SCALE % stored_scale == 0:
		money *= COIN_SCALE / stored_scale
		scaled_purse = true
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
	Locale.set_code(str(cfg.get_value("settings", "language", "ru")))
	music_volume = int(cfg.get_value("settings", "music", 40))
	sfx_volume = int(cfg.get_value("settings", "sfx", 70))
	best_ever = int(cfg.get_value("settings", "best_ever", 0))
	# A throw-shop buy used to equip the stone without keeping it.
	var kept_stone := false
	if item_id != "" and not owns(item_id) and not find(item_id).is_empty():
		owned.append(item_id)
		kept_stone = true
	if scaled_purse or kept_stone:
		save_game()
