# Changelog

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
