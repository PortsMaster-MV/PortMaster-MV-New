Lucide icons

Source: https://github.com/lucide-icons/lucide/tree/f06ac67e33d645c40b8ce19a0419c85c5d7dd751

ISC license and included Feather MIT notice: see LICENSE.
White 96 pixel cells rasterized from upstream SVGs using rsvg-convert and packed horizontally with ImageMagick. Load once and tint at draw time.

Cell order: settings, x, arrow-left-right, puzzle, search, globe, paintbrush, download, pencil, folder, upload, file-pen-line, trash, check, chevron-right, lock, lock-open, mail

The second atlas, `editor.png`, uses the same pinned upstream revision and
license. Its cell order is `NAMES` in `tools/generate_save_editor_icons.py`,
matching `editorNames` in `src/ui/kit/Icons.lua`. Regenerate it with
`python3 tools/generate_save_editor_icons.py` (rsvg-convert and ImageMagick).
Navigation, dropdowns and actions use these icons instead of text glyphs.
