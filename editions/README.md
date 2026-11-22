<!--
SPDX-FileCopyrightText: 2026 the WINDSHEAR contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Community Editions

An Edition changes the story while reusing WindShear's shared world, movement system, and section format. Editions are data packages, not private plugins. The game has no accounts, activation, DRM, or required network connection.

## Package layout

```text
my-edition/
  edition.json
  story/
    endings.json
    dialogue/
      en.json
    beats/
      4.03.beat.json
  assets/
```

`story/` is optional. When present, its files override the corresponding official story files as described in `data/story/README.md`. `assets/` is optional and may contain replacement art, the directory is optional. Replacing world geometry or mechanics requires source changes rather than an Edition data override.

## `edition.json`

The manifest has these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Stable Edition identifier. |
| `name` | string | Name shown in the Edition browser. |
| `author` | string | Author or responsible collective. |
| `story_path` | string | Relative path to the Edition's story root. Use `story` for the standard layout. |
| `description` | string | Short plain-text summary of the Edition. |
| `license` | string | SPDX license for the Edition's source and data. |
| `source_url` | string | URL for the corresponding public source. |

A complete data-only example is:

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

JSON cannot carry an SPDX comment header. Repository JSON files therefore place the SPDX identifier in a top-level `_meta` key beside the payload, with `spdx` and `spdx_file_copyright_text` fields. The optional `_meta` object in `edition.json` follows the same convention and is not part of the manifest's required fields.

## Open-source and index rules

Every Edition must be open source. Code in an Edition inherits `GPL-2.0-or-later` from the game code. A data-only Edition that reuses official story or assets inherits `CC-BY-SA-4.0` and must remain share-alike.

The official index refuses to list an Edition when:

- `license` is absent, closed, proprietary, or incompatible with the content it reuses.
- `source_url` is absent or does not identify the corresponding public source.

The index checks the declared license and source URL, but it does not remove or restrict a local installation. Locally installed Editions always load, and an index rejection never blocks what the player runs. Index validation is a distribution rule, not a DRM or activation system.
