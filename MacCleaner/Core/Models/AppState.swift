//
//  AppState.swift
//  MacCleaner
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var selectedModule: CleaningModule = .smartScan
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    @Published var showAboutWindow: Bool = false
    @Published var showPreferences: Bool = false
    @Published var showLicenseWindow: Bool = false
    
    // Smart Scan results
    @Published var smartScanResults: SmartScanResults?
    
    // Navigation
    func navigate(to module: CleaningModule) {
        selectedModule = module
    }
}

enum CleaningModule: String, CaseIterable, Identifiable {
    case smartScan = "Smart Scan"
    case systemJunk = "System Junk"
    case photoCleaner = "Photo Cleaner"
    case largeFiles = "Large & Old Files"
    case uninstaller = "Uninstaller"
    case mailAttachments = "Mail Attachments"
    case trashBins = "Trash Bins"
    case browserData = "Browser Data"
    case errorLogs = "Error Logs"
    case loginItems = "Login Items"
    case maintenance = "Maintenance"
    case privacy = "Privacy"
    case malware = "Malware Removal"
    case spaceLens = "Space Lens"
    case memoryCleaner = "Memory Cleaner"
    case appUpdater = "App Updater"
    case shredder = "Shredder"
    case extensions = "Extensions"
    case networkOptimization = "Network"
    case startupOptimization = "Startup"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .smartScan: return "sparkles"
        case .systemJunk: return "paintbrush.fill"
        case .photoCleaner: return "camera.fill"
        case .largeFiles: return "doc.fill.badge.magnifyingglass"
        case .uninstaller: return "app.badge.minus"
        case .mailAttachments: return "envelope.fill"
        case .trashBins: return "trash.fill"
        case .browserData: return "safari.fill"
        case .errorLogs: return "exclamationmark.triangle.fill"
        case .loginItems: return "rectangle.stack.badge.play.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .privacy: return "hand.raised.fill"
        case .malware: return "shield.fill"
        case .spaceLens: return "chart.pie.fill"
        case .memoryCleaner: return "memorychip.fill"
        case .appUpdater: return "arrow.triangle.2.circlepath"
        case .shredder: return "lock.shield.fill"
        case .extensions: return "puzzlepiece.extension.fill"
        case .networkOptimization: return "network"
        case .startupOptimization: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .smartScan: return .purple
        case .systemJunk: return .blue
        case .photoCleaner: return .pink
        case .largeFiles: return .orange
        case .uninstaller: return .red
        case .mailAttachments: return .cyan
        case .trashBins: return .gray
        case .browserData: return .blue
        case .errorLogs: return .red
        case .loginItems: return .indigo
        case .maintenance: return .green
        case .privacy: return .yellow
        case .malware: return .red
        case .spaceLens: return .purple
        case .memoryCleaner: return .mint
        case .appUpdater: return .teal
        case .shredder: return .red
        case .extensions: return .purple
        case .networkOptimization: return .cyan
        case .startupOptimization: return .yellow
        }
    }
}

