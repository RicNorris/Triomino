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
- A score counter is visible and resets with the board.
- The scoring formula is intentionally left as a user-editable hook.
- Reset starts a fresh board and returns every piece to the tray.

## Adding the scoring formula

Edit `calculate_placed_piece_score()` in `scripts/main.gd`. It receives the three
numbers from the piece that was just placed. Return the number of points earned:

```gdscript
func calculate_placed_piece_score(piece_numbers: Array[int]) -> int:
	# Replace this example with your own rules.
	return piece_numbers[0] + piece_numbers[1] + piece_numbers[2]
```

The returned number is automatically added to the visible score counter. For
bonuses based on the board shape, inspect `board.placed_pieces`; it already
contains the newly placed piece. You can also call `add_score(points)` directly
when another game event should change the counter.

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
