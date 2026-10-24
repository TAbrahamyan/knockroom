# Knockroom

Eight rooms, one throw each. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays at the end of the run, and the shop sells a stone for the next room.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. Start Game begins a run.

## Loop

A run is 8 rooms. The plate under the title shows the room name and `Room X / 8`.

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the coins that room earned. The shop then offers three stones. Buy one you can afford from the safe purse, or equip a stone you already unlocked, or skip. The next room loads on its own.

Coins earned during the run are not safe yet. The per-throw shop and the meta shop spend only what was already in the purse. After room 8’s shop, Run Complete adds the run’s coins to the purse once. It shows that total, the best chain, and Back to Main Menu.

Main Menu during a run ends it and drops every coin earned in that run. There is no Restart Room. The only way forward is to finish the throw and the shop.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds.

Coins, the equipped stone, unlocks, language, and volume are saved. The corner icon opens a menu for the meta shop, settings, and the main menu. Settings has English, Russian, and Chinese, plus music and effects volume.

## Room

Every room builds a new shelf layout, and each layout has its own wall, floor, light, and material. The name and the run counter sit on a plate under the title. Room 1 rolls the default layouts only. Rooms 2–8 add every room you have unlocked.

A normal throw should not clear the room. Shelves and piles need a precise, heavy hit before a long chain starts. A full clear is rare. The plain stone and the cheap stones barely shove. Heavier and more expensive stones hit harder or do something the cheap ones cannot: a downward crush, a long rebound, a wall kick, a magnet pull, a blast.

Narrow shelves, the stairs, and the alcove stock bottles. Split bay and the cellar stock bottles and jars. Market row, floor clutter, and the closet stock boxes. The stacks, the attic, and the workshop stock crates. The long shelf and the low loft stock pots. The window and the balcony stock glass. A room has 18–23 loose objects and exactly 1 sweet spot on the highest shelf. A hard hit on that spot can still drop the shelves in order, then roll only the nearby floor. A miss barely travels. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack against one wall, stairs, a balcony, and an alcove. Narrow shelves are a short column with a tall drop. Floor clutter keeps almost everything on the ground. Split bay leaves a wide empty middle, including on the floor. Window heavy crowds the shelves under a large window. Market row is one long low counter. Low loft keeps both boards near the floor. The long shelf is a warm plaster hall. Side shelves hang between plum curtains. The stacks sit on a brick column. Stairs are cut stone. The balcony is open sky. The alcove is night. The low loft is sand. Split bay is underwater. Narrow shelves are a stone well. Floor clutter is dry earth. Window heavy is a bright glass room. Market row has a striped awning. The attic is dusty wood under a roof, and its crates split into pieces when hit hard. The cellar is dirt and roots. The workshop is metal, and its parts spin as they fall and clip whatever they touch. The closet is almost black, with one warm slit.

## Coins

A miss or one or two knocks pay nothing. A chain of 3 or 4 pays 1 coin. The payout then climbs slowly: 10 links pay 7, 14 pay 9, and 18 or more pay 11. That buys one stone and does not pay for a second.

The amount is shown on the result line (`+7 coins`) and again in the shop. The purse is in the top-right corner. Cards you cannot afford stay dimmed. Skip is free.

## Stones

The equipped stone is tinted, carries an icon for what it does, and is named in the corner.

| Stone | Price | Effect |
| --- | --- | --- |
| Light Stone | 7 coins | Light. A weak shove |
| Spring Stone | 8 coins | A small bounce and a weak hit |
| Wide Stone | 9 coins | A little wider. Still a light hit |
| Glass Charm | 10 coins | Shatters bottles near the impact |
| High Pop | 11 coins | Throws nearby props upward |
| Heavy Stone | 13 coins | Slow throw, heavy downward hit |
| Magnet Stone | 16 coins | Pulls nearby props in after a hit |
| Blast Stone | 19 coins | Shoves nearby props on impact |
| Cork Stone | 8 coins | Stops where it lands. Unlocked in the meta shop |
| Needle Stone | 9 coins | Small and fast. Unlocked in the meta shop |
| Thud Stone | 10 coins | A harder first hit. Unlocked in the meta shop |
| Split Stone | 11 coins | Splits into two smaller stones on the first hit. Unlocked in the meta shop |
| Sticky Stone | 12 coins | Sticks to the first thing it hits, then they fall together. Unlocked in the meta shop |
| Bounce Stone | 13 coins | Lots of rebounds, a light direct hit. Unlocked in the meta shop |
| Ricochet Stone | 14 coins | Bounces harder off walls and shelves. Unlocked in the meta shop |
| Heavy Drop Stone | 15 coins | After the first hit it falls faster and knocks downward. Unlocked in the meta shop |

## Meta shop

The corner icon opens a centered menu: Meta Shop, Settings, and Main Menu. Meta Shop is also on the main menu and on the throw shop. Stones and rooms are listed apart, each cheapest first. Coins spent there come from the safe purse. Unlocks stay after you close the game. Main Menu during a run drops that run’s coins.

| Unlock | Kind | Cost | What it does |
| --- | --- | --- | --- |
| Cork Stone | Stone | 28 coins | Joins the throw shop. Equipping it there is free |
| Narrow Shelves | Room | 36 coins | Short planks with a tall drop between them |
| Low Loft | Room | 46 coins | Shelves sit close to the floor |
| Needle Stone | Stone | 56 coins | Joins the throw shop. Equipping it there is free |
| Floor Clutter | Room | 66 coins | One small shelf. Most props sit on the floor |
| Market Row | Room | 72 coins | One long low counter |
| Split Bay | Room | 78 coins | Two shelves far apart, at different heights |
| Window Heavy | Room | 88 coins | A large window with the shelves crowded under it |
| Thud Stone | Stone | 98 coins | Joins the throw shop. Equipping it there is free |
| Closet | Room | 104 coins | Rooms 2–8 can roll a dark closet |
| Split Stone | Stone | 112 coins | Joins the throw shop. Equipping it there is free |
| Cellar | Room | 118 coins | Rooms 2–8 can roll a dirt cellar |
| Sticky Stone | Stone | 126 coins | Joins the throw shop. Equipping it there is free |
| Attic | Room | 134 coins | Rooms 2–8 can roll a dusty attic. Hard hits split its crates |
| Bounce Stone | Stone | 140 coins | Joins the throw shop. Equipping it there is free |
| Workshop | Room | 150 coins | Rooms 2–8 can roll a metal workshop. Parts spin as they fall |
| Ricochet Stone | Stone | 158 coins | Joins the throw shop. Equipping it there is free |
| Heavy Drop Stone | Stone | 174 coins | Joins the throw shop. Equipping it there is free |

A full clear pays 11. Two clears are 22, so the first unlock takes a third strong throw. Later unlocks cost more. Owned rows stay marked Owned. Back returns to where you were. New room is only on the title. During a run it is hidden, and nothing rebuilds the current room. The throw shop mixes the eight base stones with stones you already own, and never shows a locked stone. An owned stone is marked Owned and equipped for the next room without another coin cost. Cheaper stones stay weak. Higher prices hit harder or do a job the cheap stones cannot.

## Next

The design doc’s first three priorities are in: shop items change the throw, chains pay coins, and the shop spends them. A run is eight rooms. The attic and the workshop each change the chain, not only the paint. Leaving for the menu drops the run’s coins.

The next step is a simple win on top of this run: finish all eight rooms, or hit a coin target, and show that clearly. The doc’s full room pool is still about 20, so another room can wait until the win feels good. Do not add bosses, character movement, or a collect-everything goal.

A smaller HUD step, if the win waits: show the equipped stone’s one-line effect under its name.
