# MacCleaner - Quick Start Guide

## Getting Started in 5 Minutes

### 1. Open the Project
```bash
cd MacCleaner
open MacCleaner.xcodeproj
```

### 2. Select Your Team
- Click on **MacCleaner** project in left sidebar
- Select **MacCleaner** target
- Go to "Signing & Capabilities" tab
- Choose your **Team** from dropdown
- Repeat for **MacCleanerHelper** and **MenuBarAgent** targets

### 3. Build & Run
- Select **MacCleaner** scheme in toolbar
- Press **⌘R** (or Product > Run)
- App will launch!

## First Launch

### What You'll See
1. **Beautiful sidebar** with all 18 cleaning modules
2. **Smart Scan** dashboard (selected by default)
3. **License status** in top-right (7-day trial)

### Try Smart Scan
1. Click **"Start Scan"** button
2. Watch the **animated progress ring**
3. See **categorized results** with file counts and sizes
4. Click **"Clean Selected"** to remove files

### Explore Modules
Click on any module in the sidebar:
- **System Junk** - Clean caches and logs
- **Photo Cleaner** - Find duplicate photos
- **Large Files** - Locate space hogs
- **Space Lens** - Visualize disk usage
- **Browser Data** - Clean browser caches

## Key Features Demo

### Smart Scan
The hero feature - runs all scanners in parallel.
- Beautiful circular progress indicator
- Real-time status updates
- One-click cleanup
- Animated results

### Space Lens
DaisyDisk-style disk visualizer.
- Interactive sunburst chart
- Click segments to drill down
- Show in Finder
- Move to Trash

### Animations
Watch for:
- Progress rings with gradients
- Spring physics on buttons
- Scale effects
- Smooth transitions

### Licensing
Try the license system:
1. Click license status (top-right)
2. Enter any email
3. Use test keys:
   - `OT11-2222-3333-4444` (One-time)
   - `AN11-2222-3333-4444` (Annual)
   - `FAM1-2222-3333-4444` (Family)

## Project Structure

```
MacCleaner/
├── MacCleaner/          # Main app
│   ├── Features/        # 18 cleaning modules
│   ├── Core/            # Services & models
│   ├── UI/              # Views & components
│   └── Licensing/       # Trial & activation
├── MacCleanerHelper/    # Privileged operations
└── MenuBarAgent/        # System monitoring
```

## What's Implemented

### ✅ Fully Working (8 modules)
1. Smart Scan - Orchestrates everything
2. System Junk - 10 categories
3. Photo Cleaner - Duplicates & RAW+JPEG
4. Large Files - 100MB+ scanner
5. Mail Attachments - Mail.app cleanup
6. Trash Bins - All trash locations
7. Browser Data - 6 browsers
8. Space Lens - Disk visualizer

### 🚧 Stubs (Ready to Build)
9. Uninstaller
10. Login Items
11. Maintenance
12. Privacy
13. Malware
14. Memory Cleaner
15. App Updater
16. Shredder
17. Extensions
18. Network/Startup Optimization

## Development Workflow

### Add a New Feature
1. Open relevant module folder (e.g., `Features/Malware/`)
2. Implement scanner in `MalwareScanner.swift`
3. Update view in `MalwareView.swift`
4. Follow pattern from `SystemJunkScanner.swift`

### Test a Scanner
```swift
// In SmartScanViewModel or individual view
Task {
    let results = await YourScanner.shared.scan()
    print("Found \(results.count) items")
}
```

### Add a Sound Effect
1. Add `.mp3` file to `MacCleaner/App/Assets.xcassets/`
2. Add case to `SoundManager.SoundEffect` enum
3. Use: `SoundManager.shared.play(.yourSound)`

## Common Tasks

### Run a Single Module
1. Click module in sidebar
2. Click "Start Scan"
3. Review results
4. Click "Clean"

### Check Logs
```bash
# Main app logs
log show --predicate 'process == "MacCleaner"' --last 5m

# Helper tool logs
sudo log show --predicate 'process == "com.maccleaner.helper"' --last 5m
```

### Reset Trial
```bash
defaults delete com.maccleaner.app firstLaunchDate
```

### Uninstall Helper
```bash
sudo launchctl unload /Library/LaunchDaemons/com.maccleaner.helper.plist
sudo rm /Library/PrivilegedHelperTools/com.maccleaner.helper
```

## Keyboard Shortcuts (To Implement)

- `⌘1` - Smart Scan
- `⌘2` - System Junk
- `⌘3` - Photo Cleaner
- `⌘R` - Start Scan
- `⌘K` - Clean
- `⌘,` - Preferences
- `⌘L` - Activate License

## Tips & Tricks

### Performance
- Scans run in background threads
- Results are cached for 24 hours
- Cancel anytime with minimal overhead

### Safety
- Files moved to Trash (not deleted permanently)
- Can restore from Trash if needed
- Secure delete requires helper tool confirmation

### Customization
- Adjust colors in `Color+Extensions.swift`
- Modify animations in view files
- Change sound volume in Preferences

## Next Steps

### To Complete the Project
1. **Implement stub modules** (~40 hours)
   - Follow pattern from existing scanners
   - Use `ModuleView` for consistent UI
   
2. **Add assets** (~8 hours)
   - App icon (use SF Symbols as placeholder)
   - Sound effects (royalty-free sources)
   - Fat animated icons (optional)

3. **Test thoroughly** (~20 hours)
   - Test each scanner
   - Verify cleaning works
   - Check animations
   - Test licensing

4. **Code sign & distribute** (~4 hours)
   - Get Developer ID certificate
   - Sign all targets
   - Notarize with Apple
   - Create DMG

## Resources

### Documentation
- **README.md** - Project overview
- **BUILD.md** - Detailed build guide
- **FEATURES.md** - Complete feature list
- **PROJECT_SUMMARY.md** - Implementation details

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [XPC Services](https://developer.apple.com/documentation/xpc)
- [SMJobBless](https://developer.apple.com/library/archive/samplecode/SMJobBless/)
- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)

### Community
- [Swift Forums](https://forums.swift.org)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/swiftui)
- [Apple Developer Forums](https://developer.apple.com/forums/)

## Troubleshooting

### Build Fails
- Check code signing settings
- Verify bundle IDs are unique
- Clean build folder (⌘⇧K)

### Helper Won't Install
- Temporarily disable SIP for testing
- Check entitlements match Info.plist
- Verify code signing certificate

### Scan Doesn't Find Files
- Grant Full Disk Access in System Settings
- Check file paths exist
- Review Console.app for errors

### UI Looks Wrong
- Check macOS version (15.0+ required)
- Verify SwiftUI preview settings
- Try different appearance (Light/Dark)

## Support

Having issues? Check:
1. Console.app for crash logs
2. Build output for errors
3. Entitlements and Info.plist
4. Code signing status

## Have Fun!

Explore the codebase, experiment with features, and build something amazing! 🚀

---

© 2025 MacCleaner. Built with ❤️ using Swift 6.2 & SwiftUI.

