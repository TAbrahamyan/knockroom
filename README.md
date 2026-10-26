# Knockroom

Eight rooms, one throw each. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays at the end of the run, and the shop sells a stone for the next room.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. Start Game begins a run.

## Loop

A run is 8 rooms. The plate under the title shows the room name and `Room X / 8`.

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the coins that room earned. The shop then offers three stones. Buy one you can afford from the safe purse, or equip a stone you already unlocked, or skip. Gamble is one optional risk: the next room pays 3 extra coins if you clear it, and a miss takes a larger cut. Double or nothing is the other: that room’s coins are doubled on a clear, and a miss takes about 18%. The last room has no next room, so both are hidden there. The next room loads on its own.

Each room asks for a minimum chain. The plate says it in one line, `Need 3`. Rooms 1–2 need 2, rooms 3–5 need 3, and rooms 6–8 need 4. While the chain is one or two short, the counter says so. A miss shows a full-width Room failed banner with the chain, the need, and the coins lost. The run still continues. A miss cuts about 6% of the coins earned so far in the run. Gamble raises that cut to 12%. Double or nothing, the other optional risk, doubles that room’s coins on a clear and takes about 18% on a miss. A miss also marks the next room Strained +1, up to a need of 4. Four misses in a row add 1 debt, up to 1, taken when the run ends, and the next clock starts a little shorter. A clear drops the strain and the miss streak. Beating the need by 4 or more is a Chain Master clear: a gold banner, 3 extra coins, and a slightly faster throw next room.

A room also has a small bonus that does not fail you. Odd rooms pay 2 coins for hitting the sweet spot. Even rooms pay 2 coins for a chain of 10. The clock sits in a box as `70s`. It is about 78 seconds, and it pauses in the shop and the menus. Under 12 seconds the box and the edge of the screen turn red. If it hits zero before the throw, that throw is a little softer. You can still throw.

Heat sits under the counter. Clears fill it, up to 5, and a miss cools it by one. Heat pays a small bonus on the next clear. The best chain of the run sits beside it. The run’s goal is still 24 coins after debt. The plate keeps a `Coins n / 24` count. Coins earned during the run are not safe yet. The per-throw shop and the meta shop spend only what was already in the purse. After room 8’s shop, Run Complete adds the run’s coins to the purse once, after debt. The screen shows rooms cleared, the best chain, the coins added, and the misses if there were any. The run’s goal stays 24 coins after debt.

Main Menu during a run ends it and drops every coin earned in that run. There is no Restart Room. The only way forward is to finish the throw and the shop.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds.

Coins, the equipped stone, unlocks, language, and volume are saved. The corner icon opens a menu for the meta shop, settings, and the main menu. The first launch with no save uses Russian. Settings has English and Russian, plus music and effects volume.

## Room

Every room builds a new shelf layout, and each layout has its own wall, floor, light, and material. The name and the run counter sit on a plate under the title. Room 1 rolls the default layouts only. Rooms 2–8 add every room you have unlocked.

A careful throw with a cheap stone can clear an early room. A long chain still wants a heavier hit. Heavier and more expensive stones hit harder or do something the cheap ones cannot: a downward crush, a long rebound, a wall kick, a magnet pull, a blast, a soft wide pillow, a small spark, or a fast skip off the wall.

Narrow shelves, the stairs, and the alcove stock bottles. Split bay and the cellar stock bottles and jars. Market row, floor clutter, and the closet stock boxes. The stacks, the attic, and the workshop stock crates. The long shelf and the low loft stock pots. The window and the balcony stock glass. A room has 18–23 loose objects and exactly 1 sweet spot on the highest shelf. A hard hit on that spot can still drop the shelves in order, then roll only the nearby floor. A miss barely travels. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack against one wall, stairs, a balcony, and an alcove. Narrow shelves are a short column with a tall drop. Floor clutter keeps almost everything on the ground. Split bay leaves a wide empty middle, including on the floor. Window heavy crowds the shelves under a large window. Market row is one long low counter. Low loft keeps both boards near the floor. The long shelf is a warm plaster hall. Side shelves hang between plum curtains. The stacks sit on a brick column. Stairs are cut stone. The balcony is open sky. The alcove is night. The low loft is sand. Split bay is underwater. Narrow shelves are a stone well. Floor clutter is dry earth. Window heavy is a bright glass room. Market row has a striped awning. The attic is dusty wood under a roof, and its crates split into pieces when hit hard. The cellar is dirt and roots. The workshop is metal, and its parts spin as they fall and clip whatever they touch. The closet is almost black, with one warm slit. The gallery is pale plaster with a few frames. The greenhouse is green, with stems on the wall. The laundry is pale blue, with a line and hanging cloth. The library is brown, with book spines. The kitchen is cream, with a tile band and a small window.

## Coins

One knock pays nothing. A chain of 2 pays 4 coins, 4 pays 8, 6 pays 10, 8 pays 13, 10 pays 14, and a full clear tops out at 20. A short clear no longer buys a stone by itself.

The amount is shown on the result line (`+7 coins`) and again in the shop. A failed room shows the cut instead of a payout. The purse is in the top-right corner. Cards you cannot afford stay dimmed. Skip is free. Gamble does not buy a stone.

## Stones

The equipped stone is tinted, carries an icon for what it does, and is named in the corner.

| Stone | Price | Effect |
| --- | --- | --- |
| Light Stone | 8 coins | Light. A short knock |
| Spring Stone | 9 coins | A small bounce and a weak hit |
| Wide Stone | 10 coins | A little wider. Still a light hit |
| Glass Charm | 12 coins | Shatters bottles near the impact |
| High Pop | 12 coins | Throws nearby props upward |
| Heavy Stone | 16 coins | Slow throw, heavy downward hit |
| Magnet Stone | 19 coins | Pulls nearby props in after a hit |
| Blast Stone | 22 coins | Shoves nearby props on impact |
| Cork Stone | 9 coins | Stops where it lands. Unlocked in the meta shop |
| Pebble | 9 coins | Small and quick. Unlocked in the meta shop |
| Needle Stone | 10 coins | Small and fast. Unlocked in the meta shop |
| Pillow | 10 coins | Big, slow, and soft. Unlocked in the meta shop |
| Thud Stone | 12 coins | A harder first hit. Unlocked in the meta shop |
| Feather | 12 coins | Light, and it lifts what it hits. Unlocked in the meta shop |
| Split Stone | 13 coins | Splits into two smaller stones on the first hit. Unlocked in the meta shop |
| Sticky Stone | 13 coins | Sticks to the first thing it hits, then they fall together. Unlocked in the meta shop |
| Spark | 13 coins | A small pop around the hit. Unlocked in the meta shop |
| Bounce Stone | 15 coins | Lots of rebounds, a light direct hit. Unlocked in the meta shop |
| Skip Stone | 15 coins | Fast, and it kicks off walls. Unlocked in the meta shop |
| Ricochet Stone | 16 coins | Bounces harder off walls and shelves. Unlocked in the meta shop |
| Heavy Drop Stone | 18 coins | After the first hit it falls faster and knocks downward. Unlocked in the meta shop |

## Meta shop

The corner icon opens a centered menu: Meta Shop, Settings, and Main Menu. Meta Shop is also on the main menu and on the throw shop. Stones and rooms are listed apart, each cheapest first. Coins spent there come from the safe purse. Unlocks stay after you close the game. Main Menu during a run drops that run’s coins.

| Unlock | Kind | Cost | What it does |
| --- | --- | --- | --- |
| Cork Stone | Stone | 40 coins | Joins the throw shop. Equipping it there is free |
| Narrow Shelves | Room | 36 coins | Short planks with a tall drop between them |
| Low Loft | Room | 46 coins | Shelves sit close to the floor |
| Needle Stone | Stone | 80 coins | Joins the throw shop. Equipping it there is free |
| Floor Clutter | Room | 66 coins | One small shelf. Most props sit on the floor |
| Market Row | Room | 72 coins | One long low counter |
| Split Bay | Room | 78 coins | Two shelves far apart, at different heights |
| Window Heavy | Room | 88 coins | A large window with the shelves crowded under it |
| Thud Stone | Stone | 140 coins | Joins the throw shop. Equipping it there is free |
| Closet | Room | 104 coins | Rooms 2–8 can roll a dark closet |
| Split Stone | Stone | 160 coins | Joins the throw shop. Equipping it there is free |
| Cellar | Room | 118 coins | Rooms 2–8 can roll a dirt cellar |
| Sticky Stone | Stone | 175 coins | Joins the throw shop. Equipping it there is free |
| Attic | Room | 134 coins | Rooms 2–8 can roll a dusty attic. Hard hits split its crates |
| Bounce Stone | Stone | 195 coins | Joins the throw shop. Equipping it there is free |
| Workshop | Room | 150 coins | Rooms 2–8 can roll a metal workshop. Parts spin as they fall |
| Ricochet Stone | Stone | 220 coins | Joins the throw shop. Equipping it there is free |
| Heavy Drop Stone | Stone | 245 coins | Joins the throw shop. Equipping it there is free |
| Gallery | Room | 182 coins | Rooms 2–8 can roll a pale gallery |
| Pebble | Stone | 265 coins | Joins the throw shop. Equipping it there is free |
| Greenhouse | Room | 198 coins | Rooms 2–8 can roll a green greenhouse |
| Pillow | Stone | 290 coins | Joins the throw shop. Equipping it there is free |
| Laundry | Room | 214 coins | Rooms 2–8 can roll a pale laundry |
| Feather | Stone | 310 coins | Joins the throw shop. Equipping it there is free |
| Library | Room | 230 coins | Rooms 2–8 can roll a brown library |
| Spark | Stone | 335 coins | Joins the throw shop. Equipping it there is free |
| Kitchen | Room | 246 coins | Rooms 2–8 can roll a cream kitchen |
| Skip Stone | Stone | 355 coins | Joins the throw shop. Equipping it there is free |

A full clear pays up to 16. Owned rows stay marked Owned. Back returns to where you were. New room is only on the title. During a run it is hidden, and nothing rebuilds the current room. The throw shop mixes the eight base stones with stones you already own, and never shows a locked stone. An owned stone is marked Owned and equipped for the next room without another coin cost. Cheap stones can clear a short chain. Higher prices hit harder or do a job the cheap stones cannot.

## Web

Project → Export includes a Web preset. The renderer is already Compatibility. Thread support is off, so the page can run without cross-origin isolation headers. Export it as HTML and open `index.html` through a local server. No store SDK is included.

## Next

The design doc’s first three priorities are in: shop items change the throw, chains pay coins, and the shop spends them. A run is eight rooms. The attic and the workshop each change the chain, not only the paint. Leaving for the menu drops the run’s coins.

The next step is a simple win on top of this run: finish all eight rooms, or hit a coin target, and show that clearly. The doc’s full room pool is still about 20, so another room can wait until the win feels good. Do not add bosses, character movement, or a collect-everything goal.

A smaller HUD step, if the win waits: show the equipped stone’s one-line effect under its name.
