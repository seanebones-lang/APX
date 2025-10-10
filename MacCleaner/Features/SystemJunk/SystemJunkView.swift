//
//  SystemJunkView.swift
//  MacCleaner
//

import SwiftUI

struct SystemJunkView: View {
    @StateObject private var viewModel = SystemJunkViewModel()
    
    var body: some View {
        ModuleView(
            title: "System Junk",
            description: "Clean system and user caches, logs, and temporary files",
            icon: "paintbrush.fill",
            color: .blue,
            viewModel: viewModel
        )
    }
}

@MainActor
class SystemJunkViewModel: ObservableObject, CleaningModule Protocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await SystemJunkScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

