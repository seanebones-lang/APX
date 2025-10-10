//
//  LargeFilesView.swift
//  MacCleaner
//

import SwiftUI

struct LargeFilesView: View {
    @StateObject private var viewModel = LargeFilesViewModel()
    
    var body: some View {
        ModuleView(
            title: "Large & Old Files",
            description: "Find large files taking up space on your Mac",
            icon: "doc.fill.badge.magnifyingglass",
            color: .orange,
            viewModel: viewModel
        )
    }
}

@MainActor
class LargeFilesViewModel: ObservableObject, CleaningModuleProtocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await LargeFileScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

