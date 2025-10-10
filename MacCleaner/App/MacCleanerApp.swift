//
//  MacCleanerApp.swift
//  MacCleaner
//
//  The ultimate Mac cleaning application
//

import SwiftUI

@main
struct MacCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var soundManager = SoundManager.shared
    @StateObject private var licenseManager = LicenseManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .environmentObject(soundManager)
                .environmentObject(licenseManager)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    setupWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About MacCleaner") {
                    appState.showAboutWindow = true
                }
            }
        }
    }
    
    private func setupWindow() {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(named: "WindowBackground") ?? .windowBackgroundColor
        }
    }
}

