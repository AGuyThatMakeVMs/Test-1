# RoundSystem Advanced

A Roblox round / map rotation system based on the supplied RoundSystem model.

## Files
- `RoundSystem_Advanced.rbxmx`: complete model, preserving the original GUI and adding Advanced settings.
- `main.lua`: server Script source for the RoundSystem.
- `RoundGuiScript.lua`: client LocalScript source used by the existing RoundGui.
- `README.md`: setup notes.

## Install
1. Import `RoundSystem_Advanced.rbxmx` into Roblox Studio / a compatible Studio mobile editor that supports RBXMX model import.
2. Keep the `RoundSystem` model in Workspace.
3. Put each map Model inside `RoundSystem > Maps`.
4. Add anchored BaseParts named exactly `SpawnPoint` inside each map.
5. Test with Play before publishing.

## Advanced settings
Edit values under `RoundSystem > Advanced`:
- `RandomizeSpawns`: shuffle spawn-point order.
- `AvoidRepeatingMaps`: avoid selecting the previous map when possible.
- `AutoCreateDemoMaps`: create two sample maps when Maps is empty.
- `SpawnHeightOffset`: vertical offset above each spawn point (clamped to 1–20).
- `ReturnPlayersToLobby`: reload players after a round.

## Tips
The original GUI layout is unchanged. The bottom bar keeps rotating tips, with additional messages. Edit `TIPS` and `TIP_INTERVAL` in `RoundGuiScript.lua` to customize them.

## Important
The `.lua` files are source code, not a one-line executor. The server script belongs in a normal server-side Script and the GUI script belongs in a LocalScript under the ScreenGui. Roblox game scripts should be installed through Studio/editor, not executed as an arbitrary client-side loadstring.
