# SPEC.md

FINALIZED

## Project Overview
EzzeMusic is a modern cross‑platform music player built with Flutter. It must provide a smooth, premium UI, reliable playback, and core features such as playlists, sleep timer, and offline caching.

## Core Requirements
- Play local audio files (MP3, AAC, FLAC).
- Persist user settings (theme, accent color, playlists) across restarts.
- Provide a dark‑mode UI with glass‑morphism cards and micro‑animations.
- Support Android, iOS, Windows, macOS, Linux, and Web.
- Implement a sleep timer that pauses playback when time elapses.
- Allow users to create, rename, reorder, and delete playlists.
- Enable offline playback by caching selected tracks.
- Provide media‑session controls (notification controls on Android/iOS).

## Non‑Functional Requirements
- **Performance:** UI should stay above 60 fps on typical devices.
- **Battery:** Background playback must be power‑efficient.
- **Accessibility:** All interactive elements must have proper semantics.
- **Testing:** 80 % unit‑test coverage for state management and core logic; widget tests for UI flows.

## Acceptance Criteria
- The app launches without crashes on all supported platforms.
- Users can play, pause, skip tracks, and see correct metadata.
- Playlists persist correctly after app restart.
- Sleep timer pauses playback at the configured time.
- UI follows the design specifications in the design system (see DESIGN.md).

## Future Enhancements (out of scope for now)
- Equalizer UI.
- Cloud sync of playlists.
- Lyrics display.
- Podcast support.
