# Translations

Omautoclicker follows Omarchy's selected language through `Commons.Translations`.
All 50 codes in Omarchy's `default/i18n/locales.json` have complete JSON catalogs.
The plugin makes no translation-service or other network request at runtime.

English is the source catalog. The initial non-English catalogs were
machine-assisted, then checked for placeholders, executable names and
context-sensitive mouse-button terminology. Native-speaker improvements are
welcome; complete coverage does not imply professional linguistic review.

When editing a catalog:

- Keep every key from `i18n/en.json` and preserve `%1` placeholders.
- Keep the product name, `ydotool` and `ydotoold` unchanged.
- Left/right refer to mouse buttons, not correctness.
- Keep labels concise. Complete sentences can wrap; do not concatenate sentence fragments.
- Seconds (`s`) and milliseconds (`ms`) are supplied as units at runtime.

Run `bin/test` to verify every catalog against Omarchy's registry. In a Wayland
session, `OMAUTOC_TEST_LANG=all bin/test` also loads and interacts with every
localized panel, checks automatic selection, and detects text overflow.
`tests/ci-wayland` performs this in a separate headless compositor and writes
one PNG per language to `ci-previews/`. The GitHub Actions run retains these as
an artifact for visual review.

Missing or future unrecognized languages retain Omarchy's normal English
fallback; current supported languages are required to be complete by CI.
