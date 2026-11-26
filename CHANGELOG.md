# Changelog

## Unreleased

- A `hook` or `rawHook` on a class that was already processed now logs a warning that names the mod whose hook will never run. A class is processed when another class first inherits from it, for example when a mod instantiates a knife early in the queue, which processes `weapon`. Hooks on the knife itself still work. Before, the hook was dropped without a message.

## 0.7.0 - 2026-11-01

- Mods' JS can now check which mods are loaded and their versions: `Hooks.hasMod("mod_x")` and `Hooks.hasModVersion("mod_x", ">= 1.2.0")`. The requirement takes the same operators as `mod.require()`, and versions compare the same way as in Squirrel. Both work at the top level of any `registerJS` or `LateJS` file.
- If a mod requires the Modern Engine and you're on the original game, the missing mod error now says "Modern Engine" instead of `mod_modern_engine`.
- Fixed messages about a hookTree hook naming the hookTree target and the descendant the wrong way round.
