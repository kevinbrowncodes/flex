# BACKLOG_001 — Flex in ten languages

## Summary

Launch's preflight (the owner's rule of 2026-11-10) wants every iOS app in ten languages, in the
store listing and in the app: en-US, es-ES, fr-FR, de-DE, ja, pt-BR, it, zh-Hans, ko, nl-NL. Flex
is in English only and has no string catalog. The owner exempted 1.1.0 (the watch release) in the
meta with a reason, the same day, so the exemption ends with 1.1.0 and the next release carries
the languages.

## User impact

A lifter whose iPhone is in Spanish, German or Japanese sees an English app and an English
listing today, and the listing is not found by searches in those languages.

## Rough scope

An epic (EPIC_002) of at least three stories: a `Localizable.xcstrings` catalog for every
user-facing string in `Flex/Flex`, `Flex/FlexWatch`, `Flex/FlexWatchWidgets` and the Siri
phrases in `Flex/FlexShared` (the 226 bundled exercise names included, or a reasoned
`shouldTranslate: false` for names lifters say in English everywhere); nine translations of the
catalog; `appstore/metadata/<locale>.json` for the nine locales (name, subtitle, keywords,
description, promotional text, what's new) listed under `localizations`; screenshots per locale
or the primary's; a gate that no string reaches the compiler outside the catalog (TV Lamp's
`check.sh` is the model). Launch's preflight is the store-side gate.

## Dependencies

STORY_012 shipped (1.1.0 live), so the exemption has done its job. Launch's `STANDARD_LANGUAGES`
is the list of record.

## Open questions

- Exercise names: translate all 226, or keep the barbell vocabulary in English with a
  `shouldTranslate: false` per name?
- Weights stay in lb (EPIC_001 deferred kg); a localized app in Germany showing lb needs the
  kg story first or alongside.

## Priority

High for 1.2.0: it is the owner's rule for every app, and 1.1.0 ships on an exemption that names
this item.
