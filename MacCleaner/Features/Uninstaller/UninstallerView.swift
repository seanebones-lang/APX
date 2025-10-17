//
//  UninstallerView.swift
//  MacCleaner
//
//

import SwiftUI

struct UninstallerView: View {
    @StateObject private var viewModel = UninstallerViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "app.badge.minus")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Uninstaller")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Remove applications and their associated files")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Scanning applications...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.applications.isEmpty {
                Button(action: {
                    soundManager.play(.buttonClick)
                    Task {
                        await viewModel.scanApplications()
                    }
                }) {
                    Text("Scan Applications")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxHeight: .infinity)
            } else {
                ApplicationListView(
                    applications: viewModel.applications,
                    selectedApps: $viewModel.selectedApps,
                    removeAssociated: $viewModel.removeAssociatedFiles,
                    onUninstall: {
                        soundManager.play(.buttonClick)
                        Task {
                            await viewModel.uninstallSelected()
                        }
                    },
                    onRescan: {
                        soundManager.play(.buttonClick)
                        Task {
                            await viewModel.scanApplications()
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if viewModel.applications.isEmpty && !viewModel.isScanning {
                Task {
                    await viewModel.scanApplications()
                }
            }
        }
        .alert("Uninstall Complete", isPresented: $viewModel.showCompletionAlert) {
            Button("OK") {
                viewModel.showCompletionAlert = false
            }
        } message: {
            Text("Successfully uninstalled \(viewModel.uninstalledCount) application(s)")
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") {
                viewModel.showErrorAlert = false
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct ApplicationListView: View {
    let applications: [Application]
    @Binding var selectedApps: Set<UUID>
    @Binding var removeAssociated: Bool
    let onUninstall: () -> Void
    let onRescan: () -> Void
    
    var totalSize: Int64 {
        applications.filter { selectedApps.contains($0.id) }
            .reduce(0) { $0 + ($1.size + (removeAssociated ? $1.associatedFilesSize : 0)) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onRescan) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Toggle("Remove associated files", isOn: $removeAssociated)
                    .toggleStyle(.switch)
                
                Spacer()
                
                Text("\(selectedApps.count) selected • \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onUninstall) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Uninstall")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selectedApps.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(applications) { app in
                        ApplicationRow(
                            app: app,
                            isSelected: selectedApps.contains(app.id),
                            showAssociated: removeAssociated,
                            onToggle: {
                                if selectedApps.contains(app.id) {
                                    selectedApps.remove(app.id)
                                } else {
                                    selectedApps.insert(app.id)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct ApplicationRow: View {
    let app: Application
    let isSelected: Bool
    let showAssociated: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 48, height: 48)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Text("Version \(app.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(app.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showAssociated && !app.associatedFiles.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("+\(ByteCountFormatter.string(fromByteCount: app.associatedFilesSize, countStyle: .file)) associated")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(app.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !app.associatedFiles.isEmpty {
                VStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                    Text("\(app.associatedFiles.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
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
class UninstallerViewModel: ObservableObject {
    @Published var applications: [Application] = []
    @Published var selectedApps: Set<UUID> = []
    @Published var isScanning: Bool = false
    @Published var removeAssociatedFiles: Bool = true
    @Published var showCompletionAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var uninstalledCount: Int = 0
    
    private let scanner = UninstallerScanner.shared
    
    func scanApplications() async {
        isScanning = true
        applications = await scanner.scanApplications()
        isScanning = false
    }
    
    func uninstallSelected() async {
        let appsToUninstall = applications.filter { selectedApps.contains($0.id) }
        uninstalledCount = 0
        
        for app in appsToUninstall {
            do {
                try await scanner.uninstallApplication(app, removeAssociatedFiles: removeAssociatedFiles)
                uninstalledCount += 1
            } catch {
                errorMessage = "Failed to uninstall \(app.name): \(error.localizedDescription)"
                showErrorAlert = true
                return
            }
        }
        
        applications.removeAll { selectedApps.contains($0.id) }
        selectedApps.removeAll()
        
        if uninstalledCount > 0 {
            showCompletionAlert = true
            SoundManager.shared.play(.success)
        }
    }
}

