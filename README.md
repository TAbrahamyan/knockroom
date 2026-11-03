# Knockroom

Five rooms, one throw each. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. Coins from the run are paid when the run ends. The shop between rooms lets you pick a stone you already bought, or buy one if your backpack is empty. A separate shop sells stones and rooms. A purchase leaves that shop and stays in the backpack.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. The first launch with no save is Russian. Settings switches between Russian and English.

## Loop

A run is 5 rooms. The plate under the corner menu shows the room number, the chain that room needs, and the coins of this run. Rules live on the Rules tab of the main menu and the pause menu.

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. Touch uses the same drag. When the room settles, a banner says whether the room was cleared, the chain length, and the coins gained or lost. Then the throw shop offers three stones.

Every room needs a chain of 5. Fewer than 5 pays nothing for that room. A miss does not end the run. It cuts about 6% of the coins earned so far in that run. Four misses in a row add 1 debt, taken once when the run ends.

Beating the need by 4 or more is a great clear: a gold banner, 1 extra coin, and one faster throw next room. Between rooms the only choice is a stone, or Next room. After room 5 the run ends at once.

The clock is 30 seconds, or 24 after two misses in a row. It pauses in the shop and the menus. If it hits zero before the throw, that throw is a little softer.

A streak of clears fills five marks. The next clear pays 1 extra coin when all five are full. A miss cools it by one. The best chain of the run sits beside those marks.

Coins on the plate are this run only. The number in the corner, and in the meta shop, is the saved purse. The throw shop and the meta shop spend the purse, not the coins still inside the run. After room 5 the run banks once, debt is paid out of the run first, and a short result shows the rooms cleared, the best chain, the coins added, and the misses. Main menu leaves that screen.

Main Menu during a run ends it and drops the coins that were not banked yet. There is no Restart Room.

The window fits landscape and portrait. In the editor the play window stays 1280×720. On a phone the camera zoom follows the screen.

## Stones between rooms

Between rooms you pick from the stones in your backpack. The game offers three of them at random, and taking one is free. A stone you buy stays in the backpack and is not sold again. With an empty backpack, the throw shop offers three of these eight stones for sale. The stone already on the slingshot is left out of that sale.

| Stone | Price | What it does |
| --- | --- | --- |
| Light Stone | 4 | Light. Knocks only nearby things |
| Spring Stone | 5 | Bounces. The hit is weak |
| Wide Stone | 6 | Wider, and still a light hit |
| Glass Charm | 8 | Breaks bottles near the hit |
| High Pop | 8 | Throws things upward |
| Heavy Stone | 12 | Slow, and it hits downward hard |
| Magnet Stone | 14 | Pulls nearby things in after a hit |
| Blast Stone | 16 | Shoves everything nearby |

Stones and rooms you buy in the meta shop leave that list and show up in the backpack on the Settings screen. A price you cannot pay yet says how many more coins you need. Owned stones are offered in the throw shop, and the button says Equip.

| Stone | What it does |
| --- | --- |
| Cork Stone | Drops and stops where it lands |
| Needle Stone | Thin and fast. Flies farther |
| Pebble | Small and fast. A light hit |
| Pillow | Big, slow, and soft |
| Thud Stone | The first hit is harder |
| Feather | Lifts what it hits |
| Split Stone | The first hit splits it into two stones |
| Sticky Stone | Sticks to the thing it hits and falls with it |
| Spark | A small blast where it hits |
| Bounce Stone | Bounces many times. The hit is light |
| Skip Stone | Fast. Kicks off walls |
| Ricochet Stone | Kicks harder off walls and shelves |
| Heavy Drop Stone | After the first hit it gets heavy and knocks down |

## Meta shop

The main menu, the pause menu, and the throw shop open the same shop. Stones and rooms are separate tabs. Inside a tab, rows you have not bought are grouped as Buy, Close, and Later. Bought stones and rooms are not listed there. They are in the backpack. The price sits inside the row. A shortfall says how many more coins you need, with a fill bar. The line under the list is the next unlock you cannot afford yet. It does not repeat something you already own, and it does not repeat something already sitting in Buy. The owned count in the corner counts both tabs.

Coins spent here come from the saved purse. Unlocks stay after you close the game. Owned rooms join the random mix from room 2. Room 1 uses only the default layouts.

| Unlock | Kind | Cost |
| --- | --- | --- |
| Narrow Shelves | Room | 18 |
| Cork Stone | Stone | 24 |
| Low Loft | Room | 32 |
| Floor Clutter | Room | 44 |
| Market Row | Room | 54 |
| Split Bay | Room | 66 |
| Needle Stone | Stone | 78 |
| Window Heavy | Room | 88 |
| Closet | Room | 104 |
| Cellar | Room | 118 |
| Thud Stone | Stone | 120 |
| Attic | Room | 134 |
| Workshop | Room | 150 |
| Split Stone | Stone | 160 |
| Sticky Stone | Stone | 175 |
| Gallery | Room | 182 |
| Bounce Stone | Stone | 195 |
| Greenhouse | Room | 198 |
| Laundry | Room | 214 |
| Ricochet Stone | Stone | 220 |
| Library | Room | 230 |
| Heavy Drop Stone | Stone | 245 |
| Kitchen | Room | 246 |
| Pebble | Stone | 265 |
| Pantry | Room | 268 |
| Pillow | Stone | 290 |
| Feather | Stone | 310 |
| Porch | Room | 312 |
| Spark | Stone | 335 |
| Bathroom | Room | 348 |
| Skip Stone | Stone | 355 |
| Hall | Room | 392 |
| Study | Room | 438 |

## Coins from a chain

One knock pays nothing. A chain of 5 pays 4, 6 pays 5, 8 pays 7, and 10 pays 8. A chain tops out at 13 before the small bonuses above. That is 70% less than the previous payouts, rounded, for each room and for the run total those rooms add up to. A chain under 5 pays nothing. Skip Stone stays 355, and the Study is 438, so the full set still takes more than one run.

## Room

Every room builds a new shelf layout, with its own wall, floor, light, and props. There are 18–23 loose objects and one bright spot, on the highest shelf. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack, stairs, a balcony, and an alcove. Unlocked rooms are narrow shelves, low loft, floor clutter, market row, split bay, window heavy, closet, cellar, attic, workshop, gallery, greenhouse, laundry, library, kitchen, pantry, porch, bathroom, hall, and study. The attic’s crates break when hit hard. The workshop’s parts spin as they fall.

## Saved data

Coins, the equipped stone, unlocks, language, music volume, effects volume, and the best chain are saved in `user://knockroom.cfg`.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds. Settings has language, music, and effects. The volume sliders save when you move them. Opening the panel does not zero them.

## Project

Godot 4.7, Compatibility renderer. The play scene is `scenes/main.tscn`. A Web export preset is in the project. This tree does not include a built HTML page.
