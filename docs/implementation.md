# Root Access: implementation

Godot 4.7 (4.4+ needed for `ResourceLoader.list_directory`), GDScript, Compatibility renderer.

## Structure

```
autoload/    EventBus, SaveManager (settings + codex), AudioManager (synth), GameState (run + routing)
data/        cards/, defenders/, nodes/, events/ as .tres
scripts/data/  Resource classes: CardData, EffectData, DefenderData, NodeTypeData, EventData
scripts/run/   RunState, DeckCard, MapGraph, MapNode, Content (loads data/)
scenes/map/    MapScene, MapGenerator
scenes/encounter/  TurnManager (rules), EffectResolver, DefenderState, EncounterScene, Hand
scenes/ui/     Card, Enemy, TraceMeter, Codex, MainMenu, Reward, Shop, Safehouse, Event, RunEnd, Backdrop, UI
scenes/Main    Screen router, HUD, toasts, shader overlays
shaders/       crt, glitch, fog
tests/         GUT tests
tools/         simulate.gd
```

## Key rules

- **Logic has no UI dependency.** `RunState`, `MapGenerator`, `TurnManager` and `EffectResolver` are `RefCounted` with no autoload access, so tests and the simulator run them directly. Scenes only display state and forward input.
- **Content is data.** A new `.tres` in `data/` is picked up automatically. New card effects need a new `kind` in `EffectResolver`; new defender behaviors need a case in `TurnManager`.
- **Determinism.** All randomness goes through `RunState.rng` or the seeded generator, and content ids are sorted before picks.
- **Losing a fight needs no rollback.** `begin_move` sets `pending_id`; `current_id` only changes on `complete_move`. A loss calls `abort_move`, so the player is still on the previous node.
- **Scenes are thin.** `.tscn` files hold a root node and script; UI is built in code using `UI.gd` helpers.

## Deviations from the GDD's architecture

- `MapScene` is a `Control` that draws edges in `_draw`, not `Node2D` with `Line2D`, because packets animate along the same edges.
- `EffectData` is one class with a `kind` field, not a subclass per effect.
- Antivirus's action happens at defender time but lands on the next hand drawn, because the hand is empty by then.

## Commands

Set `GODOT` to the console binary, then run from the repo root. Install GUT 9.6.1 to `addons/gut` for tests.

```
$GODOT --headless --import
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
$GODOT --headless -s res://tools/simulate.gd -- --runs=500
$GODOT --headless --export-release Web build/web/index.html
```

## Status

Run on Godot 4.7.2 (.NET build):

- Import is clean. All 25 test functions pass, but through a temporary stand-in for GUT; GUT itself isn't installed in `addons/gut` and hasn't run them.
- Every screen was loaded and checked by screenshot. Real mouse clicks were tested from the menu through scanning, a card play, ending a turn and Disconnect.
- Two full runs were played through the UI with mouse events by a scripted driver: an assisted run to the win screen and an unassisted run to the Traced screen. No person has playtested it, and audio hasn't been heard.
- No export has been built. The project stays on GDScript because Godot 4.7 C# can't officially export to web. Build from the standard (non-.NET) editor with its export templates.

Balance: the first numbers gave the greedy bot 0% wins over 200 runs at about 17 Noise per fight. Lowering defender Integrity and Noise, and Default Password's Noise to 1, gave 15.2% over 500 runs at about 14 Noise per fight. That's still far above the 6 per fight assumed for the 1:1 Trace conversion, and most losing runs die during Exfil. Tune further from human playtests.
