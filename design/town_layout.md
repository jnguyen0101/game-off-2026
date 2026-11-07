# Town layout

The 960x768 exterior follows the reference's arrangement: northwest home,
central market and fountain, western inn, eastern guild, northern palace
complex, southern approach, residential side streets, and a river on the west.
The town has no enclosing stone walls. Streets bend between offset buildings;
the market has an uneven outline and staggered stalls, with irregular woodland
clusters around the perimeter.

Open `scenes/levels/town.tscn` to edit it. Grass, River, and Paths are paintable
TileMapLayers. Buildings, stalls, and trees are under the
Y-sorted World node, with physical collision. The player camera is limited to
the map bounds. HomeEntrance and HomeSpawn remain children of PlayerHouse.

Home is the only connected interior. The guild, inn, palace, and gate currently
offer sign dialogue; the palace uses the pack's stone buildings as a placeholder
complex. The town does not yet have residents, shops, or quest progression.

`tools/build_town_layout.py` authored the initial static scene and the software
overview in `design/town_layout_overview.png`. Its overview omits text and UI.
Running the authoring script regenerates the layout, so normal map editing
should happen in Godot rather than rerunning it after manual changes.

Validation: `tests/town_layout_test.gd` checks collision-based connectivity to
major landmarks. `tests/town_transition_test.gd` checks the home entrance,
resume progress, and return spawn/facing across scene changes.
