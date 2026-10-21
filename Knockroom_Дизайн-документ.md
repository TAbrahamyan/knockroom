# Knockroom — Design Document

**Title:** Knockroom  
**Genre:** Physics roguelite / chain-reaction roguelite  
**Platform:** PC (Steam)  
**Engine:** Godot 4 (GDScript, Compatibility / Mobile renderer)  
**Development:** Solo, vibe coding, no budget  
**Target session length:** 8–12 minutes  
**Price target:** $4–6  

---

## Concept

You throw one object into a room full of props. Physics and short rules create a chain reaction. Money is earned from chain length and quality. Between throws you choose the next item in a shop. Runs are short. The goal is to reach the end or hit a money target.

One verb: “throw”. Everything else happens on its own.

Camera is fixed. The whole room is visible. No character to control.

---

## Why it can work

- Understandable in 5–8 seconds without sound.
- Clipable: good throw, average throw, and miss all work as clips.
- Short sessions.
- Low price.
- Systems over content. A solo developer can build the core quickly.

No direct clone. Closest in spirit to How to Fish and peglin-style roguelites. The specific loop “one throw into a fixed room of objects + chain score + short runs with item choices” is not heavily occupied.

---

## Core Loop

1. A room is generated (randomized structure).
2. You throw one item with the mouse (force + angle).
3. Watch the chain reaction (20–40 seconds).
4. Receive money based on chain length and quality.
5. Shop appears with 3 random item choices.
6. Pick one (or skip).
7. A new randomized room is generated.
8. Repeat.
9. Run ends after a set number of rooms (or on failure).

Between throws: 15–30 seconds for the shop. Full run: 8–12 minutes.

---

## Current Implementation Status

The following is already built and should be preserved:

- Randomized room structure (shelf count and positions vary)
- 18–23 knockable objects per room
- Exactly 3 random sweet spots on the highest shelf
- Sequential cascade on sweet spot hits (top shelf → lower shelves → floor)
- Softer cascade on misses
- Clear throw lane near the slingshot
- Wall bounce
- Bottle shatter
- Basic juice (screen shake, particles, +1 popups)
- Shop placeholder after each throw (3 choices, no real effects yet)
- English UI
- Fixed camera

---

## Rooms

**Full release pool:** ~20 rooms.  
**Per run:** 5 rooms (later).  
**Current prototype:** One room type that is heavily randomized.

Each room should change how chains behave, not just look different.

Examples for later:
- Market — many light stalls and barrels, long wide chains
- Warehouse — heavy crates, shorter but stronger chains
- Chicken coop — objects that move on their own after being hit
- Workshop — tools that spin when falling
- Attic — fragile expensive items that break easily
- Mirror room — reflecting surfaces

For now, focus on making the single randomized room feel good and varied.

---

## Items / Projectiles

**Full pool:** 20–25 items.  
**Between throws:** choice of 3.  
**Per run:** 5–7 items can be acquired.

Items must change physics and how the chain looks, not just numbers.

Current shop exists but items have no effects. Next priority is to add real effects.

Starter examples:
- Normal stone (baseline)
- Heavy weight — hits harder, flies shorter
- Spring — first impact launches objects upward
- Sticky bomb — sticks and explodes after a delay
- Bee cage — releases a swarm that pushes light objects
- Mirror — reflects the projectile once
- Magnet — pulls metallic objects toward the impact point

Synergies should be simple and visible.

---

## Progression and Meta

Money is earned from chains during a run.

Money is spent in the shop on items.

Later meta (between runs):
- Unlock new rooms into the pool
- Unlock new items into the shop

Important:
- Starting pool should already feel alive
- First unlocks should be cheap
- No “collect everything” goal
- Unlocks expand the pool, they are not a win condition

Win condition for a run: reach the end or hit a money target.  
Most players will play 4–8 hours and leave. This is fine for a $5 game.

---

## What Not To Do

- Do not add character movement after the throw
- Do not add shooting enemies
- Do not add a long economy or many biomes yet
- Do not add multiplayer
- Do not add a “collect everything” goal
- Do not add rooms or items that do not change how the chain looks
- Do not expand content until the core loop is fun

---

## Next Priorities (in order)

1. Add real, noticeable effects to shop items
2. Add money earned from chain length/quality
3. Make the shop use money (prices)
4. Improve chain readability and satisfaction
5. Later: more item variety, room modifiers, meta unlocks

---

## Prototype Success Criteria

You want to throw again yourself  
**or**  
Test players ask to throw again after the timer ends.

If most people close the game after 2–3 throws, the core has a problem. Do not fix it with more content.