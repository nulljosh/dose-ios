# dose-ios -- Claude Notes

## Overview
iOS health tracker. Drug/vitamin logging + daily check-ins. SwiftUI + @Observable. Local UserDefaults persistence (JSON-encoded). No backend.

## Dev
```bash
cd ~/Documents/Code/dose-ios
xcodegen generate
open Dose.xcodeproj
```

## Architecture
```
Views/          SwiftUI views (Dashboard, Log, History, Health)
Models/         Codable structs (Substance, DoseEntry, HealthEntry)
Services/       DataStore (@Observable, UserDefaults persistence)
DoseApp.swift   App entry point, TabView with 4 tabs
```

## Conventions
- iOS 17+, SwiftUI only, no UIKit
- @Observable (not ObservableObject)
- @Bindable for view bindings
- xcodegen for project generation (project.yml)

## Status
v1.0 -- local-only MVP. No backend, no OCR yet.
