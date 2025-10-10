//
//  BrowserDataView.swift
//  MacCleaner
//

import SwiftUI

struct BrowserDataView: View {
    @StateObject private var viewModel = BrowserDataViewModel()
    
    var body: some View {
        ModuleView(
            title: "Browser Data",
            description: "Clean browser caches and temporary files",
            icon: "safari.fill",
            color: .blue,
            viewModel: viewModel
        )
    }
}

@MainActor
class BrowserDataViewModel: ObservableObject, CleaningModuleProtocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await BrowserScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

