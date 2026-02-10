# Gemini Context — Blueth

## Project Summary
Blueth is a simple roguelike RPG MVP for itch.io.
- Engine: Godot 4.6, GDScript
- Art style: Low-poly 3D environments + 2D SVG characters/UI
- Target: 60 FPS, 1280x720, desktop (Windows/Linux/Mac)
- Scope: 3 dungeon levels, 1 player class, 3-4 enemies per level, 1-2 combat mechanics, 1 complete storyline, permadeath

## Token Saving Rules
1. Only include files relevant to the current task in context
2. Use structured state summaries, not full chat logs
3. Cache generated boilerplate in .agent/cache/
4. Batch related file edits into single operations
5. Max 4096 tokens per response unless overridden
6. Exclude from context: *.import, *.png, *.wav, .godot/*, addons/gut/*
