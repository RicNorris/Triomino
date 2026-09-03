# Triomino game architecture

This guide explains where each kind of game logic belongs after the refactor.
The main idea is that `main.gd` coordinates the game, while smaller files each
own one clear responsibility.

## The short version

```text
Player input / UI
	   |
	   v
	main.gd  <---->  multiplayer_session.gd
	   |
	   +----> game_state.gd
	   +----> round_dealer.gd
	   +----> scoring.gd
	   +----> piece_catalog.gd
	   |
	   v
	board.gd  <---->  triomino_piece.gd
```

`main.gd` is still the entry point, but it should mostly answer questions such
as “what should happen next?” It should not contain the detailed algorithm for
shuffling, scoring, validating a rotation, storing all player state, or sending
RPCs.

## Files and responsibilities

### `scripts/main.gd` — game coordinator and screen logic

This script connects the UI, board, state, rules, dealer, and network session.
It handles flows that cross multiple systems, for example:

1. The host clicks **Start game**.
2. `main.gd` asks the dealer to create trays.
3. `main.gd` asks the network session to broadcast the new round.
4. Every copy applies that round to its game state.
5. `main.gd` refreshes the board and visible tray.

UI-only behavior also stays here: changing labels, showing the winner window,
selecting a tray tile, and enabling or disabling buttons.

When adding code, put it in `main.gd` only if it coordinates two or more of the
specialized systems or directly updates this scene's UI.

### `scripts/game_state.gd` — current lobby and round data

`TriominoGameState` is the source of truth for changing session data:

- players and their display names;
- player order and current turn index;
- scores and lobby-only win counts;
- the piece IDs assigned to each player's tray;
- which tray pieces each player has consumed;
- the synchronized number of pieces remaining in the host's well;
- whether a lobby session and round are active.

It contains small state operations such as `begin_round()`, `apply_placement()`,
`remove_player()`, and `current_player_id()`.

It does not draw UI, calculate scores, inspect board geometry, or send network
messages. Access it from `main.gd` through `state`, for example:

```gdscript
if state.has_tray_piece(peer_id, piece_id):
	state.mark_piece_used(peer_id, piece_id)
```

### `scripts/round_dealer.gd` — trays and the well

`TriominoRoundDealer` owns round setup:

- choosing 9 pieces per player for a two-player game or 7 otherwise;
- shuffling the 56 physical piece IDs once;
- dealing consecutive, non-overlapping sections to the players;
- keeping all undealt IDs in `piece_well`.

Use `dealer.rng_seed` in a test when you need a repeatable deal. Leave it at
`-1` during normal play for a randomized deal.

The well exists only on the host, because the host performs the deal. A player
can request a draw, but only the host removes a piece and broadcasts its ID.

### `scripts/scoring.gd` — score calculations

`TriominoScoring` contains no scene or network code. Its two public methods are:

- `tile_value(numbers)`: adds the three tile numbers;
- `placement_score(numbers, board_features)`: adds bridge or hexagon bonuses
  and returns the full score breakdown.

This makes scoring easy to test without starting a lobby. If you change the
base scoring formula later, change `tile_value()` here.

### `scripts/piece_catalog.gd` — the 56 legal pieces

`TriominoPieceCatalog` generates the complete unique set, converts values into
typed number arrays, and checks whether submitted numbers are a valid rotation
of a particular physical tile.

This file describes which pieces can exist. It does not decide who owns them;
that belongs to the dealer and game state.

### `scripts/multiplayer_session.gd` — transport and RPCs

`TriominoMultiplayerSession` owns ENet setup and every `@rpc` function. It turns
network messages into local signals such as:

- `register_player_requested`;
- `round_started_received`;
- `play_requested`;
- `placement_received`;
- `winner_received`.

It transports data but does not decide whether a move is legal or mutate the
game state. The host's `main.gd` receives a play request, validates it using the
state/catalog/board, calculates its score, and only then broadcasts the result.

Keep the `MultiplayerSession` node at the same scene path on every peer. Godot
RPCs address nodes by path, so moving or renaming it requires the same scene
change for host and clients.

### `scripts/board.gd` — board geometry and placement rules

The board owns spatial questions:

- where pieces are placed;
- which open edges can accept a tile;
- whether shared edge and touching-corner values match;
- whether a placement forms a bridge or one or more hexagons.

It reports placement features to the scoring module. It does not own a player's
score or tray.

### `scripts/triomino_piece.gd` — one visual tile

This script draws one triangular piece and manages its own visual state,
numbers, rotation, selection, and availability. A piece node does not decide
whether it belongs to a player; `main.gd` reads the assignment from `state` and
shows or hides the node.

### `scripts/game_hud.gd` — runtime HUD composition

The main game HUD is built in code rather than stored in `main.tscn`. It keeps
the board as the dominant surface, sizes every local tray tile to fit in one
non-scrolling row, and returns references to the compact action dock, event
banner, and presentation-effects layer.

`main.gd` drives presentation from accepted network events. Draw flights,
placement drops, score punches, automatic-pass notices, and turn pulses never
decide or delay game state; they only visualize state that has already been
accepted.

### `scripts/lobby_code.gd` — lobby-code encoding

This utility converts an IPv4 address and UDP port into the shareable `TRI-...`
code and decodes it again. It does not connect to the server itself.

## Who is authoritative?

The host is authoritative for game-changing actions. A client asks to place a
piece, but it does not directly update everyone's board.

```text
Client clicks board
  -> network sends play request to host
  -> host validates turn, tray, rotation, and board position
  -> host calculates score and next turn
  -> host broadcasts the accepted placement
  -> every peer updates state, board, tray, and UI
```

This is important because trusting a client to announce its own score or legal
move would let different copies of the game disagree.

## Round and lobby lifetime

Lobby wins live in `state.player_wins`. Starting a new round resets round scores
and trays but preserves those wins. Leaving the lobby calls `state.clear()`, so
the lobby-only win counts are removed as requested.

The current win condition is deliberately temporary: after an accepted move,
the host calls `declare_winner()` when that player's total score is greater than
10. `declare_winner()` increments the lobby total and broadcasts the winner.

## How draw-from-well works

The draw flow follows this route:

1. `main.gd` receives `DrawFromWellButton.pressed`.
2. `multiplayer_session.gd` sends a client-to-host draw request.
3. The host's `main.gd` validates that it is the player's turn and that the
   well is not empty.
4. `round_dealer.gd` removes and returns one piece ID from
   `piece_well`.
5. The host broadcasts the accepted draw through `multiplayer_session.gd`.
6. Every peer uses `game_state.gd` to append that ID to the correct tray.
7. The requesting player's copy reveals the newly drawn tile in its tray UI.
8. After a third draw, the host checks every unused tray piece in all three
   rotations. If none fits an open board position, it broadcasts an automatic
   turn pass together with the updated scores and 25-point draw penalty.

Do not let each client draw independently from its own random well. Only the
host should remove the piece, then tell every client what was drawn.

Drawing keeps the same player's turn while fewer than three pieces have been
drawn, or when a legal move exists after the third draw. The host also
broadcasts the remaining well count, allowing every peer to disable its draw
button when that count reaches zero.

## A practical rule for future code

Ask what the new code is responsible for:

- Persistent player/round data? Put it in `game_state.gd`.
- Dealing or well contents? Put it in `round_dealer.gd`.
- Point calculation? Put it in `scoring.gd`.
- Legal piece definitions or rotations? Put it in `piece_catalog.gd`.
- Network transport or an RPC? Put it in `multiplayer_session.gd`.
- Board position or shape detection? Put it in `board.gd`.
- One tile's visuals? Put it in `triomino_piece.gd`.
- Connecting those systems or updating this screen? Put it in `main.gd`.

That separation keeps individual functions small and lets tests exercise rules
without having to simulate the complete game screen.

## Tests

The `tests/` folder mirrors these boundaries:

- `test_complete_piece_set.gd` checks the catalog;
- `test_player_trays.gd` checks the dealer, well, state, and local tray view;
- `test_scoring_patterns.gd` checks board features plus scoring;
- `test_placement_rules.gd` checks board legality;
- `test_win_ui.gd` checks winner state and UI;
- `test_multiplayer_host.gd` and `test_multiplayer_client.gd` run together and
  check the full network flow.
