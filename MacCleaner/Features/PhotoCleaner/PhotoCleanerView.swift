//
//  PhotoCleanerView.swift
//  MacCleaner
//

import SwiftUI

struct PhotoCleanerView: View {
    @StateObject private var viewModel = PhotoCleanerViewModel()
    
    var body: some View {
        ModuleView(
            title: "Photo Cleaner",
            description: "Find and remove duplicate and similar photos",
            icon: "camera.fill",
            color: .pink,
            viewModel: viewModel
        )
    }
}

@MainActor
class PhotoCleanerViewModel: ObservableObject, CleaningModuleProtocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await PhotoScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

