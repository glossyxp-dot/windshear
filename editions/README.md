<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Community Editions

An Edition changes the story and keeps the world. Same city, same movement, same
section grid, different things happening in it.

Editions are data packages. They are not plugins, not private code, and not
something the player has to activate. There are no accounts, no DRM and no
network requirement anywhere in this game, and there won't be.

## What a package looks like

```text
my-edition/
  edition.json
  story/
    endings.json
    dialogue/
      en.json
    beats/
      13.03.beat.json
  assets/
```

`story/` is optional. Where a file exists it overrides the official file of the
same relative path, as described in `data/story/README.md`. `assets/` is
optional too, for replacement art. Changing world geometry or mechanics means
changing source, not writing an Edition.

## `edition.json`

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Stable identifier. Pick one and keep it |
| `name` | string | What the Edition browser shows |
| `author` | string | A person or a collective |
| `story_path` | string | Relative path to the story root. `story` is the normal answer |
| `description` | string | One or two sentences, plain text |
| `license` | string | SPDX identifier for the Edition's own work |
| `source_url` | string | Where the corresponding source lives |

A complete data-only example:

```json
{
  "_meta": {
    "spdx": "CC-BY-SA-4.0",
    "spdx_file_copyright_text": "2026 The Afterlight Collective"
  },
  "id": "afterlight",
  "name": "Afterlight",
  "author": "The Afterlight Collective",
  "story_path": "story",
  "description": "A data-only Edition following the Quiet Line crew after the city loses its schedule.",
  "license": "CC-BY-SA-4.0",
  "source_url": "https://github.com/afterlight-collective/windshear-afterlight"
}
```

JSON has no comment syntax, so the SPDX line goes in a top-level `_meta` object
next to the payload. Every JSON file in this repository does it that way. The
`_meta` block in `edition.json` is optional and isn't one of the manifest's
required fields.

## Open source, and what the index will refuse

Every Edition has to be open source. Code inherits `GPL-2.0-or-later` from the
game. A data-only Edition that reuses official story or art inherits
`CC-BY-SA-4.0` and stays share-alike.

The official index won't list an Edition when:

- the licence is missing, closed, proprietary, or incompatible with whatever
  content it reuses;
- `source_url` is missing or doesn't point at the corresponding source.

That's the whole list. It's worth being clear about what the index is, though:
a distribution list, not a lock. An Edition somebody has installed locally
always loads, and being turned down by the index never stops anyone from
running it. There's no activation step to bypass, because there isn't one.
