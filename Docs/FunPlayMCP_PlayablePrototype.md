# 3x3 Card Autobattle — FunPlay MCP execution brief

## Goal

Build and verify a portrait 1080×1920 two-phase prototype loop:

`Preparation -> purchase/deploy/merge -> Battle -> reward -> Preparation (next round) -> Battle`

The prototype borrows only high-level interaction patterns: item cooldown auto-triggering and build synergies from *The Bazaar*, plus drag-to-buy, storage and combination from *Backpack Battles*. The 3×3 orthogonal-neighbour system is this project's primary differentiator.

## Non-negotiable architecture

- `CardSlot`: owns zone/index/occupant and drop highlight; no card art.
- `CardInput`: transparent interaction proxy; owns pointer and drag events; no visible art.
- `CardVisual`: follows an input proxy with lag, rotation, tilt, scale and shadow feedback; raycast disabled.
- `PrototypeGameFlowController`: owns run state, coins, round, shop offers, phase changes and saveable board data.
- `BattleSimulator`: deterministic data simulation; it never depends on scene object locations.
- Canvas layers: `Background`, `SafeArea/Content`, `CardInput`, `CardVisual`, `Drag`, `Effect`, `HUD`, `Popup`.

## Preparation rules

- Shop: 1×3, warehouse: 1×3, player board: 3×3.
- Card art is 260×170; slot is 270×180.
- Drag from Shop to Warehouse/Board purchases only when the destination is valid and coins are sufficient.
- Failed purchase returns to its exact Shop slot without charging.
- Owned cards can swap between warehouse and board.
- Dropping the same card and same quality onto an owned card consumes the moving card and upgrades the target.
- Tap without a drag opens a detail popup; dragging never opens it.
- Only cards on the 3×3 board participate in battle.

## Battle rules

- Enemy 3×3 at top; enemy HP information below it.
- Player 3×3 at bottom; player HP information above it.
- Every active card owns an independent cooldown and a bottom-to-top translucent progress overlay.
- Effects are resolved in a deterministic queue to avoid recursive trigger loops.
- Four-direction orthogonal neighbours only; diagonals do not count.
- Battle ends at 0 HP or at 45 seconds (remaining HP decides timeout).
- Win rewards `6 + round × 2` coins. Loss rewards 3 coins for prototype pacing.
- Returning increments the round, refreshes shop offers, and loads a stronger deterministic enemy board.

## Prototype card set (20)

| Id | Card | Cost | CD | Base effect | Role / adjacency |
|---|---|---:|---:|---|---|
| blade | Iron Blade | 4 | 3.2 | 9 damage | baseline weapon |
| dagger | Quick Dagger | 3 | 1.8 | 4 damage | fast trigger |
| hammer | War Hammer | 6 | 5.2 | 18 damage | slow burst |
| bow | Longbow | 5 | 3.8 | 8 damage | +3 per adjacent weapon |
| shield | Oak Shield | 4 | 4.0 | 11 shield | defense |
| armor | Plate Armor | 6 | 6.0 | 18 shield | durable defense |
| potion | Red Potion | 4 | 5.5 | 12 heal | sustain |
| herbs | Healing Herbs | 3 | 4.2 | 7 heal | +2 per adjacent support |
| fire | Fire Flask | 5 | 4.8 | 7 damage + 3 burn | damage-over-time |
| poison | Venom Vial | 5 | 4.6 | 2 damage + 4 poison | stacking pressure |
| frost | Frost Rune | 5 | 5.0 | 5 damage + slow | enemy tempo control |
| drum | War Drum | 6 | 6.5 | haste neighbours | cooldown engine |
| hourglass | Hourglass | 7 | 7.0 | haste all allies | team engine |
| banner | Battle Banner | 6 | passive | adjacent cards +25% power | formation payoff |
| battery | Arc Battery | 5 | 4.5 | 6 damage; hastes random ally | hybrid engine |
| thorns | Thorn Mail | 5 | 5.4 | 9 shield + 4 damage | hybrid defense |
| vampire | Blood Fang | 6 | 4.0 | 8 damage + 5 heal | drain |
| spark | Chain Spark | 7 | 5.0 | 7 damage × adjacent allies | adjacency burst |
| coin | Lucky Coin | 3 | 6.0 | 3 shield; +1 victory bonus | economy |
| core | Guardian Core | 8 | 7.5 | 14 shield + 8 heal | premium sustain |

Quality multiplier: Bronze `1.0`, Silver `1.65`, Gold `2.5`. Two equal cards merge into the next quality. Gold is the prototype cap.

## FunPlay MCP task order

1. Inspect active scene, VisualCard prefab and compile state; do not repeat a timed-out mutation without readback.
2. Add runtime data, run-state, preparation transaction and battle simulation scripts.
3. Recompile; stop on any error and fix before scene mutation.
4. Finish `CardSlot`, `CardInput`, and `PreparationCanvas` prefabs; bind the game-flow controller to the existing commercial layer hierarchy.
5. Add a `BattleView` hierarchy/prefab and a CD overlay beneath the interaction-free CardVisual visual root.
6. Populate shop/warehouse/player demo state through the controller, not hand-placed card art.
7. Save the scene and prefabs explicitly.
8. Enter Play Mode and verify: valid purchase, insufficient-funds rollback, swap, merge, detail popup, battle start, CD progress, result, return, round 2 start.
9. Exit Play Mode, collect Console errors, validate missing scripts/references, and capture preparation/battle screenshots.

## Acceptance checklist

- Zero compiler errors and zero missing scripts.
- A card's visible object is never the raycast target.
- Purchase is atomic: destination, ownership and coins update together or none update.
- Runtime board state is independent from RectTransform positions.
- Round 2 enemy has strictly greater effective stats than round 1.
- Scene can complete two battles without manual Inspector repair.

