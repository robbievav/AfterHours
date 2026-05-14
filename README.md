# After Hours 🌙

> *A neon-lit Roblox high school reclaimed by students. No classes. No teachers. Just vibes.*

A social sandbox game built with Luau and [Rojo](https://rojo.space/). Players explore distinct Vibe Zones, collaborate on the DJ Booth, tag the Graffiti Wall, tune their Boombox, and uncover the midnight mystery of **The Overlap**.

---

## 🗂️ Project Structure

```
After Hours/
├── default.project.json        ← Rojo sync config
└── src/
    ├── shared/
    │   ├── ZoneConfig.lua      ← Zone lighting/music/reverb data (SSoT)
    │   └── MidnightConfig.lua  ← Midnight event timing + lore config
    ├── server/
    │   ├── ZoneManager.server.lua      ← Zone detection → fires ZoneChanged
    │   ├── MidnightManager.server.lua  ← Game clock + Overlap trigger
    │   ├── GraffitiManager.server.lua  ← Validates + syncs graffiti strokes
    │   ├── DJBoothManager.server.lua   ← DJ slot claiming + music layers
    │   └── BoomboxManager.server.lua   ← Frequency grouping + member sync
    └── client/
        ├── ZoneClient.client.lua       ← A/B crossfade music + lighting tweens
        ├── MidnightClient.client.lua   ← Sepia overlay + Atmosphere tweens
        ├── GraffitiClient.client.lua   ← Canvas SurfaceGui + stroke rendering
        ├── DJBoothClient.client.lua    ← DJ Booth UI + audio mixer
        └── BoomboxClient.client.lua    ← Frequency selector UI + audio sync
```

---

## 🟣 The Vibe Zones

| Zone | Location | Vibe |
|---|---|---|
| **The Pulse** | Gymnasium | Neon dance hall — strobing UV, heavy bass |
| **The Grind** | Cafeteria | Lo-fi café — warm amber, soft rain sounds |
| **The Archive** | Library | Eerie & liminal — glowing books, phantom sounds |
| **The Observatory** | Rooftop | Expansive — star field, city glow below |
| **The Overlap** | Boiler Room *(midnight only)* | Ghost zone — sepia, locker maze, payphone lore |

---

## 🤝 Interaction Props

- **Shared DJ Booth** — Up to 4 players each control one audio layer. Collab indicator lights up when 2+ players are at the booth.
- **Graffiti Wall** — SurfaceGui canvas with 7 neon colors + 6 brush sizes. Strokes persist across the session and show the tagger's name.
- **Boombox Relay** — 5 frequencies (1–5). Players on the same frequency share a music track. A particle wave signals your location.

---

## 🕛 The Midnight Overlap

At midnight (in-game clock), the school "overlaps" with a ghostly version from a decade ago:

- Sepia + haze ColorCorrectionEffect fades in over 8 seconds
- Translucent **Echo Student** NPCs appear at tagged anchor points
- The **Boiler Room** door unlocks (invisible + non-collidable)
- The **Payphone** inside the Boiler Room rings with a random lore fragment
- After 5 minutes, everything reverts

---

## ⚙️ Setup

### Prerequisites
- [Rojo](https://rojo.space/) (v7+)
- [Roblox Studio](https://www.roblox.com/create)

### Getting Started

```bash
# Clone the repo
git clone https://github.com/<your-username>/AfterHours.git
cd AfterHours

# Start the Rojo server
rojo serve default.project.json
```

Then in Roblox Studio, connect via the Rojo plugin.

### Adding a New Zone

1. Add an entry to `src/shared/ZoneConfig.lua`
2. Place a Part in Studio named to match the config key
3. Tag the Part with `ZoneTrigger` via CollectionService
4. Done — no other code changes required

---

## 🎵 Asset IDs

Music asset IDs in `ZoneConfig.lua` and `MidnightConfig.lua` are placeholders. Replace them with your own Roblox audio asset IDs before publishing.

---

*Built with ❤️ using Luau + Rojo*
