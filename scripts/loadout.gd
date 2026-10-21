extends RefCounted

## One equipped item for the next throw. Statics live on the script, so a scene
## reload keeps the choice without writing a save.

static var item_id := ""
static var item_name := ""


static func equip(id: String, display_name: String) -> void:
	item_id = id
	item_name = display_name
