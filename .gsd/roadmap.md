# ROADMAP.md

## Phase 1 – Architecture & Refactor
- [x] Separate UI, domain, and data layers (`lib/data`, `lib/models`, `lib/state`, `lib/ui/theme`, `lib/ui/widgets/shared`).
- [x] Introduce repository pattern for song/library access (`SongsRepository`).
- [x] Extract unified theme tokens (`AppColors`, `AppTheme` with both dark and light theme definitions).
- [x] Extract shared UI components (`ThemedInputDialog`, `SongDetailsDialog`, `SelectPlaylistSheet`, `IconCircleButton`, `ThemedMenu`, `ThemedMenuItem`, `SmartMarquee`).
- [x] Optimize heavy JSON encoding/decoding using isolates (`compute`).
- [x] Fix all 118 analyzer warnings, deprecations, and dead code.

## Phase 2 – UI/UX Refresh
- [x] Redesign the app with a luxury obsidian glass palette, dynamic accent glowing, and curated accent presets.
- [x] Add SmartMarquee that eliminates scrolling jitter on short titles across Now Playing & Mini Player.
- [x] Implement smooth transitions for navigation, bottom navigation bar, floating mini player bar, and playlist detail screens.
- [x] Add live sleep timer auto-refresh and Theme Mode selector (Dark, Light, System).
- [x] Add audio format filter toggle and local file import options.

## Phase 3 – Core Features
- [x] Playlists management UI (create, rename, add songs, remove songs, delete).
- [x] Sleep timer UI with live countdown and background pause handling.
- [x] Background playback & media-session notifications (just_audio_background).
- [x] Multi-format support (`.mp3`, `.m4a`, `.aac`, `.wav`, `.flac`, `.ogg`, `.wma`, `.opus`).
- [x] Multi-song selection with bulk playlist add and bulk favorites.
- [x] Shuffle mode and 3-way Repeat modes (Off, All, One).

## Phase 4 – Testing & Quality
- [x] Write unit tests for Song model (equality, serialization, deserialization).
- [x] Write unit tests for Playlist model (immutability, operations, serialization).
- [x] Write unit tests for AppTheme & AppColors.
- [x] Add widget tests for UI flows (SmartMarquee, ThemedInputDialog).
- [x] All 11 test suites passing with 100% success rate.
