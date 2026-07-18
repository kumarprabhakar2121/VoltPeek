# VoltPeek

## Overview

VoltPeek is a native macOS menu bar application that displays real-time battery and charging information for MacBooks. The application runs in the background, consumes minimal resources, and updates battery statistics every few seconds.

The goal is to provide developers and power users with detailed charging information that is not easily visible through the default macOS battery menu.

---

# Target Platform

* macOS 14+
* Apple Silicon (Primary)
* Intel Macs (Optional)
* Native SwiftUI application

---

# Technology Stack

* Swift
* SwiftUI
* AppKit (Menu Bar)
* IOKit / IOPowerSources APIs
* Combine or Timer for periodic updates

No backend or cloud services are required.

---

# MVP Features

## 1. Menu Bar App

Display a battery icon in the macOS menu bar.

Example:

```
⚡ 46W
```

or

```
🔋 82%
```

User can choose the preferred display later.

---

## 2. Dropdown Window

Clicking the menu bar icon opens a small popover containing:

### Battery

* Battery Percentage
* Charging Status
* Time Remaining (if available)

### Charging

* Current Charging Power (Watts)
* Voltage (V)
* Current (A or mA)

### Battery Health

* Cycle Count
* Maximum Capacity
* Design Capacity
* Battery Health %

### Power Adapter

* Adapter Connected
* Adapter Wattage (if available)

---

## 3. Live Updates

Refresh all battery information every 2–5 seconds.

Requirements:

* No visible UI lag
* Low CPU usage
* Avoid unnecessary polling

---

## 4. Startup Option

User can enable:

* Launch at Login

---

## 5. Settings

Simple settings screen containing:

* Refresh Interval
* Show Watts in Menu Bar
* Show Battery Percentage in Menu Bar
* Launch at Login
* About

---

# Architecture

```
Application

├── MenuBarController
│
├── BatteryService
│     ├── Read IOKit
│     ├── Parse battery info
│     └── Publish updates
│
├── SettingsManager
│
├── Models
│     ├── BatteryInfo
│     └── ChargerInfo
│
└── SwiftUI Views
      ├── MenuView
      ├── SettingsView
      └── AboutView
```

---

# Models

## BatteryInfo

```swift
struct BatteryInfo {
    var percentage: Int
    var isCharging: Bool
    var currentCapacity: Int
    var maxCapacity: Int
    var designCapacity: Int
    var cycleCount: Int
    var voltage: Double
    var current: Double
    var watts: Double
    var health: Double
    var timeRemaining: String?
}
```

---

## ChargerInfo

```swift
struct ChargerInfo {
    var connected: Bool
    var adapterName: String?
    var adapterWatts: Double?
}
```

---

# UI Requirements

* Native macOS appearance
* Minimal design
* Support Light and Dark Mode
* Responsive popover
* No animations required for MVP

---

# Performance Goals

* Idle CPU usage under 1%
* Memory usage under 30 MB
* Battery polling every 2–5 seconds
* Fast application launch

---

# Future Features (Not in MVP)

* Charging history graphs
* Battery temperature
* Battery degradation timeline
* Charger and cable diagnostics
* Battery usage analytics
* Desktop widgets
* Notifications for slow charging
* CSV export
* Battery menu customization
* Multiple battery support

---

# Project Structure

```
VoltPeek/

├── App/
│   ├── VoltPeekApp.swift
│   └── MenuBarController.swift
│
├── Services/
│   ├── BatteryService.swift
│   ├── PowerSourceReader.swift
│   └── SettingsManager.swift
│
├── Models/
│   ├── BatteryInfo.swift
│   └── ChargerInfo.swift
│
├── Views/
│   ├── MenuView.swift
│   ├── BatteryCard.swift
│   ├── SettingsView.swift
│   └── AboutView.swift
│
├── Resources/
│
└── Tests/
```

---

# Coding Guidelines

* Use MVVM architecture.
* Keep UI and business logic separate.
* Prefer async APIs where appropriate.
* Use Swift concurrency where beneficial.
* Document public methods with comments.
* Write modular, testable code.
* Avoid third-party dependencies unless they provide clear value.
* Handle unavailable system values gracefully by displaying "Unavailable" instead of crashing.

---

# Definition of Done

The MVP is complete when:

* The app launches as a menu bar application.
* Live battery information updates automatically.
* Charging wattage is displayed correctly when available.
* Battery health information is shown.
* Settings persist across launches.
* The application runs efficiently without noticeable CPU or memory impact.
* The app builds and runs successfully on macOS 14+.
