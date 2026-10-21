# Knockroom

One room, one throw. Pull the stone back and it flies the other way. Whatever it knocks down joins the chain. The chain pays, and the shop sells a stone for the next throw.

Open the project in Godot 4.7 and run `scenes/main.tscn`.

## Loop

Hold the left mouse button, pull back from the slingshot, and release. The stone flies the opposite way. When the room settles, the result shows the chain and the money just earned. The shop then offers three stones. Buy one you can afford, or skip. The room is rebuilt, and the stone you bought changes the next throw.

R restarts the room. Money and the equipped stone stay for the session.

## Room

Every launch and every restart builds a new shelf layout. A room has 18–23 loose objects and exactly 3 sweet spots on the highest shelf. Hitting a sweet spot drops the shelves one after another, then the floor. A miss uses a softer cascade. The floor beside the slingshot stays clear.

## Money

A miss pays nothing. A chain of 1, 2, or 3 pays $6, $9, or $12. From 4 links on, each link pays $3, with an extra $4 from 4 links and an extra $8 from 10. The payout is shown on the result line (`+$12`) and again in the shop. The purse is in the top-right corner.

Cards you cannot afford stay dimmed. Skip is free.

## Stones

The equipped stone is tinted, carries a colored mark, and is named in the corner. It changes the next throw:

| Stone | Price | Effect |
| --- | --- | --- |
| Light Stone | $6 | Lighter, and it flies farther |
| Spring Stone | $10 | Bounces hard off what it hits |
| Wide Stone | $12 | A fatter stone with a wider collision |
| Glass Charm | $12 | Shatters bottles near the impact |
| High Pop | $14 | Throws nearby props upward |
| Heavy Stone | $16 | Heavier, shorter flight, harder hit |
| Magnet Stone | $20 | Pulls nearby props in after a hit |
| Blast Stone | $24 | Shoves nearby props on impact |

## Still one room

This is the single-room loop. There is no run of many rooms and no meta unlocks.
