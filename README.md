# dose-ios

iOS health tracker for drug/vitamin logging and daily check-ins. SwiftUI, @Observable, local persistence.

## Features

- Log doses with substance, amount, and notes
- Track daily health check-ins (mood, energy, sleep)
- Dashboard with streak tracking and today's log
- Full history view with filtering

## Setup

```bash
cd ~/Documents/Code/dose-ios
xcodegen generate
open Dose.xcodeproj
```

Requires Xcode 16+, iOS 17+.

## License

MIT 2026 Joshua Trommel

## Roadmap

- [ ] Sync with web app (dose)
- [ ] HealthKit integration
- [ ] Notification reminders
- [ ] Widget for today's doses
- [ ] Interaction checker
