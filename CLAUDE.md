# dose-ios -- Claude Notes

## Overview
iOS health tracker. Drug/vitamin logging (200+ substances), interaction checking, HealthKit biometrics, CSV export, daily check-ins. SwiftUI + @Observable. Local UserDefaults persistence (JSON-encoded). No backend.

## Dev
```bash
cd ~/Documents/Code/dose-ios
xcodegen generate
open Dose.xcodeproj
```

## Architecture
```
Views/          SwiftUI views (Dashboard, Library, History, Insights, Body, Log, AddDose, InteractionChecker)
Models/         Codable structs (Substance, DoseEntry, HealthEntry, BiometricEntry)
Services/       DataStore (@Observable, UserDefaults), HealthKitService, InteractionEngine, CSVExporter
Data/           SubstanceDatabase (200+ built-in substances)
DoseApp.swift   App entry point, TabView with 4 tabs
```

## Key Services
- **DataStore** -- @Observable, UserDefaults persistence for all app data
- **HealthKitService** -- @Observable, read-only HealthKit (HR, HRV, SpO2, sleep, steps, energy, distance, weight, BP)
- **InteractionEngine** -- Drug interaction analysis (contraindications, synergies, timing)
- **CSVExporter** -- Export dose history to CSV

## Conventions
- iOS 17+, SwiftUI only, no UIKit
- @Observable (not ObservableObject)
- @Bindable for view bindings
- xcodegen for project generation (project.yml)
- HealthKit entitlements via Dose.entitlements

## Status
v2.0 -- HealthKit integration, interaction checker, CSV export, rich dose logging. Local-only, no backend.
