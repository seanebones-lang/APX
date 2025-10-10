# Building MacCleaner

Complete guide to building and running the ultimate Mac cleaner application.

## Prerequisites

- **macOS 15.0+** (Sequoia or later)
- **Xcode 15.0+**
- **Swift 6.2**
- **Apple Developer Account** (for code signing)

## Project Structure

```
MacCleaner/
├── MacCleaner/              # Main app (sandboxed)
├── MacCleanerHelper/        # Privileged helper tool (non-sandboxed)
├── MenuBarAgent/            # Menu bar agent (background app)
└── MacCleaner.xcodeproj/    # Xcode project
```

## Setup Instructions

### 1. Clone/Open Project

```bash
cd MacCleaner
open MacCleaner.xcodeproj
```

### 2. Configure Code Signing

#### Main App Target (MacCleaner)
1. Select MacCleaner target
2. Go to "Signing & Capabilities"
3. Select your Team
4. Bundle Identifier: `com.maccleaner.app`
5. Ensure these entitlements are enabled:
   - App Sandbox: NO (disabled for system access)
   - Automation: YES
   - File Access: User Selected, Downloads

#### Helper Tool Target (MacCleanerHelper)
1. Select MacCleanerHelper target
2. Go to "Signing & Capabilities"
3. Select your Team
4. Bundle Identifier: `com.maccleaner.helper`
5. Code sign with same certificate as main app

#### Menu Bar Agent Target (MenuBarAgent)
1. Select MenuBarAgent target
2. Go to "Signing & Capabilities"
3. Select your Team
4. Bundle Identifier: `com.maccleaner.menubar`

### 3. Update Info.plist Files

#### MacCleaner/Info.plist
Verify `SMPrivilegedExecutables` contains:
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.maccleaner.helper</key>
    <string>identifier "com.maccleaner.helper"</string>
</dict>
```

#### MacCleanerHelper/Info.plist
Verify `SMAuthorizedClients` contains:
```xml
<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.maccleaner.app"</string>
</array>
```

### 4. Build Configuration

#### Debug Build
```bash
xcodebuild -scheme MacCleaner -configuration Debug
```

#### Release Build
```bash
xcodebuild -scheme MacCleaner -configuration Release
```

### 5. Install Helper Tool

The helper tool installation requires administrator privileges:

1. Run the main app
2. On first launch, you'll be prompted to install the helper
3. Enter your admin password
4. The helper will be installed to `/Library/PrivilegedHelperTools/`

## Development Tips

### Debugging

#### Enable XPC Logging
```bash
sudo log config --mode "level:debug" --subsystem com.maccleaner.helper
log stream --predicate 'subsystem == "com.maccleaner.helper"'
```

#### Check Helper Status
```bash
sudo launchctl list | grep com.maccleaner.helper
```

#### Uninstall Helper (for testing)
```bash
sudo launchctl unload /Library/LaunchDaemons/com.maccleaner.helper.plist
sudo rm /Library/PrivilegedHelperTools/com.maccleaner.helper
sudo rm /Library/LaunchDaemons/com.maccleaner.helper.plist
```

### Common Issues

#### Issue: "Code signing failed"
**Solution**: Ensure all three targets use the same development team and signing certificate.

#### Issue: "Helper tool not installing"
**Solution**: 
1. Disable SIP temporarily: `csrutil disable` (requires reboot)
2. Or use a properly signed developer certificate
3. Re-enable SIP after testing: `csrutil enable`

#### Issue: "Permission denied" when scanning
**Solution**: Grant Full Disk Access in System Settings > Privacy & Security > Full Disk Access

#### Issue: "App crashes on launch"
**Solution**: Check Console.app for crash logs. Common causes:
- Missing entitlements
- Code signing mismatch
- Helper tool not installed

## Testing

### Manual Testing Checklist

- [ ] Smart Scan completes successfully
- [ ] System Junk finds cache files
- [ ] Photo Cleaner detects duplicates
- [ ] Large Files scanner works
- [ ] Mail/Trash/Browser scanners functional
- [ ] Cleaning operations delete files
- [ ] Animations play smoothly
- [ ] Sounds play correctly
- [ ] License activation works
- [ ] Menu bar agent launches
- [ ] Helper tool installs successfully

### Performance Testing

Monitor with Instruments:
```bash
instruments -t "Time Profiler" -D profile.trace MacCleaner.app
```

## Distribution

### Create Distributable Build

1. Archive the app (Product > Archive)
2. Export for distribution
3. Notarize with Apple:

```bash
xcrun notarytool submit MacCleaner.zip \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

4. Staple notarization:
```bash
xcrun stapler staple MacCleaner.app
```

### Create DMG

```bash
create-dmg \
  --volname "MacCleaner" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "MacCleaner.app" 200 190 \
  --hide-extension "MacCleaner.app" \
  --app-drop-link 600 185 \
  "MacCleaner-1.0.0.dmg" \
  "dist/"
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build MacCleaner

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.0.app
      
      - name: Build
        run: xcodebuild -scheme MacCleaner -configuration Release
      
      - name: Test
        run: xcodebuild test -scheme MacCleaner
```

## Troubleshooting Resources

- **Apple Developer Forums**: https://developer.apple.com/forums/
- **XPC Documentation**: https://developer.apple.com/documentation/xpc
- **SMJobBless Guide**: https://developer.apple.com/library/archive/samplecode/SMJobBless/

## Support

For issues or questions:
- Check the README.md
- Review Console.app logs
- Enable debug logging
- Check entitlements and code signing

## License

© 2025 MacCleaner. All rights reserved. Commercial software.

