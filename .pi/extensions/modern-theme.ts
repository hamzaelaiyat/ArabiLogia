/**
 * Modern Theme Extension
 *
 * Transfers the current theme to "modern" — a clean, modern dark theme.
 *
 * Usage:
 *   /modern         - Switch to the modern theme
 *   /modern on      - Enable auto-switch (on by default)
 *   /modern off     - Disable auto-switch
 *
 * Install in .pi/extensions/ for project-local auto-discovery.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const MODERN_THEME_NAME = "modern";

/**
 * Ensure the modern theme file is available in the global themes dir
 * so it's discoverable even when switching projects.
 */
async function ensureGlobalTheme(): Promise<void> {
	const globalDir = join(homedir(), ".pi", "agent", "themes");
	const globalDest = join(globalDir, "modern.json");

	try {
		await readFile(globalDest);
		return; // already exists
	} catch {
		// Copy the theme from the local project location
		const localThemePath = join(process.cwd(), ".pi", "themes", "modern.json");
		try {
			const content = await readFile(localThemePath, "utf-8");
			await mkdir(globalDir, { recursive: true });
			await writeFile(globalDest, content, "utf-8");
		} catch {
			// If we can't copy, the theme might still be loaded via project discovery
		}
	}
}

export default function (pi: ExtensionAPI) {
	let autoSwitch = true;

	pi.registerCommand("modern", {
		description: "Switch to the modern theme. Usage: /modern [on|off]",
		handler: async (args, ctx) => {
			const arg = args?.trim().toLowerCase();

			if (arg === "off") {
				autoSwitch = false;
				ctx.ui.notify("🛑 Auto-switch to modern theme disabled", "info");
				return;
			}

			if (arg === "on") {
				autoSwitch = true;
				ctx.ui.notify("✅ Auto-switch to modern theme enabled", "info");
			}

			ctx.ui.setTheme(MODERN_THEME_NAME);
			ctx.ui.notify("🎨 Switched to modern theme!", "info");
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		// Ensure the modern theme file exists globally for discovery
		await ensureGlobalTheme();

		if (autoSwitch) {
			ctx.ui.setTheme(MODERN_THEME_NAME);
		}
	});
}
