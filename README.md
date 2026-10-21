# Knockroom

One room, one throw. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays, and the shop sells a stone for the next throw.

Open the project in Godot 4.7 and run `scenes/main.tscn`.

## Loop

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the coins just earned. The shop then offers three stones. Buy one you can afford, or skip. The room is rebuilt, and the stone you bought changes the next throw.

R restarts the room. Coins and the equipped stone stay for the session.

## Room

Every launch and every restart builds a new shelf layout. A room has 18–23 loose objects and exactly 1 sweet spot on the highest shelf. Hitting that spot drops the shelves one after another, then the floor. A miss uses a softer cascade. The floor beside the slingshot stays clear.

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

## Still one room

This is the single-room loop. There is no run of many rooms and no meta unlocks.
