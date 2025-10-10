//
//  MailAttachmentsView.swift
//  MacCleaner
//

import SwiftUI

struct MailAttachmentsView: View {
    @StateObject private var viewModel = MailAttachmentsViewModel()
    
    var body: some View {
        ModuleView(
            title: "Mail Attachments",
            description: "Clean downloaded Mail.app attachments",
            icon: "envelope.fill",
            color: .cyan,
            viewModel: viewModel
        )
    }
}

@MainActor
class MailAttachmentsViewModel: ObservableObject, CleaningModuleProtocol {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    
    func scan() async {
        isScanning = true
        results = await MailScanner.shared.scan()
        isScanning = false
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
    }
}

