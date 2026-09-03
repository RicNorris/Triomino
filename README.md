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
- On their turn, a player can draw up to three synchronized pieces from the
  host's well. After the third draw, the host automatically passes the turn
  only when none of that player's unused pieces fits the board in any rotation,
  applying the full 25-point unsuccessful-draw penalty.
- The host validates placements and keeps the board, used pieces, turns, and scores in sync.
- The deal is drawn from the complete 56-piece set using every unique combination from 0 through 5.
- Three-distinct-number tiles use the official clockwise ascending order; mirrored tiles are excluded.
- All tray pieces already show their three numbers.
- The board remains the dominant play surface while every tile in the local
  hand stays visible in one responsive, non-scrolling rack.
- Accepted draws, placements, score changes, automatic passes, and turn changes
  use synchronized cartoon-style visual feedback on every peer.
- Select any available piece from the tray.
- Rotate the selected piece clockwise with the **Rotate piece** button or the **R** key.
- The first piece is always placed at the exact center of the board.
- Further pieces snap edge-to-edge onto open edges.
- Both numbers on a shared edge must match.
- Any additional corner that touches another corner must show the same number.
- Green edges accept the selected rotation; red edges reject it.
- Each player has a synchronized score, and the sidebar shows the current turn.
- Lobby player rows track wins until that player leaves the current lobby.
- Scoring includes tile values, bridges, and single/double/triple hexagon bonuses.
- The base tile-value formula remains a user-editable hook.
- Reset starts a fresh board and returns every piece to the tray.


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
