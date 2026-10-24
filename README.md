# Knockroom

Four rooms, one throw each. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays, and the shop sells a stone for the next room.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. Start Game begins a run.

## Loop

A run is 4 rooms. The plate under the title shows the room name and `Room X / 4`.

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the coins just earned. The shop then offers three stones. Buy one you can afford, or equip a stone you already unlocked, or skip. The next room loads on its own.

Coins land in the purse as soon as the room pays, so the meta shop can spend them between rooms. The run-complete screen shows the total earned this run. It does not pay those coins a second time.

After room 4’s shop, a Run Complete screen shows the coins earned this run, the best chain, and Back to Main Menu.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds.

R and Restart Room rebuild only the current room. They do not advance the run, and they do not start it over. Main Menu ends the run and returns to the title. Coins already earned stay in the purse.

Coins, the equipped stone, unlocks, language, and volume are saved. The corner icon opens a menu for the meta shop, a restart, settings, and the main menu. Settings has English, Russian, and Chinese, plus music and effects volume.

## Room

Every room builds a new shelf layout. The name and the run counter sit on a plate under the title. Room 1 rolls the default layouts only. Rooms 2–4 add every room you have unlocked.

Narrow shelves and the alcove stock bottles. The cellar stocks bottles and jars. Market row, floor clutter, and the closet stock boxes. Split bay, the stacks, the attic, and the workshop stock crates. The long shelf and the low loft stock pots. The window and the balcony stock glass. Walls, floors, and shelf colors follow the same room. A room has 18–23 loose objects and exactly 1 sweet spot on the highest shelf. A hard hit and the sweet spot shake the view. Breaking glass and wood throw chips. An excellent chain flashes gold, and the coins pop beside the count. Hitting that spot drops the shelves one after another, then the floor. A miss uses a softer cascade. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack against one wall, stairs, a balcony, and an alcove. Narrow shelves are a short column with a tall drop. Floor clutter keeps almost everything on the ground. Split bay leaves a wide empty middle, including on the floor. Window heavy crowds the shelves under a large window. Market row is one long low counter. Low loft keeps both boards near the floor. The attic has a steep roof, a high short shelf, and crates. The cellar is dark and low, with bottles and jars. The workshop is a bench plus a small parts shelf. The closet is a tight stack of three narrow shelves.

## Coins

A miss or one or two knocks pay nothing. A chain of 3 or 4 pays 1 coin. The payout then climbs slowly: 10 links pay 7, 14 pay 9, and 18 or more pay 11. That buys one stone and does not pay for a second.

The amount is shown on the result line (`+7 coins`) and again in the shop. The purse is in the top-right corner. Cards you cannot afford stay dimmed. Skip is free.

## Stones

The equipped stone is tinted, carries an icon for what it does, and is named in the corner.

| Stone | Price | Effect |
| --- | --- | --- |
| Light Stone | 7 coins | Lighter, and it flies farther |
| Spring Stone | 8 coins | Bounces hard off what it hits |
| Wide Stone | 9 coins | A fatter stone with a wider collision |
| Glass Charm | 10 coins | Shatters bottles near the impact |
| High Pop | 11 coins | Throws nearby props upward |
| Heavy Stone | 13 coins | Heavier, shorter flight, harder hit |
| Magnet Stone | 16 coins | Pulls nearby props in after a hit |
| Blast Stone | 19 coins | Shoves nearby props on impact |
| Cork Stone | 8 coins | Stops where it lands. Unlocked in the meta shop |
| Needle Stone | 9 coins | Small and fast. Unlocked in the meta shop |
| Thud Stone | 10 coins | A harder first hit. Unlocked in the meta shop |
| Split Stone | 11 coins | Splits into two smaller stones on the first hit. Unlocked in the meta shop |
| Sticky Stone | 12 coins | Sticks to the first thing it hits, then they fall together. Unlocked in the meta shop |
| Bounce Stone | 13 coins | Bounces hard and keeps rebounding. Unlocked in the meta shop |
| Ricochet Stone | 14 coins | Bounces harder off walls and shelves. Unlocked in the meta shop |
| Heavy Drop Stone | 15 coins | After the first hit it falls faster and knocks downward. Unlocked in the meta shop |

## Meta shop

The corner icon opens a centered menu: Meta Shop, Restart Room, Settings, and Main Menu. Meta Shop is also on the main menu and on the throw shop. Stones and rooms are listed apart, each cheapest first. Coins spent there stay spent. Unlocks stay after you close the game.

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
| Closet | Room | 104 coins | Rooms 2–4 can roll a tight stack of narrow shelves |
| Split Stone | Stone | 112 coins | Joins the throw shop. Equipping it there is free |
| Cellar | Room | 118 coins | Rooms 2–4 can roll a dark, low bottle room |
| Sticky Stone | Stone | 126 coins | Joins the throw shop. Equipping it there is free |
| Attic | Room | 134 coins | Rooms 2–4 can roll a roof, crates, and a high short shelf |
| Bounce Stone | Stone | 140 coins | Joins the throw shop. Equipping it there is free |
| Workshop | Room | 150 coins | Rooms 2–4 can roll a bench and a parts shelf |
| Ricochet Stone | Stone | 158 coins | Joins the throw shop. Equipping it there is free |
| Heavy Drop Stone | Stone | 174 coins | Joins the throw shop. Equipping it there is free |

A full clear pays 11. Two clears are 22, so the first unlock takes a third strong throw. Later unlocks cost more. Owned rows stay marked Owned. Back returns to where you were. During a run, New room rebuilds the current room and does not move the counter. The throw shop mixes the eight base stones with stones you already own, and never shows a locked stone. An owned stone is marked Owned and equipped for the next room without another coin cost.

## Next

The design doc’s first three priorities are in: shop items change the throw, chains pay coins, and the shop spends them. Chain readability is in good shape. A run is now four rooms, with new rooms and stones in the unlock pool.

The doc still says each room should change how the chain behaves, not only how the room looks, and that content should stay put until that loop is fun. The next step is one small rule inside this 4-room run. Give one room a chain behavior of its own, such as fragile attic props that break, or workshop parts that spin as they fall. Do not make the rooms harder or longer.

After that feels good, grow toward the doc’s 5 rooms per run and a simple win: finish the run, or hit a coin target. The full room pool in the doc is about 20. Do not add bosses, difficulty scaling, biomes, character movement, or a collect-everything goal.

A smaller HUD step, if the chain behavior waits: show the equipped stone’s one-line effect under its name.
