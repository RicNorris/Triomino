# Triomino Desktop

An early desktop prototype of the triangular tile game, built with Godot 4.

## Current playable slice

- The tray contains the complete 56-piece set using every unique combination from 0 through 5.
- Three-distinct-number tiles use the official clockwise ascending order; mirrored tiles are excluded.
- All tray pieces already show their three numbers.
- Select any available piece from the tray.
- Rotate the selected piece clockwise with the **Rotate piece** button or the **R** key.
- The first piece is always placed at the exact center of the board.
- Further pieces snap edge-to-edge onto open edges.
- Both numbers on a shared edge must match.
- Any additional corner that touches another corner must show the same number.
- Green edges accept the selected rotation; red edges reject it.
- Scoring rules are intentionally not enforced yet.
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
