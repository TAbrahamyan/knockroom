# Knockroom

One room, one throw. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays, and the shop sells a stone for the next throw.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. Start Game enters the room.

## Loop

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the coins just earned. The shop then offers three stones. Buy one you can afford, or equip a stone you already unlocked, or skip. The room is rebuilt, and the stone you chose changes the next throw.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds.

R restarts the room. Coins, the equipped stone, unlocks, language, and volume are saved. The corner icon opens a menu for the meta shop, a restart, settings, and the main menu. Settings has English, Russian, and Chinese, plus music and effects volume.

## Room

Every new room builds a new shelf layout. The name of that layout sits under the title. A room has 18–23 loose objects and exactly 1 sweet spot on the highest shelf. Hitting that spot drops the shelves one after another, then the floor. A miss uses a softer cascade. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack against one wall, stairs, a balcony, and an alcove. Unlocked rooms join that roll. Narrow shelves are a short column with a tall drop. Floor clutter keeps almost everything on the ground. Split bay leaves a wide empty middle, including on the floor. Window heavy crowds the shelves under a large window. Market row is one long low counter. Low loft keeps both boards near the floor.

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

A full clear pays 11. Two clears are 22, so the first unlock takes a third strong throw. Later unlocks cost more. Owned rows stay marked Owned. Back returns to where you were. New room rolls the layout again from the default shelves plus anything you just unlocked. The throw shop mixes the eight base stones with stones you already own, and never shows a locked stone. An owned stone is marked Owned and equipped for the next throw without another coin cost.

## Still one room

This is still one room and one throw. The meta shop only adds stones and shelf layouts to that loop.
