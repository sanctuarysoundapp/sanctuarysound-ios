# Changelog

All notable changes to SanctuarySound will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-11

### Added
- 5-tab layout: Services, Inputs, Consoles, Tools, Settings
- Planning Center Online integration with OAuth 2.0 + PKCE
- Folder navigation, full service import, team import with editable checklist
- Drum kit templates (Basic 3-mic, Standard 5-mic, Full 7-mic, Custom)
- Smart PCO position classification with abbreviation expansion
- EQ Analyzer with 31-band 1/3-octave RTA via Accelerate/vDSP FFT
- Room Acoustics RT60 clap-test measurement with Schroeder integration
- Sound Engineer Q&A knowledge base (13 articles, 8 categories)
- Console Read Integration for TCP-connected mixers
- SPL monitoring with calibration, alerts, session reports, and breach logging
- Cross-tab SPL alert banner visible on all tabs
- watchOS companion app with real-time SPL from iPhone via WatchConnectivity
- WidgetKit complications for Apple Watch (circular, corner, rectangular)
- Past SPL session reports viewable on Watch
- TipKit hints in all 4 content tabs
- Onboarding with Quick Setup (5 screens)
- CSV import from Avantis Director with delta analysis
- 5 dark themes (Northern Lights, Ocean Depths, Arctic Serenity, Forest Canopy, Volcanic Wonder)
- Venue and Room hierarchy (2-level)
- Console profiles with connection types
- OSLog centralized logging with 5 categories
- Privacy manifest (PrivacyInfo.xcprivacy) for App Store

### Changed
- Restructured from single-view to 5-tab MVVM architecture
- Extracted ServiceSetupViewModel, SharedComponents, StepNavigation from large views
- Split ServiceModels.swift into 5 focused files
- Split SPLCalibrationView.swift into 3 focused views

### Fixed
- 12 force unwraps eliminated across 5 files with guard-let patterns
- SPL meter UI throttle from 50Hz to 10Hz for performance
- True data clear now fully empties store and resets onboarding
- Test target deployment version mismatch resolved
- Gain clamping crash when drum cage isolation inverts range bounds

## [0.1.0] - 2026-01-15

### Added
- Initial SoundEngine with gain, HPF, EQ, compression, and key-aware logic
- InputEntryView 4-step service setup wizard
- RecommendationDetailView with channel cards
- Allen & Heath Avantis as primary mixer model
- 9 mixer models with gain ranges and specs
- Detail Level system (Essentials, Detailed, Full)
- Dark booth-optimized UI with BoothColors
