# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Add get_entity_from_part to `World` interface.
- Add a selector for the Home app
- Phases will now be shown inside the Scheduler
- Add change tracker widgets
- Add separated pane for tags in the entity widget
- Add encoding / decoding into LON for `CFrame`, `Enum`, `NumberSequence`, `NumberSequenceKeypoint`, `NumberRange`, `ColorSequence`, `ColorSequenceKeypoint`, `Region3`
- Add encoding into LON for `RaycastResult` (converts into table)
- Add resizeable columns for tables
- Add `get_entity_from_part` as an alternative from obtaining entities from a Part
- Add `jabby.register` to replace `jabby.public`. Jabby will focus more on this in version 0.3

### Changes

- Registry replication is now done through unreliable remotes
- Id column is now shorter by default
- Update to Jecs 0.5.0
- Switches away from greentea to `t` for editor performance by @ffrostfall
- Move location where remotes get added to ReplicatedStorage

### Fixed

- Fix type for `jabby.set_check_function`
- Fix parsing for entity pointers
- Fix tags and nil values appearing as userdata in the query widget
- Fix entity highlighting erroring when an entity has a tag
- Fix systems not updating their state properly on the server
- Query view should work jecs 0.3.0

### Removed

- Removed `mark_system_frame_end` and `mark_system_frame_start`
- Removed `jabby.public` due to roblox-ts incompatibility

## 0.1.0 - 2024-08-26

### Added

- Initial Release
