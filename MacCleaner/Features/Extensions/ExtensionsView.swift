//
//  ExtensionsView.swift
//  MacCleaner
//

import SwiftUI

struct ExtensionsView: View {
    @StateObject private var viewModel = ExtensionsViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ModuleView(
            title: "Extensions Manager",
            subtitle: "Manage Safari and system extensions",
            icon: "puzzlepiece.extension.fill",
            iconGradient: [.purple, .pink],
            isScanning: viewModel.isScanning,
            results: viewModel.extensions.map { ext in
                ScanResult(path: ext.path, size: 0, type: .other, category: ext.type)
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
                    await viewModel.removeSelected()
                }
            }
        ) {
            if !viewModel.extensions.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.extensions) { ext in
                            ExtensionRow(
                                extension: ext,
                                isSelected: viewModel.selectedExtensions.contains(ext.id),
                                onToggle: {
                                    if viewModel.selectedExtensions.contains(ext.id) {
                                        viewModel.selectedExtensions.remove(ext.id)
                                    } else {
                                        viewModel.selectedExtensions.insert(ext.id)
                                    }
                                },
                                onToggleEnabled: {
                                    Task {
                                        await viewModel.toggleExtension(ext)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if viewModel.extensions.isEmpty && !viewModel.isScanning {
                Task {
                    await viewModel.scan()
                }
            }
        }
    }
}

struct ExtensionRow: View {
    let `extension`: SystemExtension
    let isSelected: Bool
    let onToggle: () -> Void
    let onToggleEnabled: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(`extension`.name)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(`extension`.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(`extension`.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { `extension`.isEnabled },
                set: { _ in onToggleEnabled() }
            ))
            .toggleStyle(.switch)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

@MainActor
class ExtensionsViewModel: ObservableObject {
    @Published var extensions: [SystemExtension] = []
    @Published var selectedExtensions: Set<UUID> = []
    @Published var isScanning = false
    
    func scan() async {
        isScanning = true
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let extensionPaths = [
            "\(homeDir)/Library/Safari/Extensions",
            "/Library/Application Support/SystemExtensions"
        ]
        
        var foundExtensions: [SystemExtension] = []
        for path in extensionPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else { continue }
            
            for item in contents where item.hasSuffix(".appex") || item.hasSuffix(".safariextz") {
                foundExtensions.append(SystemExtension(
                    name: item,
                    path: "\(path)/\(item)",
                    type: item.hasSuffix(".safariextz") ? "Safari Extension" : "System Extension",
                    isEnabled: true
                ))
            }
        }
        
        extensions = foundExtensions
        isScanning = false
    }
    
    func removeSelected() async {
        let extensionsToRemove = extensions.filter { selectedExtensions.contains($0.id) }
        
        for ext in extensionsToRemove {
            try? FileManager.default.removeItem(atPath: ext.path)
        }
        
        extensions.removeAll { selectedExtensions.contains($0.id) }
        selectedExtensions.removeAll()
    }
    
    func toggleExtension(_ ext: SystemExtension) async {
        if let index = extensions.firstIndex(where: { $0.id == ext.id }) {
            extensions[index].isEnabled.toggle()
        }
    }
}

struct SystemExtension: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: String
    var isEnabled: Bool
}

