//
//  UninstallerView.swift
//  MacCleaner
//

import SwiftUI

struct UninstallerView: View {
    @StateObject private var viewModel = UninstallerViewModel()
    
    var body: some View {
        Text("Uninstaller - Coming Soon")
            .font(.title)
    }
}

@MainActor
class UninstallerViewModel: ObservableObject {
    @Published var applications: [Application] = []
}

struct Application: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
}

