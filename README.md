# Triomino Desktop

An early desktop prototype of the triangular tile game, built with Godot 4.

## Current playable slice

- Host or join a two-to-four-player lobby with a shareable `TRI-...` code.
- Every player chooses a display name before joining.
- Play proceeds in synchronized turns on one shared board.
- The complete 56-piece set is shuffled once per round, then each player is
  dealt the next tiles in sequence: 9 each for two players, or 7 each for three
  or four players. No physical tile is repeated between players.
- Using a tile removes only that player's copy from their tray.
- On their turn, a player can draw one synchronized piece from the host's well
  and then continue their turn.
- The host validates placements and keeps the board, used pieces, turns, and scores in sync.
- The deal is drawn from the complete 56-piece set using every unique combination from 0 through 5.
- Three-distinct-number tiles use the official clockwise ascending order; mirrored tiles are excluded.
- All tray pieces already show their three numbers.
- Select any available piece from the tray.
- Rotate the selected piece clockwise with the **Rotate piece** button or the **R** key.
- The first piece is always placed at the exact center of the board.
- Further pieces snap edge-to-edge onto open edges.
- Both numbers on a shared edge must match.
- Any additional corner that touches another corner must show the same number.
- Green edges accept the selected rotation; red edges reject it.
- Each player has a synchronized score, and the sidebar shows the current turn.
- For win-flow testing, an accepted placement that takes a player's score over
  10 currently declares that player the winner and opens a synchronized window.
- Lobby player rows track wins until that player leaves the current lobby.
- Scoring includes tile values, bridges, and single/double/triple hexagon bonuses.
- The base tile-value formula remains a user-editable hook.
- Reset starts a fresh board and returns every piece to the tray.

## Scoring

Every legal move earns the sum of its three numbers. Special shapes then add:

- Bridge: **+40** points.
- One completed hexagon: **+50** points.
- Two hexagons completed by one tile: **+60** points.
- Three hexagons completed by one tile: **+70** points.

The board detects these from the corners surrounding the new tile before the
host commits the move. A hexagon completion does not also receive a bridge bonus.

To customize the base value, edit `tile_value()` in `scripts/scoring.gd`. It
receives the three numbers from the piece being placed:

```gdscript
func tile_value(piece_numbers: Array[int]) -> int:
	var points := 0
	for number in piece_numbers:
		points += number
	return points
```

The returned number becomes the tile-value part of the scoring breakdown; shape
bonuses are added automatically by `placement_score()`.

## Temporary win-flow test

The host-authoritative `declare_winner(peer_id)` function in `scripts/main.gd`
increments the winner's lobby win count, synchronizes it to every player, ends
the round, and opens a winner window. Each player then chooses **Continue to
lobby**. It is temporarily called after every accepted placement so the whole
win flow is easy to test. It is currently called when the player's round score
becomes greater than 10. Starting another round preserves the lobby totals;
leaving the lobby clears them.

## Project structure

```text
triomino/
|-- assets/        # Future artwork, audio, and fonts
|-- scenes/        # Godot scene files
|-- scripts/       # Small game, board, network, and UI modules
|-- tests/         # Automated rule, UI, and multiplayer checks
|-- GAME_ARCHITECTURE.md # File responsibilities and change guide
|-- project.godot  # Godot project settings
`-- README.md
```

See [`GAME_ARCHITECTURE.md`](GAME_ARCHITECTURE.md) for a beginner-friendly map
of the refactored code and where future features should be added.

## Run locally

Open `project.godot` in Godot 4.7 and press **F6/F5**, or run this from a terminal if Godot is on your `PATH`:

```powershell
godot --path .
```

## Test multiplayer on one computer

1. Run two copies of the game. In the Godot editor, use **Run Multiple Instances**
   or start the project twice from separate terminals.
2. In the first copy, enter a display name, click **Use localhost**, then
   **Host lobby**.
3. Copy the generated lobby code.
4. In the second copy, enter a different display name, paste the code, and click
   **Join lobby**.
5. In the host window, click **Start game**. Turns, placements, used tiles, and
   scores should now update in both windows.

## Play over a network

Lobby codes contain the host address and UDP port `28745`; they do not use a
central relay server.

- On the same Wi-Fi/LAN, the automatically detected local IPv4 address should
  normally work. Allow the game through the host computer's firewall if asked.
- Over the internet, the host must enter their public IPv4 address before
  creating the lobby and forward **UDP port 28745** from the router to the host
  computer. Some carrier-grade NAT connections cannot accept forwarded ports.
- A future hosted relay/matchmaking service would remove the port-forwarding
  requirement and make codes work from almost any network.

## Automated checks

The `tests/` directory includes unit checks for lobby codes and existing game
rules, plus a two-process smoke test that verifies hosting, joining, display-name
sync, round start, moves in both directions, turn changes, and scores.
