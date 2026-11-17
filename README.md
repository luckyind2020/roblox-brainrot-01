# roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/luckyind2020/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/luckyind2020/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bandits — a 3D Roblox brainrot game. Absurd meme characters walk a conveyor belt, each earning money every second: buy them, keep them on your base, climb a ladder of rarities and mutations, steal from rivals while their base is unlocked, and dash home when the tsunami sweeps the map. Rebirths and upgrades keep the climb going.

## The game

- **The belt**: a new brainrot steps on every 4 seconds and walks west to east. Click one to buy it if you can afford it.
- **The cast**: 12 original characters across 6 rarities (Common to Brainrot God), from Noodle Ned ($5/s) to The Almighty Soggy Cereal ($25,000/s), with Golden, Frozen, Lava and Rainbow mutations multiplying income up to 10x.
- **Your base**: 8 plots with 8 slots each. Bought brainrots stand on slots and earn every second.
- **Stealing**: click a brainrot on a rival base to carry it home — slower while you carry, droppable by a slap (F), and blocked while their base is locked.
- **The tsunami**: every 3 minutes a wave sweeps the map. Caught outside your base, you are thrown back to the plaza and drop what you carry.
- **Progression**: rebirth at $100k earned for +25% income, stacking; shop upgrades for speed, slap and extra slots.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output directory and writes `dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.

## Layout

- `src/shared/` — `Config.luau` (every tuning number) and `BrainrotData.luau` (the cast, rarities, mutations)
- `src/server/` — `GameServer.server.luau` (boot, remotes), `World.luau` (bases, sign, wave wall), `Spawning.luau` (the conveyor), `Economy.luau` (money, income, rebirth, upgrades), `Stealing.luau` (carry, slap, lock), `Waves.luau` (the tsunami)
- `src/client/` — `Hud.client.luau` (cash, income, wave timer, shop, slap/drop)
- `default.project.json` — the Rojo project: the 3D world (ground, belt, spawn, trees, lamps, walls) and the service layout
- `TOUR.json` — the optional tour of the three planned screenshots

## Status: publish pending

The game code and the place are built, and the entrypoint runs end to end. What is left needs the Roblox account owner, in Roblox Studio on Windows or macOS:

1. Publish this place from Studio as a Public experience (account must be 2+ days old and past its age check).
2. Put the account's make.fun play code in the experience description and fill in `PLAY.json` with the real place id and universe id.
3. Replace the three placeholder captures in `screenshots/` (the kit starter's grey-square game, there only so `main.ts` runs) with 3 real captures of this game running in Studio (first by name is the thumbnail), and upload the icon and that thumbnail on the Creator Dashboard, waiting until the experience page shows both.

Until then `PLAY.json` names no place and the screenshots are placeholders, so the entry cannot be submitted yet.

---

<sub>Entered on [make.fun](https://make.fun/?ref=4ha9jy2z&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
