//
//  ShredderView.swift
//  MacCleaner
//

import SwiftUI
import UniformTypeIdentifiers

struct ShredderView: View {
    @StateObject private var viewModel = ShredderViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Secure File Shredder")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Securely delete files using DoD 5220.22-M standard")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 20) {
                if viewModel.selectedFiles.isEmpty {
                    Button(action: {
                        viewModel.showFilePicker = true
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("Select Files to Shred")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Files will be securely deleted and cannot be recovered")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: 400, minHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                .foregroundColor(.secondary)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 16) {
                        HStack {
                            Text("\(viewModel.selectedFiles.count) files selected")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Passes", selection: $viewModel.passes) {
                                Text("3 passes").tag(3)
                                Text("7 passes (DoD)").tag(7)
                                Text("35 passes").tag(35)
                            }
                            .frame(width: 180)
                            
                            Button(action: {
                                viewModel.selectedFiles.removeAll()
                            }) {
                                Text("Clear")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.selectedFiles, id: \.self) { file in
                                    FileRow(path: file)
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 300)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        
                        if viewModel.isShredding {
                            VStack(spacing: 12) {
                                ProgressView(value: viewModel.progress)
                                    .frame(maxWidth: 400)
                                Text("Shredding files... \(Int(viewModel.progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: {
                                soundManager.play(.buttonClick)
                                Task {
                                    await viewModel.shredFiles()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Securely Shred Files")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 250, height: 50)
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                viewModel.selectedFiles = urls.map { $0.path }
            }
        }
        .alert("Complete", isPresented: $viewModel.showCompletionAlert) {
            Button("OK") { viewModel.showCompletionAlert = false }
        } message: {
            Text("Files have been securely shredded")
        }
    }
}

struct FileRow: View {
    let path: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.secondary)
            
            Text((path as NSString).lastPathComponent)
                .font(.system(size: 14))
            
            Spacer()
            
            Text((path as NSString).deletingLastPathComponent)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}

@MainActor
class ShredderViewModel: ObservableObject {
    @Published var selectedFiles: [String] = []
    @Published var passes: Int = 7
    @Published var showFilePicker = false
    @Published var isShredding = false
    @Published var progress: Double = 0.0
    @Published var showCompletionAlert = false
    
    func shredFiles() async {
        isShredding = true
        progress = 0.0
        
        let total = selectedFiles.count
        for (index, file) in selectedFiles.enumerated() {
            try? await PrivilegeManager.shared.secureDelete(path: file, passes: passes)
            progress = Double(index + 1) / Double(total)
        }
        
        selectedFiles.removeAll()
        isShredding = false
        showCompletionAlert = true
        SoundManager.shared.play(.success)
    }
}

