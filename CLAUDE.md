# dose-ios

iOS health tracker. 200+ substances, interaction checking, HealthKit, CSV export, daily check-ins. SwiftUI + @Observable. UserDefaults persistence. No backend.

## Dev

```bash
xcodegen generate && open Dose.xcodeproj
```

## Structure

```
DoseApp.swift       TabView (Home, Library, Insights, Body)
Views/              Dashboard, Library, History, Insights, Body, Log, AddDose, InteractionChecker, Reminders
Models/             Substance, DoseEntry, HealthEntry, BiometricEntry (all Codable)
Services/           DataStore, HealthKitService, InteractionEngine, CSVExporter, NotificationService
Data/               SubstanceDatabase (200+ substances)
Tests/              Unit tests (InteractionEngine, DataStore, CSVExporter, SubstanceDatabase, HealthKitService)
DoseWidget/         WidgetKit extension (small + medium, App Group shared data)
```

## Conventions

- iOS 17+, SwiftUI only, @Observable, @Bindable
- xcodegen (project.yml), no checked-in .xcodeproj
- HealthKit entitlements via Dose.entitlements
- App Group: group.com.heyitsmejosh.dose (widget data sync)

## Status

v2.1.0 -- Notifications, widget, unit tests, error handling, swipe-to-delete, search, timestamp picker. Local-only.
