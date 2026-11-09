# Root Access: MVP design

Refines `Root Access — Game Design Document.md` with the decisions made while reviewing it. Where they differ, this file wins for the MVP. All numbers are starting values to tune with `tools/simulate.gd`.

## Scope

One run through the DMZ with the Ghost rig, ending in the Perimeter Firewall boss and an Exfil encounter. Purely turn-based. The player is a gray-hat outlaw breaching the fictional Halcyon Meridian, in arcade runs with short flavor text.

Not in the MVP: layers 2 and 3, other rigs, Reputation, Zero-day vault, mid-run saves, Ransom Note, a roaming incident response team, LLM sysadmin.

## Combat

- Each turn: draw 5, 3 CPU, play cards, discard the rest of the hand, then defenders act.
- Noise is the fight's health bar. Cards and defender actions add it.
- Noise 20 means Detected: Trace +15, kicked back.
- Disconnect is voluntary: Trace +8, kicked back.
- On a win, leftover Noise converts to Trace 1:1.
- Kicked back means returning to the previous node. The host's defenders reset and you can retry or take another edge.
- Normal defender intents show `???` until a Recon card reveals them for the fight. The boss's are always visible.

## Trace

Global 0–100%; reaching 100% ends the run at once.

| Threshold | Effect |
| --- | --- |
| 25% | +1 IDS Sensor in normal fights |
| 50% | One card type patched per fight, at half effect |
| 75% | +2 Trace per map move, +1 random extra defender in normal fights |

Other sources: EDR fizzle +2, Honeypot +20, Exfil +3 per turn. Safehouse rest is -15.

## Cards

| Card | Type | CPU | Noise | Effect | Upgrade |
| --- | --- | --- | --- | --- | --- |
| Port Scan | Recon | 1 | 1 | Reveal intents, draw 1, +1 Scan | Stealth Scan: 0 noise |
| OSINT | Recon | 1 | 0 | Draw 2, +1 Scan | Deep OSINT: 0 CPU |
| Packet Sniff | Recon | 0 | 1 | Reveal intents, +1 Scan | Passive Sniff: 0 noise |
| Default Password | Exploit | 1 | 1 | 6 damage | Credential Stuffing: 9 damage |
| SQL Injection | Exploit | 2 | 4 | 13 damage | Blind Injection: 18 damage |
| Buffer Overflow | Exploit | 3 | 7 | 24 damage | Return Chain: 4 noise |
| Phishing Email | Social | 1 | 1 | Human: 8 damage, Distract 1. Machine: 2 damage | Spear Phish: 12 to humans |
| Pretext Call | Social | 2 | 2 | Human skips next 2 actions | Trusted Voice: 1 CPU |
| Proxy Chain | Stealth | 1 | 0 | Next 3 cards make half noise | Onion Route: next 5 |
| Log Wipe | Stealth | 1 | 0 | -5 noise | Log Forge: -8 |
| Living off the Land | Stealth | 1 | 0 | 4 damage | Signed Binary: 7 damage |
| Backdoor | Persistence | 2 | 2 | Rest of run: +1 CPU on first turn of later fights | Hidden Backdoor: 1 CPU |
| Privilege Escalation | Escalation | 1 | 1 | Next damage card deals double | Kernel Escalation: 0 CPU |
| Token Theft | Escalation | 1 | 3 | +2 CPU; first card of a fight: +1 Credential | Session Hijack: 1 noise |
| Data Exfil | Payload | 2 | 3 | +15 Data; 20 Upload during Exfil | Slow Drip: +25 Data |

Ghost's starting deck: 4 Default Password, 2 Living off the Land, 2 Port Scan, 1 Log Wipe, 1 Proxy Chain.

## Defenders

| Defender | Integrity | Action | Rule |
| --- | --- | --- | --- |
| Firewall | 30 | +1 Noise | Blocks one card type each turn; blocked cards can't be played |
| Antivirus | 16 | +1 Noise | Quarantines your highest-noise card for the fight |
| IDS Sensor | 10 | +1 Noise | Your cards' Noise is doubled while it's alive |
| Sysadmin (human) | 20 | +2 Noise | Strips your buffs |
| EDR Agent | 18 | +1 Noise | Same card twice in a row fizzles: CPU spent, +2 Trace |

Honeypot is a map trap with no fight.

**Perimeter Firewall (boss):** 70 Integrity, +2 Noise, rule changes every 2 turns: Deny Exploit, Rate Limit (2 cards per turn), Deep Inspection (+1 Noise per card).

**Exfil:** No defenders. Fill a 40-point Upload bar; damage counts as upload. Trace +3 per turn. No retreat: the Noise cap adds +15 Trace and resets Noise. Full bar wins; Trace 100% loses.

## Map and economy

- 6 rows of 2–4 nodes, then boss, then Exfil. A path crosses exactly 6 nodes before the boss. Seed is shown and can be entered.
- Unknown nodes show `?`. Scans reveal type, defenders and loot. The run starts with 2 Scans; each Recon card banks 1.
- Movement is forward-only, apart from being kicked back.
- Firewalled edges open with a specific Exploit card in the deck or 1 Credential, and only ever close a spare edge.
- Data is the only currency. Fight win: choose 1 of 3 cards or skip, and gain Data.
- Shop: card 40, remove 50, Credential 30.
- Safehouse: Trace -15 or upgrade one card.
- Events: 3 short choice events.

## Presentation

Neon terminal noir, drawn in code, with JetBrains Mono (OFL). Green is you, red is defenders, amber is humans. Shaders: CRT (toggleable), glitch scaled to Trace, red flash and shake at thresholds, fog on unknown nodes. Packets flow along live map edges. Menu and encounter backdrops are parallax layers. Audio is synthesized: a drone gains layers with Trace, plus click, chirp and alarm effects.

## Responsible design

Real technique names with abstract effects; no commands, payloads or real vulnerabilities. The fictional target is invented. The Codex pairs each technique with how it's detected or prevented, and Blue team notes after each run list the defenses that would have stopped the cards the player used.
