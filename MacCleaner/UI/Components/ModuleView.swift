//
//  ModuleView.swift
//  MacCleaner
//
//  Reusable view for cleaning modules
//

import SwiftUI

protocol CleaningModuleProtocol: ObservableObject {
    var isScanning: Bool { get set }
    var results: [ScanResult] { get set }
    
    func scan() async
    func clean() async throws
}

struct ModuleView<ViewModel: CleaningModuleProtocol>: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject var soundManager: SoundManager
    
    var totalSize: Int64 {
        viewModel.results.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(30)
            
            Divider()
            
            // Content
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Scanning...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else if viewModel.results.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: icon)
                        .font(.system(size: 64))
                        .foregroundColor(color.opacity(0.3))
                    
                    Text("No scan results yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Button("Start Scan") {
                        soundManager.play(.buttonClick)
                        Task {
                            await viewModel.scan()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: color))
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    // Summary
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(viewModel.results.count) items found")
                                .font(.title2.bold())
                            
                            Text(formattedSize)
                                .font(.title.bold())
                                .foregroundColor(color)
                        }
                        
                        Spacer()
                        
                        Button("Clean") {
                            soundManager.play(.buttonClick)
                            Task {
                                try? await viewModel.clean()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(color: color))
                    }
                    .padding(20)
                    
                    Divider()
                    
                    // Results list
                    List(viewModel.results) { result in
                        HStack {
                            Image(systemName: fileIcon(for: result.type))
                                .foregroundColor(color)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.filename)
                                    .font(.system(size: 14))
                                
                                Text(result.directory)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(result.formattedSize)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func fileIcon(for type: FileType) -> String {
        switch type {
        case .cache: return "folder.fill"
        case .log: return "doc.text.fill"
        case .temporary: return "clock.fill"
        case .download: return "arrow.down.circle.fill"
        case .duplicate: return "doc.on.doc.fill"
        case .large: return "doc.fill"
        case .application: return "app.fill"
        case .document: return "doc.fill"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .archive: return "archivebox.fill"
        case .trash: return "trash.fill"
        case .other: return "doc.fill"
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

