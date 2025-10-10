# MacCleaner Pro

The ultimate Mac cleaning and optimization application for macOS 15+.

## Features

### Smart Scan
- Orchestrates all cleaning modules in parallel
- Beautiful CleanMyMac-inspired UI with animations
- One-click cleanup with intelligent suggestions

### Cleaning Modules

1. **System Junk** - Clean system/user caches, logs, temp files, iOS backups, Xcode cache
2. **Photo Cleaner** - Find duplicate photos, similar images, RAW+JPEG pairs
3. **Large & Old Files** - Locate files over 100MB taking up space
4. **Uninstaller** - Remove apps with all associated files
5. **Mail Attachments** - Clean Mail.app downloads and attachments
6. **Trash Bins** - Empty all trash bins (System, Photos, Mail)
7. **Browser Data** - Clean caches for Safari, Chrome, Firefox, Edge, Brave, Arc
8. **Login Items** - Manage startup items and launch agents
9. **Maintenance** - Run disk repair, Spotlight rebuild, maintenance scripts
10. **Privacy** - Remove recent items, autofill data, Siri data
11. **Malware Removal** - Scan for adware and malware
12. **Space Lens** - Visualize disk usage with interactive sunburst chart
13. **Memory Cleaner** - Free up RAM and kill memory hogs
14. **App Updater** - Check and update all installed apps
15. **Shredder** - Securely delete files (DoD 5220.22-M standard)
16. **Extensions Manager** - Manage Safari and system extensions
17. **Network Optimization** - Optimize DNS, run diagnostics
18. **Startup Optimization** - Analyze and optimize boot time

### Additional Features

- **Menu Bar Monitor** - Real-time CPU, RAM, and network monitoring
- **Sound Effects** - Satisfying audio feedback for all actions
- **Beautiful Animations** - Spring physics, particle effects, smooth transitions
- **Licensing System** - 7-day trial, multiple pricing tiers

## Architecture

### Tech Stack
- **Language**: Swift 6.2
- **UI Framework**: SwiftUI with custom animations
- **Architecture**: MVVM with Combine/Observation
- **Privileges**: XPC-based privileged helper tool (SMJobBless)
- **Storage**: UserDefaults + SQLite for scan cache

### Project Structure

```
MacCleaner/
├── MacCleaner/              # Main application
│   ├── App/                 # Entry point
│   ├── Core/                # Models, Services, Helpers
│   ├── UI/                  # Views and Components
│   ├── Features/            # 18 cleaning modules
│   └── Licensing/           # Trial and license activation
├── MacCleanerHelper/        # Privileged XPC helper
└── MenuBarAgent/            # Menu bar monitoring app
```

## Building

### Requirements
- Xcode 15.0+
- macOS 15.0+ (Sequoia)
- Swift 6.2

### Build Instructions

1. Open `MacCleaner.xcodeproj` in Xcode
2. Select the MacCleaner scheme
3. Build and run (⌘R)

**Note**: The helper tool requires code signing and provisioning for installation. For development, you may need to disable System Integrity Protection (SIP) or use a development certificate.

## Pricing

- **One-Time Purchase**: $79.95
- **Annual Subscription**: $34.95/year
- **Family Pack (5 Macs)**: $119.95

7-day free trial included.

## License Activation

License keys follow the format: `XXXX-XXXX-XXXX-XXXX`

- Keys starting with `OT` - One-time purchase
- Keys starting with `AN` - Annual subscription  
- Keys starting with `FAM` - Family pack

## Development Status

✅ Core architecture implemented
✅ Smart Scan with animations
✅ 6 scanning modules (System Junk, Photos, Large Files, Mail, Trash, Browser)
✅ Privileged helper tool
✅ Menu bar agent
✅ Licensing system
✅ Beautiful UI with CleanMyMac-inspired design

🚧 Additional modules in progress (12 more to complete)
🚧 Space Lens disk visualizer
🚧 Advanced animations and particle effects
🚧 Sound file assets

## Contributing

This is a commercial product. Contributions are not currently accepted.

## Copyright

© 2025 MacCleaner. All rights reserved.

