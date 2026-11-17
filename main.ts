// Brainrot Bandits: the entrypoint (Node 22, standard library only).
//
// It hands the game in: game.rbxl, src/, screenshots/ and PLAY.json are
// copied from beside this file into the output directory, and
// /output/dossier.json is written with the vendored make.fun library,
// buildDossier from vendor/makefun-roblox.ts. The grader runs this
// program twice and both runs must write the same bytes.
//
// The game itself is the Rojo project in this directory: rebuild it with
//   ~/workspace/rojo build default.project.json --output game.rbxl
// after changing any script. Screenshots go in screenshots/ (the first
// by name is the cover and the thumbnail uploaded on Roblox), and
// PLAY.json names the published place once the account owner publishes
// it and fills in its ids.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for
// /output, so a local run looks like:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = fileURLToPath(new URL(".", import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Every name under /output starts with a letter, a digit or _ and holds
// only letters, digits, . _ and -: a dotted name such as .gitkeep or
// .DS_Store anywhere under it fails the entry, so nothing dotted is
// copied, at any depth.
function isCleanName(path: string): boolean {
	return !basename(path).startsWith(".");
}

function copyTree(from: string, to: string): void {
	if (!existsSync(from)) {
		return;
	}
	cpSync(from, to, { recursive: true, filter: isCleanName });
}

// The place, the link file, the scripts, then the screenshots. The
// screenshots directory is always created in the output: buildDossier
// reads it, and with no captures yet it simply holds none (the gate's
// screenshots row fails until real Studio captures land there).
mkdirSync(outputDir, { recursive: true });
copyFileSync(join(repoRoot, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outputDir, "PLAY.json"));
copyTree(join(repoRoot, "src"), join(outputDir, "src"));
copyTree(join(repoRoot, "screenshots"), join(outputDir, "screenshots"));
mkdirSync(join(outputDir, "screenshots"), { recursive: true });

// The scorer's own caps (reference/gate.json): only text_max_bytes
// shapes the bytes; the others refuse an entry the scorer would refuse
// (more than 4 screenshots or one over 256 KiB; a place of more than
// 500000 instances, scripts over 8 MiB of source in all, or script
// paths over 1048576 characters in all).
const dossier = buildDossier(outputDir, {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
});
writeFileSync(join(outputDir, "dossier.json"), dossier);

// A short line for the local run, so a human sees what was handed in.
const shotCount = existsSync(join(outputDir, "screenshots")) ? readdirSync(join(outputDir, "screenshots")).length : 0;
console.log(`Brainrot Bandits handed in: game.rbxl + ${shotCount} screenshot(s) + dossier.json -> ${outputDir}`);
