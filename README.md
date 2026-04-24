# UtilityHub

An all-in-one iOS productivity companion built with SwiftUI. UtilityHub bundles the small tools you'd otherwise juggle across half a dozen apps — habits, tasks, notes, expenses, documents, and study helpers — into a single, cohesive experience.

## Features

- **Home** — A personalized dashboard with quick access to every module and at-a-glance reminders.
- **Productivity** — Task management with reminders, due dates, and bell-style notifications.
- **Habits** — Daily habit tracking with streaks, a tap-to-edit month view, and a streak heatmap.
- **Notes** — Quick capture and organization of thoughts and snippets.
- **Expenses** — Lightweight personal expense tracking.
- **Documents** — A place for important docs, including a stock documents helper.
- **Student** — Study-oriented utilities tailored for learners.
- **Settings** — App preferences and configuration.

## Tech Stack

- **SwiftUI** for the entire UI layer
- **Swift** following an MVVM architecture (per-feature `View` + `ViewModel`)
- **Firebase** (see `GoogleService-Info.plist`) for backend services
- **Local notifications** for task reminders
- Supporting Python **tools** and a **backend** folder for auxiliary data pipelines

## Project Structure

```
UtilityHub/
├── UtilityHub/              # iOS app source
│   ├── Core/                # Shared services, models, utilities
│   ├── Features/            # One folder per feature module
│   │   ├── Home/
│   │   ├── Productivity/
│   │   ├── Habits/
│   │   ├── Notes/
│   │   ├── Expenses/
│   │   ├── Documents/
│   │   ├── Student/
│   │   └── Settings/
│   ├── Resources/
│   ├── Root/
│   └── UtilityHubApp.swift  # App entry point
├── UtilityHub.xcodeproj/
├── backend/                 # Server-side helpers
└── tools/                   # Auxiliary scripts
```

## Getting Started

1. Clone the repository.
2. Open `UtilityHub.xcodeproj` in Xcode 15 or later.
3. Ensure a valid `GoogleService-Info.plist` is present in `UtilityHub/`.
4. Select an iOS 17+ simulator or device and run (⌘R).

## Requirements

- Xcode 15+
- iOS 17+
- Swift 5.9+
