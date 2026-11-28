# The maps

These are the maps you draw in TrenchBroom, and the ones the converter reads.

| File | What it is |
| --- | --- |
| `P1_02.map` | The starter map for section `P1.02`, made by the template writer |

A map is a text file, so it can be read in a diff, and it is the **base** of
a section: the floor, the walls, the platforms, the slopes and the points. The
textures are not in here. They are made in Godot.

`tools/trenchbroom/README.md` has the names the converter reads, the units,
and the commands. `docs/AUTHORING.md` has the four steps.

To make a starter map for another section:

```bash
godot --headless --path . --script res://tools/trenchbroom/import_map.gd -- \
    --template P1.03 --out maps/P1_03.map
```

A map that is already there is never written over.
