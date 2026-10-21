extends RefCounted

## One equipped item for the next throw. Statics live on the script, so a scene
## reload keeps the choice without writing a save.

static var item_id := ""
static var item_name := ""
static var item_tint := Color(1.0, 0.86, 0.42)


static func equip(id: String, display_name: String, tint: Color = Color(1.0, 0.86, 0.42)) -> void:
	item_id = id
	item_name = display_name
	item_tint = tint
