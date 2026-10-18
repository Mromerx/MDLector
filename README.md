# MDLector

A Flutter reader for **Markdown books** with tap-to-translate and
select-to-translate, powered by Google Translate (public endpoint, no API key).

Typical use case: convert a PDF/EPUB book to Markdown with an external tool,
drop the `.md` file into MDLector, and read it while looking up any word or
fragment on the fly.

The UI is in English. The style (colors, dialogs, settings) is shared with the
[Lylyrics](https://github.com/maxi/lylyrics) reader, but the text is rendered as
plain, readable prose.

## Features

- **Markdown reader** — headings, paragraphs, lists, blockquotes, fenced code
  blocks and rules, rendered as normal text (inline syntax is cleaned up).
- **Tap a word to translate it** — a single tap on any word opens a dialog with
  its translation and, when available, the Google dictionary senses
  ("MEANINGS").
- **Long-press to select and translate** — select any fragment; the context
  menu offers a **Translate** action for the selected text.
- **Font size** — adjustable from the settings dialog (12–48 pt).
- **Dark theme** — light/dark toggle.
- **Translator target** — choose the language words/fragments are translated
  into (12 languages).
- **Lazy loading** — the document is rendered with a `ListView.builder`, so
  only the blocks near the viewport are built as you scroll. Long books open
  instantly and stay smooth.

## Requirements

- Flutter 3.44+ / Dart 3.12+
- A connected device or desktop target (Linux or Android are configured).

## Run

```bash
flutter pub get
flutter run -d linux      # desktop
flutter run -d <android>  # Android device/emulator
```

## Build

```bash
# Linux desktop bundle
flutter build linux --release

# Android APK
flutter build apk --release
```

## Usage

1. Tap the folder icon (or **Open file** on the welcome screen) and pick a
   `.md`, `.markdown` or `.txt` file.
2. Scroll to read; content loads on demand.
3. **Tap** a word to see its meaning.
4. **Long-press and drag** to select a fragment, then tap **Translate** in the
   menu.
5. Open **Settings** (tune icon) to change font size, theme and translation
   language.

### Converting books

MDLector reads Markdown only. Convert your source first, for example:

```bash
# EPUB -> Markdown
pandoc book.epub -t gfm -o book.md

# PDF -> Markdown (pandoc, or a dedicated OCR tool for scanned PDFs)
pandoc book.pdf -t gfm -o book.md
```

## How translation works

Translation uses the public Google Translate `gtx` endpoint
(`translate.googleapis.com/translate_a/single`) with no API key, exactly like
Lylyrics:

- `lib/services/translation_service.dart` — `translateText` for fragments and
  `lookUp` for a single word (translation + `dt=bd` dictionary senses).
- `lib/services/markdown_parser.dart` — block parser and the word tokenizer
  used to map a tap position to the word under the finger.

No meaning is stored: lookups are live requests. Failed or identical-language
lookups show a clear "no translation" message.

## Settings

Declared once in `lib/state/app_settings.dart` and persisted with
`shared_preferences`:

| Setting          | Key                    | Default | Range / options |
| ---------------- | ---------------------- | ------- | --------------- |
| Font size        | `ui.fontSize`          | 18 pt   | 12–48 pt        |
| Dark theme       | `ui.themeIsDark`       | off     | on/off          |
| Translation lang | `ui.translationTarget` | `es`    | 12 languages    |

## Project structure

```
lib/
  main.dart                          App root, theme (Lylyrics palette)
  services/
    markdown_parser.dart             Block parser + tokenizer + cleanInline
    translation_service.dart         Google Translate (word + text)
  state/
    app_settings.dart                Settings definitions + persistence
    reader_providers.dart            File picking, document parsing, HTTP
  ui/
    screens/
      reader_screen.dart             App bar, welcome/error states, reader
      settings_panel.dart            Settings dialog
    widgets/
      markdown_content.dart          Lazy list + tappable/selectable text
      translation_dialogs.dart       Word meaning and selected-text dialogs
      settings_tiles.dart            Reusable settings controls
      dialog_header.dart             Shared dialog header
```

## Tests

```bash
flutter test
```

Covers the Markdown parser, the tokenizer, `cleanWord` and a widget-render test
of the reader.

## Limitations

- Markdown support is intentionally lightweight (no tables, footnotes, math or
  nested-list indentation levels yet).
- Google Translate requires an internet connection and is an undocumented
  public endpoint; heavy use may be rate-limited.
- Translation is not cached between sessions.
