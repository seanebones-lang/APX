//
//  PrivacyView.swift
//  MacCleaner
//

import SwiftUI

struct PrivacyView: View {
    @StateObject private var viewModel = PrivacyViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ModuleView(
            title: "Privacy",
            subtitle: "Remove recent items, autofill data, and usage history",
            icon: "hand.raised.fill",
            iconGradient: [.yellow, .orange],
            isScanning: viewModel.isScanning,
            results: viewModel.privacyItems.map { item in
                ScanResult(path: item.path, size: item.size, type: .other, category: item.category)
            },
            onScan: {
                soundManager.play(.buttonClick)
                Task {
                    await viewModel.scan()
                }
            },
            onClean: {
                soundManager.play(.buttonClick)
                Task {
                    await viewModel.clearSelected()
                }
            }
        )
        .onAppear {
            if viewModel.privacyItems.isEmpty && !viewModel.isScanning {
                Task {
                    await viewModel.scan()
                }
            }
        }
    }
}

@MainActor
class PrivacyViewModel: ObservableObject {
    @Published var privacyItems: [PrivacyItem] = []
    @Published var isScanning = false
    
    func scan() async {
        isScanning = true
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        let paths = [
            (path: "\(homeDir)/Library/Safari/History.db", category: "Safari History"),
            (path: "\(homeDir)/Library/Safari/Downloads.plist", category: "Download History"),
            (path: "\(homeDir)/Library/Application Support/com.apple.sharedfilelist", category: "Recent Items"),
            (path: "\(homeDir)/Library/Preferences/com.apple.recentitems.plist", category: "Recent Files"),
            (path: "\(homeDir)/Library/Application Support/CrashReporter", category: "Crash Reports")
        ]
        
        var items: [PrivacyItem] = []
        for (path, category) in paths {
            if FileManager.default.fileExists(atPath: path) {
                let size = getDirectorySize(path)
                items.append(PrivacyItem(path: path, size: size, category: category))
            }
        }
        
        privacyItems = items
        isScanning = false
    }
    
    func clearSelected() async {
        for item in privacyItems {
            try? FileManager.default.removeItem(atPath: item.path)
        }
        privacyItems.removeAll()
    }
    
    private func getDirectorySize(_ path: String) -> Int64 {
        var totalSize: Int64 = 0
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path) {
            if let fileSize = attributes[.size] as? Int64 {
                totalSize = fileSize
            }
        }
        return totalSize
    }
}

struct PrivacyItem {
    let path: String
    let size: Int64
    let category: String
}

