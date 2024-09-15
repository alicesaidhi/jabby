# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- Add get_entity_from_part to `World` interface.
- Add a selector for the Home app
- Phases will now be shown inside the Scheduler
- Add support for Enum and CFrame
- Add change tracker widgets

### Fixed
- Fix type for `jabby.set_check_function`
- Fix tags and nil values appearing as userdata in the query widget
- Query view should work jecs 0.3.0

### Removed
- Removed `mark_system_frame_end` and `mark_system_frame_start`

## 0.1.0 - 2024-08-26

### Added

- Initial Release