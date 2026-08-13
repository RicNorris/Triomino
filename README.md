# Triomino Desktop

An early desktop prototype of the triangular tile game, built with Godot 4.

## Current playable slice

- All tray pieces already show their three numbers.
- Select any available piece from the tray.
- The first piece is always placed at the exact center of the board.
- Further pieces snap edge-to-edge onto any highlighted open edge.
- Number-matching and scoring rules are intentionally not enforced yet.
- Reset starts a fresh board and returns every piece to the tray.

## Project structure

```text
triomino/
|-- assets/        # Future artwork, audio, and fonts
|-- scenes/        # Godot scene files
|-- scripts/       # Gameplay and UI scripts
|-- tests/         # Future automated tests
|-- project.godot  # Godot project settings
`-- README.md
```

## Run locally

Open `project.godot` in Godot 4.7 and press **F6/F5**, or run this from a terminal if Godot is on your `PATH`:

```powershell
godot --path .
```
