//
//  AppDelegate.swift
//  MacCleaner
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Preload sounds
        SoundManager.shared.preloadSounds()
        
        // Check license status
        LicenseManager.shared.validateLicense()
        
        // Setup privileged helper if needed
        PrivilegeManager.shared.checkHelperStatus()
        
        // Setup menu bar agent
        setupMenuBarAgent()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        CleaningEngine.shared.cancelAllOperations()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func setupMenuBarAgent() {
        // Launch menu bar agent if user preference enabled
        if UserDefaults.standard.bool(forKey: "showMenuBarMonitor") {
            MenuBarAgentManager.shared.launchAgent()
        }
    }
}

