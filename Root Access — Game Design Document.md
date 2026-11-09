# Root Access — Game Design Document

Oct 31, 2026 · @Dmytro Maistruk

## Overview

Root Access is a 2D roguelike deckbuilder where you play a hacker breaching a procedurally generated corporate network, one host at a time, before the blue team traces you.

| Item | Decision |
| --- | --- |
| Genre | Roguelike deckbuilder with light dungeon crawling |
| Engine | Godot 4.x, GDScript |
| View | 2D top-down network map + card hand UI, with 2.5D shader effects |
| Platforms | PC (Windows/Linux) + Web export for itch.io and GitHub Pages |
| Run length | 15–25 minutes |
| Audience | Players of Slay the Spire, Inscryption, Hacknet; security-curious gamers and students |
| Team | Solo |

**Design pillars**

1. **Stealth vs speed.** Every action trades noise for progress. Loud exploits are fast but raise the trace meter.
2. **Real concepts, abstract mechanics.** Cards are named after real techniques (port scan, phishing, privilege escalation) and behave like them in spirit, never as real instructions.
3. **Build a playstyle.** Each run you assemble a loadout: ghost (stealth), brute force (fast and loud) or social engineer (manipulate people, not machines).
4. **Readable at a glance.** The network map tells you what you know, what you don't, and where danger is, without reading a manual.

**Elevator pitch:** Slay the Spire meets Hacknet. Breach the network, grab the data, get out before the trace hits 100%.

## Core loop and run structure

A run is one breach: three network layers, each ending in a guarded host, finishing at the Domain Controller boss and an exfiltration escape.

**Moment-to-moment loop (one host)**

1. Select an adjacent node on the map (only scanned nodes show their type).
2. Enter the host: an encounter with defenders (firewall, antivirus, IDS sensor, sysadmin).
3. Play cards from your hand using **CPU** (energy per turn) to break defenses.
4. Each card adds **Noise**; at the end of an encounter, noise feeds the global **Trace** meter.
5. Win: gain loot (new card, script upgrade, credentials, data). Lose: trace spikes and you're kicked to the previous node.

**Run structure**

| Layer | Theme | Hosts | Ends with |
| --- | --- | --- | --- |
| 1. DMZ | Public web servers, mail, VPN gateway | 5–7 | Perimeter Firewall (mini-boss) |
| 2. Internal network | Workstations, file shares, printers, IoT | 6–8 | Security Operations Center (mini-boss) |
| 3. Core | Databases, backup server, admin consoles | 5–6 | Domain Controller (boss) |
| Exfil | Escape sequence | 1 | Upload data before trace hits 100% |

**Between runs (meta progression)**

- **Reputation** earned per run unlocks new starting rigs (characters), cards in the pool and cosmetic terminal themes.
- **Zero-day vault:** rare one-shot cards found in runs can be kept (max 1) for the next run.
- Unlocks add variety, not raw power, so skill stays the main driver.

**Lose condition:** Trace reaches 100% → you're traced, the run ends. **Win:** exfiltrate the target data from the Core.

## Mechanics

Four systems carry the game: the network map, the card hand, the trace meter and the defenders.

### Network map

- Procedurally generated graph per layer (nodes = hosts, edges = network links), drawn top-down.
- **Fog of war:** unscanned nodes show only as "unknown". Recon cards reveal type, defenses and loot.
- Node types: Server, Workstation, Router, IoT device, Honeypot (trap that looks like loot), Shop (dark web market), Safehouse (rest: remove noise or upgrade a card), Event (story choice).
- Firewalls gate edges: some paths need specific cards or credentials to cross.

### Cards (exploits and tools)

Resources per turn: **CPU** (3 base) to play cards; each card also has a **Noise** value.

| Category | Example cards | Role |
| --- | --- | --- |
| Recon | Port Scan, OSINT, Packet Sniff | Reveal map and enemy intents; low noise |
| Exploit | SQL Injection, Buffer Overflow, Default Password | Deal damage to a defense's integrity |
| Social | Phishing Email, Pretext Call, Tailgate | Bypass or convert human defenders (sysadmin, helpdesk) |
| Stealth | Proxy Chain, Log Wipe, Living off the Land | Reduce noise and trace |
| Persistence | Backdoor, Scheduled Task | Effects that carry across hosts |
| Escalation | Privilege Escalation, Token Theft | Multiply effects, unlock admin-only nodes |
| Payload | Data Exfil, Ransom Note (gray hat route) | Score objectives |

Cards upgrade (e.g. Port Scan → Stealth Scan: same effect, half the noise).

### Trace meter

- Global 0–100% meter visible at all times.
- Fed by noise left at the end of each encounter, failed exploits and tripped honeypots.
- Thresholds escalate defenders: 25% more IDS sensors, 50% admins start patching (cards lose effect), 75% incident response team hunts you on the map.
- This is the main tension: rush and get caught, or play slow and run out of hand resources.

### Defenders (enemies)

| Defender | Behavior | Counter |
| --- | --- | --- |
| Firewall | High integrity, blocks one card type per turn | Recon to see which, exploit around it |
| Antivirus | Deletes your highest-noise card in hand | Stealth or obfuscated payloads |
| IDS Sensor | Doubles noise while alive | Kill it first or Log Wipe |
| Sysadmin (human) | Patches: removes your buffs | Social cards distract or turn them |
| Honeypot | Looks like loot, triggers trace spike | Recon reveals it |
| EDR Agent | Learns: the same card twice in a row is blocked | Vary your plays |

### Bosses

- **Perimeter Firewall** (DMZ): rotating rule sets; read its intents and adapt.
- **SOC** (Internal): multiple analysts that raise trace each turn until silenced.
- **Domain Controller** (Core): two phases; phase 2 starts a countdown to full lockdown.

### Characters (starting rigs)

- **Ghost:** stealth deck, low noise, low damage.
- **Script Kiddie:** cheap loud exploits, high damage, high noise.
- **Social Engineer:** human-targeting cards, weak against machines.

## Security realism and responsible design

The game teaches how attacks *flow* (recon → initial access → escalation → lateral movement → exfiltration) without teaching how to perform any of them.

- **Real names, abstract effects.** "SQL Injection" deals damage to web-app defenses; no queries, payloads or commands appear in the game.
- **Kill chain as structure.** Layers and card categories mirror MITRE ATT&CK tactics, so players absorb the logic of real intrusions.
- **Defenders are the heroes too.** Card codex entries explain how each technique is detected and prevented (e.g. "Phishing: stopped by MFA and training"). This is the educational payoff and a strong portfolio talking point.
- **Fictional world.** The target corporations, products and people are invented. No real companies, logos or vulnerabilities.
- **Optional "Blue team notes"** in the codex: after a run, show which defenses would have stopped the player's path.

## Art, audio and 2D / 2.5D direction

Gameplay is pure 2D; 2.5D is used only for atmosphere where it costs little and reads well.

| Screen | Dimension | Approach |
| --- | --- | --- |
| Network map | 2D | Top-down node graph, glowing lines, fog shader over unknown nodes |
| Encounter / card battle | 2D with 2.5D backdrop | Flat cards and enemy icons; background is a parallax server room or abstract "cyberspace" with depth layers |
| Main menu / hub | 2.5D | Hacker's desk in a dark room, monitors glowing (layered sprites or a small 3D scene rendered to a texture) |
| Codex / UI | 2D | Terminal windows, monospace fonts |

**Visual style:** neon terminal noir. Dark background, one accent color per faction (green = you, red = defenders, amber = humans).

**Cheap high-impact effects (Godot shaders):**

- CRT scanlines and slight screen curvature (toggleable for accessibility)
- Glitch / chromatic aberration when trace rises
- Data packets as particles flowing along map edges
- Screen shake and red flicker on trace thresholds

**Art production:** vector or simple pixel icons, made in Aseprite/Inkscape or from asset packs (Kenney, itch.io). Cards = frame + icon + text, built as a reusable Godot scene, so no illustrated art per card is needed.

**Audio:** synthwave / darksynth music that intensifies with trace (layered stems). Keyboard clicks, modem chirps and alarm sounds for feedback. Free sources: freesound.org, OpenGameArt, or commissioned later.

## Godot technical architecture

Data-driven design: cards, defenders and node types are Godot Resources (.tres), so new content needs no new code.

**Autoload singletons**

- `GameState` — current run: deck, trace, CPU, credentials, layer
- `EventBus` — global signals (`trace_changed`, `card_played`, `node_entered`)
- `SaveManager` — meta progression to `user://` (JSON or ConfigFile)
- `AudioManager` — music stems that react to trace

**Key scenes**

- `MapScene` — procedural graph generation + node buttons (Node2D, Line2D for edges)
- `EncounterScene` — turn manager, hand, enemies (Control-based UI)
- `Card.tscn` — reusable card view bound to a `CardData` resource
- `Enemy.tscn` — defender view bound to `DefenderData` with an intent system

**Project structure**

```
res://
  autoload/        GameState.gd, EventBus.gd, SaveManager.gd, AudioManager.gd
  data/cards/      *.tres (CardData)
  data/defenders/  *.tres (DefenderData)
  data/nodes/      *.tres (NodeTypeData)
  scenes/map/      MapScene.tscn, MapGenerator.gd
  scenes/encounter/ EncounterScene.tscn, TurnManager.gd, Hand.gd
  scenes/ui/       Card.tscn, TraceMeter.tscn, Codex.tscn
  shaders/         crt.gdshader, glitch.gdshader, fog.gdshader
  tests/           GUT unit tests
```

**Card effects:** each card holds an array of `EffectData` resources (DealDamage, AddNoise, Reveal, DrawCards…), executed in order by an `EffectResolver`. This keeps cards composable and makes balancing a data task.

**Map generation:** layered graph (like Slay the Spire's map) with constraints: guaranteed path to the boss, at least one Safehouse and one Shop per layer, honeypots never on the only path. Seeded RNG so runs can be shared and reproduced.

**Testing:** GUT (Godot Unit Test) for effect resolution, trace math and map constraints. A headless simulation script that plays random decks helps catch balance outliers.

**Exports:** Web (HTML5) for itch.io, Windows and Linux desktop. Check web export performance of shaders early.

## MVP scope, roadmap, risks, open questions

The MVP is one playable 15-minute run through a single layer, built in about 8 weeks of part-time work, reusing the Patch Notes prototype's Godot experience.

**MVP contents:** 1 layer (DMZ), 1 character (Ghost), 15 cards, 5 defender types, 1 boss (Perimeter Firewall), trace meter, map generation, web export.

**Roadmap**

1. **Weeks 1–2: Card combat prototype.** Hand, CPU, noise, 2 defenders, placeholder art. Goal: is a single fight fun?
2. **Weeks 3–4: Map + run loop.** Procedural layer, node types, trace meter, win/lose.
3. **Weeks 5–6: Content.** 15 cards, 5 defenders, boss, upgrades, shop and safehouse.
4. **Weeks 7–8: Juice + release.** Shaders, sound, codex, tutorial, itch.io web build, playtests.
5. **Post-MVP:** layers 2–3, two more characters, meta progression, Steam page if playtests are strong.

**Risks and mitigations**

| Risk | Mitigation |
| --- | --- |
| Combat feels flat | Prototype combat first with placeholder art; iterate before building content |
| Balance takes forever | Data-driven cards + headless simulation script |
| Procedural maps feel random | Hand-authored constraints and templates, not pure randomness |
| Scope creep | Freeze MVP list; new ideas go to a backlog |
| Web export performance | Test shaders on web export in week 1 |

**Open questions**

- Turn-based card combat only, or add a real-time pressure element (trace ticking per second)?
- Should the player stay "ethical" (pentester hired by the company) or play a gray-hat outlaw? Affects story and tone.
- One-time story setting or pure arcade runs?
- Should an optional LLM-driven sysadmin enemy be explored post-MVP?
