# Changelog

## Unreleased

- Fixed several `__native` wrappers on the same function running in the reverse order. The last-registered wrapper now runs first, as with every other hook. `__native` wrappers now layer exactly like `__original` wrappers.
- Fixed `__native` wrappers in `hookTree` hooks being silently ignored. They now apply to the hookTree target and its descendants, on top of the class's normal `__native` wrappers, the same way `__original` wrappers do. Each instance gets each tree wrapper once.

## 0.7.0 - 2026-11-01

- Mods' JS can now check which mods are loaded and their versions: `Hooks.hasMod("mod_x")` and `Hooks.hasModVersion("mod_x", ">= 1.2.0")`. The requirement takes the same operators as `mod.require()`, and versions compare the same way as in Squirrel. Both work at the top level of any `registerJS` or `LateJS` file.
- If a mod requires the Modern Engine and you're on the original game, the missing mod error now says "Modern Engine" instead of `mod_modern_engine`.
- Fixed messages about a hookTree hook naming the hookTree target and the descendant the wrong way round.
