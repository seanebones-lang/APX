//
//  TrashBinsView.swift
//  MacCleaner
//

import SwiftUI

struct TrashBinsView: View {
    @StateObject private var viewModel = TrashBinsViewModel()
    
    var body: some View {
        ModuleView(
            title: "Trash Bins",
            description: "Empty all trash bins on your Mac",
            icon: "trash.fill",
            color: .gray,
            viewModel: viewModel
        )
    }
}

@MainActor
class TrashBinsViewModel: ObservableObject, CleaningModuleProtocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await TrashScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

