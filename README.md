# Knockroom

Five rooms, one throw each. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. Coins from the run are paid when the run ends. The shop between rooms rents a stone for the next throw. A separate shop keeps permanent unlocks.

Open the project in Godot 4.7 and run `scenes/main.tscn`. The game opens on the main menu. The first launch with no save is Russian. Settings switches between Russian and English.

## Loop

A run is 5 rooms. The plate under the corner menu shows `Room 1 of 5` (or `Комната 1 из 5`) and the chain that room needs.

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. Touch uses the same drag. When the room settles, a banner says whether the room was cleared, the chain length, and the coins gained or lost. Then the throw shop offers three stones.

Rooms 1–3 need a chain of 2. Rooms 4–5 need a chain of 3. A miss does not end the run. It cuts about 6% of the coins earned so far in that run, and the next room needs one more link, up to 4. Four misses in a row add 1 debt, taken once when the run ends. A clear removes the extra link.

Beating the need by 4 or more is a great clear: a gold banner, 6 extra coins, and one faster throw next room. Risk, from the throw shop, adds 3 coins on the next clear and raises a miss cut to 12%. Double adds a second copy of that room’s payout on a clear and raises a miss cut to 18%. Both are hidden on room 5, because there is no next room. Skip leaves the stone you have and still advances.

Odd rooms also pay 2 coins for hitting the bright spot. Even rooms pay 2 coins for a chain of 10. The plate says which one is active. The clock is about 78 seconds, or about 66 after two misses in a row. It pauses in the shop and the menus. If it hits zero before the throw, that throw is a little softer.

A streak of clears fills five marks. The next clear pays 1, 2, or 3 extra coins from that streak. A miss cools it by one. The best chain of the run sits beside those marks.

Coins on the plate are this run only. The number in the corner, and in the meta shop, is the saved purse. The throw shop and the meta shop spend the purse, not the coins still inside the run. After room 5 the run banks once, debt is paid out of the run first, and Run Complete shows the rooms cleared, the best chain, the coins added, and the misses. The meta shop opens on top of that screen.

Main Menu during a run ends it and drops the coins that were not banked yet. There is no Restart Room.

The window fits landscape and portrait. In the editor the play window stays 1280×720. On a phone the camera zoom follows the screen.

## Stones between rooms

The throw shop shows three stones you pay for each time you take them. These eight are always the pool. The stone already on the slingshot is left out of the three, so the shop does not sell you the one you are holding. Take one you can afford, or skip.

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

Stones you buy in the meta shop are not sold again. Equip one from that shop, in Yours, for free. The button says Take. The stone already with you says With you. Rooms you own stay marked Owned.

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

The main menu, the pause menu, and the throw shop open the same shop. Rows are grouped as Buy, Close (40 coins or fewer short), Later, and Yours. The price sits inside the row. A shortfall shows how many coins are missing and a fill bar. The line under the title is the next unlock you cannot afford yet. It does not repeat something you already own, and it does not repeat something already sitting in Buy.

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
| Pillow | Stone | 290 |
| Feather | Stone | 310 |
| Spark | Stone | 335 |
| Skip Stone | Stone | 355 |

## Coins from a chain

One knock pays nothing. A chain of 2 pays 8, 3 pays 12, and 4 pays 16. From there the room pays 4 coins per link until 8, then less, and a chain tops out at 60 before the bonuses above. A chain of 2 is enough for the Light Stone at 4. Skip Stone stays 355, so the full set still takes more than one run.

## Room

Every room builds a new shelf layout, with its own wall, floor, light, and props. There are 18–23 loose objects and one bright spot, on the highest shelf. The floor beside the slingshot stays clear.

Default layouts are the long shelf, side shelves, a stack, stairs, a balcony, and an alcove. Unlocked rooms are narrow shelves, low loft, floor clutter, market row, split bay, window heavy, closet, cellar, attic, workshop, gallery, greenhouse, laundry, library, and kitchen. The attic’s crates break when hit hard. The workshop’s parts spin as they fall.

## Saved data

Coins, the equipped stone, unlocks, language, music volume, effects volume, and the best chain are saved in `user://knockroom.cfg`.

A quiet loop plays in the background. The throw, hits, breaks, and chain milestones have their own sounds. Settings has language, music, and effects. The volume sliders save when you move them. Opening the panel does not zero them.

## Project

Godot 4.7, Compatibility renderer. The play scene is `scenes/main.tscn`. A Web export preset is in the project. This tree does not include a built HTML page.
