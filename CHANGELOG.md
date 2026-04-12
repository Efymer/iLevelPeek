# Changelog

## [1.1.6] - 2026-04-12

- Fix achievement comparison error when Achievement UI has been opened

## [1.1.5] - 2026-04-12

- Improve M+ rating fetching for party and raid members
- Remove debug logging

## [1.1.4] - 2026-04-09

### Fixed

- Fix tooltip errors during combat caused by tainted values
- Fix M+ rating not showing for party/raid members when mouse moves during inspect

## [1.1.3] - 2026-04-07

### Fixed

- Fix tooltip error when inspecting other players ("secret string value" taint)

## [1.1.2] - 2026-04-02

### Added

- Settings panel is now fully translated in Russian and Spanish

## [1.1.1] - 2026-04-02

### Added

- Russian localization (ruRU)
- Spanish localization (esES, esMX)

## [1.1.0] - 2026-04-02

### Added

- Raid progress display for self-player tooltip using `C_RaidLocks.IsEncounterComplete`
- Compact "Raid: X/Y D" line on main tooltip showing best difficulty with progress
- Detailed per-raid, per-difficulty breakdown in shift-hover expanded view
- Dynamic raid/encounter discovery via Encounter Journal APIs (no hardcoded IDs)

## [1.0.1] - 2026-04-01

### Fixed

- Display M+ rating as 0 instead of "--" when a player has no rating

## [1.0.0] - 2026-03-31

### Added

- Tooltip injection for player units showing item level and M+ score on a single line
- Class-colored player name and inline class highlight on the spec line
- Guild rank injected into the guild line
- Shift-hover expanded view with tier set count and top 5 M+ run breakdown
- Live shift detection re-renders the tooltip instantly without re-hovering
- Mouseover inspect with throttle, retry logic, and a 5-minute per-player cache
- Self-player support without requiring an inspect
