# Knockroom

One room, one throw. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays, and the shop sells a stone for the next throw.

Open the project in Godot 4.7 and run `scenes/main.tscn`.

## Loop

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the shards just earned. The shop then offers three stones. Buy one you can afford, or skip. The room is rebuilt, and the stone you bought changes the next throw.

R restarts the room. Shards and the equipped stone stay for the session.

## Room

Every launch and every restart builds a new shelf layout. A room has 18–23 loose objects and exactly 3 sweet spots on the highest shelf. Hitting a sweet spot drops the shelves one after another, then the floor. A miss uses a softer cascade. The floor beside the slingshot stays clear.

## Shards

Broken glass is the purse. A miss or a single knock pays nothing. A chain of 2 or 3 pays 1 or 2 shards. A chain of 4 to 9 pays that many shards. From 10 links the payout starts at 11 and caps at 16, so one throw buys one stone.

The amount is shown on the result line (`+8 shards`) and again in the shop. The purse is in the top-right corner. Cards you cannot afford stay dimmed. Skip is free.

## Stones

The equipped stone is tinted, carries an icon for what it does, and is named in the corner.

| Stone | Price | Effect |
| --- | --- | --- |
| Light Stone | 8 shards | Lighter, and it flies farther |
| Spring Stone | 9 shards | Bounces hard off what it hits |
| Wide Stone | 10 shards | A fatter stone with a wider collision |
| Glass Charm | 11 shards | Shatters bottles near the impact |
| High Pop | 13 shards | Throws nearby props upward |
| Heavy Stone | 15 shards | Heavier, shorter flight, harder hit |
| Magnet Stone | 18 shards | Pulls nearby props in after a hit |
| Blast Stone | 22 shards | Shoves nearby props on impact |

## Still one room

This is the single-room loop. There is no run of many rooms and no meta unlocks.
